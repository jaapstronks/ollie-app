//
//  ExplorationStore.swift
//  Otis-app
//
//  Manages explored map tiles for the "fog of war" feature.
//  Tracks which map tiles the dog has visited during walks.
//

import CoreData
import CoreLocation
import Foundation
import os
import OtisShared

/// Manages explored map tiles with Core Data and CloudKit sync
@MainActor
final class ExplorationStore: ProfileScopedCRUDStore<ExploredTile, CDExploredTile> {

    // MARK: - In-Memory Cache

    /// Set of explored tile keys for O(1) lookup
    /// Rebuilt from Core Data on load and updated in real-time during walks
    private var exploredTileKeys: Set<String> = []

    /// Tiles revealed during the current walk (not yet persisted)
    private var pendingTileKeys: Set<String> = []

    // MARK: - Sort Order

    override var sortOrder: StoreSortOrder<ExploredTile> {
        .descending(\.lastExploredAt)
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared, profileStore: ProfileStore? = nil) {
        super.init(
            persistenceController: persistenceController,
            profileStore: profileStore,
            logCategory: "ExplorationStore"
        )
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        loadTilesForCurrentProfile()
    }

    /// Load tiles for the current profile
    private func loadTilesForCurrentProfile() {
        guard let profile = getCurrentProfile() else {
            setItems([])
            exploredTileKeys = []
            return
        }

        // Fetch all tile keys efficiently (just the keys, not full objects)
        exploredTileKeys = CDExploredTile.fetchAllTileKeys(forProfile: profile, in: viewContext)

        // Fetch full tile data for stats
        let cdTiles = CDExploredTile.fetchAllTiles(forProfile: profile, in: viewContext)
        let tiles = cdTiles.compactMap { $0.toModel() }
        setItems(tiles)

        logger.info("Loaded \(self.exploredTileKeys.count) explored tiles for profile")
    }

    // MARK: - Exploration Queries

    /// Check if a coordinate has been explored
    /// - Parameter coordinate: The location to check
    /// - Returns: `true` if the tile containing this coordinate has been explored
    func isExplored(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let tileKey = ExploredTile.tileKey(for: coordinate)
        return exploredTileKeys.contains(tileKey) || pendingTileKeys.contains(tileKey)
    }

    /// Check if a specific tile key has been explored
    func isExplored(tileKey: String) -> Bool {
        exploredTileKeys.contains(tileKey) || pendingTileKeys.contains(tileKey)
    }

    /// Get all explored tile coordinates for rendering
    /// - Returns: Array of (x, y) tile coordinates at the default zoom level
    func exploredTileCoordinates() -> [(x: Int, y: Int)] {
        let allKeys = exploredTileKeys.union(pendingTileKeys)
        return allKeys.compactMap { key -> (x: Int, y: Int)? in
            let parts = key.split(separator: "_")
            guard parts.count == 3,
                  let x = Int(parts[1]),
                  let y = Int(parts[2]) else { return nil }
            return (x, y)
        }
    }

    // MARK: - Real-Time Exploration Recording

    /// Record a single coordinate during a walk (real-time reveal)
    /// - Parameter coordinate: The current location
    /// - Returns: `true` if this is a newly explored tile (for haptic feedback)
    @discardableResult
    func recordCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let tileKey = ExploredTile.tileKey(for: coordinate)

        // Check if already explored (persistent or pending)
        if exploredTileKeys.contains(tileKey) || pendingTileKeys.contains(tileKey) {
            return false
        }

