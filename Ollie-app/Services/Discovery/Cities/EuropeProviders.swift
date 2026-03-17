//
//  EuropeProviders.swift
//  Ollie-app
//
//  Dog park data providers for cities in Austria and Belgium
//

import Foundation
import OtisShared

// MARK: - Vienna (Austria)

struct ViennaProvider: CityDataProvider {
    let cityName = "Vienna"
    let bounds = GeoBounds(south: 48.12, west: 16.18, north: 48.32, east: 16.58)

    private let endpoint = "https://data.wien.gv.at/daten/geo?service=WFS&request=GetFeature&version=1.1.0&typeName=ogdwien:HUNDEZONEOGD&srsName=EPSG:4326&outputFormat=json"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(ViennaWFSResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let centroid = GeoUtils.calculateGeoJSONCentroid(from: feature.geometry) else { return nil }

            let props = feature.properties
            let objectId = props.OBJECTID.map { String($0) } ?? feature.id ?? UUID().uuidString
            let id = "gov_at:vienna:\(objectId)"

            let name = props.BEZEICHNUNG ?? "Hundezone"

            var amenities: [String] = []
            if let area = props.FLAECHE, area > 0 {
                amenities.append("\(Int(area)) m²")
            }
            if let typ = props.TYP {
                amenities.append(typ)
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: centroid.lat,
                longitude: centroid.lon,
                source: .governmentAT,
                sourceId: objectId,
                category: .offLeashArea,
                address: props.ADRESSE,
                amenities: amenities,
                isFenced: true,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }
}

// MARK: - Brussels (Belgium)

struct BrusselsProvider: CityDataProvider {
    let cityName = "Brussels"
    let bounds = GeoBounds(south: 50.79, west: 4.29, north: 50.91, east: 4.44)

    private let endpoint = "https://opendata.brussels.be/api/explore/v2.1/catalog/datasets/dogzones/records"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: "\(endpoint)?limit=100")
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(BrusselsResponse.self, from: data)

        return response.results.compactMap { record -> DiscoveredSpot? in
            guard let geoPoint = record.geo_point_2d else { return nil }

            // Prefer English name, then French, then Dutch
            let name = record.name_en ?? record.name_fr ?? record.name_nl ?? "Dog Zone"

            let recordId = "\(name)_\(geoPoint.lat)_\(geoPoint.lon)".replacingOccurrences(of: " ", with: "_")
            let id = "gov_be:brussels:\(recordId)"

            // Prefer French address (Brussels is predominantly French-speaking)
            let address = record.address_fr ?? record.address_nl

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: geoPoint.lat,
                longitude: geoPoint.lon,
                source: .governmentBE,
                sourceId: recordId,
                category: .offLeashArea,
                address: address,
                amenities: [],
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }
}
