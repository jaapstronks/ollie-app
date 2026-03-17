//
//  Strings+Stats.swift
//  OtisShared
//
//  Statistics, predictions, and coverage gap strings.
//

import Foundation

extension Strings {
    // MARK: - Stats
    public enum Stats {
        public static var title: String { String(localized: "Statistics", bundle: Strings.bundle) }
        public static var pottyGaps: String { String(localized: "Potty gaps", bundle: Strings.bundle) }
        public static var avgGap: String { String(localized: "Average gap", bundle: Strings.bundle) }
        public static var medianGap: String { String(localized: "Median gap", bundle: Strings.bundle) }
        public static var shortestGap: String { String(localized: "Shortest", bundle: Strings.bundle) }
        public static var longestGap: String { String(localized: "Longest", bundle: Strings.bundle) }
        public static var outdoorPercentage: String { String(localized: "Outdoor %", bundle: Strings.bundle) }
        public static var streak: String { String(localized: "Streak", bundle: Strings.bundle) }
        public static var currentStreak: String { String(localized: "Current streak", bundle: Strings.bundle) }
        public static var bestStreak: String { String(localized: "Best streak", bundle: Strings.bundle) }
        public static var streakStartAgain: String { String(localized: "Let's start again!", bundle: Strings.bundle) }
        public static var streakGoodStart: String { String(localized: "Good start!", bundle: Strings.bundle) }
        public static var streakNiceWork: String { String(localized: "Nice work!", bundle: Strings.bundle) }
        public static var streakSuperKeepGoing: String { String(localized: "Super! Keep going!", bundle: Strings.bundle) }
        public static var streakFantastic: String { String(localized: "Fantastic!", bundle: Strings.bundle) }
        public static var streakIncredible: String { String(localized: "Incredible! 🌟", bundle: Strings.bundle) }
        public static var lastWeek: String { String(localized: "Last 7 days", bundle: Strings.bundle) }
        public static var noDataYet: String { String(localized: "No data yet", bundle: Strings.bundle) }
        public static var logSomeEvents: String { String(localized: "Log some events to see statistics", bundle: Strings.bundle) }
    }

