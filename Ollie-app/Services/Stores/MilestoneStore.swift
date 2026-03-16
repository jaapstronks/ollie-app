//
//  MilestoneStore.swift
//  Otis-app
//
//  Manages milestones with Core Data and CKSyncEngine-based CloudKit sync

import Foundation
import CoreData
import OtisShared
import os

/// Manages milestones with Core Data and CKSyncEngine-based CloudKit sync
@MainActor
final class MilestoneStore: CRUDStore<Milestone, CDMilestone>, ProfileAccessible {

    // MARK: - ProfileAccessible

    weak var profileStore: ProfileStore?

    // MARK: - Cached Computed Properties

    private var _cachedCompletedMilestones: [Milestone]?
    private var _cachedIncompleteMilestones: [Milestone]?

    // MARK: - Sort Order

    override var sortOrder: StoreSortOrder<Milestone> {
        .ascending(\.sortOrder)
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "MilestoneStore")
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        invalidateCaches()

        // Only migrate orphans if profile is owned (in private store)
        // Shared profiles can't have relationships with private store entities
        if isCurrentProfileOwned, let profile = getCurrentProfile() {
            migrateOrphanedMilestones(to: profile)
        }

        // Then load items (will use profile-scoped fetch if available)
        super.performInitialLoad()
    }

    /// Override to load profile-scoped items when profile is available
    override func loadItems() {
        if let profile = getCurrentProfile() {
            // Load profile-scoped milestones
            let cdMilestones = CDMilestone.fetchAllMilestones(for: profile, in: viewContext)
            let loadedItems = cdMilestones.compactMap { $0.toMilestone() }
            setItems(loadedItems)
            logger.debug("Loaded \(loadedItems.count) milestones for profile")
        } else {
            // Fallback to loading all records
            super.loadItems()
        }
    }

    /// Migrate orphaned milestone records to the current profile
    /// This ensures existing local-only records get synced to CloudKit
    private func migrateOrphanedMilestones(to profile: CDPuppyProfile) {
        let orphaned = CDMilestone.fetchOrphanedMilestones(in: viewContext)
        guard !orphaned.isEmpty else { return }

        logger.info("Migrating \(orphaned.count) orphaned milestones to profile")

        for cdMilestone in orphaned {
            cdMilestone.profile = profile
        }

        performSave(operation: "Migrate orphaned milestones to profile") {
            // No additional state update needed
        }
    }

    private func invalidateCaches() {
        _cachedCompletedMilestones = nil
        _cachedIncompleteMilestones = nil
    }

    // MARK: - Backward-Compatible Aliases

    /// Alias for items (backward compatibility)
    var milestones: [Milestone] { items }

    // MARK: - Cached Computed Properties

    /// All completed milestones
    var completedMilestones: [Milestone] {
        if let cached = _cachedCompletedMilestones { return cached }
        let result = items.filter { $0.isCompleted }
        _cachedCompletedMilestones = result
        return result
    }

    /// All incomplete milestones
    var incompleteMilestones: [Milestone] {
        if let cached = _cachedIncompleteMilestones { return cached }
        let result = items.filter { !$0.isCompleted }
        _cachedIncompleteMilestones = result
        return result
    }

    /// Count of completed milestones
    var completedCount: Int { completedMilestones.count }

    /// Count of total milestones
    var totalCount: Int { itemCount }

    /// Progress fraction (0.0 to 1.0)
    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    // MARK: - CRUD Operations (with cache invalidation)

    @discardableResult
    override func add(_ item: Milestone) -> Bool {
        invalidateCaches()

        // Create with profile link for CloudKit sync
        if let profile = getCurrentProfile() {
            _ = CDMilestone.create(from: item, profile: profile, in: viewContext)

            return performSave(operation: "Added \(item.displayName)", entityId: item.id) {
                var newItems = items
                newItems.append(item)
                setItems(newItems)
            }
        } else {
            // Fallback to base implementation (will need migration later)
            logger.warning("Adding milestone without profile link - will need migration")
            return super.add(item)
        }
    }

    @discardableResult
    override func update(_ item: Milestone) -> Bool {
        invalidateCaches()

        guard let cdMilestone = CDMilestone.fetch(byId: item.id, in: viewContext) as? CDMilestone else {
            logger.warning("Milestone not found for update: \(item.id)")
            setNotFoundError()
            return false
        }

        cdMilestone.update(from: item)

        // Ensure profile link exists (for migration of existing records)
        if cdMilestone.profile == nil, let profile = getCurrentProfile() {
            cdMilestone.profile = profile
        }

        return performSave(operation: "Updated \(item.displayName)", entityId: item.id) {
            var newItems = items
            if let index = newItems.firstIndex(where: { $0.id == item.id }) {
                newItems[index] = item
            }
            setItems(newItems)
        }
    }

    @discardableResult
    override func delete(_ item: Milestone) -> Bool {
        invalidateCaches()
        return super.delete(item)
    }

    // MARK: - Backward-Compatible CRUD

    /// Add a new milestone (backward-compatible alias)
    @discardableResult
    func addMilestone(_ milestone: Milestone) -> Bool {
        add(milestone)
    }

    /// Update an existing milestone (backward-compatible alias)
    @discardableResult
    func updateMilestone(_ milestone: Milestone) -> Bool {
        update(milestone)
    }

    /// Delete a milestone (backward-compatible alias)
    @discardableResult
    func deleteMilestone(_ milestone: Milestone) -> Bool {
        delete(milestone)
    }

    // MARK: - Seeding Default Milestones

    /// Seed default milestones if none exist, and remove any duplicates
    func seedDefaultMilestonesIfNeeded() {
        // First, remove any duplicate milestones (same labelKey)
        removeDuplicateMilestones()

        // Use profile-scoped count if available
        let profile = getCurrentProfile()
        let count = profile != nil
            ? CDMilestone.countMilestones(for: profile!, in: viewContext)
            : CDMilestone.countMilestones(in: viewContext)

        if count == 0 {
            logger.info("No milestones found, seeding defaults")
            let defaults = DefaultMilestones.create()

            for milestone in defaults {
                // Link to profile for CloudKit sync
                if let profile = profile {
                    _ = CDMilestone.create(from: milestone, profile: profile, in: viewContext)
                } else {
                    _ = CDMilestone.create(from: milestone, in: viewContext)
                }
            }

            performSave(operation: "Seeded \(defaults.count) default milestones") {
                performInitialLoad()
            }
        } else {
            // Check if any default milestones are missing and add them
            seedMissingDefaultMilestones()
        }
    }

    /// Remove duplicate milestones (same labelKey), keeping the one with the latest modifiedAt
    private func removeDuplicateMilestones() {
        let allMilestones = CDMilestone.fetchAllMilestones(in: viewContext)

        // Group by labelKey
        var milestonesByLabelKey: [String: [CDMilestone]] = [:]
        for cdMilestone in allMilestones {
            guard let labelKey = cdMilestone.labelKey else { continue }
            milestonesByLabelKey[labelKey, default: []].append(cdMilestone)
        }

        // Find and remove duplicates
        var removedCount = 0
        for (labelKey, milestones) in milestonesByLabelKey {
            guard milestones.count > 1 else { continue }

            // Sort by modifiedAt descending (keep most recent) and by isCompleted (prefer completed)
            let sorted = milestones.sorted { m1, m2 in
                // Prefer completed milestones
                if m1.isCompleted != m2.isCompleted {
                    return m1.isCompleted
                }
                // Then by most recent modification
                return (m1.modifiedAt ?? .distantPast) > (m2.modifiedAt ?? .distantPast)
            }

            // Keep the first one, delete the rest
            for duplicateMilestone in sorted.dropFirst() {
                logger.info("Removing duplicate milestone: \(labelKey) (id: \(duplicateMilestone.id?.uuidString ?? "nil"))")
                viewContext.delete(duplicateMilestone)
                removedCount += 1
            }
        }

        if removedCount > 0 {
            performSave(operation: "Removed \(removedCount) duplicate milestones") {
                performInitialLoad()
            }
        }
    }

    /// Seed any missing default milestones (for cases where defaults were added in an update)
    private func seedMissingDefaultMilestones() {
        let existingLabelKeys = Set(items.map { $0.labelKey })
        let defaults = DefaultMilestones.create()
        let profile = getCurrentProfile()

        var addedCount = 0
        for defaultMilestone in defaults {
            if !existingLabelKeys.contains(defaultMilestone.labelKey) {
                logger.info("Adding missing default milestone: \(defaultMilestone.labelKey)")
                // Link to profile for CloudKit sync
                if let profile = profile {
                    _ = CDMilestone.create(from: defaultMilestone, profile: profile, in: viewContext)
                } else {
                    _ = CDMilestone.create(from: defaultMilestone, in: viewContext)
                }
                addedCount += 1
            }
        }

        if addedCount > 0 {
            performSave(operation: "Added \(addedCount) missing default milestones") {
                performInitialLoad()
            }
        }
    }

    // MARK: - Completion

    /// Mark a milestone as completed
    func completeMilestone(
        _ milestone: Milestone,
        notes: String? = nil,
        photoID: UUID? = nil,
        vetClinicName: String? = nil,
        linkedContactID: UUID? = nil,
        completionDate: Date? = nil
    ) {
        var updated = milestone
        updated.isCompleted = true
        updated.completedDate = completionDate ?? Date()
        updated.completionNotes = notes
        updated.completionPhotoID = photoID
        updated.vetClinicName = vetClinicName
        updated.linkedContactID = linkedContactID
        updated.modifiedAt = Date()

        update(updated)
    }

    /// Uncomplete a milestone (mark as not done)
    func uncompleteMilestone(_ milestone: Milestone) {
        var updated = milestone
        updated.isCompleted = false
        updated.completedDate = nil
        updated.modifiedAt = Date()

        update(updated)
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

        update(updated)
    }

    // MARK: - Filtering & Queries

    /// Get milestones by category
    func milestones(for category: MilestoneCategory) -> [Milestone] {
        filter { $0.category == category }
    }

    /// Get milestone by ID (backward-compatible alias)
    func milestone(withId id: UUID) -> Milestone? {
        item(withId: id)
    }

    /// Get upcoming milestones (within next N days)
    func upcomingMilestones(birthDate: Date, withinDays: Int = 14) -> [Milestone] {
        let now = Date()
        return filter { milestone in
            guard !milestone.isCompleted,
                  milestone.targetDate(birthDate: birthDate) != nil,
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
        filter { $0.status(birthDate: birthDate) == .overdue }
    }

    /// Get next milestone that needs attention
    func nextUpMilestone(birthDate: Date) -> Milestone? {
        items
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
        filter { $0.status(birthDate: birthDate) == status }
    }

    /// Get actionable milestones due within this week (7 days)
    /// Excludes developmental milestones (isActionable: false)
    func milestonesThisWeek(birthDate: Date) -> [Milestone] {
        let now = Date()
        return filter { milestone in
            guard !milestone.isCompleted,
                  milestone.isActionable,
                  let daysUntil = milestone.daysUntil(birthDate: birthDate, from: now) else {
                return false
            }
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
        return filter { milestone in
            guard !milestone.isCompleted,
                  milestone.isActionable,
                  let daysUntil = milestone.daysUntil(birthDate: birthDate, from: now) else {
                return false
            }
            return daysUntil > 7 && daysUntil <= 28
        }.sorted { milestone1, milestone2 in
            let days1 = milestone1.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            let days2 = milestone2.daysUntil(birthDate: birthDate, from: now) ?? Int.max
            return days1 < days2
        }
    }

    /// Get active developmental periods (non-actionable milestones that apply to current age)
    func activeDevelopmentalPeriods(birthDate: Date) -> [Milestone] {
        let ageInWeeks = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0

        return filter { milestone in
            guard !milestone.isActionable,
                  milestone.category == .developmental else {
                return false
            }

            if let targetWeeks = milestone.targetAgeWeeks {
                if milestone.labelKey.contains("socialization") {
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
                if milestone.labelKey.contains("fearPeriod") {
                    return abs(ageInWeeks - targetWeeks) <= 2
                }
            }

            if let targetMonths = milestone.targetAgeMonths {
                let ageInMonths = ageInWeeks / 4
                if milestone.labelKey.contains("fearPeriod") {
                    return abs(ageInMonths - targetMonths) <= 1
                }
            }

            return false
        }
    }

    // MARK: - Calendar Grid Support

    /// Get milestones that fall within the week containing the given date
    func milestones(inWeekOf date: Date, birthDate: Date) -> [Milestone] {
        let calendar = Calendar.current

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }

        return filter { milestone in
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
    func milestoneSpans(from startDate: Date, to endDate: Date, birthDate: Date) -> [MilestoneSpan] {
        let calendar = Calendar.current

        return items.compactMap { milestone -> MilestoneSpan? in
            guard !milestone.isCompleted,
                  milestone.isActionable,
                  let targetDate = milestone.targetDate(birthDate: birthDate) else {
                return nil
            }

            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: targetDate)),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return nil
            }

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
}
