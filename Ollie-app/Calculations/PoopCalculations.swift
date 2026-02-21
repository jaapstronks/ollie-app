//
//  PoopCalculations.swift
//  Ollie-app
//
//  Poop slot tracking logic — monitors daily poop windows and alerts when overdue

import Foundation
import SwiftUI

/// A daily poop time window
struct PoopSlot: Identifiable, Equatable {
    let id: String
    let label: String
    let startHour: Int
    let endHour: Int

    /// Check if a given date/time falls within this slot
    func contains(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= startHour && hour < endHour
    }
}

/// Status of poop slots for the day
struct PoopSlotStatus: Equatable {
    let morningFilled: Bool
    let afternoonFilled: Bool
    let lastPoopTime: Date?
    let currentUrgency: PoopUrgency
    let alertMessage: String?

    var allDone: Bool {
        morningFilled && afternoonFilled
    }
}

/// Urgency level for poop alerts
enum PoopUrgency: Equatable {
    case hidden      // Night time (23:00-06:00)
    case allDone     // Both slots filled
    case normal      // Slot not yet due
    case attention   // Slot in expected window but not filled
    case urgent      // Slot overdue
}

/// Poop slot calculation utilities
struct PoopCalculations {

    // MARK: - Slot Definitions

    static let slots: [PoopSlot] = [
        PoopSlot(id: "morning", label: Strings.PoopStatus.morning, startHour: 4, endHour: 13),
        PoopSlot(id: "afternoon", label: Strings.PoopStatus.lateAfternoon, startHour: 13, endHour: 21)
    ]

    static var morningSlot: PoopSlot { slots[0] }
    static var afternoonSlot: PoopSlot { slots[1] }

    // MARK: - Alert Windows

    /// Hour when afternoon alert starts showing as "attention"
    static let afternoonAttentionHour = 17

    /// Hour when afternoon alert becomes "urgent"
    static let afternoonUrgentHour = 19

    // MARK: - Public Methods

    /// Calculate current poop slot status
    /// - Parameter todayEvents: Array of today's events
    /// - Returns: Current poop slot status
    static func calculateStatus(todayEvents: [PuppyEvent], currentTime: Date = Date()) -> PoopSlotStatus {
        let hour = Calendar.current.component(.hour, from: currentTime)

        // Check if night time (hidden)
        if Constants.isNightTime(hour: hour) {
            return PoopSlotStatus(
                morningFilled: false,
                afternoonFilled: false,
                lastPoopTime: nil,
                currentUrgency: .hidden,
                alertMessage: nil
            )
        }

        // Get today's poop events
        let poopEvents = todayEvents
            .filter { $0.type == .poepen }
            .sorted { $0.time < $1.time }

        // Check which slots are filled
        let morningFilled = poopEvents.contains { morningSlot.contains($0.time) }
        let afternoonFilled = poopEvents.contains { afternoonSlot.contains($0.time) }

        // Get last poop time
        let lastPoopTime = poopEvents.last?.time

        // Determine urgency and message
        let (urgency, message) = determineUrgencyAndMessage(
            morningFilled: morningFilled,
            afternoonFilled: afternoonFilled,
            hour: hour
        )

        return PoopSlotStatus(
            morningFilled: morningFilled,
            afternoonFilled: afternoonFilled,
            lastPoopTime: lastPoopTime,
            currentUrgency: urgency,
            alertMessage: message
        )
    }

    /// Format time since last poop for display
    /// - Parameter lastPoopTime: The time of the last poop
    /// - Returns: Formatted string like "2h15m ago"
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

    /// Get icon name for urgency level
    static func iconName(for urgency: PoopUrgency) -> String {
        switch urgency {
        case .hidden:
            return "moon.fill"
        case .allDone:
            return "checkmark.circle.fill"
        case .normal:
            return "clock"
        case .attention:
            return "exclamationmark.circle.fill"
        case .urgent:
            return "exclamationmark.triangle.fill"
        }
    }

    /// Get icon color for urgency level
    static func iconColor(for urgency: PoopUrgency) -> Color {
        switch urgency {
        case .hidden:
            return .gray
        case .allDone:
            return .ollieSuccess
        case .normal:
            return .primary
        case .attention:
            return .ollieWarning
        case .urgent:
            return .ollieDanger
        }
    }

    // MARK: - Private Helpers

    private static func determineUrgencyAndMessage(
        morningFilled: Bool,
        afternoonFilled: Bool,
        hour: Int
    ) -> (PoopUrgency, String?) {
        // Both done
        if morningFilled && afternoonFilled {
            return (.allDone, Strings.PoopStatus.allDone)
        }

        // Morning slot (04:00 - 13:00)
        if hour >= 6 && hour < 13 && !morningFilled {
            return (.normal, Strings.PoopStatus.morningNotYet)
        }

        // Afternoon slot checks
        if hour >= 13 && !afternoonFilled {
            // After morning slot, check if morning was done
            if !morningFilled && hour < 17 {
                // Morning missed but still in grace period
                return (.attention, Strings.PoopStatus.morningMissed)
            }

            // Urgent: 19:00+
            if hour >= afternoonUrgentHour {
                return (.urgent, Strings.PoopStatus.afternoonUrgent)
            }

            // Attention: 17:00-19:00
            if hour >= afternoonAttentionHour {
                return (.attention, Strings.PoopStatus.afternoonExpected)
            }

            // Normal: 13:00-17:00 (afternoon slot but not yet in expected window)
            return (.normal, nil)
        }

        // Default: all good or morning only done
        if morningFilled && !afternoonFilled && hour < afternoonAttentionHour {
            return (.normal, nil)
        }

        return (.normal, nil)
    }
}

