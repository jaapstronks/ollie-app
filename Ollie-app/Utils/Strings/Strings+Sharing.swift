//
//  Strings+Sharing.swift
//  Otis-app
//
//  Strings for sharing functionality
//

import Foundation

private let table = "Sharing"

extension Strings {

    enum Sharing {
        // Sheet
        static let title = String(localized: "Share", table: table)
        static let generating = String(localized: "Generating...", table: table)

        // Format
        static let format = String(localized: "Format", table: table)
        static let formatStory = String(localized: "Story", table: table)
        static let formatSquare = String(localized: "Square", table: table)
        static let formatPortrait = String(localized: "Portrait", table: table)
        static let formatLandscape = String(localized: "Landscape", table: table)

        // Format with aspect ratios
        static let formatSquareRatio = String(localized: "Square (1:1)", table: table)
        static let formatStoryRatio = String(localized: "Story (9:16)", table: table)
        static let formatHorizontalRatio = String(localized: "Horizontal (16:9)", table: table)

        // Actions
        static let shareTo = String(localized: "Share to", table: table)
        static let instagramStory = String(localized: "IG Story", table: table)
        static let facebookStory = String(localized: "FB Story", table: table)
        static let save = String(localized: "Save", table: table)
        static let more = String(localized: "More", table: table)
        static let copy = String(localized: "Copy", table: table)

        // Confirmations
        static let savedToPhotos = String(localized: "Saved to Photos", table: table)
        static let copiedToClipboard = String(localized: "Copied to clipboard", table: table)

        // Errors
        static let renderFailed = String(localized: "Unable to create shareable image", table: table)
        static let platformNotAvailable = String(localized: "This app is not installed", table: table)
        static let photoLibraryDenied = String(localized: "Photo library access is required to save", table: table)
        static let photoLibraryRestricted = String(localized: "Photo library access is restricted", table: table)

        // Card types (for accessibility)
        static let weeklyRecapCard = String(localized: "Weekly recap card", table: table)
        static let monthlyRecapCard = String(localized: "Monthly recap card", table: table)
        static let achievementCard = String(localized: "Achievement card", table: table)
        static let growthCard = String(localized: "Growth comparison card", table: table)

        // Captions
        static func weeklyRecapCaption(name: String, weekNumber: Int) -> String {
            String(localized: "\(name)'s week \(weekNumber) in review!", table: table)
        }

        static func monthlyRecapCaption(name: String, month: String) -> String {
            String(localized: "\(name)'s \(month) highlights!", table: table)
        }

        static func achievementCaption(name: String, achievement: String) -> String {
            String(localized: "\(name) \(achievement)!", table: table)
        }

        static func growthCaption(name: String) -> String {
            String(localized: "Look how much \(name) has grown!", table: table)
        }

        static func momentCaption(name: String, date: String) -> String {
            String(localized: "A special moment with \(name) - \(date)", table: table)
        }

        // Moment sharing
        static let momentCard = String(localized: "Photo moment card", table: table)
        static let shareThisMoment = String(localized: "Share this moment", table: table)

        // Age display
        static func ageMonths(_ months: Int) -> String {
            String(localized: "\(months)mo", table: table)
        }

        static func ageYears(_ years: Int) -> String {
            String(localized: "\(years)yr", table: table)
        }

        static func ageYearsMonths(_ years: Int, _ months: Int) -> String {
            String(localized: "\(years)yr \(months)mo", table: table)
        }

        // Watermark
        static let madeWithOllie = String(localized: "Made with Ollie", table: table)

        // Moment attribution
        static func capturedBy(_ name: String) -> String {
            String(localized: "Captured by \(name)", table: table)
        }
    }
}
