//
//  DiscoveredSpotsCache.swift
//  Ollie-app
//
//  Handles caching logic for discovered spots
//

import Foundation
import OtisShared
import os

/// Entry in the discovered spots cache
struct DiscoveredSpotsCacheEntry: Codable {
    let spots: [DiscoveredSpot]
    let fetchedAt: Date

    var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > 24 * 3600
    }
}

/// Manages caching of discovered spots with disk persistence
@MainActor
class DiscoveredSpotsCache {

    // MARK: - Properties

    private var cache: [String: DiscoveredSpotsCacheEntry] = [:]
    private let cacheValidityHours: Double = 24
    private let cacheFileName = "discovered-spots-cache.json"
    private let logger = Logger.otis(category: "DiscoveredSpotsCache")

    // MARK: - Initialization

    init() {
        loadCacheFromDisk()
    }

    // MARK: - Public Methods

    /// Generate cache key by rounding to 0.1 degree grid
    func gridCacheKey(lat: Double, lon: Double) -> String {
        let roundedLat = (lat * 10).rounded() / 10
        let roundedLon = (lon * 10).rounded() / 10
        return "\(roundedLat),\(roundedLon)"
    }

    /// Get cached entry for a key
    func get(_ key: String) -> DiscoveredSpotsCacheEntry? {
        cache[key]
    }

    /// Check if cache entry is valid (exists and not expired)
    func isValid(_ key: String) -> Bool {
        guard let entry = cache[key] else { return false }
        return Date().timeIntervalSince(entry.fetchedAt) < cacheValidityHours * 3600
    }

    /// Store spots in cache
    func store(_ spots: [DiscoveredSpot], forKey key: String) {
        cache[key] = DiscoveredSpotsCacheEntry(spots: spots, fetchedAt: Date())
        saveCacheToDisk()
    }

    /// Clear cache for all place types at a location
    func clearForLocation(latitude: Double, longitude: Double) {
        let gridKey = gridCacheKey(lat: latitude, lon: longitude)
        // Remove all cache entries for this grid cell (all place types)
        let keysToRemove = cache.keys.filter { $0.hasPrefix(gridKey) }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
        // Also remove the old-style cache key (for backwards compatibility)
        cache.removeValue(forKey: gridKey)
        saveCacheToDisk()
        logger.debug("Cleared cache for grid \(gridKey)")
    }

    /// Clear all cached data
    func clearAll() {
        cache.removeAll()
        saveCacheToDisk()
        logger.debug("Cleared all cache")
    }

    // MARK: - Cache Persistence

    /// Get the cache file URL
    private var cacheFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(cacheFileName)
    }

    /// Load cache from disk on initialization
    private func loadCacheFromDisk() {
        guard let url = cacheFileURL else {
            logger.warning("Could not determine cache file URL")
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.debug("No cache file found at \(url.path)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedCache = try decoder.decode([String: DiscoveredSpotsCacheEntry].self, from: data)

            // Filter out expired entries while loading
            var validEntries = 0
            var expiredEntries = 0
            for (key, entry) in loadedCache {
                if !entry.isExpired {
                    cache[key] = entry
                    validEntries += 1
                } else {
                    expiredEntries += 1
                }
            }

            logger.info("Loaded \(validEntries) valid cache entries from disk (skipped \(expiredEntries) expired)")
        } catch {
            logger.error("Failed to load cache from disk: \(error.localizedDescription)")
        }
    }

    /// Save cache to disk
    private func saveCacheToDisk() {
        guard let url = cacheFileURL else {
            logger.warning("Could not determine cache file URL for saving")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(cache)
            try data.write(to: url, options: .atomic)
            logger.debug("Saved \(self.cache.count) cache entries to disk")
        } catch {
            logger.error("Failed to save cache to disk: \(error.localizedDescription)")
        }
    }
}
