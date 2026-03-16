//
//  CityDataProvider.swift
//  Ollie-app
//
//  Protocol for city-specific dog park data providers
//

import Foundation
import OtisShared

/// Bounding box for a city/region
struct GeoBounds {
    let south: Double
    let west: Double
    let north: Double
    let east: Double

    func contains(latitude: Double, longitude: Double) -> Bool {
        GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: (south, west, north, east))
    }
}

/// Protocol for city-specific dog park data providers
protocol CityDataProvider {
    /// Name of the city (for logging)
    var cityName: String { get }

    /// Geographic bounds for this city
    var bounds: GeoBounds { get }

    /// Fetch dog park spots from this city's API
    func fetch() async throws -> [DiscoveredSpot]
}

/// Base helper for common fetch patterns
enum CityDataProviderHelper {

    /// Fetch JSON data from a URL
    static func fetchJSON(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return data
    }
}
