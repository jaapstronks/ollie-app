//
//  AustraliaProviders.swift
//  Ollie-app
//
//  Dog park data providers for cities in Australia
//

import Foundation
import OtisShared

// MARK: - Sydney

struct SydneyProvider: CityDataProvider {
    let cityName = "Sydney"
    let bounds = GeoBounds(south: -33.92, west: 151.15, north: -33.85, east: 151.23)

    private let endpoint = "https://services1.arcgis.com/cNVyNtjGVZybOQWZ/arcgis/rest/services/Dog_off_leash_parks/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(SydneyArcGISResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let geom = feature.geometry,
                  let lon = geom.x,
                  let lat = geom.y else {
                return nil
            }

            guard lat != 0 && lon != 0 else { return nil }

            let attrs = feature.attributes
            let objectId = attrs.OBJECTID.map { String($0) } ?? UUID().uuidString
            let id = "gov_au:sydney:\(objectId)"

            let name = attrs.park_name ?? "Dog Off-Leash Park"

            let isFenced = attrs.fenced?.lowercased() == "yes" || attrs.fenced?.lowercased() == "true"

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentAU,
                sourceId: objectId,
                category: .offLeashArea,
                address: attrs.address,
                amenities: [],
                isFenced: isFenced,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }
}

// MARK: - Canberra

struct CanberraProvider: CityDataProvider {
    let cityName = "Canberra"
    let bounds = GeoBounds(south: -35.49, west: 148.98, north: -35.15, east: 149.25)

    private let endpoint = "https://services1.arcgis.com/E5n4f1VY84i0xSjy/arcgis/rest/services/Dog_Parks/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(CanberraArcGISResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let geom = feature.geometry,
                  let lon = geom.x,
                  let lat = geom.y else {
                return nil
            }

            guard lat != 0 && lon != 0 else { return nil }

            let attrs = feature.attributes
            let objectId = attrs.OBJECTID.map { String($0) } ?? UUID().uuidString
            let id = "gov_au:canberra:\(objectId)"

            let name = attrs.DOG_PARK_NAME ?? "Dog Park"

            let isFenced = attrs.FENCED?.lowercased() == "yes" || attrs.FENCED?.lowercased() == "true"

            var address: String?
            if let suburb = attrs.SUBURB {
                address = suburb
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentAU,
                sourceId: objectId,
                category: .dogPark,
                address: address,
                amenities: [],
                isFenced: isFenced,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }
}
