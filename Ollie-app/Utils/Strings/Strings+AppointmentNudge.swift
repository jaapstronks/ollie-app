//
//  Strings+AppointmentNudge.swift
//  Otis-app
//
//  Localized strings for appointment scheduling nudges
//

import Foundation

extension Strings {

    enum AppointmentNudge {

        // MARK: - Context Header

        /// "While [name] naps..." header for contextual nudges
        static func whilePuppyNaps(name: String) -> String {
            String(localized: "While \(name) naps...", comment: "Context header when puppy is napping")
        }

        // MARK: - Titles

        /// Title for overdue milestone nudge
        static func overdueTitle(milestone: String) -> String {
            String(localized: "\(milestone) is overdue", comment: "Nudge title for overdue milestone")
        }

        /// Title for upcoming milestone nudge
        static func upcomingTitle(milestone: String) -> String {
            String(localized: "Time to schedule \(milestone)", comment: "Nudge title for upcoming milestone")
        }

        // MARK: - Subtitles

        /// Subtitle for overdue milestone (X days overdue)
        static func overdueSubtitle(days: Int) -> String {
            String(localized: "\(days) day(s) overdue — schedule soon", comment: "Nudge subtitle showing days overdue")
        }

        /// Subtitle for milestone due very soon (within 7 days)
        static func soonSubtitle(days: Int) -> String {
            if days == 1 {
                return String(localized: "Due tomorrow — book an appointment", comment: "Nudge subtitle for milestone due tomorrow")
            }
            return String(localized: "Due in \(days) days — book an appointment", comment: "Nudge subtitle showing days until due")
        }

        /// Subtitle for upcoming milestone (8-28 days away)
        static func upcomingSubtitle(days: Int) -> String {
            if days <= 14 {
                return String(localized: "Due in \(days) days — good time to schedule", comment: "Nudge subtitle for milestone due in 1-2 weeks")
            }
            let weeks = days / 7
            return String(localized: "Due in ~\(weeks) weeks — plan ahead", comment: "Nudge subtitle for milestone due in 2+ weeks")
        }

        // MARK: - Buttons

        /// "Schedule" button text
        static let scheduleNow = String(localized: "Schedule", comment: "Button to schedule an appointment")

        /// "Remind me later" button text
        static let remindLater = String(localized: "Remind me later", comment: "Button to dismiss nudge temporarily")
    }
}
