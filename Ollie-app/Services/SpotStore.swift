//
//  SpotStore.swift
//  Ollie-app
//
//  CRUD operations and persistence for WalkSpot with CloudKit sync

import Foundation
import OllieShared
import Combine
import os

/// Manages saved walk spots with local persistence and CloudKit sync
@MainActor
class SpotStore: ObservableObject {

    // MARK: - Published State

    @Published var spots: [WalkSpot] = []
    @Published private(set) var isSyncing = false

    private let logger = Logger.ollie(category: "SpotStore")
    private let cloudKit = CloudKitService.shared

    // MARK: - Pending Operations (for offline support)

    private var pendingCloudSaves: [WalkSpot] = []
    private var pendingCloudDeletes: [WalkSpot] = []

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let spotsMigrationCompleted = "spotStore.cloudMigrationCompleted"
    }

    // MARK: - Computed Properties

    /// Spots marked as favorite, sorted by name
    var favoriteSpots: [WalkSpot] {
        spots.filter { $0.isFavorite }.sorted { $0.name < $1.name }
    }

    /// Most recently used spots (last 5, non-favorites)
    var recentSpots: [WalkSpot] {
        spots
            .filter { !$0.isFavorite }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
            .map { $0 }
    }

    /// All spots sorted by visit count (most visited first)
    var popularSpots: [WalkSpot] {
        spots.sorted { $0.visitCount > $1.visitCount }
    }

    // MARK: - Storage

    private let fileName = "spots.json"

    // MARK: - Init

    init() {
        loadSpots()
    }

    // MARK: - Initial Sync

    /// Perform initial sync on app launch
    func initialSync() async {
        guard cloudKit.isCloudAvailable else {
            logger.info("CloudKit not available, skipping spot sync")
            return
        }

        // Migrate existing local spots to CloudKit if needed
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.spotsMigrationCompleted) {
            await migrateLocalSpots()
        }

        // Fetch from cloud and merge
        await fetchFromCloud()

        // Retry any pending operations
        await retryPendingOperations()
    }

    // MARK: - CRUD Operations

    /// Add a new spot
    func addSpot(_ spot: WalkSpot) {
        spots.append(spot)
        saveSpots()

        Task {
            await saveToCloud(spot)
        }
    }

    /// Create and add a spot from coordinates
    func addSpot(name: String, latitude: Double, longitude: Double, notes: String? = nil) -> WalkSpot {
        let spot = WalkSpot(
            name: name,
            latitude: latitude,
            longitude: longitude,
            notes: notes
        )
        addSpot(spot)
        return spot
    }

    /// Update an existing spot
    func updateSpot(_ spot: WalkSpot) {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else { return }
        let updatedSpot = spot.withUpdatedTimestamp()
        spots[index] = updatedSpot
        saveSpots()

        Task {
            await saveToCloud(updatedSpot)
        }
    }

    /// Delete a spot
    func deleteSpot(_ spot: WalkSpot) {
        spots.removeAll { $0.id == spot.id }
        saveSpots()

        Task {
            await deleteFromCloud(spot)
        }
    }

    /// Delete spot by ID
    func deleteSpot(id: UUID) {
        guard let spot = spots.first(where: { $0.id == id }) else { return }
        deleteSpot(spot)
    }

    /// Toggle favorite status
    func toggleFavorite(_ spot: WalkSpot) {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else { return }
        var updatedSpot = spots[index]
        updatedSpot.isFavorite.toggle()
        updatedSpot = updatedSpot.withUpdatedTimestamp()
        spots[index] = updatedSpot
        saveSpots()

        Task {
            await saveToCloud(updatedSpot)
        }
    }

    /// Increment visit count for a spot
    func incrementVisitCount(_ spot: WalkSpot) {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else { return }
        var updatedSpot = spots[index]
        updatedSpot.visitCount += 1
        updatedSpot = updatedSpot.withUpdatedTimestamp()
        spots[index] = updatedSpot
        saveSpots()

        Task {
            await saveToCloud(updatedSpot)
        }
    }

    /// Find spot by ID
    func spot(withId id: UUID) -> WalkSpot? {
        spots.first { $0.id == id }
    }

    /// Find spots near a location (within ~100m)
    func spotsNear(latitude: Double, longitude: Double, radiusMeters: Double = 100) -> [WalkSpot] {
        spots.filter { spot in
            let distance = haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: spot.latitude, lon2: spot.longitude
            )
            return distance <= radiusMeters
        }
    }

    // MARK: - Persistence

    private func loadSpots() {
        spots = JSONFileStorage.loadArray(from: fileName, logger: logger)
    }

    private func saveSpots() {
        JSONFileStorage.saveArray(spots, to: fileName, logger: logger)
    }

    // MARK: - CloudKit Operations

    /// Save a spot to CloudKit
    private func saveToCloud(_ spot: WalkSpot) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudSaves.append(spot)
            return
        }

        do {
            try await cloudKit.saveSpot(spot)
            pendingCloudSaves.removeAll { $0.id == spot.id }
        } catch {
            logger.warning("Failed to save spot to cloud, will retry: \(error.localizedDescription)")
            if !pendingCloudSaves.contains(where: { $0.id == spot.id }) {
                pendingCloudSaves.append(spot)
            }
        }
    }

    /// Delete a spot from CloudKit
    private func deleteFromCloud(_ spot: WalkSpot) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudDeletes.append(spot)
            return
        }

        do {
            try await cloudKit.deleteSpot(spot)
            pendingCloudDeletes.removeAll { $0.id == spot.id }
        } catch {
            logger.warning("Failed to delete spot from cloud: \(error.localizedDescription)")
            if !pendingCloudDeletes.contains(where: { $0.id == spot.id }) {
                pendingCloudDeletes.append(spot)
            }
        }
    }

    /// Fetch spots from CloudKit and merge with local
    func fetchFromCloud() async {
        guard cloudKit.isCloudAvailable else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let cloudSpots = try await cloudKit.fetchAllSpots()
            let merged = mergeSpots(local: spots, cloud: cloudSpots)
            spots = merged
            saveSpots()
            logger.info("Synced \(cloudSpots.count) spots from cloud, total: \(merged.count)")
        } catch {
            logger.warning("Failed to fetch spots from cloud: \(error.localizedDescription)")
        }
    }

    /// Force a full sync with CloudKit
    func forceSync() async {
        await fetchFromCloud()
        await retryPendingOperations()
    }

    /// Retry pending cloud operations
    private func retryPendingOperations() async {
        for spot in pendingCloudSaves {
            await saveToCloud(spot)
        }
        for spot in pendingCloudDeletes {
            await deleteFromCloud(spot)
        }
    }

    // MARK: - Migration

    /// Migrate existing local spots to CloudKit (one-time)
    private func migrateLocalSpots() async {
        let localSpots = spots
        guard !localSpots.isEmpty else {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.spotsMigrationCompleted)
            return
        }

        logger.info("Starting migration of \(localSpots.count) local spots to CloudKit")

        do {
            try await cloudKit.saveSpots(localSpots)
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.spotsMigrationCompleted)
            logger.info("Migration completed: \(localSpots.count) spots uploaded")
        } catch {
            logger.error("Spot migration failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Merging

    /// Merge local and cloud spots, preferring newer modifiedAt for conflicts
    private func mergeSpots(local: [WalkSpot], cloud: [WalkSpot]) -> [WalkSpot] {
        var merged: [UUID: WalkSpot] = [:]

        // Add all local spots first
        for spot in local {
            merged[spot.id] = spot
        }

        // Merge cloud spots, preferring newer modifiedAt
        for cloudSpot in cloud {
            if let existingSpot = merged[cloudSpot.id] {
                // Keep the one with the newer modifiedAt
                if cloudSpot.modifiedAt > existingSpot.modifiedAt {
                    merged[cloudSpot.id] = cloudSpot
                }
            } else {
                // New spot from cloud
                merged[cloudSpot.id] = cloudSpot
            }
        }

        return Array(merged.values).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Helpers

    /// Calculate distance between two coordinates using Haversine formula
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius: Double = 6371000 // meters

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}
