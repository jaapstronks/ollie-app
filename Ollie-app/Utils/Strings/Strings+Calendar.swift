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
        static let thisWeek = String(localized: "This Week", table: table)
        static let comingUp = String(localized: "Coming Up", table: table)
        static let rightNow = String(localized: "Right Now", table: table)

        // Empty states
        static let noAppointments = String(localized: "No upcoming appointments", table: table)
        static let noAppointmentsHint = String(localized: "Schedule vet visits, grooming, and training classes.", table: table)
        static let noMilestones = String(localized: "No upcoming milestones", table: table)
        static let allMilestonesDone = String(localized: "All milestones completed!", table: table)
        static let nothingThisWeek = String(localized: "Nothing scheduled this week", table: table)
        static let nothingComingUp = String(localized: "Nothing coming up in the next few weeks", table: table)

        // Actions
        static let addAppointment = String(localized: "Add Appointment", table: table)
        static let viewAllMilestones = String(localized: "View All Milestones", table: table)
        static let viewAllAppointments = String(localized: "View All Appointments", table: table)
        static let seeRoadmap = String(localized: "See development roadmap", table: table)

        // Age header
        static let weeksOld = String(localized: "weeks old", table: table)
        static let daysHome = String(localized: "days home", table: table)

        // MARK: - View Mode Toggle

        /// Development view mode label
        static let developmentMode = String(localized: "Development", table: table)

        /// Calendar view mode label
        static let calendarMode = String(localized: "Calendar", table: table)

        /// Week view mode label
        static let weekMode = String(localized: "Week", table: table)

        /// Month view mode label
        static let monthMode = String(localized: "Month", table: table)

        /// Socialization week banner (e.g., "Week 5 of 14 socialization")
        static func socializationWeek(_ week: Int, of total: Int) -> String {
            String(localized: "Week \(week) of \(total) socialization", table: table)
        }

        // MARK: - Calendar Grid

        /// Today button label
        static let today = String(localized: "Today", table: table)

        /// No appointments on selected day
        static let noAppointmentsOnDay = String(localized: "No appointments", table: table)

        /// Milestones due this week
        static let milestonesDueThisWeek = String(localized: "Due this week", table: table)

        /// Selected day header format (e.g., "Thursday, March 6")
        static func selectedDayHeader(date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }

        /// Month header format (e.g., "March 2024")
        static func monthHeader(date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }

        /// Accessibility: Day cell label
        static func dayCellAccessibility(date: Date, appointmentCount: Int) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            let dateString = formatter.string(from: date)

            if appointmentCount == 0 {
                return dateString
            } else if appointmentCount == 1 {
                return String(localized: "\(dateString), 1 appointment", table: table)
            } else {
                return String(localized: "\(dateString), \(appointmentCount) appointments", table: table)
            }
        }
    }
}
