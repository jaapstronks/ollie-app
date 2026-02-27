//
//  Strings+CatchUp.swift
//  Ollie-app
//
//  Localization strings for Catch-Up feature
//

import Foundation

extension Strings {

    // MARK: - Catch Up
    enum CatchUp {
        // Header
        static let title = String(localized: "Quick Catch-Up", table: "CatchUp")
        static let greeting = String(localized: "Hey! Let's get you caught up.", table: "CatchUp")
        static func lastLogged(hours: Int) -> String {
            String(localized: "Last logged: \(hours) hours ago", table: "CatchUp")
        }

        // Sleep state
        static func currentState(name: String) -> String {
            String(localized: "Right now, is \(name)...", table: "CatchUp")
        }
        static let sleeping = String(localized: "Sleeping", table: "CatchUp")
        static let awake = String(localized: "Awake", table: "CatchUp")
        static let since = String(localized: "Since:", table: "CatchUp")
        static let now = String(localized: "Now", table: "CatchUp")

        // Potty
        static let lastPotty = String(localized: "Last pee outside?", table: "CatchUp")
        static let pottyJustNow = String(localized: "Just now", table: "CatchUp")
        static let pottyOneHour = String(localized: "~1h", table: "CatchUp")
        static let pottyTwoHours = String(localized: "~2h", table: "CatchUp")

        // Meals
        static func eatenSince(time: String) -> String {
            String(localized: "Eaten since \(time)?", table: "CatchUp")
        }

        // Poop
        static let poopedToday = String(localized: "Pooped today?", table: "CatchUp")

        // Actions
        static let allCaughtUp = String(localized: "All caught up!", table: "CatchUp")
        static let skipForNow = String(localized: "Skip for now", table: "CatchUp")

        // Notes
        static let approximateNote = String(localized: "Logged via catch-up", table: "CatchUp")
    }
}
