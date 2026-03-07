//
//  OverpassAPIClient.swift
//  Ollie-app
//
//  Handles communication with Overpass API for OpenStreetMap data
//

import Foundation
import OtisShared
import os

/// Client for querying Overpass API (OpenStreetMap)
actor OverpassAPIClient {

    // MARK: - Properties

    private let endpoint = "https://overpass-api.de/api/interpreter"
    private let logger = Logger.otis(category: "OverpassAPI")

    // MARK: - Dog Parks

    /// Fetch dog parks near a location
    /// Queries multiple OSM tag patterns to capture various dog area tagging conventions
    func fetchDogParks(
        latitude: Double,
        longitude: Double,
        radiusKm: Double
    ) async throws -> [DiscoveredSpot] {
        let radiusMeters = Int(radiusKm * 1000)
        // Query multiple tag patterns to capture regional variations:
        // - leisure=dog_park (explicit dog parks)
        // - dog=yes/unleashed/off_leash on leisure areas (multi-use parks allowing dogs)
        // - animal=dog areas (alternative tagging)
        let query = """
        [out:json][timeout:25];
        (
          nwr["leisure"="dog_park"](around:\(radiusMeters),\(latitude),\(longitude));
          nwr["dog"="yes"]["leisure"~"park|pitch|recreation_ground"](around:\(radiusMeters),\(latitude),\(longitude));
          nwr["dog"="unleashed"]["leisure"](around:\(radiusMeters),\(latitude),\(longitude));
          nwr["dog"="off_leash"]["leisure"](around:\(radiusMeters),\(latitude),\(longitude));
          nwr["animal"="dog"]["leisure"](around:\(radiusMeters),\(latitude),\(longitude));
        );
        out center tags;
        """

        let data = try await executeQuery(query)
        return try parseResponse(data, category: .dogPark)
    }

    /// Fetch dog parks in a bounding box
    func fetchDogParksInBbox(
        south: Double,
        west: Double,
        north: Double,
        east: Double
    ) async throws -> [DiscoveredSpot] {
        let query = """
        [out:json][timeout:25];
        (
          nwr["leisure"="dog_park"](\(south),\(west),\(north),\(east));
          nwr["dog"="yes"]["leisure"~"park|pitch|recreation_ground"](\(south),\(west),\(north),\(east));
          nwr["dog"="unleashed"]["leisure"](\(south),\(west),\(north),\(east));
          nwr["dog"="off_leash"]["leisure"](\(south),\(west),\(north),\(east));
          nwr["animal"="dog"]["leisure"](\(south),\(west),\(north),\(east));
        );
        out center tags;
        """

        let data = try await executeQuery(query)
        return try parseResponse(data, category: .dogPark)
    }

    // MARK: - Vet Clinics

    func fetchVetClinics(
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

        let data = try await executeQuery(query)
        return try parseResponse(data, category: .vetClinic)
    }

    // MARK: - Pet Stores

    func fetchPetStores(
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

        let data = try await executeQuery(query)
        return try parseResponse(data, category: .petStore)
    }

    // MARK: - Dog-Friendly Places

    func fetchDogFriendlyPlaces(
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

        let data = try await executeQuery(query)
        return try parseResponse(data, category: .dogFriendlyCafe)
    }

    // MARK: - Query Execution

    private func executeQuery(_ query: String) async throws -> Data {
        guard let url = URL(string: endpoint) else {
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

    // MARK: - Response Parsing

    private func parseResponse(_ data: Data, category: DiscoveredSpotCategory) throws -> [DiscoveredSpot] {
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
                name = generatePlaceholderName(for: category, lat: lat, lon: lon)
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
            case .dogPark:
                if tags["dog_waste_bin"] == "yes" { amenities.append("waste bin") }
                if tags["bench"] == "yes" { amenities.append("bench") }
                if tags["water"] == "yes" || tags["drinking_water"] == "yes" { amenities.append("water") }
                if tags["lit"] == "yes" { amenities.append("lighting") }
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

            // Determine if fenced (for dog parks)
            let isFenced: Bool? = category == .dogPark
                ? (tags["fence"] == "yes" || tags["fenced"] == "yes")
                : nil

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
                isFenced: isFenced,
                surface: tags["surface"],
                fetchedAt: Date()
            )
        }
    }

    private func generatePlaceholderName(for category: DiscoveredSpotCategory, lat: Double, lon: Double) -> String {
        let latDir = lat >= 0 ? "N" : "S"
        let lonDir = lon >= 0 ? "E" : "W"
        let coords = "(\(abs(lat).formatted(.number.precision(.fractionLength(2))))\(latDir), \(abs(lon).formatted(.number.precision(.fractionLength(2))))\(lonDir))"

        switch category {
        case .dogPark:
            return "Dog Park \(coords)"
        case .vetClinic:
            return "Vet Clinic \(coords)"
        case .petStore:
            return "Pet Store \(coords)"
        case .dogFriendlyCafe:
            return "Dog-Friendly Cafe \(coords)"
        default:
            return category.label + " \(coords)"
        }
    }
}
