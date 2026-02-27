//
//  RecurrenceRule.swift
//  OllieShared
//
//  Defines recurrence rules for repeating appointments

import Foundation

/// Defines how an appointment repeats
public struct RecurrenceRule: Codable, Hashable, Sendable {

    /// How often the appointment repeats
    public enum Frequency: String, Codable, CaseIterable, Sendable {
        case daily
        case weekly
        case monthly
        case yearly

        public var displayName: String {
            switch self {
            case .daily:
                return String(localized: "Daily", comment: "Recurrence frequency")
            case .weekly:
                return String(localized: "Weekly", comment: "Recurrence frequency")
            case .monthly:
                return String(localized: "Monthly", comment: "Recurrence frequency")
            case .yearly:
                return String(localized: "Yearly", comment: "Recurrence frequency")
            }
        }
    }

    /// The frequency of recurrence
    public var frequency: Frequency

    /// Interval between occurrences (e.g., 2 = every 2 weeks)
    public var interval: Int

    /// Days of the week for weekly recurrence (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    public var daysOfWeek: [Int]?

    /// End date for the recurrence (nil = forever)
    public var endDate: Date?

    /// Number of occurrences (alternative to endDate)
    public var occurrenceCount: Int?

    // MARK: - Init

    public init(
        frequency: Frequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
    }

    // MARK: - Factory Methods

    /// Create a rule for repeating weekly on a specific day for a number of weeks
    /// - Parameters:
    ///   - weekday: Day of week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    ///   - count: Number of occurrences
    public static func weekly(on weekday: Int, forWeeks count: Int) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [weekday],
            occurrenceCount: count
        )
    }

    /// Create a rule for repeating weekly on specific days
    /// - Parameters:
    ///   - days: Days of week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    ///   - until: Optional end date
    public static func weeklyOn(days: [Int], until endDate: Date? = nil) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: days,
            endDate: endDate
        )
    }

    /// Create a rule for daily recurrence
    /// - Parameter until: Optional end date
    public static func daily(until endDate: Date? = nil) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .daily,
            interval: 1,
            endDate: endDate
        )
    }

    // MARK: - Display

    /// Human-readable description of the recurrence
    public var displayDescription: String {
        var description: String

        if interval == 1 {
            description = frequency.displayName
        } else {
            switch frequency {
            case .daily:
                description = String(localized: "Every \(interval) days", comment: "Recurrence description")
            case .weekly:
                description = String(localized: "Every \(interval) weeks", comment: "Recurrence description")
            case .monthly:
                description = String(localized: "Every \(interval) months", comment: "Recurrence description")
            case .yearly:
                description = String(localized: "Every \(interval) years", comment: "Recurrence description")
            }
        }

        // Add day of week info for weekly
        if frequency == .weekly, let days = daysOfWeek, !days.isEmpty {
            let dayNames = days.compactMap { Self.weekdayName(for: $0) }
            if !dayNames.isEmpty {
                let daysString = dayNames.joined(separator: ", ")
                description += " (\(daysString))"
            }
        }

        // Add end condition
        if let count = occurrenceCount {
            description += " • " + String(localized: "\(count) times", comment: "Recurrence count")
        } else if let end = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            description += " • " + String(localized: "Until \(formatter.string(from: end))", comment: "Recurrence end date")
        }

        return description
    }

    /// Get weekday name for a weekday number
    private static func weekdayName(for weekday: Int) -> String? {
        let calendar = Calendar.current
        guard weekday >= 1 && weekday <= 7 else { return nil }
        return calendar.shortWeekdaySymbols[weekday - 1]
    }
}
