//
//  Strings+Appointments.swift
//  Ollie-app
//
//  Localized strings for appointments

import Foundation

extension Strings {
    private static let table = "Settings"

    /// Strings for the appointments feature
    enum Appointments {
        // View titles
        static let title = String(localized: "Appointments", table: table)
        static let addAppointment = String(localized: "Add Appointment", table: table)
        static let editAppointment = String(localized: "Edit Appointment", table: table)

        // Segments
        static let upcoming = String(localized: "Upcoming", table: table)
        static let past = String(localized: "Past", table: table)

        // Empty state
        static let noAppointments = String(localized: "No Appointments", table: table)
        static let noAppointmentsHint = String(localized: "Schedule vet visits, training classes, grooming, and more.", table: table)
        static let noUpcomingAppointments = String(localized: "No upcoming appointments", table: table)
        static let noPastAppointments = String(localized: "No past appointments", table: table)

        // Form fields
        static let appointmentType = String(localized: "Type", table: table)
        static let appointmentTitle = String(localized: "Title", table: table)
        static let titlePlaceholder = String(localized: "Appointment title", table: table)
        static let date = String(localized: "Date", table: table)
        static let startTime = String(localized: "Start Time", table: table)
        static let endTime = String(localized: "End Time", table: table)
        static let allDay = String(localized: "All Day", table: table)
        static let location = String(localized: "Location", table: table)
        static let locationPlaceholder = String(localized: "Address or location name", table: table)
        static let notes = String(localized: "Notes", table: table)
        static let notesPlaceholder = String(localized: "Optional notes about this appointment...", table: table)

        // Reminder
        static let reminder = String(localized: "Reminder", table: table)

        // Recurrence
        static let repeats = String(localized: "Repeats", table: table)
        static let doesNotRepeat = String(localized: "Does not repeat", table: table)
        static let recurrenceSection = String(localized: "Repeat Schedule", table: table)
        static let frequency = String(localized: "Frequency", table: table)
        static let interval = String(localized: "Every", table: table)
        static let ends = String(localized: "Ends", table: table)
        static let never = String(localized: "Never", table: table)
        static let onDate = String(localized: "On Date", table: table)
        static let afterOccurrences = String(localized: "After", table: table)
        static let occurrences = String(localized: "occurrences", table: table)

        // Linking
        static let linkContact = String(localized: "Link Contact", table: table)
        static let linkedContact = String(localized: "Contact", table: table)
        static let linkMilestone = String(localized: "Link Milestone", table: table)
        static let linkedMilestone = String(localized: "Milestone", table: table)
        static let noContact = String(localized: "None", table: table)
        static let noMilestone = String(localized: "None", table: table)

        // Calendar
        static let addToCalendar = String(localized: "Add to Calendar", table: table)
        static let inCalendar = String(localized: "In Calendar", table: table)
        static let removeFromCalendar = String(localized: "Remove from Calendar", table: table)
        static let calendarPermissionNeeded = String(localized: "Calendar access is required to sync appointments.", table: table)

        // Completion
        static let markComplete = String(localized: "Mark as Completed", table: table)
        static let completed = String(localized: "Completed", table: table)
        static let completionNotes = String(localized: "Notes from Appointment", table: table)
        static let completionNotesPlaceholder = String(localized: "What happened at this appointment?", table: table)

        // Delete
        static let deleteConfirmTitle = String(localized: "Delete Appointment?", table: table)
        static let deleteConfirmMessage = String(localized: "This appointment will be permanently deleted.", table: table)

        // Today
        static let todaysSchedule = String(localized: "Today's Schedule", table: table)
        static let noAppointmentsToday = String(localized: "No appointments today", table: table)

        // More appointments
        static func moreAppointments(count: Int) -> String {
            String(localized: "+\(count) more", table: table)
        }

        // Date formatting
        static let today = String(localized: "Today", table: table)
        static let tomorrow = String(localized: "Tomorrow", table: table)
        static func todayAt(time: String) -> String {
            String(localized: "Today at \(time)", table: table)
        }
        static func tomorrowAt(time: String) -> String {
            String(localized: "Tomorrow at \(time)", table: table)
        }
    }
}
