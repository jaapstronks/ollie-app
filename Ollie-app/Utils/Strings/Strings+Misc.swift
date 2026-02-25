//
//  Strings+Misc.swift
//  Ollie-app
//
//  Stats, streak, tips, errors, and other miscellaneous strings

import Foundation

extension Strings {

    // MARK: - Streak Card
    enum Streak {
        static let accessibility = String(localized: "Outdoor pee streak")
        static func outdoorStreak(count: Int) -> String {
            if count == 1 {
                return String(localized: "1 pee outside")
            } else {
                return String(localized: "\(count) pees outside in a row")
            }
        }
        static let onFire = String(localized: "On fire!")
        static let inARow = String(localized: "in a row!")
        static let streakBroken = String(localized: "Streak broken")
        static func recordTryAgain(count: Int) -> String {
            String(localized: "Record: \(count)x — try again!")
        }
        static func record(count: Int) -> String {
            String(localized: "Record: \(count)x")
        }
        static let progressHint = String(localized: "Progress toward next milestone")

        // Accessibility values
        static func accessibilityValue(current: Int, record: Int) -> String {
            String(localized: "\(current) pees outside in a row. Record: \(record)")
        }
        static func progressAccessibilityValue(current: Int, milestone: Int) -> String {
            String(localized: "\(current) of \(milestone)")
        }
    }

    // MARK: - Stats View
    enum Stats {
        static let title = String(localized: "Statistics")
        static let outdoorStreak = String(localized: "Outdoor Streak")
        static let pottyGaps = String(localized: "Pee Intervals (7 days)")
        static let today = String(localized: "Today")
        static let sleepToday = String(localized: "Sleep Today")
        static let patterns = String(localized: "Patterns (7 days)")

        // Expanded Stats tab sections
        static let health = String(localized: "Health")
        static let walkHistory = String(localized: "Walk History")
        static let spots = String(localized: "Spots")
        static let thisWeek = String(localized: "This week")

        static let currentStreak = String(localized: "Current streak")
        static let bestEver = String(localized: "Best ever")
        static let median = String(localized: "Median")
        static let average = String(localized: "Average")
        static let shortest = String(localized: "Shortest")
        static let longest = String(localized: "Longest")

        static func outsideCount(_ count: Int) -> String {
            String(localized: "\(count) outside")
        }
        static func insideCount(_ count: Int) -> String {
            String(localized: "\(count) inside")
        }
        static let outsidePercent = String(localized: "% outside")
        static let insufficientData = String(localized: "Not enough data yet")

        // Week grid row labels
        static let outdoor = String(localized: "Outdoor")
        static let indoor = String(localized: "Indoor")
        static let mealsLabel = String(localized: "Meals")
        static let walksLabel = String(localized: "Walks")
        static let sleepLabel = String(localized: "Sleep")
        static let trainingLabel = String(localized: "Training")

        // Streak motivational messages
        static let streakStartAgain = String(localized: "Start again!")
        static let streakGoodStart = String(localized: "Good start!")
        static let streakNiceWork = String(localized: "Nice work!")
        static let streakSuperKeepGoing = String(localized: "Super! Keep going!")
        static let streakFantastic = String(localized: "Fantastic! 🎉")
        static let streakIncredible = String(localized: "Incredible! 🏆")

        static let timesPeed = String(localized: "Times peed")
        static let meals = String(localized: "Meals")
        static let timesPooped = String(localized: "Times pooped")
        static let totalSlept = String(localized: "Total slept")
        static let naps = String(localized: "Naps")
        static let sleepGoal = String(localized: "Goal: 18 hours")
        static let sleepProgress = String(localized: "Sleep progress")
        static let percentOfGoal = String(localized: "percent of goal")
    }

    // MARK: - Tips
    enum Tips {
        static let swipeToDeleteTitle = String(localized: "Swipe to delete")
        static let swipeToDeleteMessage = String(localized: "Swipe an event left to delete it.")

        static let longPressTitle = String(localized: "Hold for options")
        static let longPressMessage = String(localized: "Hold an event for extra options like edit.")

        static let mealRemindersTitle = String(localized: "Set up meal reminders")
        static let mealRemindersMessage = String(localized: "Get notified when it's time for the next meal.")

        static let quickLogTitle = String(localized: "Quick log")
        static let quickLogMessage = String(localized: "Use the bar at the bottom to quickly log events with one tap.")

        static let patternsTitle = String(localized: "Discover patterns")
        static let patternsMessage = String(localized: "Check statistics to discover patterns in your puppy's behavior.")

        static let predictionTitle = String(localized: "Prediction")
        static let predictionMessage = String(localized: "The app learns from patterns and predicts when your puppy needs to pee.")
    }

    // MARK: - Errors
    enum Errors {
        static let title = String(localized: "Error")
        static let networkError = String(localized: "Network error")
        static let fileError = String(localized: "File error")
        static let dataCorrupted = String(localized: "Data corrupted")
        static let unknownError = String(localized: "Unknown error")

        static let networkRecovery = String(localized: "Check your internet connection and try again.")
        static let fileRecovery = String(localized: "Something went wrong while saving. Please try again.")
        static let dataRecovery = String(localized: "The data could not be read. Try restarting the app.")
        static let unknownRecovery = String(localized: "Please try again later.")

        static let cloudKitNotConfigured = String(localized: "CloudKit not configured")
        static let cloudKitNotAvailable = String(localized: "CloudKit not available")
        static let cloudKitSimulator = String(localized: "CloudKit not available on simulator")
        static let couldNotShare = String(localized: "Could not share")
        static let couldNotStopSharing = String(localized: "Could not stop sharing")
        static let couldNotProcessWeather = String(localized: "Could not process weather data")
    }

    // MARK: - Streaks
    enum StreakMessages {
        static let startAgain = String(localized: "Start again!")
    }

    // MARK: - Potty Progress Summary Card
    enum PottyProgress {
        static func streakCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 in a row")
            } else {
                return String(localized: "\(count) in a row")
            }
        }

        static func poopCountWithExpected(count: Int, lower: Int, upper: Int) -> String {
            String(localized: "\(count) poops (\(lower)-\(upper) expected)")
        }

        static func poopCountSimple(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 poop")
            } else {
                return String(localized: "\(count) poops")
            }
        }

        // Accessibility
        static func streakAccessibility(_ count: Int) -> String {
            String(localized: "\(count) outdoor pees in a row")
        }

        static func poopAccessibility(count: Int, hasPattern: Bool, lower: Int, upper: Int) -> String {
            if hasPattern {
                return String(localized: "\(count) poops today, \(lower) to \(upper) expected")
            } else {
                return String(localized: "\(count) poops today")
            }
        }
    }
}
