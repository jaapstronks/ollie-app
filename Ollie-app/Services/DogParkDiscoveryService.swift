//
//  DogParkDiscoveryService.swift
//  Ollie-app
//
//  Discovers dog parks from external data sources (OpenStreetMap, government open data).
//  Uses Overpass API for OSM queries and caches results locally.
//

import Foundation
import Combine
import OllieShared
import os
import CoreLocation

/// Service for discovering dog parks from external data sources
@MainActor
class DogParkDiscoveryService: ObservableObject {

    // MARK: - Published State

    @Published var discoveredSpots: [DiscoveredSpot] = []
    @Published var isLoading = false
    @Published var lastError: Error?

    // MARK: - Private Properties

    private let logger = Logger.ollie(category: "DogParkDiscovery")

    // Cache: keyed by grid cell (rounded lat/lon)
    private var cache: [String: CacheEntry] = [:]
    private let cacheValidityHours: Double = 24

    private struct CacheEntry {
        let spots: [DiscoveredSpot]
        let fetchedAt: Date
    }

    // Overpass API endpoint
    private let overpassEndpoint = "https://overpass-api.de/api/interpreter"

    // Dutch government data endpoints
    private let eindhovenEndpoint = "https://data.eindhoven.nl/api/explore/v2.1/catalog/datasets/hondenlosloopterreinen/records"
    private let amsterdamEndpoint = "https://maps.amsterdam.nl/open_geodata/geojson_lnglat.php?KAARTLAAG=HONDEN&THEMA=honden"

    // Bounding boxes for Dutch cities (to determine when to fetch local data)
    private let eindhovenBounds = (south: 51.35, west: 5.35, north: 51.52, east: 5.60)
    private let amsterdamBounds = (south: 52.28, west: 4.73, north: 52.43, east: 5.07)

    // MARK: - Public Methods

    /// Discover dog parks near a location
    /// - Parameters:
    ///   - latitude: Center latitude
    ///   - longitude: Center longitude
    ///   - radiusKm: Search radius in kilometers (default 5km)
    func discoverNearby(latitude: Double, longitude: Double, radiusKm: Double = 5.0) async {
        let cacheKey = gridCacheKey(lat: latitude, lon: longitude)

        // Check cache
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.fetchedAt) < cacheValidityHours * 3600 {
            discoveredSpots = cached.spots
            logger.debug("Using cached dog parks for grid \(cacheKey): \(cached.spots.count) spots")
            return
        }

        isLoading = true
        lastError = nil

        do {
            // Fetch from OpenStreetMap
            var allSpots = try await fetchFromOverpass(
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm
            )

            // Also fetch from Dutch government sources if in range
            let dutchSpots = await fetchDutchGovernmentData(latitude: latitude, longitude: longitude)
            allSpots.append(contentsOf: dutchSpots)

            // Deduplicate by proximity (spots within 50m are considered duplicates)
            let uniqueSpots = deduplicateSpots(allSpots)

            discoveredSpots = uniqueSpots
            cache[cacheKey] = CacheEntry(spots: uniqueSpots, fetchedAt: Date())
            logger.info("Discovered \(uniqueSpots.count) dog parks near (\(latitude), \(longitude)) (OSM: \(allSpots.count - dutchSpots.count), Dutch gov: \(dutchSpots.count))")
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
        let cacheKey = gridCacheKey(lat: centerLat, lon: centerLon)

        // Check cache
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.fetchedAt) < cacheValidityHours * 3600 {
            discoveredSpots = cached.spots
            return
        }

        isLoading = true
        lastError = nil

