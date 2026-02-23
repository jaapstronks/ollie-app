//
//  LocationEntity.swift
//  Ollie-app
//
//  AppEntity for event locations (inside/outside)

import AppIntents
import OllieShared

/// App Entity representing event location (inside/outside)
struct LocationEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Location")
    }

    static var defaultQuery = LocationEntityQuery()

    var id: String
    var eventLocation: EventLocation

    var displayRepresentation: DisplayRepresentation {
        switch eventLocation {
        case .buiten:
            return DisplayRepresentation(
                title: "Outside",
                subtitle: "Outdoor location",
                image: .init(systemName: "sun.max.fill")
            )
        case .binnen:
            return DisplayRepresentation(
                title: "Inside",
                subtitle: "Indoor location",
                image: .init(systemName: "house.fill")
            )
        }
    }

    static let outside = LocationEntity(id: "outside", eventLocation: .buiten)
    static let inside = LocationEntity(id: "inside", eventLocation: .binnen)
}

struct LocationEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [LocationEntity] {
        identifiers.compactMap { id in
            switch id {
            case "outside": return .outside
            case "inside": return .inside
            default: return nil
            }
        }
    }

    func suggestedEntities() async throws -> [LocationEntity] {
        [.outside, .inside]
    }

    func defaultResult() async -> LocationEntity? {
        .outside
    }
}
