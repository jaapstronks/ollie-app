//
//  SkillProgressHelpers.swift
//  OtisShared
//
//  Helper types for SkillProgress: MaintenanceIntervals, StandardTrainingContext
//

import Foundation

// MARK: - Maintenance Intervals

/// Spaced repetition intervals for maintenance phase
public enum MaintenanceIntervals {
    /// Get the interval in seconds for a given tier
    public static func interval(forTier tier: Int) -> TimeInterval {
        switch tier {
        case 1: return 1 * 24 * 60 * 60        // 1 day
        case 2: return 3 * 24 * 60 * 60        // 3 days
        case 3: return 7 * 24 * 60 * 60        // 1 week
        case 4: return 14 * 24 * 60 * 60       // 2 weeks
        case 5: return 30 * 24 * 60 * 60       // 1 month
        default: return 60 * 24 * 60 * 60      // 2 months (tier 6+)
        }
    }

    /// Get the tier key for localization (UI layer handles actual localization)
    public static func tierKey(forTier tier: Int) -> String {
        switch tier {
        case 1: return "1day"
        case 2: return "3days"
        case 3: return "1week"
        case 4: return "2weeks"
        case 5: return "1month"
        default: return "2months"
        }
    }
}

// MARK: - Standard Training Context

/// Standard context identifiers for generalization tracking
public enum StandardTrainingContext: String, CaseIterable, Sendable {
    case home = "home"
    case garden = "garden"
    case quietStreet = "quiet_street"
    case busyStreet = "busy_street"
    case park = "park"
    case indoorPublic = "indoor_public"  // Pet store, vet, etc.
    case carRide = "car_ride"
    case other = "other"

    public var labelKey: String {
        rawValue
    }

    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .garden: return "leaf.fill"
        case .quietStreet: return "road.lanes"
        case .busyStreet: return "car.fill"
        case .park: return "tree.fill"
        case .indoorPublic: return "building.2.fill"
        case .carRide: return "car.side.fill"
        case .other: return "mappin.circle.fill"
        }
    }

    /// Distraction level for this context (0-5)
    public var distractionLevel: Int {
        switch self {
        case .home: return 0
        case .garden: return 1
        case .quietStreet: return 2
        case .carRide: return 2
        case .indoorPublic: return 3
        case .park: return 4
        case .busyStreet: return 5
        case .other: return 2
        }
    }
}
