//
//  MilestoneEnums.swift
//  OtisShared
//
//  Enums for milestone categorization and status tracking
//

import Foundation

// MARK: - Milestone Category

/// Categories for organizing milestones
public enum MilestoneCategory: String, Codable, CaseIterable, Sendable {
    case health          // Vaccinations, deworming, vet visits
    case developmental   // Socialization window, training milestones
    case administrative  // Registration, insurance, microchip
    case custom          // User-created milestones (Otis+)

    /// SF Symbol icon for the category
    public var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .developmental: return "brain.head.profile"
        case .administrative: return "doc.text.fill"
        case .custom: return "star.fill"
        }
    }

    /// Localized display name
    public var displayName: String {
        // Category names are in different xcstrings files
        switch self {
        case .health: return String(localized: "Health", table: "Health", bundle: Strings.bundle)
        case .developmental: return String(localized: "Development", table: "Calendar", bundle: Strings.bundle)
        case .administrative: return String(localized: "Administrative", bundle: Strings.bundle)
        case .custom: return String(localized: "Custom", bundle: Strings.bundle)
        }
    }
}

// MARK: - Milestone Status

/// Status of a milestone relative to current date
public enum MilestoneStatus: String, Codable, Sendable {
    case upcoming   // Future milestone
    case nextUp     // Coming up within the current or next week
    case overdue    // Past due date, not completed
    case completed  // Marked as done

    /// SF Symbol icon for the status
    public var icon: String {
        switch self {
        case .upcoming: return "circle"
        case .nextUp: return "arrow.right.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}
