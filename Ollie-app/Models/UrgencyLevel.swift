//
//  UrgencyLevel.swift
//  Ollie-app
//
//  Shared protocol for urgency presentation across different status types
//  Consolidates icon, color, and text presentation for potty/poop urgency

import SwiftUI
import OllieShared

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
            return .ollieSuccess
        case .normal:
            return .ollieInfo
        case .attention:
            return .ollieAccent
        case .soon:
            return .ollieWarning
        case .overdue:
            return .ollieDanger
        case .postAccident:
            return .ollieDanger
        case .coverageGap:
            return .orange
        case .unknown:
            return .ollieMuted
        }
    }

    var textColor: Color {
        switch self {
        case .justWent, .normal:
            return .primary
        case .attention:
            return .ollieAccent
        case .soon:
            return .ollieWarning
        case .overdue, .postAccident:
            return .ollieDanger
        case .coverageGap:
            return .orange
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
            return .gray
        case .good:
            return .ollieSuccess
        case .info:
            return .secondary
        case .gentle:
            return .ollieWarning
        case .attention:
            return .ollieWarning
        }
    }

    var textColor: Color {
        switch self {
        case .hidden, .good, .info, .gentle:
            return .primary
        case .attention:
            return .ollieWarning
        }
    }

    var isHidden: Bool {
        self == .hidden
    }

    var isUrgent: Bool {
        self == .attention
    }
}