        do {
            let spots = try await fetchFromOverpassBbox(
                south: south,
                west: west,
                north: north,
                east: east
            )
            discoveredSpots = spots
            cache[cacheKey] = CacheEntry(spots: spots, fetchedAt: Date())
            logger.info("Discovered \(spots.count) dog parks in bbox")
        } catch {
            lastError = error
            logger.error("Failed to discover dog parks: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Clear cache and refetch
    func refresh(latitude: Double, longitude: Double, radiusKm: Double = 5.0) async {
        let cacheKey = gridCacheKey(lat: latitude, lon: longitude)
        cache.removeValue(forKey: cacheKey)
        await discoverNearby(latitude: latitude, longitude: longitude, radiusKm: radiusKm)
    }

    /// Get spots within a certain distance
    func spotsNear(latitude: Double, longitude: Double, maxDistanceMeters: Double = 1000) -> [DiscoveredSpot] {
        discoveredSpots.filter { spot in
            let distance = haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: spot.latitude, lon2: spot.longitude
            )
            return distance <= maxDistanceMeters
        }
    }

    // MARK: - Overpass API

    private func fetchFromOverpass(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) async throws -> [DiscoveredSpot] {
        // Overpass QL query for dog parks within radius
        let radiusMeters = Int(radiusKm * 1000)
        let query = """
        [out:json][timeout:25];
        (
          nwr["leisure"="dog_park"](around:\(radiusMeters),\(latitude),\(longitude));
        );
        out center tags;
        """

        return try await executeOverpassQuery(query)
    }

    private func fetchFromOverpassBbox(
        south: Double,
        west: Double,
        north: Double,
        east: Double
    ) async throws -> [DiscoveredSpot] {
        // Overpass QL query for dog parks in bounding box
        // Format: (south,west,north,east)
        let query = """
        [out:json][timeout:25];
        (
          nwr["leisure"="dog_park"](\(south),\(west),\(north),\(east));
        );
        out center tags;
        """

        return try await executeOverpassQuery(query)
    }

    private func executeOverpassQuery(_ query: String) async throws -> [DiscoveredSpot] {
        guard let url = URL(string: overpassEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DiscoveryError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            logger.error("Overpass API returned status \(httpResponse.statusCode)")
            throw DiscoveryError.serverError(httpResponse.statusCode)
        }

        return try parseOverpassResponse(data)
    }

    private func parseOverpassResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(OverpassResponse.self, from: data)

        return response.elements.compactMap { element -> DiscoveredSpot? in
            // Get coordinates (nodes have lat/lon directly, ways/relations have center)
            let lat: Double
            let lon: Double

            if let centerLat = element.center?.lat, let centerLon = element.center?.lon {
                lat = centerLat
                lon = centerLon
            } else if let directLat = element.lat, let directLon = element.lon {
                lat = directLat
                lon = directLon
            } else {
                return nil
            }

            // Build unique ID
            let sourceId = "\(element.id)"
            let id = "osm:\(element.type):\(sourceId)"

            // Get name from tags (or generate from coordinates)
            let tags = element.tags ?? [:]
            let name = tags["name"] ?? tags["name:en"] ?? generatePlaceholderName(lat: lat, lon: lon)

            // Parse amenities
            var amenities: [String] = []
            if tags["dog_waste_bin"] == "yes" { amenities.append("waste bin") }
            if tags["bench"] == "yes" { amenities.append("bench") }
            if tags["water"] == "yes" || tags["drinking_water"] == "yes" { amenities.append("water") }
            if tags["lit"] == "yes" { amenities.append("lighting") }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .openStreetMap,
                sourceId: sourceId,
                category: .dogPark,
                address: tags["addr:street"],
                amenities: amenities,
                isFenced: tags["fence"] == "yes" || tags["fenced"] == "yes",
                surface: tags["surface"],
                fetchedAt: Date()
            )
        }
    }

    private func generatePlaceholderName(lat: Double, lon: Double) -> String {
        // Generate a simple name based on coordinates
        let latDir = lat >= 0 ? "N" : "S"
        let lonDir = lon >= 0 ? "E" : "W"
        return "Dog Park (\(abs(lat).formatted(.number.precision(.fractionLength(2))))\(latDir), \(abs(lon).formatted(.number.precision(.fractionLength(2))))\(lonDir))"
    }

    // MARK: - Dutch Government Data

    /// Fetch dog parks from Dutch government sources based on location
    private func fetchDutchGovernmentData(latitude: Double, longitude: Double) async -> [DiscoveredSpot] {
        var spots: [DiscoveredSpot] = []

        // Check if we're near Eindhoven
        if isInBounds(lat: latitude, lon: longitude, bounds: eindhovenBounds) {
            do {
                let eindhovenSpots = try await fetchFromEindhoven()
                spots.append(contentsOf: eindhovenSpots)
                logger.debug("Fetched \(eindhovenSpots.count) spots from Eindhoven open data")
            } catch {
                logger.warning("Failed to fetch Eindhoven data: \(error.localizedDescription)")
            }
        }

        // Check if we're near Amsterdam
        if isInBounds(lat: latitude, lon: longitude, bounds: amsterdamBounds) {
            do {
                let amsterdamSpots = try await fetchFromAmsterdam()
                spots.append(contentsOf: amsterdamSpots)
                logger.debug("Fetched \(amsterdamSpots.count) spots from Amsterdam open data")
            } catch {
                logger.warning("Failed to fetch Amsterdam data: \(error.localizedDescription)")
            }
        }

        return spots
    }

    private func isInBounds(lat: Double, lon: Double, bounds: (south: Double, west: Double, north: Double, east: Double)) -> Bool {
        return lat >= bounds.south && lat <= bounds.north && lon >= bounds.west && lon <= bounds.east
    }

    // MARK: - Eindhoven API

    private func fetchFromEindhoven() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: "\(eindhovenEndpoint)?limit=100") else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseEindhovenResponse(data)
    }

    private func parseEindhovenResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(EindhovenResponse.self, from: data)

        return response.results.compactMap { record -> DiscoveredSpot? in
            guard let geoPoint = record.geo_point_2d else { return nil }

            let id = "gov_nl:eindhoven:\(record.id ?? UUID().uuidString)"
            let name = record.straat ?? record.buurt ?? "Hondenlosloopterrein"

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: geoPoint.lat,
                longitude: geoPoint.lon,
                source: .governmentNL,
                sourceId: record.id ?? "",
                category: .offLeashArea,
                address: record.straat,
                amenities: [],
                isFenced: nil,
                surface: record.hoofd_categorie?.lowercased() == "gazon" ? "grass" : nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - Amsterdam API

    private func fetchFromAmsterdam() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: amsterdamEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseAmsterdamResponse(data)
    }

    private func parseAmsterdamResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(AmsterdamGeoJSON.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            // Get centroid of polygon
            guard let centroid = calculateCentroid(from: feature.geometry) else { return nil }

            let locationNumber = feature.properties.Locatienummer ?? "unknown"
            let id = "gov_nl:amsterdam:\(locationNumber)"

            // Determine category based on type
            let category: DiscoveredSpotCategory = feature.properties.Soort?.contains("Losloopgebied") == true
                ? .offLeashArea
                : .dogPark

            // Build name from location number and type
            let name = "Hondenzone \(locationNumber)"

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: centroid.lat,
                longitude: centroid.lon,
                source: .governmentNL,
                sourceId: locationNumber,
                category: category,
                address: nil,
                amenities: [],
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    private func calculateCentroid(from geometry: AmsterdamGeometry) -> (lat: Double, lon: Double)? {
        if let coords = geometry.polygonCoordinates,
           let ring = coords.first, !ring.isEmpty {
            let sumLon = ring.reduce(0.0) { $0 + $1[0] }
            let sumLat = ring.reduce(0.0) { $0 + $1[1] }
            return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
        }

        if let coords = geometry.multiPolygonCoordinates,
           let firstPolygon = coords.first,
           let ring = firstPolygon.first, !ring.isEmpty {
            let sumLon = ring.reduce(0.0) { $0 + $1[0] }
            let sumLat = ring.reduce(0.0) { $0 + $1[1] }
            return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
        }

        return nil
    }

    // MARK: - Deduplication

    /// Remove duplicate spots that are within 50 meters of each other
    /// Prefers government data over OSM when duplicates are found
    private func deduplicateSpots(_ spots: [DiscoveredSpot]) -> [DiscoveredSpot] {
        var unique: [DiscoveredSpot] = []

        for spot in spots {
            let isDuplicate = unique.contains { existing in
                let distance = haversineDistance(
                    lat1: spot.latitude, lon1: spot.longitude,
                    lat2: existing.latitude, lon2: existing.longitude
                )
                return distance < 50 // 50 meters threshold
            }

            if !isDuplicate {
                unique.append(spot)
            } else if spot.source == .governmentNL {
                // Replace OSM spot with government data if duplicate
                if let index = unique.firstIndex(where: { existing in
                    let distance = haversineDistance(
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

    // MARK: - Caching Helpers

    /// Generate cache key by rounding to 0.1 degree grid
    private func gridCacheKey(lat: Double, lon: Double) -> String {
        let roundedLat = (lat * 10).rounded() / 10
        let roundedLon = (lon * 10).rounded() / 10
        return "\(roundedLat),\(roundedLon)"
    }

    // MARK: - Distance Calculation

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

// MARK: - Overpass Response Models

private struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Codable {
    let type: String
    let id: Int64
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

private struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Eindhoven Response Models

private struct EindhovenResponse: Codable {
    let results: [EindhovenRecord]
}

private struct EindhovenRecord: Codable {
    let id: String?
    let straat: String?
    let buurt: String?
    let stadsdeel: String?
    let hoofd_categorie: String?
    let geo_point_2d: EindhovenGeoPoint?
}

private struct EindhovenGeoPoint: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Amsterdam Response Models

private struct AmsterdamGeoJSON: Codable {
    let type: String
    let features: [AmsterdamFeature]
}

private struct AmsterdamFeature: Codable {
    let type: String
    let properties: AmsterdamProperties
    let geometry: AmsterdamGeometry
}

private struct AmsterdamProperties: Codable {
    let Locatienummer: String?
    let Soort: String?
    let Speciale_regels: String?
}

private struct AmsterdamGeometry: Codable {
    let type: String
    var polygonCoordinates: [[[Double]]]?
    var multiPolygonCoordinates: [[[[Double]]]]?

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        if type == "MultiPolygon" {
            multiPolygonCoordinates = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            polygonCoordinates = nil
        } else {
            polygonCoordinates = try container.decode([[[Double]]].self, forKey: .coordinates)
            multiPolygonCoordinates = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let coords = multiPolygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        } else if let coords = polygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        }
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
