//
//  NetherlandsProviders.swift
//  Ollie-app
//
//  Dog park data providers for cities in the Netherlands
//

import Foundation
import OtisShared

// MARK: - Eindhoven

struct EindhovenProvider: CityDataProvider {
    let cityName = "Eindhoven"
    let bounds = GeoBounds(south: 51.35, west: 5.35, north: 51.52, east: 5.60)

    private let endpoint = "https://data.eindhoven.nl/api/explore/v2.1/catalog/datasets/hondenlosloopterreinen/records"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: "\(endpoint)?limit=100")
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
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
}

// MARK: - Amsterdam

struct AmsterdamProvider: CityDataProvider {
    let cityName = "Amsterdam"
    let bounds = GeoBounds(south: 52.28, west: 4.73, north: 52.43, east: 5.07)

    private let endpoint = "https://maps.amsterdam.nl/open_geodata/geojson_lnglat.php?KAARTLAAG=HONDEN&THEMA=honden"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: endpoint)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(AmsterdamGeoJSON.self, from: data)

        return response.features.compactMap { feature -> DiscoveredSpot? in
            guard let centroid = GeoUtils.calculateAmsterdamCentroid(from: feature.geometry) else { return nil }

            let locationNumber = feature.properties.Locatienummer ?? "unknown"
            let id = "gov_nl:amsterdam:\(locationNumber)"

            let category: DiscoveredSpotCategory = feature.properties.Soort?.contains("Losloopgebied") == true
                ? .offLeashArea
                : .dogPark

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
}
