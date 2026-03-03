//
//  SocializationStore.swift
//  Otis-app
//
//  Manages socialization checklist items and exposures with Core Data and automatic CloudKit sync
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages socialization items and user exposures with Core Data and automatic CloudKit sync
@MainActor
final class SocializationStore: BaseStore {

    // MARK: - Published State

    @Published var categories: [SocializationCategory] = []
    @Published private(set) var exposuresByItem: [String: [Exposure]] = [:]
    @Published private(set) var comfortableItems: [ComfortableItem] = []
    @Published private(set) var earlyMilestones: [EarlyMilestoneRecord] = []
    @Published var startedDate: Date?

    // MARK: - Phase Assignments (loaded from JSON)

    private var phaseAssignments: [String: [String]] = [:]
    private var earlyMilestoneDefinitions: [EarlyMilestoneDefinition] = []

    // MARK: - Profile Reference

    private var profileStore: ProfileStore?

    func setProfileStore(_ store: ProfileStore) {
        self.profileStore = store
    }

    // MARK: - Computed Properties

    /// Total number of socialization items
    var totalItems: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }

    /// Number of items where puppy is comfortable (enough positive exposures OR explicitly marked)
    var totalComfortable: Int {
        categories.reduce(0) { sum, category in
            sum + category.items.filter { isComfortable(itemId: $0.id) }.count
        }
    }

    /// All exposures flattened
    var allExposures: [Exposure] {
        exposuresByItem.values.flatMap { $0 }
    }

    /// Current socialization phase based on profile
    var currentPhase: SocializationPhase {
        guard let profile = profileStore?.profile else {
            return .firstSteps
        }
        return SocializationPhase.current(daysHome: profile.daysHome, ageInWeeks: profile.ageInWeeks)
    }

    /// Items for the current phase
    var currentPhaseItems: [SocializationItem] {
        items(for: currentPhase)
    }

    /// Progress for current phase (comfortable count, total count)
    var currentPhaseProgress: (comfortable: Int, total: Int) {
        let phaseItems = currentPhaseItems
        let comfortable = phaseItems.filter { isComfortable(itemId: $0.id) }.count
        return (comfortable, phaseItems.count)
    }

    /// Next focus items (highest priority, not yet comfortable, in current phase)
    var nextFocusItems: [SocializationItem] {
        let phase = currentPhase

        // In settling in phase, no focus items
        guard phase != .settlingIn else { return [] }

        let phaseItems = items(for: phase)
        let notComfortable = phaseItems.filter { !isComfortable(itemId: $0.id) }

        // Sort by priority (highest first), then by exposures (items with some progress first)
        let sorted = notComfortable.sorted { item1, item2 in
            if item1.priority != item2.priority {
                return item1.priority > item2.priority
            }
            // Prefer items with some exposures (in progress) over not started
            let exp1 = getExposures(for: item1.id).count
            let exp2 = getExposures(for: item2.id).count
            if exp1 > 0 && exp2 == 0 { return true }
            if exp2 > 0 && exp1 == 0 { return false }
            return false
        }

        return Array(sorted.prefix(2))
    }

    /// Whether user has logged any exposures (for first-visit detection)
    var hasAnyExposures: Bool {
        !allExposures.isEmpty
    }

    /// Whether user has any comfortable items (for first-visit detection)
    var hasAnyComfortableItems: Bool {
        !comfortableItems.isEmpty || totalComfortable > 0
    }

    /// Early milestone definitions
    var milestoneDefinitions: [EarlyMilestoneDefinition] {
        earlyMilestoneDefinitions
    }

    /// Achieved early milestones
    var achievedMilestoneIds: Set<String> {
        Set(earlyMilestones.map { $0.milestoneId })
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "SocializationStore")
        loadCategories()
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        // Load exposures
        let cdExposures = CDExposure.fetchAllExposures(in: viewContext)
        let exposures = cdExposures.compactMap { $0.toExposure() }
        exposuresByItem = Dictionary(grouping: exposures, by: { $0.itemId })
        logger.info("Loaded \(exposures.count) exposures from Core Data")

        // Load comfortable items
        let cdComfortable = CDComfortableItem.fetchAll(in: viewContext)
        comfortableItems = cdComfortable.compactMap { $0.toComfortableItem() }
        logger.info("Loaded \(self.comfortableItems.count) comfortable items from Core Data")

        // Load early milestones
        let cdMilestones = CDEarlyMilestone.fetchAll(in: viewContext)
        earlyMilestones = cdMilestones.compactMap { $0.toEarlyMilestoneRecord() }
        logger.info("Loaded \(self.earlyMilestones.count) early milestones from Core Data")
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
            phaseAssignments = container.phaseAssignments ?? [:]
            earlyMilestoneDefinitions = container.earlyMilestones ?? []
            logger.info("Loaded \(self.categories.count) socialization categories, \(self.earlyMilestoneDefinitions.count) early milestones")
        } catch {
            logger.error("Failed to decode socialization items: \(error.localizedDescription)")
        }
    }

    // MARK: - Phase-Based Item Access

    /// Get items for a specific phase
    func items(for phase: SocializationPhase) -> [SocializationItem] {
        let phaseKey: String
        switch phase {
        case .settlingIn:
            return [] // No items in settling in phase
        case .firstSteps:
            phaseKey = "firstSteps"
        case .buildingConfidence:
            phaseKey = "buildingConfidence"
        case .peakWindow:
            phaseKey = "peakWindow"
        case .maintenance:
            // In maintenance, return all items
            return categories.flatMap { $0.items }
        }

        guard let itemIds = phaseAssignments[phaseKey] else {
            return []
        }

        let idSet = Set(itemIds)
        return categories.flatMap { $0.items }.filter { idSet.contains($0.id) }
    }

    /// Get all items up to and including a phase (cumulative)
    func itemsUpToPhase(_ phase: SocializationPhase) -> [SocializationItem] {
        var allItems: [SocializationItem] = []
        for p in SocializationPhase.allCases where p.sortOrder <= phase.sortOrder {
            allItems.append(contentsOf: items(for: p))
        }
        return allItems
    }

    /// Get phase for an item
    func phase(for itemId: String) -> SocializationPhase? {
        for (key, ids) in phaseAssignments {
            if ids.contains(itemId) {
                switch key {
                case "firstSteps": return .firstSteps
                case "buildingConfidence": return .buildingConfidence
                case "peakWindow": return .peakWindow
                default: break
                }
            }
        }
        return nil
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

        _ = CDExposure.create(from: exposure, in: viewContext)

        performSave(operation: "Added exposure for item: \(itemId)") {
            var exposures = exposuresByItem[itemId] ?? []
            exposures.append(exposure)
            exposuresByItem[itemId] = exposures
        }

        // Check if this makes the item comfortable and update explicit tracking
        checkAndUpdateComfortStatus(itemId: itemId)

        return exposure
    }

    /// Get all exposures for an item
    func getExposures(for itemId: String) -> [Exposure] {
        exposuresByItem[itemId] ?? []
    }

    /// Delete an exposure
    func deleteExposure(_ exposure: Exposure) {
        guard let cdExposure = CDExposure.fetch(byId: exposure.id, in: viewContext) else {
            logger.warning("Exposure not found for deletion: \(exposure.id)")
            return
        }

        viewContext.delete(cdExposure)

        performDelete(operation: "Deleted exposure: \(exposure.id)") {
            exposuresByItem[exposure.itemId]?.removeAll { $0.id == exposure.id }
        }
    }

    // MARK: - Comfortable Item CRUD

    /// Mark an item as comfortable (quick check or via logging)
    func markComfortable(_ itemId: String, method: ComfortableItem.ComfortMethod = .quickCheck) {
        // Check if already marked
        if comfortableItems.contains(where: { $0.itemId == itemId }) {
            return
        }

        let item = ComfortableItem(itemId: itemId, method: method)
        _ = CDComfortableItem.create(from: item, in: viewContext)

        performSave(operation: "Marked comfortable: \(itemId)") {
            comfortableItems.append(item)
        }
    }

    /// Unmark an item as comfortable
    func unmarkComfortable(_ itemId: String) {
        CDComfortableItem.delete(byItemId: itemId, in: viewContext)

        performSave(operation: "Unmarked comfortable: \(itemId)") {
            comfortableItems.removeAll { $0.itemId == itemId }
        }
    }

    /// Toggle comfortable status
    func toggleComfortable(_ itemId: String) {
        if isExplicitlyComfortable(itemId: itemId) {
            unmarkComfortable(itemId)
        } else {
            markComfortable(itemId)
        }
    }

    /// Check if item is explicitly marked comfortable (via CDComfortableItem)
    func isExplicitlyComfortable(itemId: String) -> Bool {
        comfortableItems.contains { $0.itemId == itemId }
    }

    /// Update comfort status after logging exposures
    private func checkAndUpdateComfortStatus(itemId: String) {
        // If already explicitly marked, skip
        if isExplicitlyComfortable(itemId: itemId) { return }

        // Check if now comfortable via exposures
        guard let item = item(withId: itemId) else { return }
        let positiveCount = getExposures(for: itemId).filter { $0.reaction.isPositive }.count

        if positiveCount >= item.targetExposures {
            markComfortable(itemId, method: .logged)
        }
    }

    // MARK: - Early Milestone CRUD

    /// Mark an early milestone as achieved
    func markMilestoneAchieved(_ milestoneId: String) {
        // Check if already achieved
        if earlyMilestones.contains(where: { $0.milestoneId == milestoneId }) {
            return
        }

        let record = EarlyMilestoneRecord(milestoneId: milestoneId)
        _ = CDEarlyMilestone.create(from: record, in: viewContext)

        performSave(operation: "Marked milestone achieved: \(milestoneId)") {
            earlyMilestones.append(record)
        }
    }

    /// Unmark an early milestone
    func unmarkMilestone(_ milestoneId: String) {
        CDEarlyMilestone.delete(byMilestoneId: milestoneId, in: viewContext)

        performSave(operation: "Unmarked milestone: \(milestoneId)") {
            earlyMilestones.removeAll { $0.milestoneId == milestoneId }
        }
    }

    /// Toggle milestone achieved status
    func toggleMilestone(_ milestoneId: String) {
        if isMilestoneAchieved(milestoneId) {
            unmarkMilestone(milestoneId)
        } else {
            markMilestoneAchieved(milestoneId)
        }
    }

    /// Check if a milestone is achieved
    func isMilestoneAchieved(_ milestoneId: String) -> Bool {
        earlyMilestones.contains { $0.milestoneId == milestoneId }
    }

    /// Get early milestone definition by ID
    func milestoneDefinition(for id: String) -> EarlyMilestoneDefinition? {
        earlyMilestoneDefinitions.first { $0.id == id }
    }

    // MARK: - Progress Calculations

    /// Progress fraction for an item (0.0 to 1.0)
    func progressFraction(for itemId: String) -> Double {
        // If explicitly marked comfortable, return 1.0
        if isExplicitlyComfortable(itemId: itemId) {
            return 1.0
        }

        guard let item = item(withId: itemId) else { return 0 }
        let positiveCount = getExposures(for: itemId).filter { $0.reaction.isPositive }.count
        return min(1.0, Double(positiveCount) / Double(item.targetExposures))
    }

    /// Whether the puppy is comfortable with this item (explicitly marked OR enough positive exposures)
    func isComfortable(itemId: String) -> Bool {
        // Check explicit marking first
        if isExplicitlyComfortable(itemId: itemId) {
            return true
        }

        // Fall back to exposure-based check
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
        // Only suggest items from current phase or earlier
        let availableItems = itemsUpToPhase(currentPhase).filter { $0.isWalkable && !isComfortable(itemId: $0.id) }

        let scoredItems = availableItems.map { item -> (SocializationItem, Int) in
            let exposures = getExposures(for: item.id)
            let positiveCount = exposures.filter { $0.reaction.isPositive }.count
            let lastExposure = exposures.sorted { $0.date > $1.date }.first

            var score = item.priority * 20 // Priority is key

            // Boost items with recent negative reactions
            if let last = lastExposure, !last.reaction.isPositive {
                let daysSince = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
                if daysSince < 7 {
                    score += 100
                }
            }

            // Boost items close to completion
            let remaining = item.targetExposures - positiveCount
            if remaining > 0 && remaining <= 2 {
                score += 50
            }

            // Boost items not yet started
            if exposures.isEmpty {
                score += 30
            }

            return (item, score)
        }

        return scoredItems
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
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
                .map { $0.localizedDisplayName }
                .joined(separator: ", ")

            if !itemNames.isEmpty {
                suggestions.append("\(category.localizedDisplayName): \(itemNames)")
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
                    .map { $0.localizedDisplayName }
                    .joined(separator: ", ")

                if !itemNames.isEmpty && !suggestions.contains(where: { $0.hasPrefix(category.localizedDisplayName) }) {
                    suggestions.append("\(category.localizedDisplayName): \(itemNames)")
                }
            }
        }

        return suggestions
    }
}

// MARK: - Seed Data Container

private struct SeedDataContainer: Codable {
    let categories: [SocializationCategory]
    let phaseAssignments: [String: [String]]?
    let earlyMilestones: [EarlyMilestoneDefinition]?
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitSocializationSyncCompleted = Notification.Name("cloudKitSocializationSyncCompleted")
}
