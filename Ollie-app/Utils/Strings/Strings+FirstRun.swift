//
//  Strings+FirstRun.swift
//  Otis-app
//
//  Localized strings for first run welcome feature
//

import Foundation

extension Strings {
    enum FirstRun {
        private static let table = "FirstRun"

        // Welcome content
        static func welcomeTitle(name: String) -> String {
            String(localized: "Let's get started with \(name)!", table: table)
        }

        static let welcomeSubtitle = String(localized: "We'll help you track everything.", table: table)

        // Question
        static func sleepQuestion(name: String) -> String {
            String(localized: "Is \(name) sleeping right now?", table: table)
        }

        // Buttons
        static let yesSleeping = String(localized: "Yes, sleeping", table: table)
        static let noAwake = String(localized: "No, awake", table: table)

        // Accessibility
        static func accessibilityLabel(name: String) -> String {
            String(localized: "Welcome! Tell us if \(name) is currently sleeping or awake to get started.", table: table)
        }
    }
}
