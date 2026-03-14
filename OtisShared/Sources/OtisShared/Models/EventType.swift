//
//  EventType.swift
//  OtisShared
//
//  Event types for tracking puppy activities
//

import Foundation

/// Event types for tracking puppy activities
public enum EventType: String, Codable, CaseIterable, Identifiable, Sendable {
    case eten
    case drinken
    case plassen
    case poepen
    case slapen
    case ontwaken
    case uitlaten
    case tuin
    case training
    case bench
    case sociaal
    case milestone
    case gedrag
    case gewicht
    case moment
    case medicatie
    case verzorging
    case coverageGap

    public var id: String { rawValue }

    /// SF Symbol name for this event type
    public var icon: String {
        switch self {
        case .eten: return "fork.knife"
        case .drinken: return "drop.fill"
        case .plassen: return "drop.fill"
        case .poepen: return "circle.inset.filled"
        case .slapen: return "moon.zzz.fill"
        case .ontwaken: return "sun.max.fill"
        case .uitlaten: return "figure.walk"
        case .tuin: return "leaf.fill"
        case .training: return "graduationcap.fill"
        case .bench: return "house.fill"
        case .sociaal: return "dog.fill"
        case .milestone: return "star.fill"
        case .gedrag: return "note.text"
        case .gewicht: return "scalemass.fill"
        case .moment: return "camera.fill"
        case .medicatie: return "pills.fill"
        case .verzorging: return "comb.fill"
        case .coverageGap: return "person.badge.clock.fill"
        }
    }

    public var label: String {
        switch self {
        case .eten: return Strings.EventType.eat
        case .drinken: return Strings.EventType.drink
        case .plassen: return Strings.EventType.pee
        case .poepen: return Strings.EventType.poop
        case .slapen: return Strings.EventType.sleep
        case .ontwaken: return Strings.EventType.wakeUp
        case .uitlaten: return Strings.EventType.walk
        case .tuin: return Strings.EventType.garden
        case .training: return Strings.EventType.training
        case .bench: return Strings.EventType.crate
        case .sociaal: return Strings.EventType.social
        case .milestone: return Strings.EventType.milestone
        case .gedrag: return Strings.EventType.behavior
        case .gewicht: return Strings.EventType.weight
        case .moment: return Strings.EventType.moment
        case .medicatie: return Strings.EventType.medication
        case .verzorging: return Strings.EventType.grooming
        case .coverageGap: return Strings.CoverageGap.eventLabel
        }
    }

    /// Whether this event type requires a location (inside/outside)
    public var requiresLocation: Bool {
        self == .plassen || self == .poepen
    }

    /// Whether this event type is a potty event
    public var isPottyEvent: Bool {
        self == .plassen || self == .poepen
    }

    /// Whether this event type is a sleep-related event
    public var isSleepEvent: Bool {
        self == .slapen || self == .ontwaken
    }

    /// Whether this event type is a coverage gap
    public var isCoverageGap: Bool {
        self == .coverageGap
    }
}
