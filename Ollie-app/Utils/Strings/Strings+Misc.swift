//
//  Strings+Misc.swift
//  Otis-app
//
//  Stats, streak, tips, errors, and other miscellaneous strings

import Foundation

private let table = "Misc"

extension Strings {

    // MARK: - Streak Card
    enum Streak {
        static let accessibility = String(localized: "Outdoor pee streak", table: table)
        static func outdoorStreak(count: Int) -> String {
            if count == 1 {
                return String(localized: "1 pee outside", table: table)
            } else {
                return String(localized: "\(count) pees outside in a row", table: table)
            }
        }
        static let onFire = String(localized: "On fire!", table: table)
        static let inARow = String(localized: "in a row!", table: table)
        static let streakBroken = String(localized: "Streak broken", table: table)
        static func recordTryAgain(count: Int) -> String {
            String(localized: "Record: \(count)x — try again!", table: table)
        }
        static func record(count: Int) -> String {
            String(localized: "Record: \(count)x", table: table)
        }
        static let progressHint = String(localized: "Progress toward next milestone", table: table)

        // Accessibility values
        static func accessibilityValue(current: Int, record: Int) -> String {
            String(localized: "\(current) pees outside in a row. Record: \(record)", table: table)
        }
        static func progressAccessibilityValue(current: Int, milestone: Int) -> String {
            String(localized: "\(current) of \(milestone)", table: table)
        }
    }

    // MARK: - Stats View
    enum Stats {
        static let title = String(localized: "Statistics", table: table)
        static let outdoorStreak = String(localized: "Outdoor Streak", table: table)
        static let pottyGaps = String(localized: "Pee Intervals (7 days)", table: table)
        static let pottyTraining = String(localized: "Potty Training", table: table)
        static let today = String(localized: "Today", table: table)
        static let sleepToday = String(localized: "Sleep Today", table: table)
        static let patterns = String(localized: "Potty Triggers (7 days)", table: table)
        static let patternsSubtitle = String(localized: "Outdoor success rate by trigger", table: table)

        // Expanded Stats tab sections
        static let health = String(localized: "Health", table: table)
        static let walkHistory = String(localized: "Walk History", table: table)
        static let spots = String(localized: "Spots", table: table)
        static let thisWeek = String(localized: "This week", table: table)

        static let currentStreak = String(localized: "Current streak", table: table)
        static let bestEver = String(localized: "Best ever", table: table)
        static let median = String(localized: "Median", table: table)
        static let average = String(localized: "Average", table: table)
        static let shortest = String(localized: "Shortest", table: table)
        static let longest = String(localized: "Longest", table: table)

        static func outsideCount(_ count: Int) -> String {
            String(localized: "\(count) outside", table: table)
        }
        static func insideCount(_ count: Int) -> String {
            String(localized: "\(count) inside", table: table)
        }
        static let outsidePercent = String(localized: "% outside", table: table)
        static let insufficientData = String(localized: "Not enough data yet", table: table)

        // Week grid row labels
        static let outdoor = String(localized: "Outdoor", table: table)
        static let indoor = String(localized: "Indoor", table: table)
        static let mealsLabel = String(localized: "Meals", table: table)
        static let walksLabel = String(localized: "Walks", table: table)
        static let sleepLabel = String(localized: "Sleep", table: table)
        static let trainingLabel = String(localized: "Training", table: table)

        // Streak motivational messages
        static let streakStartAgain = String(localized: "Start again!", table: table)
        static let streakGoodStart = String(localized: "Good start!", table: table)
        static let streakNiceWork = String(localized: "Nice work!", table: table)
        static let streakSuperKeepGoing = String(localized: "Super! Keep going!", table: table)
        static let streakFantastic = String(localized: "Fantastic! 🎉", table: table)
        static let streakIncredible = String(localized: "Incredible! 🏆", table: table)

        static let timesPeed = String(localized: "Times peed", table: table)
        static let meals = String(localized: "Meals", table: table)
        static let timesPooped = String(localized: "Times pooped", table: table)
        static let totalSlept = String(localized: "Total slept", table: table)
        static let naps = String(localized: "Naps", table: table)
        static let sleepGoal = String(localized: "Goal: 18 hours", table: table)
        static let sleepProgress = String(localized: "Sleep progress", table: table)
        static let percentOfGoal = String(localized: "percent of goal", table: table)
    }

    // MARK: - Tips (nonisolated for TipKit protocol conformance - hardcoded table name)
    enum Tips {
        nonisolated static let swipeToDeleteTitle = String(localized: "Swipe to delete", table: "Localizable")
        nonisolated static let swipeToDeleteMessage = String(localized: "Swipe an event left to delete it.", table: "Localizable")

        nonisolated static let longPressTitle = String(localized: "Hold for options", table: "Localizable")
        nonisolated static let longPressMessage = String(localized: "Hold an event for extra options like edit.", table: "Localizable")

        nonisolated static let mealRemindersTitle = String(localized: "Set up meal reminders", table: "Localizable")
        nonisolated static let mealRemindersMessage = String(localized: "Get notified when it's time for the next meal.", table: "Localizable")

        nonisolated static let quickLogTitle = String(localized: "Quick log", table: "Localizable")
        nonisolated static let quickLogMessage = String(localized: "Use the bar at the bottom to quickly log events with one tap.", table: "Localizable")

