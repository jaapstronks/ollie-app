//
//  DiscoveryResponseModels.swift
//  Otis-app
//
//  Response models for external discovery APIs (Overpass, government data sources)
//

import Foundation

// MARK: - Overpass Response Models

struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String
    let id: Int64
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Eindhoven Response Models

struct EindhovenResponse: Codable {
    let results: [EindhovenRecord]
}

struct EindhovenRecord: Codable {
    let id: String?
    let straat: String?
    let buurt: String?
    let stadsdeel: String?
    let hoofd_categorie: String?
    let geo_point_2d: EindhovenGeoPoint?
}

struct EindhovenGeoPoint: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Amsterdam Response Models

struct AmsterdamGeoJSON: Codable {
    let type: String
    let features: [AmsterdamFeature]
}

struct AmsterdamFeature: Codable {
    let type: String
    let properties: AmsterdamProperties
    let geometry: AmsterdamGeometry
}

struct AmsterdamProperties: Codable {
    let Locatienummer: String?
    let Soort: String?
    let Speciale_regels: String?
}

struct AmsterdamGeometry: Codable {
    let type: String
    var polygonCoordinates: [[[Double]]]?
    var multiPolygonCoordinates: [[[[Double]]]]?

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        if type == "MultiPolygon" {
            multiPolygonCoordinates = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            polygonCoordinates = nil
        } else {
            polygonCoordinates = try container.decode([[[Double]]].self, forKey: .coordinates)
            multiPolygonCoordinates = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let coords = multiPolygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        } else if let coords = polygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        }
    }
}

// MARK: - Generic GeoJSON Geometry

struct GeoJSONGeometry: Codable {
    let type: String
    var pointCoordinates: [Double]?
    var polygonCoordinates: [[[Double]]]?
    var multiPolygonCoordinates: [[[[Double]]]]?

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        switch type {
        case "Point":
            pointCoordinates = try container.decode([Double].self, forKey: .coordinates)
        case "MultiPolygon":
            multiPolygonCoordinates = try container.decode([[[[Double]]]].self, forKey: .coordinates)
        case "Polygon":
            polygonCoordinates = try container.decode([[[Double]]].self, forKey: .coordinates)
        default:
            // Try polygon as fallback
            polygonCoordinates = try? container.decode([[[Double]]].self, forKey: .coordinates)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let coords = pointCoordinates {
            try container.encode(coords, forKey: .coordinates)
        } else if let coords = multiPolygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        } else if let coords = polygonCoordinates {
            try container.encode(coords, forKey: .coordinates)
        }
    }
}

// MARK: - Berlin WFS Response Models

struct BerlinWFSResponse: Codable {
    let type: String
    let features: [BerlinFeature]
}

struct BerlinFeature: Codable {
    let type: String
    let properties: BerlinProperties
    let geometry: GeoJSONGeometry
}

struct BerlinProperties: Codable {
    let gisid: Int?
    let uid: String?
    let bezirk: String?
    let typ: String?
    let info: String?
    let adresse: String?
    let bezeich: String?
    let zustaendig: String?
}

// MARK: - Hamburg OGC Response Models

struct HamburgOGCResponse: Codable {
    let type: String
    let features: [HamburgFeature]
}

struct HamburgFeature: Codable {
    let type: String
    let id: String?
    let properties: HamburgProperties
    let geometry: GeoJSONGeometry
}

struct HamburgProperties: Codable {
    let bezeichnung: String?
    let ortsteilnummer: Int?
    let flaeche_in_qm: String?
}

// MARK: - NYC Socrata Response Models

struct NYCDogRun: Codable {
    let prop_id: String?
    let name: String?
    let park_name: String?
    let dogruns_type: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let the_geom: NYCGeometry?

    private enum CodingKeys: String, CodingKey {
        case prop_id
        case name
        case park_name = "park_name"
        case dogruns_type
        case address
        case latitude
        case longitude
        case the_geom
    }
}

struct NYCGeometry: Codable {
    let type: String?
    let coordinates: [Double]?
}

// MARK: - Seattle ArcGIS Response Models

struct SeattleArcGISResponse: Codable {
    let features: [SeattleFeature]
}

struct SeattleFeature: Codable {
    let attributes: SeattleAttributes
    let geometry: SeattleGeometry?
}

struct SeattleAttributes: Codable {
    let OBJECTID: Int?
    let ID: Int?
    let NAME: String?
    let LATITUDE: Double?
    let LONGITUDE: Double?
    let PMAID: String?
    let LOCID: String?
}

struct SeattleGeometry: Codable {
    let x: Double?
    let y: Double?
}

// MARK: - San Francisco Socrata Response Models

struct SFDogPlayArea: Codable {
    let objectid: Int?
    let park_name: String?
    let dpa_name: String?
    let latitude: Double?
    let longitude: Double?

    private enum CodingKeys: String, CodingKey {
        case objectid
        case park_name
        case dpa_name
        case latitude
        case longitude
    }
}
