//
//  Strings+WalkSchedule.swift
//  Ollie-app
//
//  Walk schedule editor strings

import Foundation

extension Strings {

    // MARK: - Walk Schedule Editor
    enum WalkScheduleEditor {
        static let title = String(localized: "Walk Schedule")
        static let editWalks = String(localized: "Edit walk schedule")

        // Section headers
        static let schedulingMode = String(localized: "Scheduling Mode")
        static let walksSection = String(localized: "Walks")
        static let timingSection = String(localized: "Timing")
        static let dayBoundaries = String(localized: "Day Boundaries")
        static let exerciseLimits = String(localized: "Exercise Limits")

        // Mode labels
        static let modeFlexible = String(localized: "Flexible")
        static let modeStrict = String(localized: "Strict")
        static let modeFlexibleRecommended = String(localized: "Flexible (Recommended)")
        static let modeFlexibleDescription = String(localized: "Walk times adjust based on when the last walk happened. Good for adapting to real-world timing.")
        static let modeStrictDescription = String(localized: "Walk times are fixed to the scheduled times. Useful for strict routines or multiple caretakers.")

        // Walk list
        static let addWalk = String(localized: "Add walk")
        static let editWalk = String(localized: "Edit walk")
        static let walkName = String(localized: "Walk name")
        static let walkNamePlaceholder = String(localized: "e.g. Morning walk")
        static let walkTime = String(localized: "Time")
        static let deleteWalk = String(localized: "Delete walk")
        static func walksCount(_ count: Int) -> String {
            String(localized: "\(count) walks")
        }

        // Timing
        static let intervalBetweenWalks = String(localized: "Interval between walks")
        static func intervalMinutes(_ minutes: Int) -> String {
            String(localized: "\(minutes) min")
        }
        static let intervalFooter = String(localized: "In flexible mode, this is the minimum time between walks.")

        // Day boundaries
        static let firstWalkAfter = String(localized: "First walk after")
        static let lastWalkBefore = String(localized: "Last walk before")

        // Exercise limits
        static let maxDurationPerWalk = String(localized: "Max duration per walk")
        static let minutesPerMonth = String(localized: "Minutes per month of age")
        static let fiveMinuteRule = String(localized: "The '5-minute rule' — puppies can walk 5 minutes per month of age per session.")
        static func minutesPerMonthValue(_ minutes: Int) -> String {
            String(localized: "\(minutes) min/month")
        }
        static func maxDurationFooter(age: Int, minutes: Int) -> String {
            String(localized: "At \(age) months: max \(minutes) min per walk")
        }

        // Summary (for WalkSection)
        static func walksPerDay(_ count: Int) -> String {
            String(localized: "\(count) walks/day")
        }
        static func intervalSummary(_ minutes: Int) -> String {
            String(localized: "~\(minutes) min interval")
        }
        static func maxExerciseSummary(_ minutes: Int) -> String {
            String(localized: "Max \(minutes) min/walk")
        }
    }
}
