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
    private let washingtonDCEndpoint = "https://maps2.dcgis.dc.gov/dcgis/rest/services/DCGIS_DATA/Recreation_WebMercator/MapServer/8/query?f=json&where=1=1&outFields=*&outSR=4326"
    private let phoenixEndpoint = "https://services1.arcgis.com/jyOUPqAWIBSiBXvb/arcgis/rest/services/Dog_Parks/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"

    // Canada
    private let vancouverEndpoint = "https://opendata.vancouver.ca/api/explore/v2.1/catalog/datasets/dog-off-leash-parks/records"
    private let calgaryEndpoint = "https://data.calgary.ca/resource/kami-qbfh.json"

    // Australia
    private let sydneyEndpoint = "https://services1.arcgis.com/cNVyNtjGVZybOQWZ/arcgis/rest/services/Dog_off_leash_parks/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"
    private let canberraEndpoint = "https://services1.arcgis.com/E5n4f1VY84i0xSjy/arcgis/rest/services/Dog_Parks/FeatureServer/0/query?f=json&where=1=1&outFields=*&outSR=4326"

    // Austria
    private let viennaEndpoint = "https://data.wien.gv.at/daten/geo?service=WFS&request=GetFeature&version=1.1.0&typeName=ogdwien:HUNDEZONEOGD&srsName=EPSG:4326&outputFormat=json"

    // Belgium
    private let brusselsEndpoint = "https://opendata.brussels.be/api/explore/v2.1/catalog/datasets/dogzones/records"

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
    private let washingtonDCBounds = (south: 38.79, west: -77.12, north: 38.99, east: -76.91)
    private let phoenixBounds = (south: 33.29, west: -112.33, north: 33.75, east: -111.93)

    // Canada
    private let vancouverBounds = (south: 49.20, west: -123.27, north: 49.32, east: -123.02)
    private let calgaryBounds = (south: 50.84, west: -114.27, north: 51.21, east: -113.90)

    // Australia
    private let sydneyBounds = (south: -33.92, west: 151.15, north: -33.85, east: 151.23)
    private let canberraBounds = (south: -35.49, west: 148.98, north: -35.15, east: 149.25)

    // Austria
    private let viennaBounds = (south: 48.12, west: 16.18, north: 48.32, east: 16.58)

    // Belgium
    private let brusselsBounds = (south: 50.79, west: 4.29, north: 50.91, east: 4.44)

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
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: washingtonDCBounds) {
            spots.append(contentsOf: await fetchSafely("Washington D.C.") { try await self.fetchFromWashingtonDC() })
        }
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: phoenixBounds) {
            spots.append(contentsOf: await fetchSafely("Phoenix") { try await self.fetchFromPhoenix() })
        }

        // Canada
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: vancouverBounds) {
            spots.append(contentsOf: await fetchSafely("Vancouver") { try await self.fetchFromVancouver() })
        }
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: calgaryBounds) {
            spots.append(contentsOf: await fetchSafely("Calgary") { try await self.fetchFromCalgary() })
        }

        // Australia
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: sydneyBounds) {
            spots.append(contentsOf: await fetchSafely("Sydney") { try await self.fetchFromSydney() })
        }
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: canberraBounds) {
            spots.append(contentsOf: await fetchSafely("Canberra") { try await self.fetchFromCanberra() })
        }

        // Austria
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: viennaBounds) {
            spots.append(contentsOf: await fetchSafely("Vienna") { try await self.fetchFromVienna() })
        }

        // Belgium
        if GeoUtils.isInBounds(lat: latitude, lon: longitude, bounds: brusselsBounds) {
            spots.append(contentsOf: await fetchSafely("Brussels") { try await self.fetchFromBrussels() })
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

    // MARK: - Washington D.C. API (ArcGIS)

    private func fetchFromWashingtonDC() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: washingtonDCEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseWashingtonDCResponse(data)
    }

    private func parseWashingtonDCResponse(_ data: Data) throws -> [DiscoveredSpot] {
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

    // MARK: - Phoenix API (ArcGIS)

    private func fetchFromPhoenix() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: phoenixEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parsePhoenixResponse(data)
    }

    private func parsePhoenixResponse(_ data: Data) throws -> [DiscoveredSpot] {
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

    // MARK: - Vancouver API (CKAN/OpenAPI)

    private func fetchFromVancouver() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: "\(vancouverEndpoint)?limit=100") else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseVancouverResponse(data)
    }

    private func parseVancouverResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(VancouverCKANResponse.self, from: data)

        return response.records.compactMap { record -> DiscoveredSpot? in
            guard let geom = record.geom,
                  let coords = geom.coordinates,
                  coords.count >= 2 else {
                return nil
            }

            let lon = coords[0]
            let lat = coords[1]

            let parkId = record.park_id.map { String($0) } ?? UUID().uuidString
            let id = "gov_ca:vancouver:\(parkId)"

            let name = record.name ?? "Off-Leash Dog Park"

            var amenities: [String] = []
            if let hectare = record.hectare, hectare > 0 {
                amenities.append(String(format: "%.2f ha", hectare))
            }

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentCA,
                sourceId: parkId,
                category: .offLeashArea,
                address: nil,
                amenities: amenities,
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - Calgary API (Socrata)

    private func fetchFromCalgary() async throws -> [DiscoveredSpot] {
        // Filter for off-leash parks only
        guard let url = URL(string: "\(calgaryEndpoint)?$where=park_type='OFF LEASH'&$limit=500") else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseCalgaryResponse(data)
    }

    private func parseCalgaryResponse(_ data: Data) throws -> [DiscoveredSpot] {
        let decoder = JSONDecoder()
        let records = try decoder.decode([CalgaryParkSite].self, from: data)

        return records.compactMap { record -> DiscoveredSpot? in
            guard let latStr = record.latitude,
                  let lonStr = record.longitude,
                  let lat = Double(latStr),
                  let lon = Double(lonStr) else {
                return nil
            }

            let recordId = "\(record.park_name ?? "unknown")_\(lat)_\(lon)".replacingOccurrences(of: " ", with: "_")
            let id = "gov_ca:calgary:\(recordId)"

            let name = record.park_name ?? "Off-Leash Dog Park"

            return DiscoveredSpot(
                id: id,
                name: name,
                latitude: lat,
                longitude: lon,
                source: .governmentCA,
                sourceId: recordId,
                category: .offLeashArea,
                address: record.address,
                amenities: [],
                isFenced: nil,
                surface: nil,
                fetchedAt: Date()
            )
        }
    }

    // MARK: - Sydney API (ArcGIS)

    private func fetchFromSydney() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: sydneyEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseSydneyResponse(data)
    }

    private func parseSydneyResponse(_ data: Data) throws -> [DiscoveredSpot] {
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

    // MARK: - Canberra API (ArcGIS)

    private func fetchFromCanberra() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: canberraEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseCanberraResponse(data)
    }

    private func parseCanberraResponse(_ data: Data) throws -> [DiscoveredSpot] {
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

    // MARK: - Vienna API (WFS)

    private func fetchFromVienna() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: viennaEndpoint) else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseViennaResponse(data)
    }

    private func parseViennaResponse(_ data: Data) throws -> [DiscoveredSpot] {
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

    // MARK: - Brussels API (OpenData)

    private func fetchFromBrussels() async throws -> [DiscoveredSpot] {
        guard let url = URL(string: "\(brusselsEndpoint)?limit=100") else {
            throw DiscoveryError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DiscoveryError.networkError
        }

        return try parseBrusselsResponse(data)
    }

    private func parseBrusselsResponse(_ data: Data) throws -> [DiscoveredSpot] {
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
