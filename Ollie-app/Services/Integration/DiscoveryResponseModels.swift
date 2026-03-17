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

// MARK: - Washington D.C. ArcGIS Response Models

struct DCArcGISResponse: Codable {
    let features: [DCFeature]
}

struct DCFeature: Codable {
    let attributes: DCAttributes
    let geometry: ArcGISRingGeometry?
}

struct DCAttributes: Codable {
    let OBJECTID: Int?
    let NAME: String?
    let ADDRESS: String?
    let ZIPCODE: String?
}

// MARK: - Phoenix ArcGIS Response Models

struct PhoenixArcGISResponse: Codable {
    let features: [PhoenixFeature]
}

struct PhoenixFeature: Codable {
    let attributes: PhoenixAttributes
    let geometry: ArcGISPointGeometry?
}

struct PhoenixAttributes: Codable {
    let OBJECTID: Int?
    let PARK_NAME: String?
    let PARK_ADDRESS: String?
    let ACRES: Double?
}

// MARK: - Generic ArcGIS Geometry Types

struct ArcGISPointGeometry: Codable {
    let x: Double?
    let y: Double?
}

struct ArcGISRingGeometry: Codable {
    let rings: [[[Double]]]?
}

// MARK: - Vancouver CKAN Response Models

struct VancouverCKANResponse: Codable {
    let records: [VancouverRecord]
}

struct VancouverRecord: Codable {
    let park_id: Int?
    let name: String?
    let hectare: Double?
    let geom: VancouverGeometry?

    private enum CodingKeys: String, CodingKey {
        case park_id
        case name
        case hectare
        case geom
    }
}

struct VancouverGeometry: Codable {
    let type: String?
    let coordinates: [Double]?
}

// MARK: - Calgary Socrata Response Models

struct CalgaryParkSite: Codable {
    let class_type: String?
    let park_type: String?
    let park_name: String?
    let address: String?
    let latitude: String?
    let longitude: String?

    private enum CodingKeys: String, CodingKey {
        case class_type
        case park_type
        case park_name
        case address
        case latitude
        case longitude
    }
}

// MARK: - Sydney ArcGIS Response Models

struct SydneyArcGISResponse: Codable {
    let features: [SydneyFeature]
}

struct SydneyFeature: Codable {
    let attributes: SydneyAttributes
    let geometry: ArcGISPointGeometry?
}

struct SydneyAttributes: Codable {
    let OBJECTID: Int?
    let park_name: String?
    let category: String?
    let address: String?
    let fenced: String?
}

// MARK: - Canberra (ACT) ArcGIS Response Models

struct CanberraArcGISResponse: Codable {
    let features: [CanberraFeature]
}

struct CanberraFeature: Codable {
    let attributes: CanberraAttributes
    let geometry: ArcGISPointGeometry?
}

struct CanberraAttributes: Codable {
    let OBJECTID: Int?
    let DOG_PARK_NAME: String?
    let SUBURB: String?
    let FENCED: String?
}

// MARK: - Vienna WFS Response Models

struct ViennaWFSResponse: Codable {
    let type: String
    let features: [ViennaFeature]
}

struct ViennaFeature: Codable {
    let type: String
    let id: String?
    let properties: ViennaProperties
    let geometry: GeoJSONGeometry
}

struct ViennaProperties: Codable {
    let OBJECTID: Int?
    let BEZEICHNUNG: String?
    let BEZIRK: Int?
    let ADRESSE: String?
    let FLAECHE: Double?
    let TYP: String?

    private enum CodingKeys: String, CodingKey {
        case OBJECTID
        case BEZEICHNUNG
        case BEZIRK
        case ADRESSE
        case FLAECHE
        case TYP
    }
}

// MARK: - Brussels Open Data Response Models

struct BrusselsResponse: Codable {
    let results: [BrusselsRecord]
}

struct BrusselsRecord: Codable {
    let name_fr: String?
    let name_nl: String?
    let name_en: String?
    let address_fr: String?
    let address_nl: String?
    let geo_point_2d: BrusselsGeoPoint?

    private enum CodingKeys: String, CodingKey {
        case name_fr
        case name_nl
        case name_en
        case address_fr
        case address_nl
        case geo_point_2d
    }
}

struct BrusselsGeoPoint: Codable {
    let lat: Double
    let lon: Double
}
