//
//  Strings+Common.swift
//  Ollie-app
//
//  Common, App, Tabs, and FAB strings

import Foundation

extension Strings {

    // MARK: - Common
    enum Common {
        static let cancel = String(localized: "Cancel")
        static let save = String(localized: "Save")
        static let delete = String(localized: "Delete")
        static let done = String(localized: "Done")
        static let ok = String(localized: "OK")
        static let close = String(localized: "Close")
        static let next = String(localized: "Next")
        static let back = String(localized: "Back")
        static let edit = String(localized: "Edit")
        static let undo = String(localized: "Undo")
        static let error = String(localized: "Error")
        static let loading = String(localized: "Loading...")
        static let log = String(localized: "Log")
        static let start = String(localized: "Start!")
        static let allow = String(localized: "Allow")
        static let on = String(localized: "On")
        static let off = String(localized: "Off")

        // Time units
        static let minutes = String(localized: "min")
        static let minutesFull = String(localized: "minutes")
        static let weeks = String(localized: "weeks")
        static let days = String(localized: "days")
        static let hours = String(localized: "hours")

        // Relative dates
        static let today = String(localized: "Today")
        static let yesterday = String(localized: "Yesterday")
        static let tomorrow = String(localized: "Tomorrow")

        // Navigation
        static let seeAll = String(localized: "See all")
    }

    // MARK: - App
    enum App {
        static let name = String(localized: "Ollie")
        static let subtitle = String(localized: "Puppy Tracker")
        static let tagline = String(localized: "Puppyhood is chaos. Ollie brings the calm.")
    }

    // MARK: - Tabs
    enum Tabs {
        static let journal = String(localized: "Journal")
        static let stats = String(localized: "Stats")
        static let moments = String(localized: "Moments")
        static let settings = String(localized: "Settings")
        // 4-tab structure
        static let today = String(localized: "Today")
        static let insights = String(localized: "Insights")
        static let train = String(localized: "Train")
        static let walks = String(localized: "Walks")
        static let plan = String(localized: "Plan")
    }

    // MARK: - FAB (Floating Action Button)
    enum FAB {
        static let log = String(localized: "Log")
        static let peeOutside = String(localized: "Pee outside")
        static let poopOutside = String(localized: "Poop outside")
        static let eat = String(localized: "Eat")
        static let sleep = String(localized: "Sleep")
        static let wakeUp = String(localized: "Wake up")
        static let walk = String(localized: "Walk")
        static let training = String(localized: "Training")
        static let accessibilityLabel = String(localized: "Log event")
        static let accessibilityHint = String(localized: "Tap to log any event, or hold for quick actions")
        static let showQuickMenu = String(localized: "Show quick menu")
        static func quickActionHint(_ action: String) -> String {
            String(localized: "Double-tap to log \(action)")
        }
    }

    // MARK: - Insights View
    enum Insights {
        static let title = String(localized: "Insights")
        static let weekOverview = String(localized: "Week Overview")
        static let trends = String(localized: "Trends")
        static let explore = String(localized: "Explore")
        static let training = String(localized: "Training")
        static let trainingDescription = String(localized: "Track skills & progress")
        static let health = String(localized: "Health")
        static let healthDescription = String(localized: "Weight & milestones")
        static let momentsTitle = String(localized: "Moments")
        static let momentsDescription = String(localized: "Photos & memories")
    }
}
