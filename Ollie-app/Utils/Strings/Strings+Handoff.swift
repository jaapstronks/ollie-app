//
//  Strings+Handoff.swift
//  Otis-app
//
//  Partner activity handoff card strings
//

import Foundation

private let table = "Handoff"

extension Strings {

    // MARK: - Handoff Card
    enum Handoff {
        /// Header text: "While you were away"
        static let whileYouWereAway = String(localized: "While you were away", table: table)

        /// Header text: "{name} has been taking care of {dogName}" (singular)
        static func takingCareOfSingular(_ name: String, dogName: String) -> String {
            String(localized: "\(name) has been taking care of \(dogName)", table: table)
        }

        /// Header text: "{names} have been taking care of {dogName}" (plural)
        static func takingCareOfPlural(_ names: String, dogName: String) -> String {
            String(localized: "\(names) have been taking care of \(dogName)", table: table)
        }

        /// Header text with automatic singular/plural selection
        static func takingCareOf(_ name: String, dogName: String, partnerCount: Int) -> String {
            if partnerCount > 1 {
                return takingCareOfPlural(name, dogName: dogName)
            } else {
                return takingCareOfSingular(name, dogName: dogName)
            }
        }

        /// Summary: "{name} logged {count} activities"
        static func partnerLoggedActivities(_ name: String, count: Int) -> String {
            String(localized: "\(name) logged \(count) activities", table: table)
        }

        /// Summary for single activity
        static func partnerLoggedActivity(_ name: String) -> String {
            String(localized: "\(name) logged 1 activity", table: table)
        }

        // MARK: - Aggregate Attribution (Timeline)

        /// Header for grouped events: "{name} logged these"
        static func loggedThese(_ name: String) -> String {
            String(localized: "\(name) logged these", table: table)
        }

        /// Header for grouped events with count: "{name} logged {count} events"
        static func loggedEvents(_ name: String, count: Int) -> String {
            String(localized: "\(name) logged \(count) events", table: table)
        }

        /// Category labels
        static let training = String(localized: "Training", table: table)
        static let socialization = String(localized: "Socialization", table: table)
        static let walk = String(localized: "Walk", table: table)
        static let walks = String(localized: "Walks", table: table)

        /// "View {count} more events"
        static func moreEvents(_ count: Int) -> String {
            String(localized: "View \(count) more", table: table)
        }

        /// Show less
        static let showLess = String(localized: "Show less", table: table)

        /// Dismiss button accessibility label
        static let dismiss = String(localized: "Dismiss", table: table)

        /// Time range format (e.g., "2:30 PM - 5:45 PM" or "Yesterday 2:30 PM - Today 10:51 AM")
        static func timeRange(start: Date, end: Date) -> String {
            let calendar = Foundation.Calendar.current
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.dateStyle = .none

            // Check if both dates are on the same day
            if calendar.isDate(start, inSameDayAs: end) {
                return "\(timeFormatter.string(from: start)) - \(timeFormatter.string(from: end))"
            }

            // Different days - show date context
            let dayFormatter = DateFormatter()
            dayFormatter.timeStyle = .short

            // Determine appropriate date format for start
            let startPrefix: String
            if calendar.isDateInYesterday(start) {
                startPrefix = String(localized: "Yesterday", table: table)
            } else {
                dayFormatter.dateStyle = .short
                startPrefix = dayFormatter.string(from: start)
                dayFormatter.dateStyle = .none
            }

            // Determine appropriate date format for end
            let endPrefix: String
            if calendar.isDateInToday(end) {
                endPrefix = String(localized: "Today", table: table)
            } else if calendar.isDateInYesterday(end) {
                endPrefix = String(localized: "Yesterday", table: table)
            } else {
                dayFormatter.dateStyle = .short
                endPrefix = dayFormatter.string(from: end)
            }

            return "\(startPrefix) \(timeFormatter.string(from: start)) - \(endPrefix) \(timeFormatter.string(from: end))"
        }

        /// Duration format (e.g., "45 min walk")
        static func walkWithDuration(_ minutes: Int) -> String {
            String(localized: "\(minutes) min walk", table: table)
        }

        /// Training with exercise name
        static func trainingExercise(_ exercise: String) -> String {
            String(localized: "Training: \(exercise)", table: table)
        }

        /// Socialization with who
        static func metSomeone(_ who: String) -> String {
            String(localized: "Met \(who)", table: table)
        }

        /// Generic partner label when name is unknown
        static let partner = String(localized: "Partner", table: table)

        /// Featured moment header
        static let featuredMoment = String(localized: "Featured moment", table: table)
    }

    // MARK: - First Session Handoff
    enum FirstSession {
        static let title = String(localized: "You're all set", table: table)
        static let subtitle = String(localized: "Let's make your first session useful in under a minute.", table: table)

        static let stepOneTitle = String(localized: "Log your first event", table: table)
        static let stepOneBody = String(localized: "A single log starts your timeline and unlocks smarter suggestions.", table: table)

        static let stepTwoTitle = String(localized: "Understand your timeline", table: table)
        static let stepTwoBody = String(localized: "Today appears in order, so you can quickly spot gaps and routines.", table: table)

        static let stepThreeTitle = String(localized: "Take the next best action", table: table)
        static let stepThreeBody = String(localized: "Use the suggestion card to focus on one helpful thing right now.", table: table)

        static let logFirstEvent = String(localized: "Log first event", table: table)
        static let viewTimeline = String(localized: "View timeline first", table: table)
        static let maybeLater = String(localized: "Maybe later", table: table)
    }
}
