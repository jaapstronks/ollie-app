//
//  Strings+GrowthCards.swift
//  Otis-app
//
//  Localized strings for growth shareable cards
//

import Foundation

private let table = "GrowthCards"

extension Strings {

    // MARK: - Growth Cards
    enum GrowthCards {
        // Card types
        static let thenVsNow = String(localized: "Then vs Now", table: table)
        static let then = String(localized: "Then", table: table)
        static let now = String(localized: "Now", table: table)
        static let monthlyGrowth = String(localized: "Monthly Growth", table: table)
        static let growthChart = String(localized: "Growth Chart", table: table)

        // Creator sheet
        static let createGrowthCard = String(localized: "Create Growth Card", table: table)
        static let selectPhotos = String(localized: "Select Photos", table: table)
        static let shareGrowth = String(localized: "Share Growth", table: table)
        static let cardType = String(localized: "Card Type", table: table)
        static let share = String(localized: "Share", table: table)

        // Card titles
        static func growthStoryTitle(name: String) -> String {
            String(localized: "\(name)'s Growth Story", table: table)
        }

        static func firstMonthsTitle(name: String, months: Int) -> String {
            if months == 1 {
                return String(localized: "\(name)'s First Month", table: table)
            } else {
                return String(localized: "\(name)'s First \(months) Months", table: table)
            }
        }

        static func growthJourneyTitle(name: String) -> String {
            String(localized: "\(name)'s Growth Journey", table: table)
        }

        // Growth captions
        static func growthCaption(multiplier: String) -> String {
            String(localized: "\(multiplier) bigger!", table: table)
        }

        static func weightGain(startWeight: String, currentWeight: String, gain: String) -> String {
            String(localized: "\(startWeight) → \(currentWeight) (+\(gain))", table: table)
        }

        // Age labels
        static func ageWeeks(_ weeks: Int) -> String {
            if weeks == 1 {
                return String(localized: "1 week", table: table)
            } else {
                return String(localized: "\(weeks) weeks", table: table)
            }
        }

        static func ageMonths(_ months: Int) -> String {
            if months == 1 {
                return String(localized: "1 month", table: table)
            } else {
                return String(localized: "\(months) months", table: table)
            }
        }

        static func monthLabel(_ month: Int) -> String {
            String(localized: "Mo \(month)", table: table)
        }

        // Stats labels
        static let starting = String(localized: "Starting", table: table)
        static let current = String(localized: "Current", table: table)
        static let growth = String(localized: "Growth", table: table)

        // Empty states
        static let addPhotosToCreate = String(localized: "Add photos to create growth cards", table: table)
        static let needMorePhotos = String(localized: "Take more photos to unlock this card", table: table)
        static let noWeightData = String(localized: "Log weight measurements to see chart", table: table)
    }
}