        // Add to pending tiles (will be persisted when walk ends)
        pendingTileKeys.insert(tileKey)
        logger.debug("New tile revealed: \(tileKey)")
        return true
    }

    /// Persist pending tiles when a walk ends
    /// - Parameter route: Optional walk route to also process (if not already recorded via recordCoordinate)
    func persistPendingTiles(fromRoute route: WalkRoute? = nil) {
        guard let profile = getCurrentProfile() else {
            logger.warning("Cannot persist tiles: no current profile")
            pendingTileKeys.removeAll()
            return
        }

        // Collect tiles from route if provided (for historical data or batch processing)
        var allTileKeys = pendingTileKeys
        if let route = route {
            for location in route.coordinates {
                let tileKey = ExploredTile.tileKey(for: location.coordinate)
                allTileKeys.insert(tileKey)
            }
        }

        guard !allTileKeys.isEmpty else {
            logger.debug("No tiles to persist")
            return
        }

        let now = Date()
        var newTileCount = 0
        var updatedTileCount = 0

        for tileKey in allTileKeys {
            if exploredTileKeys.contains(tileKey) {
                // Update existing tile
                if let cdTile = CDExploredTile.fetchTile(byKey: tileKey, forProfile: profile, in: viewContext) {
                    cdTile.walkCount += 1
                    cdTile.lastExploredAt = now
                    cdTile.modifiedAt = now
                    updatedTileCount += 1
                }
            } else {
                // Create new tile
                let tile = ExploredTile(
                    tileKey: tileKey,
                    firstExploredAt: now,
                    lastExploredAt: now,
                    createdAt: now,
                    modifiedAt: now
                )
                let cdTile = CDExploredTile.create(from: tile, in: viewContext) as? CDExploredTile
                cdTile?.profile = profile
                exploredTileKeys.insert(tileKey)
                newTileCount += 1
            }
        }

        // Save to Core Data and queue for CloudKit sync
        do {
            try persistenceController.save()

            // Queue all new/updated tiles for CloudKit sync
            if let recordType = cloudKitRecordType {
                for tileKey in allTileKeys {
                    if let cdTile = CDExploredTile.fetchTile(byKey: tileKey, forProfile: profile, in: viewContext),
                       let tileId = cdTile.id {
                        let recordID = SyncCoordinator.shared.recordID(for: recordType, id: tileId)
                        SyncCoordinator.shared.markPendingSave(recordID: recordID)
                    }
                }
            }

            logger.info("Persisted \(newTileCount) new tiles, updated \(updatedTileCount) existing tiles")
        } catch {
            viewContext.rollback()
            logger.error("Failed to persist tiles: \(error.localizedDescription)")
        }

        // Clear pending tiles
        pendingTileKeys.removeAll()

        // Reload to update items array
        loadTilesForCurrentProfile()
    }

    /// Clear pending tiles without persisting (e.g., if walk was cancelled)
    func clearPendingTiles() {
        pendingTileKeys.removeAll()
    }

    // MARK: - Batch Route Recording

    /// Record all coordinates from a completed walk route
    /// Call this when a walk ends to persist exploration data
    /// - Parameter route: The completed walk route
    func recordWalkRoute(_ route: WalkRoute) {
        persistPendingTiles(fromRoute: route)
    }

    // MARK: - Statistics

    /// Total number of explored tiles
    var exploredTileCount: Int {
        exploredTileKeys.count
    }

    /// Estimated explored area in square meters
    /// Uses the default zoom level tile size
    var exploredAreaM2: Double {
        guard let firstTile = items.first,
              let y = firstTile.tileY else {
            // Estimate using equator tile size for default zoom
            let tileSizeM = ExploredTile.tileSizeMeters(atLatitude: 0, zoom: ExploredTile.defaultZoomLevel)
            return Double(exploredTileCount) * tileSizeM * tileSizeM
        }

        // Get approximate latitude from first tile for more accurate calculation
        let center = ExploredTile.coordinate(forTileX: firstTile.tileX ?? 0, tileY: y, zoom: ExploredTile.defaultZoomLevel)
        let tileSizeM = ExploredTile.tileSizeMeters(atLatitude: center.latitude, zoom: ExploredTile.defaultZoomLevel)
        return Double(exploredTileCount) * tileSizeM * tileSizeM
    }

    /// Formatted explored area string (e.g., "2.5 km\u{00B2}" or "450 m\u{00B2}")
    var formattedExploredArea: String {
        let areaM2 = exploredAreaM2
        if areaM2 >= 1_000_000 {
            let areaKm2 = areaM2 / 1_000_000
            return String(format: "%.1f km\u{00B2}", areaKm2)
        } else {
            return String(format: "%.0f m\u{00B2}", areaM2)
        }
    }
}

// MARK: - StorableModel Conformance

extension ExploredTile: StorableModel {
    public var displayName: String { tileKey }
}
