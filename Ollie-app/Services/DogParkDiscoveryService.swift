//
//  DogParkDiscoveryService.swift
//  Ollie-app
//
//  Discovers dog parks from external data sources (OpenStreetMap, government open data).
//  Coordinates between OverpassAPIClient, GovernmentDataProviders, and DiscoveredSpotsCache.
//

import Foundation
import Combine
import OtisShared
import os
import CoreLocation

/// Place types that can be discovered via Overpass API
enum DiscoverablePlaceType: CaseIterable {
    case dogParks
    case vetClinics
    case petStores
    case dogFriendlyPlaces

    var label: String {
        switch self {
        case .dogParks: return OtisShared.Strings.PlacesDiscovery.filterDogAreas
        case .vetClinics: return OtisShared.Strings.PlacesDiscovery.filterVets
        case .petStores: return OtisShared.Strings.PlacesDiscovery.filterPetStores
        case .dogFriendlyPlaces: return OtisShared.Strings.PlacesDiscovery.filterDogFriendly
        }
    }

    var defaultRadius: Double {
        switch self {
        case .dogParks: return 5.0
        case .vetClinics: return 10.0
        case .petStores: return 5.0
        case .dogFriendlyPlaces: return 3.0
        }
    }
}

/// Service for discovering dog parks from external data sources
@MainActor
class DogParkDiscoveryService: ObservableObject {

    // MARK: - Published State

    @Published var discoveredSpots: [DiscoveredSpot] = []
    @Published var isLoading = false
    @Published var lastError: Error?

    /// Active place type filters (which types are currently being shown)
    @Published var activePlaceTypes: Set<DiscoverablePlaceType> = Set(DiscoverablePlaceType.allCases)

    // MARK: - Private Properties

    private let logger = Logger.otis(category: "DogParkDiscovery")
    private let cache = DiscoveredSpotsCache()
    private let overpassClient = OverpassAPIClient()
    private let governmentProviders = GovernmentDataProviders()

    // MARK: - Public Methods

