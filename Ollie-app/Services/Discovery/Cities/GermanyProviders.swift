//
//  GermanyProviders.swift
//  Ollie-app
//
//  Dog park data providers for cities in Germany
//

import Foundation
import OtisShared

// MARK: - Berlin

struct BerlinProvider: CityDataProvider {
    let cityName = "Berlin"
    let bounds = GeoBounds(south: 52.34, west: 13.09, north: 52.68, east: 13.76)

    private let endpoint = "https://gdi.berlin.de/services/wfs/hundefreilauf?service=wfs&version=2.0.0&request=GetFeature&typenames=hundefreilauf:hundefreilauf&outputFormat=application/json&srsName=EPSG:4326"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(BerlinWFSResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let centroid = GeoUtils.calculateGeoJSONCentroid(from: feature.geometry) else { return nil }

            let props = feature.properties
            let gisId = props.gisid.map { String($0) } ?? UUID().uuidString
            let id = "gov_de:berlin:\(gisId)"

            let name = props.bezeich ?? props.adresse ?? "Hundefreilauffläche"

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
}

// MARK: - Hamburg

struct HamburgProvider: CityDataProvider {
    let cityName = "Hamburg"
    let bounds = GeoBounds(south: 53.39, west: 9.73, north: 53.72, east: 10.33)

    private let endpoint = "https://api.hamburg.de/datasets/v1/hundeauslaufzonen_paragraf_8/collections/hundeauslaufzonen_paragraf_8/items?f=json&limit=200"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(HamburgOGCResponse.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let centroid = GeoUtils.calculateGeoJSONCentroid(from: feature.geometry) else { return nil }

            let props = feature.properties
            let featureId = feature.id ?? UUID().uuidString
            let id = "gov_de:hamburg:\(featureId)"

            let name = props.bezeichnung ?? "Hundeauslaufzone"

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
}
