//
//  Strings+Widgets.swift
//  Ollie-app
//
//  Widgets and push notification strings

import Foundation

extension Strings {

    // MARK: - Notifications (push)
    enum PushNotifications {
        static let pottyAlarmTitle = String(localized: "Potty alarm!")
        static let goOutsideNowTitle = String(localized: "Go outside now!")
        static let mealTimeTitle = String(localized: "Time to eat!")
        static let walkTimeTitle = String(localized: "Time for a walk!")

        static func needsToPeeSoon(name: String) -> String {
            String(localized: "\(name) needs to pee soon!")
        }
        static func needsToPeeIn(name: String, minutes: Int) -> String {
            String(localized: "\(name) needs to pee in ~\(minutes) min")
        }
        static func needsToPeeNow(name: String) -> String {
            String(localized: "\(name) needs to pee now!")
        }
        static func mealReminder(name: String, meal: String) -> String {
            String(localized: "Time for \(name)'s \(meal)")
        }
        static func walkReminder(name: String) -> String {
            String(localized: "Time for \(name)'s walk")
        }
        static let napNeededTitle = String(localized: "Nap needed?")
        static func napNeededBody(name: String, minutes: Int) -> String {
            String(localized: "\(name) has been awake for \(minutes) minutes")
        }
    }

    // MARK: - Weather Alerts
    enum WeatherAlerts {
        static func rainExpected(time: String) -> String {
            String(localized: "Rain expected at \(time) — maybe go outside now?")
        }
        static func dryUntil(time: String) -> String {
            String(localized: "Dry until \(time) — good time for a walk")
        }
    }

    // MARK: - Widgets
    // Note: Widget extension uses its own String(localized:) calls since it's a separate target.
    // These are documented here for reference and String Catalog sync.
    enum Widgets {
        // Potty Timer Widget
        static let pottyTimerName = String(localized: "Potty Timer")
        static let pottyTimerDescription = String(localized: "See how long since the last potty break.")
        static let sincePotty = String(localized: "since potty")
        static let sinceLastPotty = String(localized: "since last potty")
        static let now = String(localized: "Now")

        // Combined Widget
        static let overviewName = String(localized: "Ollie Overview")
        static let overviewDescription = String(localized: "Potty timer and streak in one widget.")
        static let outdoorStreak = String(localized: "outdoor streak")
        static let pottyBreakReminder = String(localized: "Time for a potty break!")
        static let pottyLabel = String(localized: "potty")
        static let outdoorLabel = String(localized: "outdoor")
        static let recordLabel = String(localized: "record")

        // Streak Widget
        static let streakCounterName = String(localized: "Streak Counter")
        static let streakCounterDescription = String(localized: "Track your outdoor potty streak.")
        static let startFresh = String(localized: "Start fresh!")
    }
}
