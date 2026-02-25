//
//  Strings+Social.swift
//  Ollie-app
//
//  Socialization strings

import Foundation

extension Strings {

    // MARK: - Socialization
    enum Socialization {
        // Section header
        static let title = String(localized: "Socialization")
        static let sectionTitle = String(localized: "Socialization Checklist")

        // Progress
        static let comfortable = String(localized: "comfortable")
        static func progressLabel(current: Int, total: Int) -> String {
            String(localized: "\(current) / \(total) comfortable")
        }
        static func categoryProgress(completed: Int, total: Int) -> String {
            String(localized: "\(completed)/\(total)")
        }

        // Window status
        static let windowPeak = String(localized: "Critical socialization period")
        static let windowOpen = String(localized: "In the socialization window")
        static let windowClosing = String(localized: "Window closing soon")
        static let windowJustClosed = String(localized: "Window just closed")
        static let windowClosed = String(localized: "Past socialization window")
        static func weeksRemaining(_ weeks: Int) -> String {
            String(localized: "\(weeks) weeks remaining")
        }

        // Distance labels
        static let distanceFar = String(localized: "Far")
        static let distanceNear = String(localized: "Near")
        static let distanceDirect = String(localized: "Direct")
        static let distanceFarDescription = String(localized: "Observed from a distance")
        static let distanceNearDescription = String(localized: "Close but no contact")
        static let distanceDirectDescription = String(localized: "Direct interaction")

        // Reaction labels
        static let reactionPositive = String(localized: "Positive")
        static let reactionNeutral = String(localized: "Neutral")
        static let reactionUnsure = String(localized: "Unsure")
        static let reactionFearful = String(localized: "Fearful")
        static let reactionPositiveDescription = String(localized: "Curious, relaxed, playful")
        static let reactionNeutralDescription = String(localized: "Calm, no reaction — this is the goal!")
        static let reactionUnsureDescription = String(localized: "Hesitant, ears back, tail low")
        static let reactionFearfulDescription = String(localized: "Hiding, trembling, trying to escape")

        // Log exposure
        static let logExposure = String(localized: "Log Exposure")
        static let distance = String(localized: "Distance")
        static let reaction = String(localized: "Reaction")
        static let noteOptional = String(localized: "Note (optional)")
        static let notePlaceholder = String(localized: "What happened?")
        static let calmIsGoal = String(localized: "Calm, neutral behavior is the goal — not interaction!")

        // Fear protocol
        static let fearProtocolTitle = String(localized: "Tips for Fearful Reactions")
        static let fearProtocolTip1 = String(localized: "Don't force interaction — increase distance")
        static let fearProtocolTip2 = String(localized: "Pair the stimulus with treats (look, treat, look away)")
        static let fearProtocolTip3 = String(localized: "Keep sessions very short")
        static let fearProtocolTip4 = String(localized: "End on a positive note if possible")
        static let fearProtocolTip5 = String(localized: "Consult a professional trainer if fear persists")
        static let understood = String(localized: "Understood")

        // Item states
        static let notStarted = String(localized: "Not started")
        static let inProgress = String(localized: "In progress")
        static let almostThere = String(localized: "Almost there")
        static let comfortableState = String(localized: "Comfortable")

        // Walk suggestions
        static let walkSuggestionsTitle = String(localized: "Watch for during walk")
        static let walkSuggestionsTip = String(localized: "Tap to log exposure")
        static let seeAll = String(localized: "See all")
        static func showMore(_ count: Int) -> String {
            String(localized: "Show \(count) more")
        }
        static let showLess = String(localized: "Show less")

        // Last exposure
        static func lastExposure(date: String) -> String {
            String(localized: "Last: \(date)")
        }
        static func exposureCount(_ count: Int) -> String {
            String(localized: "\(count) exposures")
        }

        // Categories (for fallback if not localized in seed data)
        static let categoryPeople = String(localized: "People")
        static let categoryAnimals = String(localized: "Animals")
        static let categoryVehicles = String(localized: "Vehicles")
        static let categorySounds = String(localized: "Sounds")
        static let categoryEnvironments = String(localized: "Environments")
        static let categorySurfaces = String(localized: "Surfaces")
        static let categoryHandling = String(localized: "Handling")
        static let categoryObjects = String(localized: "Objects")
        static let categoryWeather = String(localized: "Weather")

        // Empty state
        static let noExposuresYet = String(localized: "No exposures logged yet")
        static let tapToLogFirst = String(localized: "Tap to log your first exposure")
    }
}
