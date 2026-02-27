//
//  SocializationStore.swift
//  Ollie-app
//
//  Manages socialization checklist items and exposures with Core Data and automatic CloudKit sync
//

import Foundation
import CoreData
import OllieShared
import Combine
import os

/// Manages socialization items and user exposures with Core Data and automatic CloudKit sync
@MainActor
class SocializationStore: ObservableObject {

    // MARK: - Published State

    @Published var categories: [SocializationCategory] = []
    @Published private(set) var exposuresByItem: [String: [Exposure]] = [:]
    @Published var startedDate: Date?
    @Published private(set) var isSyncing = false

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "SocializationStore")
    private var cancellables = Set<AnyCancellable>()

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Computed Properties

    /// Total number of socialization items
    var totalItems: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }

    /// Number of items where puppy is comfortable (enough positive exposures)
    var totalComfortable: Int {
        categories.reduce(0) { sum, category in
            sum + category.items.filter { isComfortable(itemId: $0.id) }.count
        }
    }

    /// All exposures flattened
    var allExposures: [Exposure] {
        exposuresByItem.values.flatMap { $0 }
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadCategories()
        loadExposures()
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
        logger.debug("Detected CloudKit remote change for exposures")
        loadExposures()
    }

    // MARK: - Category Loading

    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "socialization-items", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            logger.error("Failed to load socialization-items.json from bundle")
            return
        }

        do {
            let decoder = JSONDecoder()
            let container = try decoder.decode(SeedDataContainer.self, from: data)
            categories = container.categories
            logger.info("Loaded \(self.categories.count) socialization categories")
        } catch {
            logger.error("Failed to decode socialization items: \(error.localizedDescription)")
        }
    }

    // MARK: - Exposure CRUD

    /// Add a new exposure for an item
    @discardableResult
    func addExposure(
        itemId: String,
        distance: ExposureDistance,
        reaction: SocializationReaction,
        note: String? = nil
    ) -> Exposure {
        let exposure = Exposure(
            itemId: itemId,
            date: Date(),
            distance: distance,
            reaction: reaction,
            note: note
        )

        // Save to Core Data
        _ = CDExposure.create(from: exposure, in: viewContext)

        do {
            try persistenceController.save()

            // Update in-memory
            var exposures = exposuresByItem[itemId] ?? []
            exposures.append(exposure)
            exposuresByItem[itemId] = exposures
        } catch {
            logger.error("Failed to save exposure: \(error.localizedDescription)")
        }

        return exposure
    }

    /// Get all exposures for an item
    func getExposures(for itemId: String) -> [Exposure] {
        exposuresByItem[itemId] ?? []
    }

    /// Delete an exposure
    func deleteExposure(_ exposure: Exposure) {
        if let cdExposure = CDExposure.fetch(byId: exposure.id, in: viewContext) {
            viewContext.delete(cdExposure)

            do {
                try persistenceController.save()
                exposuresByItem[exposure.itemId]?.removeAll { $0.id == exposure.id }
            } catch {
                logger.error("Failed to delete exposure: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Progress Calculations

    /// Progress fraction for an item (0.0 to 1.0)
    func progressFraction(for itemId: String) -> Double {
        guard let item = item(withId: itemId) else { return 0 }
        let positiveCount = getExposures(for: itemId).filter { $0.reaction.isPositive }.count
        return min(1.0, Double(positiveCount) / Double(item.targetExposures))
    }

    /// Whether the puppy is comfortable with this item
    func isComfortable(itemId: String) -> Bool {
        guard let item = item(withId: itemId) else { return false }
        let positiveCount = getExposures(for: itemId).filter { $0.reaction.isPositive }.count
        return positiveCount >= item.targetExposures
    }

    /// Progress for a category
    func categoryProgress(for categoryId: String) -> (completed: Int, total: Int) {
        guard let category = categories.first(where: { $0.id == categoryId }) else {
            return (0, 0)
        }
        let completed = category.items.filter { isComfortable(itemId: $0.id) }.count
        return (completed, category.items.count)
    }

    /// Most recent exposure for an item
    func lastExposure(for itemId: String) -> Exposure? {
        getExposures(for: itemId).sorted { $0.date > $1.date }.first
    }

    // MARK: - Item Lookup

    /// Find an item by ID
    func item(withId id: String) -> SocializationItem? {
        for category in categories {
            if let item = category.items.first(where: { $0.id == id }) {
                return item
            }
        }
        return nil
    }

    /// Find category for an item
    func category(forItemId itemId: String) -> SocializationCategory? {
        categories.first { category in
            category.items.contains { $0.id == itemId }
        }
    }

    // MARK: - Walk Suggestions

    /// Get suggested items to watch for during walks
    func suggestedWalkItems(limit: Int = 3) -> [SocializationItem] {
        let walkableItems = categories.flatMap { $0.items }.filter { $0.isWalkable }

        let scoredItems = walkableItems.map { item -> (SocializationItem, Int) in
            let exposures = getExposures(for: item.id)
            let positiveCount = exposures.filter { $0.reaction.isPositive }.count
            let lastExposure = exposures.sorted { $0.date > $1.date }.first

            var score = 0

            if let last = lastExposure, !last.reaction.isPositive {
                let daysSince = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
                if daysSince < 7 {
                    score += 100
                }
            }

            let remaining = item.targetExposures - positiveCount
            if remaining > 0 && remaining <= 2 {
                score += 50
            }

            if exposures.isEmpty {
                score += 20 + (item.priority * 10)
            }

            if positiveCount >= item.targetExposures {
                score = 0
            }

            return (item, score)
        }

        return scoredItems
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    // MARK: - Persistence

    private func loadExposures() {
        let cdExposures = CDExposure.fetchAllExposures(in: viewContext)
        let exposures = cdExposures.compactMap { $0.toExposure() }

        // Group by itemId
        exposuresByItem = Dictionary(grouping: exposures, by: { $0.itemId })
        logger.info("Loaded \(exposures.count) exposures from Core Data")
    }

    // MARK: - CloudKit Sync

    /// Sync exposures from CloudKit (no-op with automatic sync)
    func syncFromCloud() async {
        viewContext.refreshAllObjects()
        loadExposures()
    }

    /// Retry pending operations (no-op with automatic sync)
    func retryPendingOperations() async {
        // With NSPersistentCloudKitContainer, retries are automatic
    }

    // MARK: - Weekly Progress

    /// Get progress for a specific week
    func weeklyProgress(for weekNumber: Int, profile: PuppyProfile) -> WeeklyProgress {
        let calendar = Calendar.current

        // Calculate week start/end dates based on birth date
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekNumber, to: profile.birthDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return WeeklyProgress(
                weekNumber: weekNumber,
                startDate: Date(),
                endDate: Date()
            )
        }

        // Filter exposures for this week
        let weekExposures = allExposures.filter { exposure in
            exposure.date >= weekStart && exposure.date <= calendar.date(byAdding: .day, value: 1, to: weekEnd)!
        }

        // Count unique categories with exposures
        let categoriesWithExposures = Set(
            weekExposures.compactMap { exposure in
                category(forItemId: exposure.itemId)?.id
            }
        ).count

        // Calculate positive reaction rate
        let positiveCount = weekExposures.filter { $0.reaction.isPositive }.count
        let positiveRate = weekExposures.isEmpty ? 0.0 : Double(positiveCount) / Double(weekExposures.count)

        return WeeklyProgress(
            weekNumber: weekNumber,
            startDate: weekStart,
            endDate: weekEnd,
            exposureCount: weekExposures.count,
            categoriesWithExposures: categoriesWithExposures,
            positiveReactionRate: positiveRate,
            totalCategories: categories.count
        )
    }

    /// Get all weekly progress for the socialization window
    func allWeeklyProgress(profile: PuppyProfile) -> [WeeklyProgress] {
        SocializationWindow.allWeeks.map { weekNumber in
            weeklyProgress(for: weekNumber, profile: profile)
        }
    }

    /// Get suggested focus categories (categories with least progress)
    func suggestedFocusCategories(limit: Int = 2) -> [SocializationCategory] {
        let sortedCategories = categories.sorted { cat1, cat2 in
            let (completed1, total1) = categoryProgress(for: cat1.id)
            let (completed2, total2) = categoryProgress(for: cat2.id)

            let progress1 = total1 > 0 ? Double(completed1) / Double(total1) : 0
            let progress2 = total2 > 0 ? Double(completed2) / Double(total2) : 0

            return progress1 < progress2
        }

        return Array(sortedCategories.prefix(limit))
    }

    /// Get the current week's progress
    func currentWeekProgress(profile: PuppyProfile) -> WeeklyProgress? {
        let ageWeeks = profile.ageInWeeks
        guard SocializationWindow.isInWindow(ageWeeks: ageWeeks) else { return nil }
        return weeklyProgress(for: ageWeeks, profile: profile)
    }

    /// Check if in socialization window
    func isInSocializationWindow(profile: PuppyProfile) -> Bool {
        SocializationWindow.isInWindow(ageWeeks: profile.ageInWeeks)
    }

    /// Check if socialization window has closed
    func socializationWindowClosed(profile: PuppyProfile) -> Bool {
        SocializationWindow.windowClosed(ageWeeks: profile.ageInWeeks)
    }

    // MARK: - Week Detail Helpers

    /// Get category-level progress for a specific week
    func categoryProgressForWeek(_ week: WeeklyProgress, profile: PuppyProfile) -> [(category: SocializationCategory, count: Int, total: Int)] {
        var result: [(category: SocializationCategory, count: Int, total: Int)] = []

        for category in categories {
            let exposuresInWeek = category.items.reduce(0) { count, item in
                count + allExposures.filter { exposure in
                    exposure.itemId == item.id &&
                    exposure.date >= week.startDate &&
                    exposure.date <= week.endDate
                }.count
            }

            // Target is roughly items count (one per item as minimum goal)
            let target = max(1, category.items.count)
            result.append((category: category, count: exposuresInWeek, total: target))
        }

        return result
    }

    /// Get focus suggestions for a specific week
    func focusSuggestions(for week: WeeklyProgress, profile: PuppyProfile) -> [String] {
        var suggestions: [String] = []
        let progress = categoryProgressForWeek(week, profile: profile)

        // Find categories with zero exposures this week (critical gaps)
        let zeroExposureCategories = progress.filter { $0.count == 0 }
            .map { $0.category }
            .prefix(2)

        for category in zeroExposureCategories {
            // Get a few item suggestions from the category (items not yet comfortable)
            let itemNames = category.items.filter { !isComfortable(itemId: $0.id) }
                .prefix(3)
                .map { $0.name }
                .joined(separator: ", ")

            if !itemNames.isEmpty {
                suggestions.append("\(category.name): \(itemNames)")
            }
        }

        // If we have fewer than 2 suggestions, add categories below 50%
        if suggestions.count < 2 {
            let lowProgressCategories = progress
                .filter { Double($0.count) / Double(max(1, $0.total)) < 0.5 && $0.count > 0 }
                .sorted { $0.count < $1.count }
                .map { $0.category }
                .prefix(2 - suggestions.count)

            for category in lowProgressCategories {
                let itemNames = category.items.filter { !isComfortable(itemId: $0.id) }
                    .prefix(3)
                    .map { $0.name }
                    .joined(separator: ", ")

                if !itemNames.isEmpty && !suggestions.contains(where: { $0.hasPrefix(category.name) }) {
                    suggestions.append("\(category.name): \(itemNames)")
                }
            }
        }

        return suggestions
    }
}

// MARK: - Seed Data Container

private struct SeedDataContainer: Codable {
    let categories: [SocializationCategory]
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitSocializationSyncCompleted = Notification.Name("cloudKitSocializationSyncCompleted")
}
