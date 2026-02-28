//
//  Strings+Growth.swift
//  Ollie-app
//
//  Growth story localization strings
//

import Foundation

private let table = "Growth"

extension Strings {

    // MARK: - Growth Story
    enum Growth {
        static let title = String(localized: "Growth", table: table)
        static let growthStory = String(localized: "Growth Story", table: table)
        static let sinceArrival = String(localized: "Since arrival", table: table)
        static let journeyBegins = String(localized: "The journey begins", table: table)
        static let logFirstWeight = String(localized: "Log your first weight to start tracking growth", table: table)
        static let logSecondWeight = String(localized: "Log another weight to see the growth story", table: table)
        static let startWeight = String(localized: "Start", table: table)
        static let currentWeight = String(localized: "Now", table: table)
        static let adultWeight = String(localized: "Adult", table: table)
        static let logWeight = String(localized: "Log weight", table: table)

        // Growth multiplier messages
        static func grewXTimes(name: String, multiplier: String) -> String {
            String(localized: "\(name) is now \(multiplier) bigger!", table: table)
        }

        static func doubledWeight(name: String) -> String {
            String(localized: "\(name) has doubled in weight!", table: table)
        }

        static func tripledWeight(name: String) -> String {
            String(localized: "\(name) has tripled in weight!", table: table)
        }

        static func grewOneAndHalf(name: String) -> String {
            String(localized: "\(name) is 1.5x bigger now!", table: table)
        }

        // Timeline context
        static func inDays(_ days: Int) -> String {
            if days == 1 {
                return String(localized: "in 1 day", table: table)
            } else {
                return String(localized: "in \(days) days", table: table)
            }
        }

        static func inWeeks(_ weeks: Int) -> String {
            if weeks == 1 {
                return String(localized: "in 1 week", table: table)
            } else {
                return String(localized: "in \(weeks) weeks", table: table)
            }
        }

        static func sinceDate(_ date: String) -> String {
            String(localized: "since \(date)", table: table)
        }

        // Progress to adult
        static func percentToAdult(_ percent: Int) -> String {
            String(localized: "\(percent)% to adult weight", table: table)
        }

        static func percentOfAdult(_ percent: Int) -> String {
            String(localized: "\(percent)% of adult weight", table: table)
        }

        // Gentle growth (less than doubled)
        static func grewBy(name: String, percent: Int) -> String {
            String(localized: "\(name) grew \(percent)%!", table: table)
        }

        // Weight loss handling
        static func maintainingWeight(name: String) -> String {
            String(localized: "\(name) is maintaining a healthy weight", table: table)
        }
    }
}
