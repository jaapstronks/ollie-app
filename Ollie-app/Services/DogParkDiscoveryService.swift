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

/// Place types that can be discovered via Overpass API
enum DiscoverablePlaceType: CaseIterable {
    case dogParks
    case vetClinics
    case petStores
    case dogFriendlyPlaces

    var label: String {
        switch self {
        case .dogParks: return Strings.PlacesDiscovery.filterDogAreas
        case .vetClinics: return Strings.PlacesDiscovery.filterVets
        case .petStores: return Strings.PlacesDiscovery.filterPetStores
        case .dogFriendlyPlaces: return Strings.PlacesDiscovery.filterDogFriendly
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
    @Published var activePlaceTypes: Set<DiscoverablePlaceType> = [.dogParks]

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

    // German government data endpoints
    private let berlinEndpoint = "https://gdi.berlin.de/services/wfs/hundefreilauf?service=wfs&version=2.0.0&request=GetFeature&typenames=hundefreilauf:hundefreilauf&outputFormat=application/json&srsName=EPSG:4326"
    private let hamburgEndpoint = "https://api.hamburg.de/datasets/v1/hundeauslaufzonen_paragraf_8/collections/hundeauslaufzonen_paragraf_8/items?f=json&limit=200"

    // USA government data endpoints (Socrata / ArcGIS)
    private let nycEndpoint = "https://data.cityofnewyork.us/resource/ipbu-mtcs.json"
    private let seattleEndpoint = "https://services.arcgis.com/ZOyb2t4B0UYuYNYH/arcgis/rest/services/Dog_Off_Leash_Areas/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"
    private let sanFranciscoEndpoint = "https://data.sfgov.org/resource/fjzq-yb2u.json"

    // Bounding boxes for Dutch cities (to determine when to fetch local data)
    private let eindhovenBounds = (south: 51.35, west: 5.35, north: 51.52, east: 5.60)
    private let amsterdamBounds = (south: 52.28, west: 4.73, north: 52.43, east: 5.07)

    // Bounding boxes for German cities
    private let berlinBounds = (south: 52.34, west: 13.09, north: 52.68, east: 13.76)
    private let hamburgBounds = (south: 53.39, west: 9.73, north: 53.72, east: 10.33)

    // Bounding boxes for US cities
    private let nycBounds = (south: 40.49, west: -74.26, north: 40.92, east: -73.70)
    private let seattleBounds = (south: 47.49, west: -122.46, north: 47.74, east: -122.22)
    private let sanFranciscoBounds = (south: 37.70, west: -122.52, north: 37.83, east: -122.35)

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

            // Also fetch from government sources if in range
            let govSpots = await fetchGovernmentData(latitude: latitude, longitude: longitude)
            allSpots.append(contentsOf: govSpots)

            // Deduplicate by proximity (spots within 50m are considered duplicates)
            let uniqueSpots = deduplicateSpots(allSpots)

            discoveredSpots = uniqueSpots
            cache[cacheKey] = CacheEntry(spots: uniqueSpots, fetchedAt: Date())
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

    // MARK: - Multi-Type Discovery

    /// Discover all active place types near a location
    func discoverAllActiveTypes(latitude: Double, longitude: Double) async {
        isLoading = true
        lastError = nil

        var allSpots: [DiscoveredSpot] = []

        // Fetch each active place type
        for placeType in activePlaceTypes {
            let spots = await discoverPlaceType(
                placeType,
                latitude: latitude,
                longitude: longitude,
                radiusKm: placeType.defaultRadius
            )
            allSpots.append(contentsOf: spots)
        }

        // Deduplicate by proximity
        discoveredSpots = deduplicateSpots(allSpots)
        isLoading = false

        logger.info("Discovered \(discoveredSpots.count) total spots across \(activePlaceTypes.count) place types")
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
                var spots = try await fetchFromOverpass(latitude: latitude, longitude: longitude, radiusKm: radius)
                let govSpots = await fetchGovernmentData(latitude: latitude, longitude: longitude)
                spots.append(contentsOf: govSpots)
                return spots
            } catch {
                logger.error("Failed to fetch dog parks: \(error.localizedDescription)")
                return []
            }

        case .vetClinics:
            return await fetchSafely("vet clinics") {
                try await self.fetchVetClinics(latitude: latitude, longitude: longitude, radiusKm: radius)
            }

        case .petStores:
            return await fetchSafely("pet stores") {
                try await self.fetchPetStores(latitude: latitude, longitude: longitude, radiusKm: radius)
            }

        case .dogFriendlyPlaces:
            return await fetchSafely("dog-friendly places") {
                try await self.fetchDogFriendlyPlaces(latitude: latitude, longitude: longitude, radiusKm: radius)
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

    // MARK: - Vet Clinics (Overpass)

    private func fetchVetClinics(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) async throws -> [DiscoveredSpot] {
        let radiusMeters = Int(radiusKm * 1000)
        let query = """
        [out:json][timeout:25];
        (
          nwr["amenity"="veterinary"](around:\(radiusMeters),\(latitude),\(longitude));
        );
        out center tags;
        """

        let data = try await executeOverpassQueryRaw(query)
        return try parseOverpassResponseWithCategory(data, category: .vetClinic)
    }

    // MARK: - Pet Stores (Overpass)

    private func fetchPetStores(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) async throws -> [DiscoveredSpot] {
        let radiusMeters = Int(radiusKm * 1000)
        let query = """
        [out:json][timeout:25];
        (
          nwr["shop"="pet"](around:\(radiusMeters),\(latitude),\(longitude));
        );
        out center tags;
        """

        let data = try await executeOverpassQueryRaw(query)
        return try parseOverpassResponseWithCategory(data, category: .petStore)
    }

    // MARK: - Dog-Friendly Places (Overpass)

    private func fetchDogFriendlyPlaces(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) async throws -> [DiscoveredSpot] {
        let radiusMeters = Int(radiusKm * 1000)
        // Query for cafes, restaurants, and pubs that explicitly allow dogs
        let query = """
        [out:json][timeout:25];
        (
          nwr["dog"="yes"]["amenity"~"cafe|restaurant|pub|bar"](around:\(radiusMeters),\(latitude),\(longitude));
        );
        out center tags;
        """

        let data = try await executeOverpassQueryRaw(query)
        return try parseOverpassResponseWithCategory(data, category: .dogFriendlyCafe)
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
        let data = try await executeOverpassQueryRaw(query)
        return try parseOverpassResponse(data)
    }

    /// Execute Overpass query and return raw data (for parsing with different categories)
    private func executeOverpassQueryRaw(_ query: String) async throws -> Data {
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

        return data
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

    /// Parse Overpass response with a specific category (for vets, pet stores, etc.)
    private func parseOverpassResponseWithCategory(_ data: Data, category: DiscoveredSpotCategory) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(OverpassResponse.self, from: data)

        return response.elements.compactMap { element -> DiscoveredSpot? in
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

            let sourceId = "\(element.id)"
            let id = "osm:\(element.type):\(sourceId)"

            let tags = element.tags ?? [:]

            // Get name or generate placeholder based on category
            let name: String
            if let tagName = tags["name"] ?? tags["name:en"] {
                name = tagName
            } else {
                name = generatePlaceholderNameForCategory(category, lat: lat, lon: lon)
            }

            // Build address from OSM address tags
            var address: String?
            if let street = tags["addr:street"] {
                if let houseNumber = tags["addr:housenumber"] {
                    address = "\(street) \(houseNumber)"
                } else {
                    address = street
                }
                if let city = tags["addr:city"] {
                    address = "\(address!), \(city)"
                }
            }

            // Category-specific amenities
            var amenities: [String] = []
            switch category {
            case .vetClinic:
                if tags["emergency"] == "yes" { amenities.append("24h emergency") }
                if tags["wheelchair"] == "yes" { amenities.append("wheelchair accessible") }
            case .petStore:
                if tags["grooming"] == "yes" { amenities.append("grooming") }
            case .dogFriendlyCafe:
                if tags["outdoor_seating"] == "yes" { amenities.append("outdoor seating") }
                if tags["wifi"] == "yes" { amenities.append("wifi") }
            default:
                break
            }

            // Parse opening hours if available
            if let hours = tags["opening_hours"] {
                amenities.append(hours)
            }

            // Parse phone/website
            if tags["phone"] != nil || tags["contact:phone"] != nil {
                amenities.append("phone available")
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .openStreetMap,
                sourceId: sourceId,
                category: category,
                address: address,
                amenities: amenities,
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    private func generatePlaceholderNameForCategory(_ category: DiscoveredSpotCategory, lat: Double, lon: Double) -> String {
        let latDir = lat >= 0 ? "N" : "S"
        let lonDir = lon >= 0 ? "E" : "W"
        let coords = "(\(abs(lat).formatted(.number.precision(.fractionLength(2))))\(latDir), \(abs(lon).formatted(.number.precision(.fractionLength(2))))\(lonDir))"

        switch category {
        case .vetClinic:
            return "Vet Clinic \(coords)"
        case .petStore:
            return "Pet Store \(coords)"
        case .dogFriendlyCafe:
            return "Dog-Friendly Café \(coords)"
        default:
            return category.label + " \(coords)"
        }
    }

    // MARK: - Government Data (All Regions)

    /// Fetch dog parks from government sources based on location
    private func fetchGovernmentData(latitude: Double, longitude: Double) async -> [DiscoveredSpot] {
        var spots: [DiscoveredSpot] = []

        // Netherlands
        if isInBounds(lat: latitude, lon: longitude, bounds: eindhovenBounds) {
            spots.append(contentsOf: await fetchSafely("Eindhoven") { try await self.fetchFromEindhoven() })
        }
        if isInBounds(lat: latitude, lon: longitude, bounds: amsterdamBounds) {
            spots.append(contentsOf: await fetchSafely("Amsterdam") { try await self.fetchFromAmsterdam() })
        }

        // Germany
        if isInBounds(lat: latitude, lon: longitude, bounds: berlinBounds) {
            spots.append(contentsOf: await fetchSafely("Berlin") { try await self.fetchFromBerlin() })
        }
        if isInBounds(lat: latitude, lon: longitude, bounds: hamburgBounds) {
            spots.append(contentsOf: await fetchSafely("Hamburg") { try await self.fetchFromHamburg() })
        }

        // USA
        if isInBounds(lat: latitude, lon: longitude, bounds: nycBounds) {
            spots.append(contentsOf: await fetchSafely("NYC") { try await self.fetchFromNYC() })
        }
        if isInBounds(lat: latitude, lon: longitude, bounds: seattleBounds) {
            spots.append(contentsOf: await fetchSafely("Seattle") { try await self.fetchFromSeattle() })
        }
        if isInBounds(lat: latitude, lon: longitude, bounds: sanFranciscoBounds) {
            spots.append(contentsOf: await fetchSafely("San Francisco") { try await self.fetchFromSanFrancisco() })
        }

        return spots
    }

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

    // MARK: - Berlin API (WFS GeoJSON)

    private func fetchFromBerlin() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: berlinEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseBerlinResponse(data)
    }

    private func parseBerlinResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(BerlinWFSResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let centroid = calculateGeoJSONCentroid(from: feature.geometry) else { return nil }

            let props = feature.properties
            let gisId = props.gisid.map { String($0) } ?? UUID().uuidString
            let id = "gov_de:berlin:\(gisId)"

            // Build name from designation or address
            let name = props.bezeich ?? props.adresse ?? "Hundefreilauffläche"

            // Parse area from info field (e.g., "9186 m²")
            var amenities: [String] = []
            if let info = props.info, info.contains("m²") {
                amenities.append(info)
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: centroid.lat,
                longitude: centroid.lon,
                source: .governmentDE,
                sourceId: gisId,
                category: .offLeashArea,
                address: props.adresse,
                amenities: amenities,
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - Hamburg API (OGC Features)

    private func fetchFromHamburg() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: hamburgEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseHamburgResponse(data)
    }

    private func parseHamburgResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(HamburgOGCResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let centroid = calculateGeoJSONCentroid(from: feature.geometry) else { return nil }

            let props = feature.properties
            let featureId = feature.id ?? UUID().uuidString
            let id = "gov_de:hamburg:\(featureId)"

            let name = props.bezeichnung ?? "Hundeauslaufzone"

            // Parse area if available
            var amenities: [String] = []
            if let area = props.flaeche_in_qm {
                let areaNum = Double(area) ?? 0
                if areaNum > 0 {
                    amenities.append("\(Int(areaNum)) m²")
                }
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: centroid.lat,
                longitude: centroid.lon,
                source: .governmentDE,
                sourceId: featureId,
                category: .offLeashArea,
                address: nil,
                amenities: amenities,
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - NYC API (Socrata)

    private func fetchFromNYC() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: "\(nycEndpoint)?$limit=500") else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseNYCResponse(data)
    }

    private func parseNYCResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let records = try decoder.decode([NYCDogRun].self, from: data)

        return records.compactMap { record -> DiscoveredSpot? in
            // Try to get coordinates from various possible fields
            guard let lat = record.latitude ?? record.the_geom?.coordinates?.last,
                  let lon = record.longitude ?? record.the_geom?.coordinates?.first else {
                return nil
            }

            let recordId = record.prop_id ?? UUID().uuidString
            let id = "gov_us:nyc:\(recordId)"

            // Build name from park name and dog run name
            var name = record.name ?? record.dogruns_type ?? "Dog Run"
            if let parkName = record.park_name, !name.contains(parkName) {
                name = "\(parkName) - \(name)"
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentUS,
                sourceId: recordId,
                category: .dogPark,
                address: record.address,
                amenities: [],
                isFenced: record.dogruns_type?.lowercased().contains("run") == true,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - Seattle API (ArcGIS)

    private func fetchFromSeattle() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: seattleEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseSeattleResponse(data)
    }

    private func parseSeattleResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(SeattleArcGISResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            let attrs = feature.attributes

            // Use LATITUDE/LONGITUDE fields, or geometry centroid
            let lat: Double
            let lon: Double

            if let attrLat = attrs.LATITUDE, let attrLon = attrs.LONGITUDE {
                lat = attrLat
                lon = attrLon
            } else if let geom = feature.geometry {
                lat = geom.y ?? 0
                lon = geom.x ?? 0
            } else {
                return nil
            }

            guard lat != 0 && lon != 0 else { return nil }

            let objectId = attrs.OBJECTID.map { String($0) } ?? UUID().uuidString
            let id = "gov_us:seattle:\(objectId)"

            let name = attrs.NAME ?? "Off-Leash Dog Area"

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentUS,
                sourceId: objectId,
                category: .offLeashArea,
                address: nil,
                amenities: [],
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - San Francisco API (Socrata)

    private func fetchFromSanFrancisco() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: "\(sanFranciscoEndpoint)?$limit=200") else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseSanFranciscoResponse(data)
    }

    private func parseSanFranciscoResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let records = try decoder.decode([SFDogPlayArea].self, from: data)

        return records.compactMap { record -> DiscoveredSpot? in
            guard let lat = record.latitude,
                  let lon = record.longitude else {
                return nil
            }

            let recordId = record.objectid.map { String($0) } ?? UUID().uuidString
            let id = "gov_us:sf:\(recordId)"

            let name = record.park_name ?? record.dpa_name ?? "Dog Play Area"

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentUS,
                sourceId: recordId,
                category: .offLeashArea,
                address: nil,
                amenities: [],
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - GeoJSON Centroid Helper

    private func calculateGeoJSONCentroid(from geometry: GeoJSONGeometry) -> (lat: Double, lon: Double)? {
        switch geometry.type {
        case "Point":
            if let coords = geometry.pointCoordinates, coords.count >= 2 {
                return (lat: coords[1], lon: coords[0])
            }
        case "Polygon":
            if let coords = geometry.polygonCoordinates,
               let ring = coords.first, !ring.isEmpty {
                let sumLon = ring.reduce(0.0) { $0 + $1[0] }
                let sumLat = ring.reduce(0.0) { $0 + $1[1] }
                return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
            }
        case "MultiPolygon":
            if let coords = geometry.multiPolygonCoordinates,
               let firstPolygon = coords.first,
               let ring = firstPolygon.first, !ring.isEmpty {
                let sumLon = ring.reduce(0.0) { $0 + $1[0] }
                let sumLat = ring.reduce(0.0) { $0 + $1[1] }
                return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
            }
        default:
            break
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
            } else if spot.source != .openStreetMap {
                // Replace OSM spot with government data if duplicate (gov data preferred)
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

// MARK: - Generic GeoJSON Geometry

private struct GeoJSONGeometry: Codable {
    let type: String
    var pointCoordinates: [Double]?
    var polygonCoordinates: [[[Double]]]?
    var multiPolygonCoordinates: [[[[Double]]]]?

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        switch type {
        case "Point":
            pointCoordinates = try container.decode([Double].self, forKey: .coordinates)
        case "MultiPolygon":
            multiPolygonCoordinates = try container.decode([[[[Double]]]].self, forKey: .coordinates)
        case "Polygon":
            polygonCoordinates = try container.decode([[[Double]]].self, forKey: .coordinates)
        default:
            // Try polygon as fallback
            polygonCoordinates = try? container.decode([[[Double]]].self, forKey: .coordinates)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let coords = pointCoordinates {
            try container.encode(coords, forKey: .coordinates)
        } else if let coords = multiPolygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        } else if let coords = polygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        }
    }
}

// MARK: - Berlin WFS Response Models

private struct BerlinWFSResponse: Codable {
    let type: String
    let features: [BerlinFeature]
}

private struct BerlinFeature: Codable {
    let type: String
    let properties: BerlinProperties
    let geometry: GeoJSONGeometry
}

private struct BerlinProperties: Codable {
    let gisid: Int?
    let uid: String?
    let bezirk: String?
    let typ: String?
    let info: String?
    let adresse: String?
    let bezeich: String?
    let zustaendig: String?
}

// MARK: - Hamburg OGC Response Models

private struct HamburgOGCResponse: Codable {
    let type: String
    let features: [HamburgFeature]
}

private struct HamburgFeature: Codable {
    let type: String
    let id: String?
    let properties: HamburgProperties
    let geometry: GeoJSONGeometry
}

private struct HamburgProperties: Codable {
    let bezeichnung: String?
    let ortsteilnummer: Int?
    let flaeche_in_qm: String?
}

// MARK: - NYC Socrata Response Models

private struct NYCDogRun: Codable {
    let prop_id: String?
    let name: String?
    let park_name: String?
    let dogruns_type: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let the_geom: NYCGeometry?

    private enum CodingKeys: String, CodingKey {
        case prop_id
        case name
        case park_name = "park_name"
        case dogruns_type
        case address
        case latitude
        case longitude
        case the_geom
    }
}

private struct NYCGeometry: Codable {
    let type: String?
    let coordinates: [Double]?
}

// MARK: - Seattle ArcGIS Response Models

private struct SeattleArcGISResponse: Codable {
    let features: [SeattleFeature]
}

private struct SeattleFeature: Codable {
    let attributes: SeattleAttributes
    let geometry: SeattleGeometry?
}

private struct SeattleAttributes: Codable {
    let OBJECTID: Int?
    let ID: Int?
    let NAME: String?
    let LATITUDE: Double?
    let LONGITUDE: Double?
    let PMAID: String?
    let LOCID: String?
}

private struct SeattleGeometry: Codable {
    let x: Double?
    let y: Double?
}

// MARK: - San Francisco Socrata Response Models

private struct SFDogPlayArea: Codable {
    let objectid: Int?
    let park_name: String?
    let dpa_name: String?
    let latitude: Double?
    let longitude: Double?

    private enum CodingKeys: String, CodingKey {
        case objectid
        case park_name
        case dpa_name
        case latitude
        case longitude
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
