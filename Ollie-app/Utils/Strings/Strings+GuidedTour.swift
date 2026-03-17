//
//  Strings+GuidedTour.swift
//  Ollie-app
//
//  Guided tour strings for new user walkthrough

import Foundation

private let table = "GuidedTour"

extension Strings {
    enum GuidedTour {
        // Welcome step
        static let welcomeTitle = String(localized: "Welcome to Ollie!", table: table)
        static let welcomeBody = String(localized: "Let's show you around so you can get the most out of tracking your puppy.", table: table)

        // Today tab
        static let todayTitle = String(localized: "Today", table: table)
        static let todayBody = String(localized: "This is your daily dashboard. See today's events, log meals, potty, sleep, and more.", table: table)

        // Train tab
        static let trainTitle = String(localized: "Train", table: table)
        static let trainBody = String(localized: "Track potty training progress, socialization, and teach new skills.", table: table)

        // Explore tab
        static let exploreTitle = String(localized: "Explore", table: table)
        static let exploreBody = String(localized: "Save favorite walk spots, see your photos on a map, and discover new places.", table: table)

        // Schedule tab
        static let scheduleTitle = String(localized: "Schedule", table: table)
        static let scheduleBody = String(localized: "Manage appointments, contacts, and track important milestones.", table: table)

        // Health tab
        static let healthTitle = String(localized: "Health", table: table)
        static let healthBody = String(localized: "View statistics, weight tracking, and health patterns.", table: table)

        // Done step
        static let doneTitle = String(localized: "You're all set!", table: table)
        static let doneBody = String(localized: "Start by logging your first event using the + button.", table: table)

        // Navigation
        static let gotIt = String(localized: "Got it", table: table)
        static let startExploring = String(localized: "Start Exploring", table: table)
        static let nextStep = String(localized: "Next", table: table)

        // Progress
        static func stepProgress(current: Int, total: Int) -> String {
            String(localized: "Step \(current) of \(total)", table: table)
        }
    }
}
