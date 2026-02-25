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
}

// MARK: - Seed Data Container

private struct SeedDataContainer: Codable {
    let categories: [SocializationCategory]
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitSocializationSyncCompleted = Notification.Name("cloudKitSocializationSyncCompleted")
}
