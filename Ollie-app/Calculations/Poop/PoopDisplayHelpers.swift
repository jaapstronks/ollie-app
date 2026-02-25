//
//  PoopDisplayHelpers.swift
//  Ollie-app
//
//  Display helpers for poop status (icons, colors, formatting)
//

import Foundation
import SwiftUI
import OllieShared

/// Display helpers for poop status
struct PoopDisplayHelpers {

    // MARK: - Time Formatting

    /// Format time since last poop
    static func formatTimeSince(_ lastPoopTime: Date?, currentTime: Date = Date()) -> String? {
        guard let lastTime = lastPoopTime else { return nil }

        let minutes = currentTime.minutesSince(lastTime)

        if minutes < 60 {
            return Strings.PoopStatus.minutesAgo(minutes)
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return Strings.PoopStatus.hoursAgo(hours)
            }
            return Strings.PoopStatus.hoursMinutesAgo(hours: hours, minutes: mins)
        }
    }

    // MARK: - Icon Helpers

    /// Get icon name for urgency level
    static func iconName(for urgency: PoopUrgency) -> String {
        switch urgency {
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

    /// Get icon color for urgency level
    static func iconColor(for urgency: PoopUrgency) -> Color {
        switch urgency {
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
}
