//
//  Strings+Misc.swift
//  Ollie-app
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
        static let today = String(localized: "Today", table: table)
        static let sleepToday = String(localized: "Sleep Today", table: table)
        static let patterns = String(localized: "Patterns (7 days)", table: table)

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

    // MARK: - Tips
    enum Tips {
        static let swipeToDeleteTitle = String(localized: "Swipe to delete", table: table)
        static let swipeToDeleteMessage = String(localized: "Swipe an event left to delete it.", table: table)

        static let longPressTitle = String(localized: "Hold for options", table: table)
        static let longPressMessage = String(localized: "Hold an event for extra options like edit.", table: table)

        static let mealRemindersTitle = String(localized: "Set up meal reminders", table: table)
        static let mealRemindersMessage = String(localized: "Get notified when it's time for the next meal.", table: table)

        static let quickLogTitle = String(localized: "Quick log", table: table)
        static let quickLogMessage = String(localized: "Use the bar at the bottom to quickly log events with one tap.", table: table)

        static let patternsTitle = String(localized: "Discover patterns", table: table)
        static let patternsMessage = String(localized: "Check statistics to discover patterns in your puppy's behavior.", table: table)

        static let predictionTitle = String(localized: "Prediction", table: table)
        static let predictionMessage = String(localized: "The app learns from patterns and predicts when your puppy needs to pee.", table: table)
    }

    // MARK: - Errors
    enum Errors {
        static let title = String(localized: "Error", table: table)
        static let networkError = String(localized: "Network error", table: table)
        static let fileError = String(localized: "File error", table: table)
        static let dataCorrupted = String(localized: "Data corrupted", table: table)
        static let unknownError = String(localized: "Unknown error", table: table)

        static let networkRecovery = String(localized: "Check your internet connection and try again.", table: table)
        static let fileRecovery = String(localized: "Something went wrong while saving. Please try again.", table: table)
        static let dataRecovery = String(localized: "The data could not be read. Try restarting the app.", table: table)
        static let unknownRecovery = String(localized: "Please try again later.", table: table)

        static let cloudKitNotConfigured = String(localized: "CloudKit not configured", table: table)
        static let cloudKitNotAvailable = String(localized: "CloudKit not available", table: table)
        static let cloudKitSimulator = String(localized: "CloudKit not available on simulator", table: table)
        static let couldNotShare = String(localized: "Could not share", table: table)
        static let couldNotStopSharing = String(localized: "Could not stop sharing", table: table)
        static let couldNotProcessWeather = String(localized: "Could not process weather data", table: table)

        // Weather errors
        static let invalidURL = String(localized: "Invalid URL", table: table)

        // Import errors
        static let apiError = String(localized: "Could not reach GitHub API", table: table)
        static let invalidResponse = String(localized: "Invalid response from GitHub", table: table)
        static let downloadFailed = String(localized: "Download failed", table: table)
        static let invalidContent = String(localized: "Invalid file content", table: table)
        static let untrustedURL = String(localized: "Untrusted download URL", table: table)
        static let contentTooLarge = String(localized: "File too large", table: table)
        static let maliciousContent = String(localized: "Suspicious content detected", table: table)
    }

    // MARK: - Streaks
    enum StreakMessages {
        static let startAgain = String(localized: "Start again!", table: table)
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
            String(localized: "\(count) poops (\(lower)-\(upper) expected)", table: table)
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
}
