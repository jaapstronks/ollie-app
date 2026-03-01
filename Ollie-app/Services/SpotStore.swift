//
//  SpotStore.swift
//  Otis-app
//
//  CRUD operations and persistence for WalkSpot with Core Data and automatic CloudKit sync
//

import Foundation
import CoreData
import OtisShared

/// Manages saved walk spots with Core Data and automatic CloudKit sync
@MainActor
final class SpotStore: CRUDStore<WalkSpot, CDWalkSpot> {

    // MARK: - Cached Computed Properties

    private var _cachedRecentSpots: [WalkSpot]?
    private var _cachedPopularSpots: [WalkSpot]?

    // MARK: - Sort Order

    override var sortOrder: StoreSortOrder<WalkSpot> {
        .custom { spot1, spot2 in
            // Sort by visit count (most visited first)
            spot1.visitCount > spot2.visitCount
        }
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "SpotStore")
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        invalidateCaches()
        super.performInitialLoad()
    }

    private func invalidateCaches() {
        _cachedRecentSpots = nil
        _cachedPopularSpots = nil
    }

    // MARK: - Backward-Compatible Aliases

    /// Alias for items (backward compatibility)
    var spots: [WalkSpot] { items }

    // MARK: - Cached Computed Properties

    /// Most recently added spots (last 5)
    var recentSpots: [WalkSpot] {
        if let cached = _cachedRecentSpots { return cached }
        let result = items
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
            .map { $0 }
        _cachedRecentSpots = result
        return result
    }

    /// All spots sorted by visit count (most visited first)
    var popularSpots: [WalkSpot] {
        if let cached = _cachedPopularSpots { return cached }
        let result = items.sorted { $0.visitCount > $1.visitCount }
        _cachedPopularSpots = result
        return result
    }

    // MARK: - CRUD Operations (with cache invalidation)

    @discardableResult
    override func add(_ item: WalkSpot) -> Bool {
        invalidateCaches()
        return super.add(item)
    }

    @discardableResult
    override func update(_ item: WalkSpot) -> Bool {
        invalidateCaches()
        return super.update(item.withUpdatedTimestamp())
    }

    @discardableResult
    override func delete(_ item: WalkSpot) -> Bool {
        invalidateCaches()
        return super.delete(item)
    }

    // MARK: - Backward-Compatible CRUD

    /// Add a new spot (backward-compatible alias)
    @discardableResult
    func addSpot(_ spot: WalkSpot) -> Bool {
        add(spot)
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
        add(spot)
        return spot
    }

    /// Update an existing spot (backward-compatible alias)
    @discardableResult
    func updateSpot(_ spot: WalkSpot) -> Bool {
        update(spot)
    }

    /// Delete a spot (backward-compatible alias)
    @discardableResult
    func deleteSpot(_ spot: WalkSpot) -> Bool {
        delete(spot)
    }

    /// Delete spot by ID
    func deleteSpot(id: UUID) {
        guard let spot = item(withId: id) else { return }
        delete(spot)
    }

    // MARK: - Domain-Specific Operations

    /// Increment visit count for a spot
    func incrementVisitCount(_ spot: WalkSpot) {
        guard var updatedSpot = item(withId: spot.id) else { return }
        updatedSpot.visitCount += 1
        update(updatedSpot)
    }

    /// Find spot by ID (backward-compatible alias)
    func spot(withId id: UUID) -> WalkSpot? {
        item(withId: id)
    }

    /// Find spots near a location (within ~100m)
    func spotsNear(latitude: Double, longitude: Double, radiusMeters: Double = 100) -> [WalkSpot] {
        filter { spot in
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
        let earthRadius: Double = 6_371_000 // meters

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}
