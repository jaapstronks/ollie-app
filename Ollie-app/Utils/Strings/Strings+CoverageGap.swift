//
//  Strings+CoverageGap.swift
//  Ollie-app
//
//  Localization strings for Coverage Gap feature
//

import Foundation

extension Strings {

    // MARK: - Coverage Gap
    enum CoverageGap {
        // Event label
        static let eventLabel = String(localized: "Coverage Gap", table: "CoverageGap")

        // Gap types
        static let typeDaycare = String(localized: "Daycare", table: "CoverageGap")
        static let typeFamily = String(localized: "Family", table: "CoverageGap")
        static let typeSitter = String(localized: "Pet Sitter", table: "CoverageGap")
        static let typeVacation = String(localized: "Vacation", table: "CoverageGap")
        static let typeOther = String(localized: "Other", table: "CoverageGap")

        // Banner
        static func since(time: String) -> String {
            String(localized: "Since \(time)", table: "CoverageGap")
        }
        static let endGap = String(localized: "End", table: "CoverageGap")
        static let trackingPaused = String(localized: "Tracking paused", table: "CoverageGap")

        // Sheets
        static let startTitle = String(localized: "Who's caring for your dog?", table: "CoverageGap")
        static let endTitle = String(localized: "End Coverage Gap", table: "CoverageGap")
        static let locationPlaceholder = String(localized: "Location (optional)", table: "CoverageGap")
        static let startButton = String(localized: "Start", table: "CoverageGap")
        static let endButton = String(localized: "End Gap", table: "CoverageGap")
        static let notePlaceholder = String(localized: "Notes (optional)", table: "CoverageGap")
        static let startTime = String(localized: "Start time", table: "CoverageGap")
        static let endTime = String(localized: "End time", table: "CoverageGap")

        // Detection prompt
        static func detectionPrompt(hours: Int, name: String) -> String {
            String(localized: "No events logged in \(hours) hours. Was \(name) with someone else?", table: "CoverageGap")
        }
        static let yesLogCoverage = String(localized: "Yes, log coverage", table: "CoverageGap")
        static let noIForgot = String(localized: "No, I forgot to log", table: "CoverageGap")

        // Timeline
        static let ongoing = String(localized: "Ongoing", table: "CoverageGap")
        static func duration(hours: Int, minutes: Int) -> String {
            if hours > 0 {
                return String(localized: "\(hours)h \(minutes)m", table: "CoverageGap")
            } else {
                return String(localized: "\(minutes)m", table: "CoverageGap")
            }
        }

        // Accessibility
        static func gapTypeAccessibility(_ type: String) -> String {
            String(localized: "Care type: \(type)", table: "CoverageGap")
        }
        static let endGapAccessibilityHint = String(localized: "Double-tap to end the coverage gap", table: "CoverageGap")
    }
}
