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
final class SpotStore: BaseStore {

    // MARK: - Published State

    @Published var spots: [WalkSpot] = []

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
        super.init(persistenceController: persistenceController, logCategory: "SpotStore")
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        let cdSpots = CDWalkSpot.fetchAllSpots(in: viewContext)
        spots = cdSpots.compactMap { $0.toWalkSpot() }
        logger.info("Loaded \(self.spots.count) spots from Core Data")
    }

    // MARK: - CRUD Operations

    /// Add a new spot
    @discardableResult
    func addSpot(_ spot: WalkSpot) -> Bool {
        _ = CDWalkSpot.create(from: spot, in: viewContext)

        return performSave(operation: "Added spot: \(spot.name)") {
            spots.append(spot)
        }
    }

    /// Create and add a spot from coordinates
    @discardableResult
    func addSpot(name: String, latitude: Double, longitude: Double, notes: String? = nil, photoFilename: String? = nil) -> WalkSpot {
        let spot = WalkSpot(
            name: name,
            latitude: latitude,
            longitude: longitude,
            notes: notes,
            photoFilename: photoFilename
        )
        addSpot(spot)
        return spot
    }

    /// Update an existing spot
    @discardableResult
    func updateSpot(_ spot: WalkSpot) -> Bool {
        let updatedSpot = spot.withUpdatedTimestamp()

        guard let existing = CDWalkSpot.fetch(byId: spot.id, in: viewContext) else {
            logger.warning("Spot not found for update: \(spot.id)")
            setError(Strings.Common.notFound)
            return false
        }

        existing.update(from: updatedSpot)

        return performSave(operation: "Updated spot: \(spot.name)") {
            if let index = spots.firstIndex(where: { $0.id == spot.id }) {
                spots[index] = updatedSpot
            }
        }
    }

    /// Delete a spot
    @discardableResult
    func deleteSpot(_ spot: WalkSpot) -> Bool {
        guard let existing = CDWalkSpot.fetch(byId: spot.id, in: viewContext) else {
            logger.warning("Spot not found for deletion: \(spot.id)")
            setError(Strings.Common.notFound)
            return false
        }

        viewContext.delete(existing)

        return performDelete(operation: "Deleted spot: \(spot.name)") {
            spots.removeAll { $0.id == spot.id }
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
