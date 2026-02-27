//
//  Strings+Calendar.swift
//  Ollie-app
//
//  Localized strings for the Calendar tab

import Foundation

private let table = "Calendar"

extension Strings {

    /// Strings for the Calendar tab
    enum Calendar {
        // Section headers
        static let upcomingAppointments = String(localized: "Upcoming Appointments", table: table)
        static let milestoneTimeline = String(localized: "Milestone Timeline", table: table)
        static let overdueMilestones = String(localized: "Overdue", table: table)
        static let upcomingMilestones = String(localized: "Coming Up", table: table)

        // Empty states
        static let noAppointments = String(localized: "No upcoming appointments", table: table)
        static let noAppointmentsHint = String(localized: "Schedule vet visits, grooming, and training classes.", table: table)
        static let noMilestones = String(localized: "No upcoming milestones", table: table)
        static let allMilestonesDone = String(localized: "All milestones completed!", table: table)

        // Actions
        static let addAppointment = String(localized: "Add Appointment", table: table)
        static let viewAllMilestones = String(localized: "View All Milestones", table: table)
        static let viewAllAppointments = String(localized: "View All Appointments", table: table)

        // Age header
        static let weeksOld = String(localized: "weeks old", table: table)
        static let daysHome = String(localized: "days home", table: table)
    }
}
