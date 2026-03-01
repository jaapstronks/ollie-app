//
//  UrgencyLevel.swift
//  Otis-app
//
//  Shared protocol for urgency presentation across different status types
//  Consolidates icon, color, and text presentation for potty/poop urgency

import SwiftUI
import OtisShared

/// Protocol for types that represent urgency levels
/// Provides consistent UI presentation across different urgency types
protocol UrgencyPresentable {
    /// SF Symbol icon name for this urgency level
    var iconName: String { get }

    /// Icon tint color for this urgency level
    var iconColor: Color { get }

    /// Text color for this urgency level
    var textColor: Color { get }

    /// Whether this urgency should be hidden (e.g., night time)
    var isHidden: Bool { get }

    /// Whether this urgency requires immediate attention
    var isUrgent: Bool { get }
}

// MARK: - Default Implementations

extension UrgencyPresentable {
    /// Default text color is primary
    var textColor: Color { .primary }

    /// Default is not hidden
    var isHidden: Bool { false }

    /// Default is not urgent
    var isUrgent: Bool { false }
}

// MARK: - PottyUrgency Conformance

extension PottyUrgency: UrgencyPresentable {
    var iconName: String {
        switch self {
        case .justWent:
            return "checkmark.circle.fill"
        case .normal:
            return "clock.fill"
        case .attention:
            return "clock.badge.exclamationmark.fill"
        case .soon:
            return "exclamationmark.triangle.fill"
        case .overdue:
            return "bell.badge.fill"
        case .postAccident:
            return "exclamationmark.triangle.fill"
        case .coverageGap(let type, _):
            return type.icon
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .justWent:
            return .otisSuccess
        case .normal:
            return .otisInfo
        case .attention:
            return .otisAccent
        case .soon:
            return .otisWarning
        case .overdue:
            return .otisDanger
        case .postAccident:
            return .otisDanger
        case .coverageGap:
            return .otisWarning
        case .unknown:
            return .otisMuted
        }
    }

    var textColor: Color {
        switch self {
        case .justWent, .normal:
            return .primary
        case .attention:
            return .otisAccent
        case .soon:
            return .otisWarning
        case .overdue, .postAccident:
            return .otisDanger
        case .coverageGap:
            return .otisWarning
        case .unknown:
            return .secondary
        }
    }

    var isHidden: Bool { false }

    // Note: isUrgent already exists on PottyUrgency in PredictionCalculations.swift
}

// MARK: - PoopUrgency Conformance

extension PoopUrgency: UrgencyPresentable {
    var iconName: String {
        switch self {
        case .hidden:
            return "moon.fill"
        case .good:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle"
        case .gentle:
            return "exclamationmark.circle"
        case .attention:
            return "exclamationmark.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .hidden:
            return .otisMuted
        case .good:
            return .otisSuccess
        case .info:
            return .secondary
        case .gentle:
            return .otisWarning
        case .attention:
            return .otisWarning
        }
    }

    var textColor: Color {
        switch self {
        case .hidden, .good, .info, .gentle:
            return .primary
        case .attention:
            return .otisWarning
        }
    }

    var isHidden: Bool {
        self == .hidden
    }

    var isUrgent: Bool {
        self == .attention
    }
}