    /// Discover dog parks near a location
    func discoverNearby(latitude: Double, longitude: Double, radiusKm: Double = 5.0) async {
        let cacheKey = cache.gridCacheKey(lat: latitude, lon: longitude)

        // Check cache
        if cache.isValid(cacheKey), let cached = cache.get(cacheKey) {
            discoveredSpots = cached.spots
            logger.debug("Using cached dog parks for grid \(cacheKey): \(cached.spots.count) spots")
            return
        }

        isLoading = true
        lastError = nil

        do {
            // Fetch from OpenStreetMap
            var allSpots = try await overpassClient.fetchDogParks(
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm
            )

            // Also fetch from government sources if in range
            let govSpots = await governmentProviders.fetchAll(latitude: latitude, longitude: longitude)
            allSpots.append(contentsOf: govSpots)

            // Deduplicate by proximity (spots within 50m are considered duplicates)
            let uniqueSpots = deduplicateSpots(allSpots)

            discoveredSpots = uniqueSpots
            cache.store(uniqueSpots, forKey: cacheKey)
            logger.info("Discovered \(uniqueSpots.count) dog parks near (\(latitude), \(longitude)) (OSM: \(allSpots.count - govSpots.count), gov: \(govSpots.count))")
        } catch {
            lastError = error
            logger.error("Failed to discover dog parks: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Discover dog parks in a map bounding box
    func discoverInBounds(
        south: Double,
        west: Double,
        north: Double,
        east: Double
    ) async {
        // Use center point for cache key
        let centerLat = (south + north) / 2
        let centerLon = (west + east) / 2
        let cacheKey = cache.gridCacheKey(lat: centerLat, lon: centerLon)

        // Check cache
        if cache.isValid(cacheKey), let cached = cache.get(cacheKey) {
            discoveredSpots = cached.spots
            return
        }

        isLoading = true
        lastError = nil

        do {
            let spots = try await overpassClient.fetchDogParksInBbox(
                south: south,
                west: west,
                north: north,
                east: east
            )
            discoveredSpots = spots
            cache.store(spots, forKey: cacheKey)
            logger.info("Discovered \(spots.count) dog parks in bbox")
        } catch {
            lastError = error
            logger.error("Failed to discover dog parks: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Clear cache and refetch
    func refresh(latitude: Double, longitude: Double, radiusKm: Double = 5.0) async {
        cache.clearForLocation(latitude: latitude, longitude: longitude)
        await discoverNearby(latitude: latitude, longitude: longitude, radiusKm: radiusKm)
    }

    /// Get spots within a certain distance
    func spotsNear(latitude: Double, longitude: Double, maxDistanceMeters: Double = 1000) -> [DiscoveredSpot] {
        discoveredSpots.filter { spot in
            let distance = GeoUtils.haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: spot.latitude, lon2: spot.longitude
            )
            return distance <= maxDistanceMeters
        }
    }

    // MARK: - Multi-Type Discovery

    /// Discover all active place types near a location
    func discoverAllActiveTypes(latitude: Double, longitude: Double) async {
        let gridKey = cache.gridCacheKey(lat: latitude, lon: longitude)

        // Check if all active types are cached and valid
        var allCached = true
        var cachedSpots: [DiscoveredSpot] = []

        for placeType in activePlaceTypes {
            let typeKey = "\(gridKey):\(placeType)"
            if let cached = cache.get(typeKey), !cached.isExpired {
                cachedSpots.append(contentsOf: cached.spots)
            } else {
                allCached = false
                break
            }
        }

        // If all types are cached, use cached data
        if allCached {
            discoveredSpots = deduplicateSpots(cachedSpots)
            logger.debug("Using cached data for \(self.activePlaceTypes.count) place types at grid \(gridKey): \(self.discoveredSpots.count) spots")
            return
        }

        // Otherwise, fetch missing types
        isLoading = true
        lastError = nil

        var allSpots: [DiscoveredSpot] = []

        // Fetch each active place type (use cache if available)
        for placeType in activePlaceTypes {
            let typeKey = "\(gridKey):\(placeType)"

            if let cached = cache.get(typeKey), !cached.isExpired {
                // Use cached data for this type
                allSpots.append(contentsOf: cached.spots)
                logger.debug("Using cached \(String(describing: placeType)) at grid \(gridKey)")
            } else {
                // Fetch fresh data for this type
                let spots = await discoverPlaceType(
                    placeType,
                    latitude: latitude,
                    longitude: longitude,
                    radiusKm: placeType.defaultRadius
                )
                allSpots.append(contentsOf: spots)

                // Cache the results for this type
                cache.store(spots, forKey: typeKey)
                logger.debug("Fetched and cached \(spots.count) \(String(describing: placeType)) at grid \(gridKey)")
            }
        }

        // Deduplicate by proximity
        discoveredSpots = deduplicateSpots(allSpots)
        isLoading = false

        logger.info("Discovered \(self.discoveredSpots.count) total spots across \(self.activePlaceTypes.count) place types")
    }

    /// Discover a specific place type
    func discoverPlaceType(
        _ type: DiscoverablePlaceType,
        latitude: Double,
        longitude: Double,
        radiusKm: Double? = nil
    ) async -> [DiscoveredSpot] {
        let radius = radiusKm ?? type.defaultRadius

        switch type {
        case .dogParks:
            // Use existing dog park discovery (includes government sources)
            do {
                var spots = try await overpassClient.fetchDogParks(latitude: latitude, longitude: longitude, radiusKm: radius)
                let govSpots = await governmentProviders.fetchAll(latitude: latitude, longitude: longitude)
                spots.append(contentsOf: govSpots)
                return spots
            } catch {
                logger.error("Failed to fetch dog parks: \(error.localizedDescription)")
                return []
            }

        case .vetClinics:
            return await fetchSafely("vet clinics") {
                try await self.overpassClient.fetchVetClinics(latitude: latitude, longitude: longitude, radiusKm: radius)
            }

        case .petStores:
            return await fetchSafely("pet stores") {
                try await self.overpassClient.fetchPetStores(latitude: latitude, longitude: longitude, radiusKm: radius)
            }

        case .dogFriendlyPlaces:
            return await fetchSafely("dog-friendly places") {
                try await self.overpassClient.fetchDogFriendlyPlaces(latitude: latitude, longitude: longitude, radiusKm: radius)
            }
        }
    }

    /// Toggle a place type filter
    func togglePlaceType(_ type: DiscoverablePlaceType) {
        if activePlaceTypes.contains(type) {
            activePlaceTypes.remove(type)
        } else {
            activePlaceTypes.insert(type)
        }
    }

    // MARK: - Private Helpers

    /// Safely fetch from a source, logging errors but not throwing
    private func fetchSafely(_ source: String, _ fetcher: () async throws -> [DiscoveredSpot]) async -> [DiscoveredSpot] {
        do {
            let spots = try await fetcher()
            logger.debug("Fetched \(spots.count) spots from \(source)")
            return spots
        } catch {
            logger.warning("Failed to fetch \(source) data: \(error.localizedDescription)")
            return []
        }
    }

    /// Remove duplicate spots that are within 50 meters of each other
    /// Prefers government data over OSM when duplicates are found
    private func deduplicateSpots(_ spots: [DiscoveredSpot]) -> [DiscoveredSpot] {
        var unique: [DiscoveredSpot] = []

        for spot in spots {
            let isDuplicate = unique.contains { existing in
                let distance = GeoUtils.haversineDistance(
                    lat1: spot.latitude, lon1: spot.longitude,
                    lat2: existing.latitude, lon2: existing.longitude
                )
                return distance < 50 // 50 meters threshold
            }

            if !isDuplicate {
                unique.append(spot)
            } else if spot.source != .openStreetMap {
                // Replace OSM spot with government data if duplicate (gov data preferred)
                if let index = unique.firstIndex(where: { existing in
                    let distance = GeoUtils.haversineDistance(
                        lat1: spot.latitude, lon1: spot.longitude,
                        lat2: existing.latitude, lon2: existing.longitude
                    )
                    return distance < 50 && existing.source == .openStreetMap
                }) {
                    unique[index] = spot
                }
            }
        }

        return unique
    }
}

// MARK: - Errors

enum DiscoveryError: LocalizedError {
    case invalidURL
    case networkError
    case serverError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network connection failed"
        case .serverError(let code):
            return "Server error (code \(code))"
        case .parseError:
            return "Failed to parse response"
        }
    }
}
