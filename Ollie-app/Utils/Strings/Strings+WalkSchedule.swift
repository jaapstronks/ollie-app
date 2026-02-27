//
//  Strings+WalkSchedule.swift
//  Ollie-app
//
//  Walk schedule editor strings

import Foundation

private let table = "WalkSchedule"

extension Strings {

    // MARK: - Walk Schedule Editor
    enum WalkScheduleEditor {
        static let title = String(localized: "Walk Schedule", table: table)
        static let editWalks = String(localized: "Edit walk schedule", table: table)

        // Section headers
        static let schedulingMode = String(localized: "Scheduling Mode", table: table)
        static let walksSection = String(localized: "Walks", table: table)
        static let timingSection = String(localized: "Timing", table: table)
        static let dayBoundaries = String(localized: "Day Boundaries", table: table)
        static let exerciseLimits = String(localized: "Exercise Limits", table: table)

        // Mode labels
        static let modeFlexible = String(localized: "Flexible", table: table)
        static let modeStrict = String(localized: "Strict", table: table)
        static let modeFlexibleRecommended = String(localized: "Flexible (Recommended)", table: table)
        static let modeFlexibleDescription = String(localized: "Walk times adjust based on when the last walk happened. Good for adapting to real-world timing.", table: table)
        static let modeStrictDescription = String(localized: "Walk times are fixed to the scheduled times. Useful for strict routines or multiple caretakers.", table: table)

        // Walk list
        static let addWalk = String(localized: "Add walk", table: table)
        static let editWalk = String(localized: "Edit walk", table: table)
        static let walkName = String(localized: "Walk name", table: table)
        static let walkNamePlaceholder = String(localized: "e.g. Morning walk", table: table)
        static let walkTime = String(localized: "Time", table: table)
        static let deleteWalk = String(localized: "Delete walk", table: table)
        static func walksCount(_ count: Int) -> String {
            String(localized: "\(count) walks", table: table)
        }

        // Timing
        static let intervalBetweenWalks = String(localized: "Interval between walks", table: table)
        static func intervalMinutes(_ minutes: Int) -> String {
            String(localized: "\(minutes) min", table: table)
        }
        static let intervalFooter = String(localized: "In flexible mode, this is the minimum time between walks.", table: table)

        // Day boundaries
        static let firstWalkAfter = String(localized: "First walk after", table: table)
        static let lastWalkBefore = String(localized: "Last walk before", table: table)

        // Exercise limits
        static let maxDurationPerWalk = String(localized: "Max duration per walk", table: table)
        static let minutesPerMonth = String(localized: "Minutes per month of age", table: table)
        static let fiveMinuteRule = String(localized: "The '5-minute rule' — puppies can walk 5 minutes per month of age per session.", table: table)
        static func minutesPerMonthValue(_ minutes: Int) -> String {
            String(localized: "\(minutes) min/month", table: table)
        }
        static func maxDurationFooter(age: Int, minutes: Int) -> String {
            String(localized: "At \(age) months: max \(minutes) min per walk", table: table)
        }

        // Summary (for WalkSection)
        static func walksPerDay(_ count: Int) -> String {
            String(localized: "\(count) walks/day", table: table)
        }
        static func intervalSummary(_ minutes: Int) -> String {
            String(localized: "~\(minutes) min interval", table: table)
        }
        static func maxExerciseSummary(_ minutes: Int) -> String {
            String(localized: "Max \(minutes) min/walk", table: table)
        }
    }
}
