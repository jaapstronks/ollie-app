//
//  Strings+Toast.swift
//  Otis-app
//
//  Localization strings for toast notifications.

import Foundation

private let table = "Toast"

extension Strings {

    // MARK: - Toast Messages
    enum Toast {
        // Success messages
        static let logged = String(localized: "Logged!", table: table)
        static let saved = String(localized: "Saved", table: table)
        static let deleted = String(localized: "Deleted", table: table)
        static let addedToCalendar = String(localized: "Added to calendar", table: table)
        static let removedFromCalendar = String(localized: "Removed from calendar", table: table)
        static let documentAdded = String(localized: "Document added", table: table)
        static let contactAdded = String(localized: "Contact added", table: table)
        static let spotSaved = String(localized: "Spot saved", table: table)
        static let copied = String(localized: "Copied to clipboard", table: table)
        static let exportComplete = String(localized: "Export complete", table: table)

        // Warning/info messages
        static let goOutsideNow = String(localized: "Go outside now!", table: table)
        static let syncInProgress = String(localized: "Syncing...", table: table)

        // Error messages
        static let couldNotSave = String(localized: "Could not save. Try again.", table: table)
        static let couldNotDelete = String(localized: "Could not delete. Try again.", table: table)
        static let exportFailed = String(localized: "Export failed", table: table)
        static let networkError = String(localized: "Network error. Check your connection.", table: table)

        // Accessibility
        static let dismissHint = String(localized: "Tap or swipe up to dismiss", table: table)

        // Dynamic messages
        static func streakMilestone(_ count: Int) -> String {
            String(localized: "\(count) times outside in a row!", table: table)
        }

        static func eventsImported(_ count: Int) -> String {
            String(localized: "\(count) events imported", table: table)
        }
    }
}
