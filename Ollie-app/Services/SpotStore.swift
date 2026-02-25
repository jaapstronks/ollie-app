//
//  SpotStore.swift
//  Ollie-app
//
//  CRUD operations and persistence for WalkSpot with Core Data and automatic CloudKit sync
//

import Foundation
import CoreData
import OllieShared
import Combine
import os

/// Manages saved walk spots with Core Data and automatic CloudKit sync
@MainActor
class SpotStore: ObservableObject {

    // MARK: - Published State

    @Published var spots: [WalkSpot] = []
    @Published private(set) var isSyncing = false

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "SpotStore")
    private var cancellables = Set<AnyCancellable>()

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
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

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadSpots()
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
        logger.debug("Detected CloudKit remote change for spots")
        loadSpots()
    }

    // MARK: - Initial Sync

    /// Perform initial sync on app launch
    func initialSync() async {
        // With NSPersistentCloudKitContainer, sync is automatic
        viewContext.refreshAllObjects()
        loadSpots()
    }

    // MARK: - CRUD Operations

    /// Add a new spot
    func addSpot(_ spot: WalkSpot) {
        _ = CDWalkSpot.create(from: spot, in: viewContext)

        do {
            try persistenceController.save()
            spots.append(spot)
        } catch {
            logger.error("Failed to add spot: \(error.localizedDescription)")
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
        let updatedSpot = spot.withUpdatedTimestamp()

        if let existing = CDWalkSpot.fetch(byId: spot.id, in: viewContext) {
            existing.update(from: updatedSpot)

            do {
                try persistenceController.save()
                if let index = spots.firstIndex(where: { $0.id == spot.id }) {
                    spots[index] = updatedSpot
                }
            } catch {
                logger.error("Failed to update spot: \(error.localizedDescription)")
            }
        }
    }

    /// Delete a spot
    func deleteSpot(_ spot: WalkSpot) {
        if let existing = CDWalkSpot.fetch(byId: spot.id, in: viewContext) {
            viewContext.delete(existing)

            do {
                try persistenceController.save()
                spots.removeAll { $0.id == spot.id }
            } catch {
                logger.error("Failed to delete spot: \(error.localizedDescription)")
            }
        }
    }

    /// Delete spot by ID
    func deleteSpot(id: UUID) {
        guard let spot = spots.first(where: { $0.id == id }) else { return }
        deleteSpot(spot)
    }

    /// Toggle favorite status
    func toggleFavorite(_ spot: WalkSpot) {
        guard var updatedSpot = spots.first(where: { $0.id == spot.id }) else { return }
        updatedSpot.isFavorite.toggle()
        updateSpot(updatedSpot)
    }

    /// Increment visit count for a spot
    func incrementVisitCount(_ spot: WalkSpot) {
        guard var updatedSpot = spots.first(where: { $0.id == spot.id }) else { return }
        updatedSpot.visitCount += 1
        updateSpot(updatedSpot)
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
        let cdSpots = CDWalkSpot.fetchAllSpots(in: viewContext)
        spots = cdSpots.compactMap { $0.toWalkSpot() }
    }

    // MARK: - Sync

    /// Fetch from CloudKit (no-op with automatic sync)
    func fetchFromCloud() async {
        viewContext.refreshAllObjects()
        loadSpots()
    }

    /// Force a full sync with CloudKit
    func forceSync() async {
        await fetchFromCloud()
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
