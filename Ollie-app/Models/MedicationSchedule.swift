//
//  MedicationSchedule.swift
//  Ollie-app
//
//  Configurable medication schedules for a puppy
//

import Foundation

/// Configurable medication schedule for a puppy
struct MedicationSchedule: Codable {
    var medications: [Medication]

    init(medications: [Medication] = []) {
        self.medications = medications
    }

    static func empty() -> MedicationSchedule {
        MedicationSchedule(medications: [])
    }
}

/// A single medication with schedule information
struct Medication: Codable, Identifiable {
    var id: UUID
    var name: String                     // "Heartgard", "Flea & Tick"
    var instructions: String?            // Dosage notes, special instructions
    var icon: String                     // SF Symbol, default "pills.fill"
    var recurrence: RecurrenceType
    var daysOfWeek: [Int]?               // 0=Sun...6=Sat, nil=all days (for weekly)
    var times: [MedicationTime]          // One or more times per day
    var startDate: Date
    var endDate: Date?                   // nil = indefinite
    var isActive: Bool                   // Pause without deleting

    init(
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
    func isScheduledFor(date: Date) -> Bool {
        guard isActive else { return false }

        let calendar = Calendar.current

        // Check start date
        if date < calendar.startOfDay(for: startDate) {
            return false
        }

        // Check end date
        if let endDate = endDate, date > calendar.startOfDay(for: endDate) {
            return false
        }

        // Check recurrence
        switch recurrence {
        case .daily:
            return true
        case .weekly:
            guard let days = daysOfWeek else { return true }
            let weekday = calendar.component(.weekday, from: date) - 1 // Convert to 0-indexed
            return days.contains(weekday)
        }
    }
}

/// Recurrence type for medications
enum RecurrenceType: String, Codable, CaseIterable {
    case daily
    case weekly

    var label: String {
        switch self {
        case .daily: return Strings.Medications.daily
        case .weekly: return Strings.Medications.weekly
        }
    }
}

/// A specific time for medication administration
struct MedicationTime: Codable, Identifiable {
    var id: UUID
    var targetTime: String               // "08:00" format (matches MealSchedule)
    var linkedMealId: UUID?              // Optional: link to specific meal portion

    init(
        id: UUID = UUID(),
        targetTime: String = "08:00",
        linkedMealId: UUID? = nil
    ) {
        self.id = id
        self.targetTime = targetTime
        self.linkedMealId = linkedMealId
    }

    /// Parse targetTime string to Date components
    var timeComponents: (hour: Int, minute: Int)? {
        let parts = targetTime.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        return (hour, minute)
    }

    /// Get the scheduled date for a specific calendar date
    func scheduledDate(for date: Date) -> Date? {
        guard let (hour, minute) = timeComponents else { return nil }
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
    }
}
