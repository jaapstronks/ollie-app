//
//  Strings+Trial.swift
//  Otis-app
//
//  Localized strings for 14-day local trial

import Foundation

private let table = "Trial"

extension Strings {

    // MARK: - Trial

    enum Trial {
        // Onboarding trial step
        static let heroTitle = String(localized: "Your AI Puppy Coach is Ready", table: table)
        static let heroSubtitle = String(localized: "Get personalized insights, smart predictions, and expert guidance tailored to your puppy.", table: table)
        static let startTrialButton = String(localized: "Start 14-Day Free Trial", table: table)
        static let skipTrialLink = String(localized: "Continue without trial", table: table)

        // Trial benefits
        static let benefit1 = String(localized: "AI-powered potty predictions", table: table)
        static let benefit2 = String(localized: "Personalized training guidance", table: table)
        static let benefit3 = String(localized: "Smart pattern recognition", table: table)
        static let benefit4 = String(localized: "No credit card required", table: table)

        // Trial banner
        static func trialDaysRemaining(_ days: Int) -> String {
            if days == 1 {
                return String(localized: "1 day left in trial", table: table)
            }
            return String(localized: "\(days) days left in trial", table: table)
        }

        // Trial status
        static let trialActive = String(localized: "Trial Active", table: table)
        static let trialExpired = String(localized: "Trial Ended", table: table)

        // Expired trial sheet
        static let expiredTitle = String(localized: "Your Trial Has Ended", table: table)
        static func expiredSubtitle(name: String) -> String {
            String(localized: "Keep \(name)'s journey on track with Ollie+", table: table)
        }

        // What you've built section
        static let whatYouBuilt = String(localized: "What you've built", table: table)
        static func eventsLogged(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 event logged", table: table)
            }
            return String(localized: "\(count) events logged", table: table)
        }
        static func trainingSessions(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 training session", table: table)
            }
            return String(localized: "\(count) training sessions", table: table)
        }
        static func daysTracking(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 day tracking", table: table)
            }
            return String(localized: "\(count) days tracking", table: table)
        }

        // What you'll lose section
        static let whatYouLose = String(localized: "Without Ollie+, you'll lose access to:", table: table)
        static let losePredictions = String(localized: "AI potty predictions", table: table)
        static let loseInsights = String(localized: "Personalized insights", table: table)
        static let loseTraining = String(localized: "Full training library", table: table)
        static let loseAnalytics = String(localized: "Advanced analytics", table: table)

        // CTA
        static let subscribeNow = String(localized: "Subscribe Now", table: table)
        static let notNow = String(localized: "Not now", table: table)
        static func pricePerMonth(_ price: String) -> String {
            String(localized: "\(price)/month", table: table)
        }

        // Migration trial
        static let migrationTitle = String(localized: "Welcome Back!", table: table)
        static let migrationSubtitle = String(localized: "As a valued user, enjoy 14 days of Ollie+ free to explore our new AI features.", table: table)
        static let migrationStartButton = String(localized: "Start My Free Trial", table: table)

        // MARK: - Touchpoint Cards

        // Day 1: First Insight
        static let day1Title = String(localized: "Your AI Coach is Learning", table: table)
        static func day1Subtitle(name: String) -> String {
            String(localized: "Your patterns with \(name) are being analyzed. Keep logging to unlock personalized predictions!", table: table)
        }
        static let day1Dismiss = String(localized: "Got it", table: table)

        // Day 7: Value Summary
        static let day7Title = String(localized: "One Week with Your AI Coach", table: table)
        static let day7Subtitle = String(localized: "Look what we've discovered together", table: table)
        static func day7PredictionsMade(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 prediction made", table: table)
            }
            return String(localized: "\(count) predictions made", table: table)
        }
        static func day7InsightsGenerated(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 insight generated", table: table)
            }
            return String(localized: "\(count) insights generated", table: table)
        }
        static func day7PatternsLearned(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 pattern learned", table: table)
            }
            return String(localized: "\(count) patterns learned", table: table)
        }
        static let day7KeepGoing = String(localized: "Keep it up!", table: table)

        // Day 12: Warning
        static let day12Title = String(localized: "Only 2 Days Left", table: table)
        static func day12Subtitle(name: String) -> String {
            String(localized: "Your trial ends soon. Don't lose the insights you've built with \(name).", table: table)
        }
        static let day12Subscribe = String(localized: "See Plans", table: table)
        static let day12Later = String(localized: "Remind Me Later", table: table)

        // Day 14: Conversion
        static let day14Title = String(localized: "Last Day of Your Trial", table: table)
        static func day14Subtitle(name: String) -> String {
            String(localized: "Keep \(name)'s personalized AI coach working for you. Subscribe today to continue.", table: table)
        }
        static let day14Subscribe = String(localized: "Subscribe Now", table: table)
        static let day14Dismiss = String(localized: "Not Yet", table: table)

        // Day 3: Notification (push only, no card)
        static let day3NotificationTitle = String(localized: "Your puppy's patterns are forming", table: table)
        static let day3NotificationBody = String(localized: "Open Ollie to see what your AI coach is learning", table: table)
    }
}
