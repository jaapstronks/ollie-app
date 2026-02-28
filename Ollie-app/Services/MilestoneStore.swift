//
//  MilestoneStore.swift
//  Ollie-app
//
//  Manages milestones with Core Data and automatic CloudKit sync

import Foundation
import CoreData
import OllieShared
import Combine
import os

/// Manages milestones with Core Data and automatic CloudKit sync
@MainActor
class MilestoneStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var milestones: [Milestone] = []
    @Published private(set) var isSyncing = false
    /// Last error that occurred during a store operation (for UI display)
    @Published private(set) var lastError: (message: String, date: Date)? = nil

    /// Clear the last error (call when user dismisses error banner)
    func clearError() {
        lastError = nil
    }

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "MilestoneStore")
    private var cancellables = Set<AnyCancellable>()

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Computed Properties

    /// All completed milestones
    var completedMilestones: [Milestone] {
        milestones.filter { $0.isCompleted }
    }

    /// All incomplete milestones
    var incompleteMilestones: [Milestone] {
        milestones.filter { !$0.isCompleted }
    }

    /// Count of completed milestones
    var completedCount: Int {
        completedMilestones.count
    }

    /// Count of total milestones
    var totalCount: Int {
        milestones.count
    }

    /// Progress fraction (0.0 to 1.0)
    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadMilestones()
        setupRemoteChangeObserver()
    }

    // MARK: - Setup

    private func setupRemoteChangeObserver() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change for milestones")
        loadMilestones()
    }

    // MARK: - Milestone Loading

    private func loadMilestones() {
        let cdMilestones = CDMilestone.fetchAllMilestones(in: viewContext)
        milestones = cdMilestones.compactMap { $0.toMilestone() }
        logger.info("Loaded \(self.milestones.count) milestones from Core Data")
    }

    // MARK: - Seeding Default Milestones

    /// Seed default milestones if none exist
    func seedDefaultMilestonesIfNeeded() {
        let count = CDMilestone.countMilestones(in: viewContext)

        if count == 0 {
            logger.info("No milestones found, seeding defaults")
            let defaults = DefaultMilestones.create()

            for milestone in defaults {
                _ = CDMilestone.create(from: milestone, in: viewContext)
            }

            do {
                try persistenceController.save()
                loadMilestones()
                logger.info("Seeded \(defaults.count) default milestones")
            } catch {
                logger.error("Failed to seed default milestones: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - CRUD Operations

    /// Add a new milestone
    /// - Returns: `true` if the milestone was saved successfully, `false` otherwise
    @discardableResult
    func addMilestone(_ milestone: Milestone) -> Bool {
        _ = CDMilestone.create(from: milestone, in: viewContext)

        do {
            try persistenceController.save()
            // Only update in-memory state after confirming persistence succeeded
            milestones.append(milestone)
            milestones.sort { $0.sortOrder < $1.sortOrder }
            lastError = nil
            logger.info("Added milestone: \(milestone.labelKey)")
            return true
        } catch {
            // Rollback the unsaved Core Data change
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to add milestone: \(error.localizedDescription)")
            return false
        }
    }

    /// Update an existing milestone
    /// - Returns: `true` if the milestone was updated successfully, `false` otherwise
    @discardableResult
    func updateMilestone(_ milestone: Milestone) -> Bool {
        guard let cdMilestone = CDMilestone.fetch(byId: milestone.id, in: viewContext) else {
            logger.warning("Milestone not found for update: \(milestone.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        cdMilestone.update(from: milestone)

        do {
            try persistenceController.save()
            // Only update in-memory state after confirming persistence succeeded
            if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
                milestones[index] = milestone
            }
            lastError = nil
            logger.info("Updated milestone: \(milestone.labelKey)")
            return true
        } catch {
            // Rollback the unsaved Core Data change
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to update milestone: \(error.localizedDescription)")
            return false
        }
    }

    /// Delete a milestone
    /// - Returns: `true` if the milestone was deleted successfully, `false` otherwise
    @discardableResult
    func deleteMilestone(_ milestone: Milestone) -> Bool {
        guard let cdMilestone = CDMilestone.fetch(byId: milestone.id, in: viewContext) else {
            logger.warning("Milestone not found for deletion: \(milestone.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        viewContext.delete(cdMilestone)

        do {
            try persistenceController.save()
            // Only update in-memory state after confirming persistence succeeded
            milestones.removeAll { $0.id == milestone.id }
            lastError = nil
            logger.info("Deleted milestone: \(milestone.labelKey)")
            return true
        } catch {
            // Rollback the unsaved Core Data change
            viewContext.rollback()
            lastError = (Strings.Common.deleteFailed, Date())
            logger.error("Failed to delete milestone: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Completion

    /// Mark a milestone as completed
    func completeMilestone(
        _ milestone: Milestone,
        notes: String? = nil,
        photoID: UUID? = nil,
        vetClinicName: String? = nil,
        completionDate: Date? = nil
    ) {
        var updated = milestone
        updated.isCompleted = true
        updated.completedDate = completionDate ?? Date()
        updated.completionNotes = notes
        updated.completionPhotoID = photoID
        updated.vetClinicName = vetClinicName
        updated.modifiedAt = Date()

        updateMilestone(updated)
    }

    /// Uncomplete a milestone (mark as not done)
    func uncompleteMilestone(_ milestone: Milestone) {
        var updated = milestone
        updated.isCompleted = false
        updated.completedDate = nil
        updated.modifiedAt = Date()

        updateMilestone(updated)
    }

    /// Toggle completion status
    func toggleMilestoneCompletion(_ milestone: Milestone) {
        if milestone.isCompleted {
            uncompleteMilestone(milestone)
        } else {
            completeMilestone(milestone)
        }
    }

    // MARK: - Calendar Integration

    /// Update calendar event ID for a milestone
    func updateCalendarEventID(_ milestone: Milestone, eventID: String?) {
        var updated = milestone
        updated.calendarEventID = eventID
        updated.modifiedAt = Date()

        updateMilestone(updated)
    }

    // MARK: - Filtering & Queries

    /// Get milestones by category
    func milestones(for category: MilestoneCategory) -> [Milestone] {
        milestones.filter { $0.category == category }
    }

    /// Get milestone by ID
    func milestone(withId id: UUID) -> Milestone? {
        milestones.first { $0.id == id }
    }

    /// Get upcoming milestones (within next N days)
    func upcomingMilestones(birthDate: Date, withinDays: Int = 14) -> [Milestone] {
        let now = Date()
        return milestones.filter { milestone in
            guard !milestone.isCompleted,
                  let _ = milestone.targetDate(birthDate: birthDate),
                  let daysUntil = milestone.daysUntil(birthDate: birthDate, from: now) else {
                return false
            }
            return daysUntil >= 0 && daysUntil <= withinDays
        }.sorted { milestone1, milestone2 in
            let days1 = milestone1.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            let days2 = milestone2.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            return days1 < days2
        }
    }

    /// Get overdue milestones
    func overdueMilestones(birthDate: Date) -> [Milestone] {
        milestones.filter { milestone in
            milestone.status(birthDate: birthDate) == .overdue
        }
    }

    /// Get next milestone that needs attention
    func nextUpMilestone(birthDate: Date) -> Milestone? {
        milestones
            .filter { !$0.isCompleted && $0.isActionable }
            .filter { $0.status(birthDate: birthDate) == .nextUp || $0.status(birthDate: birthDate) == .overdue }
            .sorted { milestone1, milestone2 in
                let date1 = milestone1.targetDate(birthDate: birthDate) ?? .distantFuture
                let date2 = milestone2.targetDate(birthDate: birthDate) ?? .distantFuture
                return date1 < date2
            }
            .first
    }

    /// Get milestones with status
    func milestonesWithStatus(birthDate: Date, status: MilestoneStatus) -> [Milestone] {
        milestones.filter { $0.status(birthDate: birthDate) == status }
    }

    /// Get actionable milestones due within this week (7 days)
    /// Excludes developmental milestones (isActionable: false)
    func milestonesThisWeek(birthDate: Date) -> [Milestone] {
        let now = Date()
        return milestones.filter { milestone in
            guard !milestone.isCompleted,
                  milestone.isActionable,
                  let daysUntil = milestone.daysUntil(birthDate: birthDate, from: now) else {
                return false
            }
            // Include overdue (negative) and within 7 days
            return daysUntil <= 7
        }.sorted { milestone1, milestone2 in
            let days1 = milestone1.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            let days2 = milestone2.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            return days1 < days2
        }
    }

    /// Get actionable milestones coming up in 2-4 weeks
    /// Excludes developmental milestones (isActionable: false)
    func milestonesComingUp(birthDate: Date) -> [Milestone] {
        let now = Date()
        return milestones.filter { milestone in
            guard !milestone.isCompleted,
                  milestone.isActionable,
                  let daysUntil = milestone.daysUntil(birthDate: birthDate, from: now) else {
                return false
            }
            // Between 8 and 28 days (2-4 weeks)
            return daysUntil > 7 && daysUntil <= 28
        }.sorted { milestone1, milestone2 in
            let days1 = milestone1.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            let days2 = milestone2.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            return days1 < days2
        }
    }

    /// Get active developmental periods (non-actionable milestones that apply to current age)
    /// These include socialization window markers and fear periods
    func activeDevelopmentalPeriods(birthDate: Date) -> [Milestone] {
        let ageInWeeks = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0

        return milestones.filter { milestone in
            guard !milestone.isActionable,
                  milestone.category == .developmental else {
                return false
            }

            // Check if this developmental period is currently active
            if let targetWeeks = milestone.targetAgeWeeks {
                // Socialization periods are active from their start week
                if milestone.labelKey.contains("socialization") {
                    // Socialization window: 8-16 weeks
                    if milestone.labelKey.contains("Start") {
                        return ageInWeeks >= targetWeeks && ageInWeeks <= 16
                    }
                    if milestone.labelKey.contains("Peak") {
                        return ageInWeeks >= targetWeeks && ageInWeeks <= 16
                    }
                    if milestone.labelKey.contains("End") {
                        return ageInWeeks >= 14 && ageInWeeks <= 18
                    }
                }
                // Fear periods are active for about 2-3 weeks around target
                if milestone.labelKey.contains("fearPeriod") {
                    return abs(ageInWeeks - targetWeeks) <= 2
                }
            }

            if let targetMonths = milestone.targetAgeMonths {
                let ageInMonths = ageInWeeks / 4
                // Fear period 2 around 6 months
                if milestone.labelKey.contains("fearPeriod") {
                    return abs(ageInMonths - targetMonths) <= 1
                }
            }

            return false
        }
    }

    // MARK: - Calendar Grid Support

    /// Get milestones that fall within the week containing the given date
    /// Returns actionable milestones due in that week
    func milestones(inWeekOf date: Date, birthDate: Date) -> [Milestone] {
        let calendar = Calendar.current

        // Get the start of the week containing the date
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }

        return milestones.filter { milestone in
            guard !milestone.isCompleted,
                  milestone.isActionable,
                  let targetDate = milestone.targetDate(birthDate: birthDate) else {
                return false
            }
            let targetDay = calendar.startOfDay(for: targetDate)
            return targetDay >= weekStart && targetDay < weekEnd
        }.sorted { milestone1, milestone2 in
            let date1 = milestone1.targetDate(birthDate: birthDate) ?? .distantFuture
            let date2 = milestone2.targetDate(birthDate: birthDate) ?? .distantFuture
            return date1 < date2
        }
    }

    /// Get milestone spans for a date range (for calendar month view)
    /// Returns MilestoneSpan objects with their week ranges for background tinting
    func milestoneSpans(from startDate: Date, to endDate: Date, birthDate: Date) -> [MilestoneSpan] {
        let calendar = Calendar.current

        return milestones.compactMap { milestone -> MilestoneSpan? in
            guard !milestone.isCompleted,
                  milestone.isActionable,
                  let targetDate = milestone.targetDate(birthDate: birthDate) else {
                return nil
            }

            // Get the week containing the target date
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: targetDate)),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return nil
            }

            // Check if this week overlaps with the date range
            guard weekEnd > startDate && weekStart < endDate else {
                return nil
            }

            return MilestoneSpan(
                id: milestone.id,
                milestone: milestone,
                weekStartDate: weekStart,
                weekEndDate: weekEnd
            )
        }
    }

    // MARK: - CloudKit Sync

    /// Sync milestones from CloudKit (no-op with automatic sync)
    func syncFromCloud() async {
        viewContext.refreshAllObjects()
        loadMilestones()
    }
}
