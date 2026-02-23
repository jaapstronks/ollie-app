//
//  MedicationSchedule.swift
//  OllieShared
//

import Foundation

/// Configurable medication schedule for a puppy
public struct MedicationSchedule: Codable, Sendable {
    public var medications: [Medication]

    public init(medications: [Medication] = []) {
        self.medications = medications
    }

    public static func empty() -> MedicationSchedule {
        MedicationSchedule(medications: [])
    }
}

/// A single medication with schedule information
public struct Medication: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var instructions: String?
    public var icon: String
    public var recurrence: RecurrenceType
    public var daysOfWeek: [Int]?
    public var times: [MedicationTime]
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        instructions: String? = nil,
        icon: String = "pills.fill",
        recurrence: RecurrenceType = .daily,
        daysOfWeek: [Int]? = nil,
        times: [MedicationTime] = [],
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.icon = icon
        self.recurrence = recurrence
        self.daysOfWeek = daysOfWeek
        self.times = times
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }

    /// Check if medication is scheduled for a specific date
    public func isScheduledFor(date: Date) -> Bool {
        guard isActive else { return false }

        let calendar = Calendar.current

        if date < calendar.startOfDay(for: startDate) {
            return false
        }

        if let endDate = endDate, date > calendar.startOfDay(for: endDate) {
            return false
        }

        switch recurrence {
        case .daily:
            return true
        case .weekly:
            guard let days = daysOfWeek else { return true }
            let weekday = calendar.component(.weekday, from: date) - 1
            return days.contains(weekday)
        }
    }
}

/// Recurrence type for medications
public enum RecurrenceType: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly

    public var label: String {
        switch self {
        case .daily: return Strings.Medications.daily
        case .weekly: return Strings.Medications.weekly
        }
    }
}

/// A specific time for medication administration
public struct MedicationTime: Codable, Identifiable, Sendable {
    public var id: UUID
    public var targetTime: String
    public var linkedMealId: UUID?

    public init(
        id: UUID = UUID(),
        targetTime: String = "08:00",
        linkedMealId: UUID? = nil
    ) {
        self.id = id
        self.targetTime = targetTime
        self.linkedMealId = linkedMealId
    }

    /// Parse targetTime string to Date components
    public var timeComponents: (hour: Int, minute: Int)? {
        let parts = targetTime.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        return (hour, minute)
    }

    /// Get the scheduled date for a specific calendar date
    public func scheduledDate(for date: Date) -> Date? {
        guard let (hour, minute) = timeComponents else { return nil }
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
    }
}
