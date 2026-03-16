//
//  SocializationStore.swift
//  Otis-app
//
//  Manages socialization checklist items and exposures with Core Data and CKSyncEngine-based CloudKit sync
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages socialization items and user exposures with Core Data and CKSyncEngine-based CloudKit sync
@MainActor
final class SocializationStore: BaseStore {

    // MARK: - State

    var categories: [SocializationCategory] = []
    var exposuresByItem: [String: [Exposure]] = [:]
    var comfortableItems: [ComfortableItem] = []
    var earlyMilestones: [EarlyMilestoneRecord] = []
    var startedDate: Date?

    // MARK: - Phase Assignments (loaded from JSON)

    var phaseAssignments: [String: [String]] = [:]
    private var _earlyMilestoneDefinitions: [EarlyMilestoneDefinition] = []

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
        _earlyMilestoneDefinitions
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
            _earlyMilestoneDefinitions = container.earlyMilestones ?? []
            logger.info("Loaded \(self.categories.count) socialization categories, \(self._earlyMilestoneDefinitions.count) early milestones")
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
