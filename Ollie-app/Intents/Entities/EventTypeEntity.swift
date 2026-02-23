//
//  EventTypeEntity.swift
//  Ollie-app
//
//  AppEntity for event types used in App Intents

import AppIntents
import OllieShared

/// App Entity representing potty event types (pee/poop)
struct PottyTypeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Potty Type")
    }

    static var defaultQuery = PottyTypeQuery()

    var id: String
    var eventType: EventType

    var displayRepresentation: DisplayRepresentation {
        switch eventType {
        case .plassen:
            return DisplayRepresentation(
                title: "Pee",
                subtitle: "Log a pee event",
                image: .init(systemName: "drop.fill")
            )
        case .poepen:
            return DisplayRepresentation(
                title: "Poop",
                subtitle: "Log a poop event",
                image: .init(systemName: "circle.inset.filled")
            )
        default:
            return DisplayRepresentation(title: LocalizedStringResource(stringLiteral: eventType.rawValue))
        }
    }

    static let pee = PottyTypeEntity(id: "pee", eventType: .plassen)
    static let poop = PottyTypeEntity(id: "poop", eventType: .poepen)
}

struct PottyTypeQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PottyTypeEntity] {
        identifiers.compactMap { id in
            switch id {
            case "pee": return .pee
            case "poop": return .poop
            default: return nil
            }
        }
    }

    func suggestedEntities() async throws -> [PottyTypeEntity] {
        [.pee, .poop]
    }

    func defaultResult() async -> PottyTypeEntity? {
        .pee
    }
}

/// App Entity for common quick-log event types
struct QuickEventTypeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Event Type")
    }

    static var defaultQuery = QuickEventTypeQuery()

    var id: String
    var eventType: EventType

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: eventType.label),
            image: .init(systemName: eventType.icon)
        )
    }

    static let eat = QuickEventTypeEntity(id: "eat", eventType: .eten)
    static let walk = QuickEventTypeEntity(id: "walk", eventType: .uitlaten)
    static let sleep = QuickEventTypeEntity(id: "sleep", eventType: .slapen)
    static let wakeUp = QuickEventTypeEntity(id: "wakeup", eventType: .ontwaken)
}

struct QuickEventTypeQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [QuickEventTypeEntity] {
        identifiers.compactMap { id in
            switch id {
            case "eat": return .eat
            case "walk": return .walk
            case "sleep": return .sleep
            case "wakeup": return .wakeUp
            default: return nil
            }
        }
    }

    func suggestedEntities() async throws -> [QuickEventTypeEntity] {
        [.eat, .walk, .sleep, .wakeUp]
    }
}
