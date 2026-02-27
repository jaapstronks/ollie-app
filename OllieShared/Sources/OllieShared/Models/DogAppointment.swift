//
//  DogAppointment.swift
//  OllieShared
//
//  Model for storing dog appointments (vet visits, training, daycare, etc.)

import Foundation

/// A scheduled appointment for the dog
public struct DogAppointment: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    public var appointmentType: AppointmentType
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var location: String?
    public var notes: String?
    public var reminderMinutesBefore: Int

    // Recurrence
    public var recurrence: RecurrenceRule?

    // Linking
    public var linkedMilestoneID: UUID?
    public var linkedContactID: UUID?
    public var calendarEventID: String?

    // Completion
    public var isCompleted: Bool
    public var completionNotes: String?

    // Timestamps
    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        title: String,
        appointmentType: AppointmentType,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        reminderMinutesBefore: Int = 60,
        recurrence: RecurrenceRule? = nil,
        linkedMilestoneID: UUID? = nil,
        linkedContactID: UUID? = nil,
        calendarEventID: String? = nil,
        isCompleted: Bool = false,
        completionNotes: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.appointmentType = appointmentType
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrence = recurrence
        self.linkedMilestoneID = linkedMilestoneID
        self.linkedContactID = linkedContactID
        self.calendarEventID = calendarEventID
        self.isCompleted = isCompleted
        self.completionNotes = completionNotes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// Whether the appointment is in the past
    public var isPast: Bool {
        endDate < Date()
    }

    /// Whether the appointment is happening today
    public var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }

    /// Whether the appointment is upcoming (in the future)
    public var isUpcoming: Bool {
        startDate > Date()
    }

    /// Duration of the appointment in minutes
    public var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    /// Whether this is a recurring appointment
    public var isRecurring: Bool {
        recurrence != nil
    }

    /// Whether this appointment is linked to a contact
    public var hasLinkedContact: Bool {
        linkedContactID != nil
    }

    /// Whether this appointment is linked to a milestone
    public var hasLinkedMilestone: Bool {
        linkedMilestoneID != nil
    }

    /// Whether this appointment is synced to the calendar
    public var isSyncedToCalendar: Bool {
        calendarEventID != nil
    }

    /// Formatted time range for display
    public var timeRangeString: String {
        if isAllDay {
            return String(localized: "All Day", comment: "All day appointment")
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)

        return "\(start) - \(end)"
    }

    /// Formatted date for display
    public var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startDate)
    }
}

// MARK: - Hashable

extension DogAppointment {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: DogAppointment, rhs: DogAppointment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Reminder Options

extension DogAppointment {
    /// Available reminder options in minutes
    public static let reminderOptions: [(minutes: Int, label: String)] = [
        (0, String(localized: "None", comment: "No reminder")),
        (15, String(localized: "15 minutes before", comment: "Reminder time")),
        (30, String(localized: "30 minutes before", comment: "Reminder time")),
        (60, String(localized: "1 hour before", comment: "Reminder time")),
        (120, String(localized: "2 hours before", comment: "Reminder time")),
        (1440, String(localized: "1 day before", comment: "Reminder time")),
        (2880, String(localized: "2 days before", comment: "Reminder time"))
    ]

    /// Get the label for the current reminder setting
    public var reminderLabel: String {
        Self.reminderOptions.first { $0.minutes == reminderMinutesBefore }?.label
            ?? String(localized: "\(reminderMinutesBefore) minutes before", comment: "Custom reminder time")
    }
}
