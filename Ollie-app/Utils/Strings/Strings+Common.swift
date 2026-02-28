//
//  Strings+Common.swift
//  Ollie-app
//
//  Common, App, Tabs, and FAB strings

import Foundation

private let table = "Common"

extension Strings {

    // MARK: - Common
    enum Common {
        static let cancel = String(localized: "Cancel", table: table)
        static let save = String(localized: "Save", table: table)
        static let add = String(localized: "Add", table: table)
        static let delete = String(localized: "Delete", table: table)
        static let done = String(localized: "Done", table: table)
        static let ok = String(localized: "OK", table: table)
        static let close = String(localized: "Close", table: table)
        static let next = String(localized: "Next", table: table)
        static let back = String(localized: "Back", table: table)
        static let edit = String(localized: "Edit", table: table)
        static let undo = String(localized: "Undo", table: table)
        static let error = String(localized: "Error", table: table)
        static let loading = String(localized: "Loading...", table: table)
        static let log = String(localized: "Log", table: table)
        static let start = String(localized: "Start!", table: table)
        static let allow = String(localized: "Allow", table: table)
        static let on = String(localized: "On", table: table)
        static let off = String(localized: "Off", table: table)
        static let remove = String(localized: "Remove", table: table)
        static let yes = String(localized: "Yes", table: table)
        static let no = String(localized: "No", table: table)
        static let share = String(localized: "Share", table: table)
        static let addPhoto = String(localized: "Add Photo", table: table)

        // Error messages
        static let saveFailed = String(localized: "Failed to save. Please try again.", table: table)
        static let deleteFailed = String(localized: "Failed to delete. Please try again.", table: table)
        static let notFound = String(localized: "Item not found.", table: table)
        static let calendarSyncFailed = String(localized: "Failed to sync with calendar", table: table)
        static let calendarAccessDenied = String(localized: "Calendar access denied. Enable in Settings.", table: table)

        // Photo picker
        static let takePhoto = String(localized: "Take Photo", table: table)
        static let chooseFromLibrary = String(localized: "Choose from Library", table: table)

        // Time units
        static let minutes = String(localized: "min", table: table)
        static let minutesFull = String(localized: "minutes", table: table)
        static let week = String(localized: "week", table: table)
        static let weeks = String(localized: "weeks", table: table)
        static let days = String(localized: "days", table: table)
        static let hours = String(localized: "hours", table: table)
        static let atTime = String(localized: "at", table: table)

        // Relative dates
        static let today = String(localized: "Today", table: table)
        static let yesterday = String(localized: "Yesterday", table: table)
        static let tomorrow = String(localized: "Tomorrow", table: table)

        // Navigation
        static let seeAll = String(localized: "See all", table: table)
    }

    // MARK: - App
    enum App {
        static let name = String(localized: "Ollie", table: table)
        static let subtitle = String(localized: "Puppy Tracker", table: table)
        static let tagline = String(localized: "Puppyhood is chaos. Ollie brings the calm.", table: table)
    }

    // MARK: - Tabs
    enum Tabs {
        static let journal = String(localized: "Journal", table: table)
        static let stats = String(localized: "Stats", table: table)
        static let moments = String(localized: "Moments", table: table)
        static let settings = String(localized: "Settings", table: table)
        // 5-tab structure
        static let today = String(localized: "Today", table: table)
        static let insights = String(localized: "Insights", table: table)
        static let train = String(localized: "Train", table: table)
        static let walks = String(localized: "Walks", table: table)
        static let plan = String(localized: "Plan", table: table)
        static let explore = String(localized: "Explore", table: table)
        static let calendar = String(localized: "Calendar", table: table)
        // Renamed tabs
        static let schedule = String(localized: "Schedule", table: table)
        static let health = String(localized: "Health", table: table)
    }

    // MARK: - FAB (Floating Action Button)
    enum FAB {
        static let log = String(localized: "Log", table: table)
        static let peeOutside = String(localized: "Pee outside", table: table)
        static let poopOutside = String(localized: "Poop outside", table: table)
        static let eat = String(localized: "Eat", table: table)
        static let sleep = String(localized: "Sleep", table: table)
        static let wakeUp = String(localized: "Wake up", table: table)
        static let walk = String(localized: "Walk", table: table)
        static let training = String(localized: "Training", table: table)
        static let accessibilityLabel = String(localized: "Log event", table: table)
        static let accessibilityHint = String(localized: "Tap to log any event, or hold for quick actions", table: table)
        static let showQuickMenu = String(localized: "Show quick menu", table: table)
        static func quickActionHint(_ action: String) -> String {
            String(localized: "Double-tap to log \(action)", table: table)
        }
    }

    // MARK: - Insights View
    enum Insights {
        static let title = String(localized: "Insights", table: table)
        static let weekOverview = String(localized: "Week Overview", table: table)
        static let outdoorPottyTrend = String(localized: "Outdoor Potty Success", table: table)
        static let outdoorPottyTrendSubtitle = String(localized: "% of potty outside vs accidents", table: table)
        static let explore = String(localized: "Explore", table: table)
        static let training = String(localized: "Training", table: table)
        static let trainingDescription = String(localized: "Track skills & progress", table: table)
        static let health = String(localized: "Health", table: table)
        static let healthDescription = String(localized: "Weight & milestones", table: table)
        static let momentsTitle = String(localized: "Moments", table: table)
        static let momentsDescription = String(localized: "Photos & memories", table: table)
    }
}
