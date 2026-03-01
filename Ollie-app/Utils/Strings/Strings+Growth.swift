//
//  Strings+Growth.swift
//  Otis-app
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

        // Weigh reminder
        static let timeToWeigh = String(localized: "Time to weigh", table: table)
        static let weighNow = String(localized: "Weigh now", table: table)

        static func lastWeighed(_ days: Int) -> String {
            if days == 1 {
                return String(localized: "Last weighed 1 day ago", table: table)
            } else {
                return String(localized: "Last weighed \(days) days ago", table: table)
            }
        }

        static let neverWeighed = String(localized: "Never weighed", table: table)

        static func weighEveryDays(_ days: Int) -> String {
            if days == 7 {
                return String(localized: "Weigh weekly during rapid growth", table: table)
            } else if days == 14 {
                return String(localized: "Weigh every 2 weeks to track growth", table: table)
            } else if days == 30 {
                return String(localized: "Monthly weigh-ins recommended", table: table)
            } else {
                return String(localized: "Weigh every \(days) days", table: table)
            }
        }

        // Current weight display
        static let currentWeightLabel = String(localized: "Current weight", table: table)
        static func weightChange(_ delta: String) -> String {
            String(localized: "\(delta) since last", table: table)
        }

        // Growth detail sheet
        static let growthChart = String(localized: "Growth Chart", table: table)
        static let growthStats = String(localized: "Growth Statistics", table: table)
        static let totalGain = String(localized: "Total Gain", table: table)
        static let growthRatioLabel = String(localized: "Growth", table: table)
        static let percentOfAdultShort = String(localized: "Adult %", table: table)
        static let estimatedAdult = String(localized: "Est. Adult", table: table)
        static let measurementHistory = String(localized: "Measurement History", table: table)

        static func lastMeasured(_ date: String) -> String {
            String(localized: "Last measured \(date)", table: table)
        }

        // Delete measurement
        static let deleteMeasurement = String(localized: "Delete Measurement", table: table)
        static func deleteMeasurementMessage(_ weight: String) -> String {
            String(localized: "Are you sure you want to delete the measurement of \(weight)?", table: table)
        }
    }
}
