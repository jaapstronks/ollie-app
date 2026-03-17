//
//  CanadaProviders.swift
//  Ollie-app
//
//  Dog park data providers for cities in Canada
//

import Foundation
import OtisShared

// MARK: - Vancouver

struct VancouverProvider: CityDataProvider {
    let cityName = "Vancouver"
    let bounds = GeoBounds(south: 49.20, west: -123.27, north: 49.32, east: -123.02)

    private let endpoint = "https://opendata.vancouver.ca/api/explore/v2.1/catalog/datasets/dog-off-leash-parks/records"

    func fetch() async throws -> [DiscoveredSpot] {
        let data = try await CityDataProviderHelper.fetchJSON(from: "\(endpoint)?limit=100")
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
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
}

// MARK: - Calgary

struct CalgaryProvider: CityDataProvider {
    let cityName = "Calgary"
    let bounds = GeoBounds(south: 50.84, west: -114.27, north: 51.21, east: -113.90)

    private let endpoint = "https://data.calgary.ca/resource/kami-qbfh.json"

    func fetch() async throws -> [DiscoveredSpot] {
        // Filter for off-leash parks only
        let data = try await CityDataProviderHelper.fetchJSON(from: "\(endpoint)?$where=park_type='OFF LEASH'&$limit=500")
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> [DiscoveredSpot] {
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
}
