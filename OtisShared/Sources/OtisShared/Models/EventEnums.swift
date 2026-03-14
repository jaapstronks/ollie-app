//
//  EventEnums.swift
//  OtisShared
//
//  Supporting enums for PuppyEvent: CoverageGapType, EventLocation, NapLocation
//

import Foundation

// MARK: - Coverage Gap Type

/// Types of coverage gaps when the puppy is cared for by someone else
public enum CoverageGapType: String, Codable, CaseIterable, Sendable {
    case daycare
    case family
    case sitter
    case vacation
    case other

    public var label: String {
        switch self {
        case .daycare: return Strings.CoverageGap.typeDaycare
        case .family: return Strings.CoverageGap.typeFamily
        case .sitter: return Strings.CoverageGap.typeSitter
        case .vacation: return Strings.CoverageGap.typeVacation
        case .other: return Strings.CoverageGap.typeOther
        }
    }

    public var icon: String {
        switch self {
        case .daycare: return "building.2.fill"
        case .family: return "person.2.fill"
        case .sitter: return "person.fill.checkmark"
        case .vacation: return "airplane"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Event Location

/// Location for potty events (inside vs outside)
public enum EventLocation: String, Codable, Sendable {
    case buiten  // outside
    case binnen  // inside

    public var label: String {
        switch self {
        case .buiten: return Strings.EventLocation.outside
        case .binnen: return Strings.EventLocation.inside
        }
    }
}

// MARK: - Nap Location

/// Location where a nap took place
public enum NapLocation: String, Codable, CaseIterable, Sendable {
    case crate
    case dogBed
    case other

    public var label: String {
        switch self {
        case .crate: return Strings.NapLocation.crate
        case .dogBed: return Strings.NapLocation.dogBed
        case .other: return Strings.NapLocation.other
        }
    }

    public var icon: String {
        switch self {
        case .crate: return "house.fill"
        case .dogBed: return "bed.double.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
