//
//  USAProviders.swift
//  Ollie-app
//
//  Dog park data providers for cities in the USA
//

import Foundation
import OtisShared

// MARK: - New York City

struct NYCProvider: CityDataProvider {
    let cityName = "NYC"
    let bounds = GeoBounds(south: 40.49, west: -74.26, north: 40.92, east: -73.70)

    private let endpoint = "https://data.cityofnewyork.us/resource/ipbu-mtcs.json"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: "\(endpoint)?$limit=500")
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let records = try decoder.decode([NYCDogRun].self, from: data)

        return records.compactMap { record -> DiscoveredSpot? in
            guard let lat = record.latitude ?? record.the_geom?.coordinates?.last,
                  let lon = record.longitude ?? record.the_geom?.coordinates?.first else {
                return nil
            }

            let recordId = record.prop_id ?? UUID().uuidString
            let id = "gov_us:nyc:\(recordId)"

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
}

// MARK: - Seattle

struct SeattleProvider: CityDataProvider {
    let cityName = "Seattle"
    let bounds = GeoBounds(south: 47.49, west: -122.46, north: 47.74, east: -122.22)

    private let endpoint = "https://services.arcgis.com/ZOyb2t4B0UYuYNYH/arcgis/rest/services/Dog_Off_Leash_Areas/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(SeattleArcGISResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            let attrs = feature.attributes

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
}

// MARK: - San Francisco

struct SanFranciscoProvider: CityDataProvider {
    let cityName = "San Francisco"
    let bounds = GeoBounds(south: 37.70, west: -122.52, north: 37.83, east: -122.35)

    private let endpoint = "https://data.sfgov.org/resource/fjzq-yb2u.json"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: "\(endpoint)?$limit=200")
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
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
}

// MARK: - Washington D.C.

struct WashingtonDCProvider: CityDataProvider {
    let cityName = "Washington D.C."
    let bounds = GeoBounds(south: 38.79, west: -77.12, north: 38.99, east: -76.91)

    private let endpoint = "https://maps2.dcgis.dc.gov/dcgis/rest/services/DCGIS_DATA/Recreation_WebMercator/MapServer/8/query?f=json&where=1=1&outFields=*&outSR=4326"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(DCArcGISResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            // Calculate centroid from polygon rings
            guard let rings = feature.geometry?.rings,
                  let firstRing = rings.first,
                  !firstRing.isEmpty else {
                return nil
            }

            // Calculate centroid of the first ring
            var sumLat = 0.0
            var sumLon = 0.0
            for coord in firstRing {
                if coord.count >= 2 {
                    sumLon += coord[0]
                    sumLat += coord[1]
                }
            }
            let lat = sumLat / Double(firstRing.count)
            let lon = sumLon / Double(firstRing.count)

            guard lat != 0 && lon != 0 else { return nil }

            let attrs = feature.attributes
            let objectId = attrs.OBJECTID.map { String($0) } ?? UUID().uuidString
            let id = "gov_us:dc:\(objectId)"

            let name = attrs.NAME ?? "Dog Park"

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentUS,
                sourceId: objectId,
                category: .dogPark,
                address: attrs.ADDRESS,
                amenities: [],
                isFenced: true,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }
}

// MARK: - Phoenix

struct PhoenixProvider: CityDataProvider {
    let cityName = "Phoenix"
    let bounds = GeoBounds(south: 33.29, west: -112.33, north: 33.75, east: -111.93)

    private let endpoint = "https://services1.arcgis.com/jyOUPqAWIBSiBXvb/arcgis/rest/services/Dog_Parks/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(PhoenixArcGISResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let geom = feature.geometry,
                  let lon = geom.x,
                  let lat = geom.y else {
                return nil
            }

            guard lat != 0 && lon != 0 else { return nil }

            let attrs = feature.attributes
            let objectId = attrs.OBJECTID.map { String($0) } ?? UUID().uuidString
            let id = "gov_us:phoenix:\(objectId)"

            let name = attrs.PARK_NAME ?? "Dog Park"

            var amenities: [String] = []
            if let acres = attrs.ACRES, acres > 0 {
                amenities.append(String(format: "%.1f acres", acres))
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentUS,
                sourceId: objectId,
                category: .dogPark,
                address: attrs.PARK_ADDRESS,
                amenities: amenities,
                isFenced: true,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }
}
