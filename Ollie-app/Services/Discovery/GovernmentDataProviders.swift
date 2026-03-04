//
//  GovernmentDataProviders.swift
//  Ollie-app
//
//  Fetches dog park data from government open data sources
//

import Foundation
import OtisShared
import os

/// Fetches dog park data from various government APIs
actor GovernmentDataProviders {

    // MARK: - Endpoints

    // Netherlands
    private let eindhovenEndpoint = "https://data.eindhoven.nl/api/explore/v2.1/catalog/datasets/hondenlosloopterreinen/records"
    private let amsterdamEndpoint = "https://maps.amsterdam.nl/open_geodata/geojson_lnglat.php?KAARTLAAG=HONDEN&THEMA=honden"

    // Germany
    private let berlinEndpoint = "https://gdi.berlin.de/services/wfs/hundefreilauf?service=wfs&version=2.0.0&request=GetFeature&typenames=hundefreilauf:hundefreilauf&outputFormat=application/json&srsName=EPSG:4326"
    private let hamburgEndpoint = "https://api.hamburg.de/datasets/v1/hundeauslaufzonen_paragraf_8/collections/hundeauslaufzonen_paragraf_8/items?f=json&limit=200"

    // USA
    private let nycEndpoint = "https://data.cityofnewyork.us/resource/ipbu-mtcs.json"
    private let seattleEndpoint = "https://services.arcgis.com/ZOyb2t4B0UYuYNYH/arcgis/rest/services/Dog_Off_Leash_Areas/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"
    private let sanFranciscoEndpoint = "https://data.sfgov.org/resource/fjzq-yb2u.json"

    // MARK: - Bounding Boxes

    // Netherlands
    private let eindhovenBounds = (south: 51.35, west: 5.35, north: 51.52, east: 5.60)
    private let amsterdamBounds = (south: 52.28, west: 4.73, north: 52.43, east: 5.07)

    // Germany
    private let berlinBounds = (south: 52.34, west: 13.09, north: 52.68, east: 13.76)
    private let hamburgBounds = (south: 53.39, west: 9.73, north: 53.72, east: 10.33)

    // USA
    private let nycBounds = (south: 40.49, west: -74.26, north: 40.92, east: -73.70)
    private let seattleBounds = (south: 47.49, west: -122.46, north: 47.74, east: -122.22)
    private let sanFranciscoBounds = (south: 37.70, west: -122.52, north: 37.83, east: -122.35)

    // MARK: - Properties

    private let logger = Logger.otis(category: "GovernmentData")

    // MARK: - Main Fetcher

    /// Fetch dog parks from government sources based on location
    func fetchAll(latitude: Double, longitude: Double) async -> [DiscoveredSpot] {
        var spots: [DiscoveredSpot] = []

        // Netherlands
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: eindhovenBounds) {
            spots.append(contentsOf: await fetchSafely("Eindhoven") { try await self.fetchFromEindhoven() })
        }
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: amsterdamBounds) {
            spots.append(contentsOf: await fetchSafely("Amsterdam") { try await self.fetchFromAmsterdam() })
        }

        // Germany
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: berlinBounds) {
            spots.append(contentsOf: await fetchSafely("Berlin") { try await self.fetchFromBerlin() })
        }
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: hamburgBounds) {
            spots.append(contentsOf: await fetchSafely("Hamburg") { try await self.fetchFromHamburg() })
        }

        // USA
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: nycBounds) {
            spots.append(contentsOf: await fetchSafely("NYC") { try await self.fetchFromNYC() })
        }
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: seattleBounds) {
            spots.append(contentsOf: await fetchSafely("Seattle") { try await self.fetchFromSeattle() })
        }
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: sanFranciscoBounds) {
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
}
