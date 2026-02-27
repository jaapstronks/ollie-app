//
//  Strings+Widgets.swift
//  Ollie-app
//
//  Widgets and push notification strings

import Foundation

private let table = "Widgets"

extension Strings {

    // MARK: - Notifications (push)
    enum PushNotifications {
        static let pottyAlarmTitle = String(localized: "Potty alarm!", table: table)
        static let goOutsideNowTitle = String(localized: "Go outside now!", table: table)
        static let mealTimeTitle = String(localized: "Time to eat!", table: table)
        static let walkTimeTitle = String(localized: "Time for a walk!", table: table)

        static func needsToPeeSoon(name: String) -> String {
            String(localized: "\(name) needs to pee soon!", table: table)
        }
        static func needsToPeeIn(name: String, minutes: Int) -> String {
            String(localized: "\(name) needs to pee in ~\(minutes) min", table: table)
        }
        static func needsToPeeNow(name: String) -> String {
            String(localized: "\(name) needs to pee now!", table: table)
        }
        static func mealReminder(name: String, meal: String) -> String {
            String(localized: "Time for \(name)'s \(meal)", table: table)
        }
        static func walkReminder(name: String) -> String {
            String(localized: "Time for \(name)'s walk", table: table)
        }
        static let napNeededTitle = String(localized: "Nap needed?", table: table)
        static func napNeededBody(name: String, minutes: Int) -> String {
            String(localized: "\(name) has been awake for \(minutes) minutes", table: table)
        }
    }

    // MARK: - Widgets
    // Note: Widget extension uses its own String(localized:) calls since it's a separate target.
    // These are documented here for reference and String Catalog sync.
    enum Widgets {
        // Potty Timer Widget
        static let pottyTimerName = String(localized: "Potty Timer", table: table)
        static let pottyTimerDescription = String(localized: "See how long since the last potty break.", table: table)
        static let sincePotty = String(localized: "since potty", table: table)
        static let sinceLastPotty = String(localized: "since last potty", table: table)
        static let now = String(localized: "Now", table: table)

        // Combined Widget
        static let overviewName = String(localized: "Ollie Overview", table: table)
        static let overviewDescription = String(localized: "Potty timer and streak in one widget.", table: table)
        static let outdoorStreak = String(localized: "outdoor streak", table: table)
        static let pottyBreakReminder = String(localized: "Time for a potty break!", table: table)
        static let pottyLabel = String(localized: "potty", table: table)
        static let outdoorLabel = String(localized: "outdoor", table: table)
        static let recordLabel = String(localized: "record", table: table)

        // Streak Widget
        static let streakCounterName = String(localized: "Streak Counter", table: table)
        static let streakCounterDescription = String(localized: "Track your outdoor potty streak.", table: table)
        static let startFresh = String(localized: "Start fresh!", table: table)
    }
}