        nonisolated static let patternsTitle = String(localized: "Discover patterns", table: "Localizable")
        nonisolated static let patternsMessage = String(localized: "Check statistics to discover patterns in your puppy's behavior.", table: "Localizable")

        nonisolated static let predictionTitle = String(localized: "Prediction", table: "Localizable")
        nonisolated static let predictionMessage = String(localized: "The app learns from patterns and predicts when your puppy needs to pee.", table: "Localizable")
    }

    // MARK: - Errors
    enum Errors {
        static let title = String(localized: "Error", table: table)
        // nonisolated for use in LocalizedError conformance - hardcoded table name
        nonisolated static let networkError = String(localized: "Network error", table: "Localizable")
        nonisolated static let fileError = String(localized: "File error", table: "Localizable")
        nonisolated static let dataCorrupted = String(localized: "Data corrupted", table: "Localizable")
        nonisolated static let unknownError = String(localized: "Unknown error", table: "Localizable")

        nonisolated static let networkRecovery = String(localized: "Check your internet connection and try again.", table: "Localizable")
        nonisolated static let fileRecovery = String(localized: "Something went wrong while saving. Please try again.", table: "Localizable")
        nonisolated static let dataRecovery = String(localized: "The data could not be read. Try restarting the app.", table: "Localizable")
        nonisolated static let unknownRecovery = String(localized: "Please try again later.", table: "Localizable")

        static let cloudKitNotConfigured = String(localized: "CloudKit not configured", table: table)
        static let cloudKitNotAvailable = String(localized: "CloudKit not available", table: table)
        static let cloudKitSimulator = String(localized: "CloudKit not available on simulator", table: table)
        static let couldNotShare = String(localized: "Could not share", table: table)
        static let couldNotStopSharing = String(localized: "Could not stop sharing", table: table)
        nonisolated static let couldNotProcessWeather = String(localized: "Could not process weather data", table: "Localizable")

        // Weather errors (nonisolated for use in LocalizedError conformance - hardcoded table name)
        nonisolated static let invalidURL = String(localized: "Invalid URL", table: "Localizable")

        // Import errors (nonisolated for use in LocalizedError conformance - hardcoded table name)
        nonisolated static let invalidFile = String(localized: "Invalid file format", table: "Localizable")
        nonisolated static let invalidContent = String(localized: "Invalid file content", table: "Localizable")
        nonisolated static let contentTooLarge = String(localized: "File too large", table: "Localizable")
        nonisolated static let maliciousContent = String(localized: "Suspicious content detected", table: "Localizable")
        nonisolated static let noProfileFound = String(localized: "No profile found. Please create a profile first.", table: "Localizable")

        // Other errors
        nonisolated static let couldNotProcessData = String(localized: "Could not process data", table: "Localizable")
        nonisolated static let parseError = String(localized: "Could not parse data", table: "Localizable")
    }

    // MARK: - Streaks
    enum StreakMessages {
        static let startAgain = String(localized: "Start again!", table: table)
    }

    // MARK: - Celebration Messages
    enum Celebration {
        static func outdoorStreakToday(count: Int, puppyName: String) -> String {
            String(localized: "\(count) outdoor pees in a row today! \(puppyName) is doing amazing!", table: table)
        }
        static func outdoorStreakTodayShort(count: Int) -> String {
            String(localized: "\(count) outdoor pees today!", table: table)
        }
        static let perfectDaySoFar = String(localized: "Perfect day so far!", table: table)
        static let keepItUp = String(localized: "Keep it up!", table: table)
    }

    // MARK: - Potty Progress Summary Card
    enum PottyProgress {
        static func streakCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 in a row", table: table)
            } else {
                return String(localized: "\(count) in a row", table: table)
            }
        }

        static func poopCountWithExpected(count: Int, lower: Int, upper: Int) -> String {
            if lower == upper {
                return String(localized: "\(count) poops (\(lower) expected)", table: table)
            } else {
                return String(localized: "\(count) poops (\(lower)-\(upper) expected)", table: table)
            }
        }

        static func poopCountSimple(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 poop", table: table)
            } else {
                return String(localized: "\(count) poops", table: table)
            }
        }

        // Accessibility
        static func streakAccessibility(_ count: Int) -> String {
            String(localized: "\(count) outdoor pees in a row", table: table)
        }

        static func poopAccessibility(count: Int, hasPattern: Bool, lower: Int, upper: Int) -> String {
            if hasPattern {
                return String(localized: "\(count) poops today, \(lower) to \(upper) expected", table: table)
            } else {
                return String(localized: "\(count) poops today", table: table)
            }
        }
    }

    // MARK: - AI Nudges
    enum AINudges {
        static let recommendationTitle = String(localized: "Quick tweak suggestion", table: table)
        static let reduceReminders = String(localized: "Reduce reminders", table: table)
        static let keepCurrent = String(localized: "Keep current", table: table)
        static let settingsUpdated = String(localized: "Reminder settings updated", table: table)
        static let recommendationDismissed = String(localized: "Got it, we'll keep current reminders", table: table)

        static func recommendationBody(category: String) -> String {
            String(localized: "You've logged fewer \(category) entries lately. Want us to reduce those reminders for now?", table: table)
        }

        static let categoryPotty = String(localized: "potty", table: table)
        static let categoryWalk = String(localized: "walk", table: table)
        static let categoryMeal = String(localized: "meal", table: table)
        static let categoryTraining = String(localized: "training", table: table)
        static let categorySocialization = String(localized: "socialization", table: table)
    }
}
