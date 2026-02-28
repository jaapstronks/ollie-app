//
//  Strings+Celebrations.swift
//  Ollie-app
//
//  Localized strings for milestone celebrations

import Foundation

private let table = "Celebrations"

extension Strings {

    // MARK: - Celebrations
    enum Celebrations {
        // Photo prompts
        static func addPhotoPrompt(puppyName: String) -> String {
            String(localized: "Add a photo to remember this moment with \(puppyName)", table: table)
        }

        static let captureThisMoment = String(localized: "Capture this moment", table: table)

        // Tier 3 prompts
        static func takePhotoWith(puppyName: String) -> String {
            String(localized: "Take a photo with \(puppyName)", table: table)
        }

        // Achievement messages
        static let congratulations = String(localized: "Congratulations!", table: table)
        static let newRecord = String(localized: "New Record!", table: table)
        static let amazing = String(localized: "Amazing!", table: table)
        static let keepItUp = String(localized: "Keep up the great work!", table: table)

        // Buttons
        static let maybeLater = String(localized: "Maybe Later", table: table)
        static let addFromLibrary = String(localized: "Add from Library", table: table)

        // Settings
        static let celebrationStyle = String(localized: "Celebration Style", table: table)
        static let celebrationStyleDescription = String(localized: "Choose how achievements are celebrated", table: table)

        // Style names
        static let fullCelebrations = String(localized: "Full celebrations", table: table)
        static let subtleOnly = String(localized: "Subtle only", table: table)
        static let minimal = String(localized: "Minimal", table: table)
        static let celebrationsOff = String(localized: "Off", table: table)

        // Style descriptions
        static let fullDescription = String(localized: "All celebration tiers as designed", table: table)
        static let subtleDescription = String(localized: "Cards become shimmer effects", table: table)
        static let minimalDescription = String(localized: "All celebrations become subtle", table: table)
        static let offDescription = String(localized: "No celebration UI (achievements still tracked)", table: table)
    }
}