    // MARK: - Digest
    public enum Digest {
        public static func peeCount(_ count: Int, percentage: Int) -> String {
            String(localized: "\(count)x pee (\(percentage)% outside)", bundle: Strings.bundle)
        }
        public static func poopCount(_ count: Int, percentage: Int) -> String {
            String(localized: "\(count)x poop (\(percentage)% outside)", bundle: Strings.bundle)
        }
        public static func mealCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 meal", bundle: Strings.bundle)
            }
            return String(localized: "\(count) meals", bundle: Strings.bundle)
        }
        public static func walkCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 walk", bundle: Strings.bundle)
            }
            return String(localized: "\(count) walks", bundle: Strings.bundle)
        }
        public static func sleepMinutes(_ minutes: Int) -> String {
            String(localized: "\(minutes) min sleep", bundle: Strings.bundle)
        }
        public static func sleepHours(_ hours: Int) -> String {
            String(localized: "\(hours) hours sleep", bundle: Strings.bundle)
        }
        public static func sleepHoursMinutes(hours: Int, minutes: Int) -> String {
            String(localized: "\(hours)h\(minutes)m sleep", bundle: Strings.bundle)
        }
    }

    // MARK: - Patterns
    public enum Patterns {
        public static var afterSleep: String { String(localized: "After sleep", bundle: Strings.bundle) }
        public static var afterEating: String { String(localized: "After eating", bundle: Strings.bundle) }
        public static var duringWalk: String { String(localized: "During walk", bundle: Strings.bundle) }
        public static var afterDrinking: String { String(localized: "After drinking", bundle: Strings.bundle) }
        public static var afterPlaying: String { String(localized: "After playing", bundle: Strings.bundle) }
    }

    // MARK: - Prediction
    public enum Prediction {
        public static var justPeed: String { String(localized: "Just peed", bundle: Strings.bundle) }
        public static var soon: String { String(localized: "Soon", bundle: Strings.bundle) }
        public static var afterAccidentGoOutside: String { String(localized: "Go outside now!", bundle: Strings.bundle) }
        public static func nextIn(_ minutes: Int) -> String {
            String(localized: "Next in ~\(minutes) min", bundle: Strings.bundle)
        }
        public static func needsToPeeNow(name: String) -> String {
            String(localized: "\(name) needs to pee!", bundle: Strings.bundle)
        }
        public static func needsToPeeNowOverdue(name: String, minutes: Int) -> String {
            String(localized: "\(name) needs to pee! (\(minutes) min overdue)", bundle: Strings.bundle)
        }
        /// Rounded overdue display for widgets (15+, 30+, 45+, 1h+)
        public static func needsToPeeNowOverdueRounded(name: String, bucket: String) -> String {
            String(localized: "\(name) needs to pee! (\(bucket) overdue)", bundle: Strings.bundle)
        }
    }

    // MARK: - Time Format
    public enum TimeFormat {
        public static var noData: String { String(localized: "No data", bundle: Strings.bundle) }
        public static var inside: String { String(localized: "(inside)", bundle: Strings.bundle) }
        public static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago", bundle: Strings.bundle)
        }
        public static func hoursAgo(_ hours: Int) -> String {
            String(localized: "\(hours) hours ago", bundle: Strings.bundle)
        }
        public static func hoursMinutesAgo(hours: Int, minutes: Int) -> String {
            String(localized: "\(hours)h\(minutes)m ago", bundle: Strings.bundle)
        }
        public static func stillMinutes(_ minutes: Int) -> String {
            String(localized: "~\(minutes) min left", bundle: Strings.bundle)
        }
        public static func afterEatingAgo(_ minutes: Int) -> String {
            String(localized: "(after meal \(minutes) min ago)", bundle: Strings.bundle)
        }
        public static func afterNapAgo(_ minutes: Int) -> String {
            String(localized: "(after nap \(minutes) min ago)", bundle: Strings.bundle)
        }
    }

    // MARK: - Poop Status
    public enum PoopStatus {
        public static var noPoopYetEarly: String { String(localized: "No poop yet this morning", bundle: Strings.bundle) }
        public static var noPoopYet: String { String(localized: "No poop yet today", bundle: Strings.bundle) }
        public static var walkCompletedNoPoop: String { String(localized: "Walk done, no poop yet", bundle: Strings.bundle) }
        public static var longerThanUsual: String { String(localized: "Longer than usual since last poop", bundle: Strings.bundle) }
        public static var longGap: String { String(localized: "Long time since last poop", bundle: Strings.bundle) }
        public static var belowExpected: String { String(localized: "Below expected today", bundle: Strings.bundle) }
        public static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago", bundle: Strings.bundle)
        }
        public static func hoursAgo(_ hours: Int) -> String {
            String(localized: "\(hours) hours ago", bundle: Strings.bundle)
        }
        public static func hoursMinutesAgo(hours: Int, minutes: Int) -> String {
            String(localized: "\(hours)h\(minutes)m ago", bundle: Strings.bundle)
        }
    }

    // MARK: - Coverage Gap
    public enum CoverageGap {
        // Event label
        public static var eventLabel: String { String(localized: "Coverage Gap", bundle: Strings.bundle) }

        // Gap types
        public static var typeDaycare: String { String(localized: "Daycare", bundle: Strings.bundle) }
        public static var typeFamily: String { String(localized: "Family", bundle: Strings.bundle) }
        public static var typeSitter: String { String(localized: "Pet Sitter", bundle: Strings.bundle) }
        public static var typeVacation: String { String(localized: "Vacation", bundle: Strings.bundle) }
        public static var typeOther: String { String(localized: "Other", bundle: Strings.bundle) }

        // Banner
        public static func since(time: String) -> String {
            String(localized: "Since \(time)", bundle: Strings.bundle)
        }
        public static var endGap: String { String(localized: "End", bundle: Strings.bundle) }
        public static var trackingPaused: String { String(localized: "Tracking paused", bundle: Strings.bundle) }

        // Sheets
        public static var startTitle: String { String(localized: "Who's caring for your dog?", bundle: Strings.bundle) }
        public static var endTitle: String { String(localized: "End Coverage Gap", bundle: Strings.bundle) }
        public static var locationPlaceholder: String { String(localized: "Location (optional)", bundle: Strings.bundle) }
        public static var startButton: String { String(localized: "Start", bundle: Strings.bundle) }
        public static var endButton: String { String(localized: "End Gap", bundle: Strings.bundle) }
        public static var notePlaceholder: String { String(localized: "Notes (optional)", bundle: Strings.bundle) }
        public static var startTime: String { String(localized: "Start time", bundle: Strings.bundle) }
        public static var endTime: String { String(localized: "End time", bundle: Strings.bundle) }

        // Detection prompt
        public static func detectionPrompt(hours: Int, name: String) -> String {
            String(localized: "No events logged in \(hours) hours. Was \(name) with someone else?", bundle: Strings.bundle)
        }
        public static var yesLogCoverage: String { String(localized: "Yes, log coverage", bundle: Strings.bundle) }
        public static var noIForgot: String { String(localized: "No, I forgot to log", bundle: Strings.bundle) }

        // Timeline
        public static var ongoing: String { String(localized: "Ongoing", bundle: Strings.bundle) }
        public static func duration(hours: Int, minutes: Int) -> String {
            if hours > 0 {
                return String(localized: "\(hours)h \(minutes)m", bundle: Strings.bundle)
            } else {
                return String(localized: "\(minutes)m", bundle: Strings.bundle)
            }
        }

        // Accessibility
        public static func gapTypeAccessibility(_ type: String) -> String {
            String(localized: "Care type: \(type)", bundle: Strings.bundle)
        }
        public static var endGapAccessibilityHint: String { String(localized: "Double-tap to end the coverage gap", bundle: Strings.bundle) }
    }

    // MARK: - Contribution Stats
    public enum ContributionStats {
        /// "Today"
        public static var today: String { String(localized: "Today", bundle: Strings.bundle) }

        /// "This week"
        public static var thisWeek: String { String(localized: "This week", bundle: Strings.bundle) }

        /// "This month"
        public static var thisMonth: String { String(localized: "This month", bundle: Strings.bundle) }

        /// "All time"
        public static var allTime: String { String(localized: "All time", bundle: Strings.bundle) }

        /// "Team contributions"
        public static var teamContributions: String { String(localized: "Team contributions", bundle: Strings.bundle) }

        /// "Your contributions"
        public static var yourContributions: String { String(localized: "Your contributions", bundle: Strings.bundle) }

        /// "Events logged"
        public static var eventsLogged: String { String(localized: "Events logged", bundle: Strings.bundle) }

        /// "Walks"
        public static var walks: String { String(localized: "Walks", bundle: Strings.bundle) }

        /// "Walk minutes"
        public static var walkMinutes: String { String(localized: "Walk minutes", bundle: Strings.bundle) }

        /// "Training sessions"
        public static var trainingSessions: String { String(localized: "Training sessions", bundle: Strings.bundle) }

        /// "Potty breaks"
        public static var pottyBreaks: String { String(localized: "Potty breaks", bundle: Strings.bundle) }

        /// "Moments captured"
        public static var momentsCaptured: String { String(localized: "Moments captured", bundle: Strings.bundle) }

        /// "Meals logged"
        public static var mealsLogged: String { String(localized: "Meals logged", bundle: Strings.bundle) }

        /// "Social events"
        public static var socialEvents: String { String(localized: "Social events", bundle: Strings.bundle) }

        /// "Top contributor"
        public static var topContributor: String { String(localized: "Top contributor", bundle: Strings.bundle) }

        /// "Team effort!"
        public static var teamEffort: String { String(localized: "Team effort!", bundle: Strings.bundle) }

        /// "%d%% of all events"
        public static func percentageOfEvents(_ percentage: Int) -> String {
            String(localized: "\(percentage)% of all events", bundle: Strings.bundle)
        }
    }
}
