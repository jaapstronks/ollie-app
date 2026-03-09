//
//  Strings+Leash.swift
//  Ollie-app
//
//  Leash training module strings

import Foundation

private let table = "Training"

extension Strings {

    // MARK: - Leash Training
    enum Leash {
        // Guide entry card
        static let guideTitle = String(localized: "Leash Walking", table: table)
        static let guideSubtitle = String(localized: "Walk nicely together", table: table)

        // Guide sheet
        static let guideSheetTitle = String(localized: "Leash Walking Guide", table: table)
        static let currentProgress = String(localized: "How it's going", table: table)

        // Walk classification
        static let wasThataWalk = String(localized: "Was that a walk?", table: table)
        static let yesLogWalk = String(localized: "Yes, log walk", table: table)

        // Mastery
        static let markMastered = String(localized: "Mark leash walking as mastered", table: table)
        static let markMasteredDescription = String(localized: "Your pup walks nicely on a loose leash without constant pulling", table: table)
        static let mastered = String(localized: "Mastered", table: table)
        static let masteredCelebration = String(localized: "Great leash skills!", table: table)
        static let masteredDescription = String(localized: "Walking nicely on leash is now second nature.", table: table)
        static func masteredOn(date: String) -> String {
            String(localized: "Mastered on \(date)", table: table)
        }

        // Mastery prompt
        static let masteryPromptTitle = String(localized: "Ready to mark leash walking as mastered?", table: table)
        static func weeksOfGreatRatings(_ weeks: Int) -> String {
            if weeks == 1 {
                return String(localized: "1 week of great ratings", table: table)
            }
            return String(localized: "\(weeks) weeks of great ratings", table: table)
        }

        // Reactivation
        static let reactivationTitle = String(localized: "Need some leash walking tips?", table: table)
        static let reactivationMessage = String(localized: "Looks like walks have been challenging lately. Would you like to reactivate leash training guidance?", table: table)
        static let reactivateNow = String(localized: "Yes, reactivate", table: table)
        static let notNow = String(localized: "Not now", table: table)
        static let reactivateLink = String(localized: "Having trouble? Reactivate training", table: table)

        // Sentiment prompt
        static let howWasTheWalk = String(localized: "How was the walk?", table: table)
        static let leashBehavior = String(localized: "Leash behavior", table: table)

        // Progress display
        static func averageRating(_ avg: Double) -> String {
            String(localized: "\(String(format: "%.1f", avg))/5 average", table: table)
        }
        static let improving = String(localized: "Improving", table: table)
        static let stable = String(localized: "Stable", table: table)
        static let declining = String(localized: "Needs attention", table: table)
        static let noRatingsYet = String(localized: "No ratings yet", table: table)
        static let rateAfterWalks = String(localized: "Rate after walks to track progress", table: table)

        // Key principles
        static let keyPrinciples = String(localized: "Key Principles", table: table)
        static let principle1 = String(localized: "Keep leash loose - tension creates opposition reflex", table: table)
        static let principle2 = String(localized: "Reward position, not movement - mark when beside you", table: table)
        static let principle3 = String(localized: "Stop when pulling - be a tree, don't pull back", table: table)
        static let principle4 = String(localized: "Start easy - practice indoors/garden before busy streets", table: table)
        static let principle5 = String(localized: "High-value treats - walking competes with exciting smells", table: table)

        // Age-based tips headers
        static let earlyWeeks = String(localized: "8-14 Weeks: Getting Started", table: table)
        static let middleWeeks = String(localized: "14-20 Weeks: Building Skills", table: table)
        static let adolescent = String(localized: "20+ Weeks: Adolescent Phase", table: table)

        // Early weeks tips (8-14)
        static let earlyTip1 = String(localized: "Focus on collar and leash comfort first", table: table)
        static let earlyTip2 = String(localized: "Keep sessions very short (2-3 minutes)", table: table)
        static let earlyTip3 = String(localized: "Practice indoors before going outside", table: table)
        static let earlyTip4 = String(localized: "Reward frequently for staying close", table: table)

        // Middle weeks tips (14-20)
        static let middleTip1 = String(localized: "Build duration gradually", table: table)
        static let middleTip2 = String(localized: "Start generalizing to new places", table: table)
        static let middleTip3 = String(localized: "Practice direction changes", table: table)
        static let middleTip4 = String(localized: "Add mild distractions", table: table)

        // Adolescent tips (20+)
        static let adolescentTip1 = String(localized: "Expect some regression - it's normal", table: table)
        static let adolescentTip2 = String(localized: "Increase reinforcement rate during this phase", table: table)
        static let adolescentTip3 = String(localized: "Stay patient and consistent", table: table)
        static let adolescentTip4 = String(localized: "Consider a front-clip harness if needed", table: table)

        // Common mistakes
        static let commonMistakes = String(localized: "Common Mistakes", table: table)
        static let mistake1 = String(localized: "Using a retractable leash (teaches pulling)", table: table)
        static let mistake2 = String(localized: "Pulling back when they pull (creates tension)", table: table)
        static let mistake3 = String(localized: "Moving too fast - let them sniff sometimes", table: table)
        static let mistake4 = String(localized: "Expecting too much too soon", table: table)

        // Sentiment message
        static let sentimentHappened = String(localized: "Walks are a work in progress", table: table)
        static let sentimentMessage = String(localized: "Leash skills take time. Keep practicing and you'll see improvement.", table: table)

        // Accessibility
        static let progressCardAccessibility = String(localized: "Leash walking progress card", table: table)
    }
}
