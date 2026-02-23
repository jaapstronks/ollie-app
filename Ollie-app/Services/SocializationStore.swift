//
//  SocializationStore.swift
//  Ollie-app
//
//  Manages socialization checklist items and exposures with CloudKit sync

import Foundation
import Combine
import os

/// Manages socialization items and user exposures with local persistence and CloudKit sync
@MainActor
class SocializationStore: ObservableObject {

    // MARK: - Published State

    @Published var categories: [SocializationCategory] = []
    @Published private(set) var exposuresByItem: [String: [Exposure]] = [:]
    @Published var startedDate: Date?
    @Published private(set) var isSyncing = false

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

    // MARK: - Storage

    private let fileName = "socialization.json"
    private let logger = Logger(subsystem: "nl.jaapstronks.Ollie", category: "SocializationStore")
    private let cloudKit = CloudKitService.shared

    private var cancellables = Set<AnyCancellable>()
    private var pendingCloudSaves: [Exposure] = []
    private var pendingCloudDeletes: [Exposure] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Init

    init() {
        loadCategories()
        loadExposures()
        setupCloudKitObservers()

        // Initial sync
        Task {
            await syncFromCloud()
        }
    }

    // MARK: - Setup

    private func setupCloudKitObservers() {
        // Listen for sync completion to refresh
        NotificationCenter.default.publisher(for: .cloudKitSocializationSyncCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleSyncCompleted(notification)
            }
            .store(in: &cancellables)
    }

    private func handleSyncCompleted(_ notification: Notification) {
        Task {
            await syncFromCloud()
        }
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

        if exposuresByItem[itemId] == nil {
            exposuresByItem[itemId] = []
        }
        exposuresByItem[itemId]?.append(exposure)

        saveExposures()

        // Sync to CloudKit
        Task {
            await saveToCloud(exposure)
        }

        return exposure
    }

    /// Get all exposures for an item
    func getExposures(for itemId: String) -> [Exposure] {
        exposuresByItem[itemId] ?? []
    }

    /// Delete an exposure
    func deleteExposure(_ exposure: Exposure) {
        exposuresByItem[exposure.itemId]?.removeAll { $0.id == exposure.id }
        saveExposures()

        Task {
            await deleteFromCloud(exposure)
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
    /// Priority: recent negative reaction > almost complete > not started
    func suggestedWalkItems(limit: Int = 3) -> [SocializationItem] {
        let walkableItems = categories.flatMap { $0.items }.filter { $0.isWalkable }

        // Score each item
        let scoredItems = walkableItems.map { item -> (SocializationItem, Int) in
            let exposures = getExposures(for: item.id)
            let positiveCount = exposures.filter { $0.reaction.isPositive }.count
            let lastExposure = exposures.sorted { $0.date > $1.date }.first

            var score = 0

            // Recent negative reaction gets highest priority
            if let last = lastExposure, !last.reaction.isPositive {
                let daysSince = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
                if daysSince < 7 {
                    score += 100
                }
            }

            // Almost complete (1-2 away from target)
            let remaining = item.targetExposures - positiveCount
            if remaining > 0 && remaining <= 2 {
                score += 50
            }

            // Not started yet
            if exposures.isEmpty {
                score += 25
            }

            // Items that are already comfortable get low priority
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

    // MARK: - Local Persistence

    private func loadExposures() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            exposuresByItem = [:]
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let container = try decoder.decode(ExposureDataContainer.self, from: data)
            exposuresByItem = container.exposuresByItem
            startedDate = container.startedDate
            logger.info("Loaded \(self.allExposures.count) exposures")
        } catch {
            logger.error("Failed to load exposures: \(error.localizedDescription)")
            exposuresByItem = [:]
        }
    }

    private func saveExposures() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let container = ExposureDataContainer(
                exposuresByItem: exposuresByItem,
                startedDate: startedDate ?? Date()
            )
            let data = try encoder.encode(container)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed to save exposures: \(error.localizedDescription)")
        }
    }

    // MARK: - CloudKit Operations

    private func saveToCloud(_ exposure: Exposure) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudSaves.append(exposure)
            return
        }

        do {
            try await cloudKit.saveExposure(exposure)
            pendingCloudSaves.removeAll { $0.id == exposure.id }
        } catch {
            logger.warning("Failed to save exposure to cloud: \(error.localizedDescription)")
            if !pendingCloudSaves.contains(where: { $0.id == exposure.id }) {
                pendingCloudSaves.append(exposure)
            }
        }
    }

    private func deleteFromCloud(_ exposure: Exposure) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudDeletes.append(exposure)
            return
        }

        do {
            try await cloudKit.deleteExposure(exposure)
            pendingCloudDeletes.removeAll { $0.id == exposure.id }
        } catch {
            logger.warning("Failed to delete exposure from cloud: \(error.localizedDescription)")
        }
    }

    /// Sync exposures from CloudKit
    func syncFromCloud() async {
        guard cloudKit.isCloudAvailable else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let cloudExposures = try await cloudKit.fetchAllExposures()
            mergeExposures(cloud: cloudExposures)
            saveExposures()
            logger.info("Synced \(cloudExposures.count) exposures from cloud")
        } catch {
            logger.warning("Failed to sync from cloud: \(error.localizedDescription)")
        }
    }

    /// Merge cloud exposures with local
    private func mergeExposures(cloud: [Exposure]) {
        for exposure in cloud {
            if exposuresByItem[exposure.itemId] == nil {
                exposuresByItem[exposure.itemId] = []
            }

            // Check if we already have this exposure
            if let index = exposuresByItem[exposure.itemId]?.firstIndex(where: { $0.id == exposure.id }) {
                // Cloud wins for conflicts (compare modifiedAt)
                if let localExposure = exposuresByItem[exposure.itemId]?[index],
                   exposure.modifiedAt > localExposure.modifiedAt {
                    exposuresByItem[exposure.itemId]?[index] = exposure
                }
            } else {
                // New exposure from cloud
                exposuresByItem[exposure.itemId]?.append(exposure)
            }
        }
    }

    /// Retry pending cloud operations
    func retryPendingOperations() async {
        for exposure in pendingCloudSaves {
            await saveToCloud(exposure)
        }
        for exposure in pendingCloudDeletes {
            await deleteFromCloud(exposure)
        }
    }
}

// MARK: - Seed Data Container

private struct SeedDataContainer: Codable {
    let categories: [SocializationCategory]
}

// MARK: - Exposure Data Container

private struct ExposureDataContainer: Codable {
    let exposuresByItem: [String: [Exposure]]
    let startedDate: Date
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitSocializationSyncCompleted = Notification.Name("cloudKitSocializationSyncCompleted")
}
