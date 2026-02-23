//
//  SpotStore.swift
//  Ollie-app
//
//  CRUD operations and persistence for WalkSpot

import Foundation
import Combine

/// Manages saved walk spots with local persistence
@MainActor
class SpotStore: ObservableObject {

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

    // MARK: - Storage

    private let fileName = "spots.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Init

    init() {
        loadSpots()
    }

    // MARK: - CRUD Operations

    /// Add a new spot
    func addSpot(_ spot: WalkSpot) {
        spots.append(spot)
        saveSpots()
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
        spots[index] = spot
        saveSpots()
    }

    /// Delete a spot
    func deleteSpot(_ spot: WalkSpot) {
        spots.removeAll { $0.id == spot.id }
        saveSpots()
    }

    /// Delete spot by ID
    func deleteSpot(id: UUID) {
        spots.removeAll { $0.id == id }
        saveSpots()
    }

    /// Toggle favorite status
    func toggleFavorite(_ spot: WalkSpot) {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else { return }
        spots[index].isFavorite.toggle()
        saveSpots()
    }

    /// Increment visit count for a spot
    func incrementVisitCount(_ spot: WalkSpot) {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else { return }
        spots[index].visitCount += 1
        saveSpots()
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
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            spots = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            spots = try decoder.decode([WalkSpot].self, from: data)
        } catch {
            print("Failed to load spots: \(error)")
            spots = []
        }
    }

    private func saveSpots() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(spots)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save spots: \(error)")
        }
    }

    // MARK: - CloudKit Sync Stubs

    /// Sync spots to CloudKit (stub - implement when CloudKit is enabled)
    func syncToCloud() async {
        // TODO: Implement CloudKit sync for spots
    }

    /// Fetch spots from CloudKit (stub)
    func fetchFromCloud() async {
        // TODO: Implement CloudKit fetch for spots
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
