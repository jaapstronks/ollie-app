//
//  Strings+Social.swift
//  Ollie-app
//
//  Socialization strings

import Foundation

private let table = "Social"

extension Strings {

    // MARK: - Socialization
    enum Socialization {
        // Section header
        static let title = String(localized: "Socialization", table: table)
        static let sectionTitle = String(localized: "Socialization Checklist", table: table)

        // Progress
        static let comfortable = String(localized: "comfortable", table: table)
        static func progressLabel(current: Int, total: Int) -> String {
            String(localized: "\(current) / \(total) comfortable", table: table)
        }
        static func categoryProgress(completed: Int, total: Int) -> String {
            String(localized: "\(completed)/\(total)", table: table)
        }

        // Window status
        static let windowPeak = String(localized: "Critical socialization period", table: table)
        static let windowOpen = String(localized: "In the socialization window", table: table)
        static let windowClosing = String(localized: "Window closing soon", table: table)
        static let windowJustClosed = String(localized: "Window just closed", table: table)
        static let windowClosed = String(localized: "Past socialization window", table: table)
        static func weeksRemaining(_ weeks: Int) -> String {
            String(localized: "\(weeks) weeks remaining", table: table)
        }

        // Distance labels
        static let distanceFar = String(localized: "Far", table: table)
        static let distanceNear = String(localized: "Near", table: table)
        static let distanceDirect = String(localized: "Direct", table: table)
        static let distanceFarDescription = String(localized: "Observed from a distance", table: table)
        static let distanceNearDescription = String(localized: "Close but no contact", table: table)
        static let distanceDirectDescription = String(localized: "Direct interaction", table: table)

        // Reaction labels
        static let reactionPositive = String(localized: "Positive", table: table)
        static let reactionNeutral = String(localized: "Neutral", table: table)
        static let reactionUnsure = String(localized: "Unsure", table: table)
        static let reactionFearful = String(localized: "Fearful", table: table)
        static let reactionPositiveDescription = String(localized: "Curious, relaxed, playful", table: table)
        static let reactionNeutralDescription = String(localized: "Calm, no reaction — this is the goal!", table: table)
        static let reactionUnsureDescription = String(localized: "Hesitant, ears back, tail low", table: table)
        static let reactionFearfulDescription = String(localized: "Hiding, trembling, trying to escape", table: table)

        // Log exposure
        static let logExposure = String(localized: "Log Exposure", table: table)
        static let distance = String(localized: "Distance", table: table)
        static let reaction = String(localized: "Reaction", table: table)
        static let noteOptional = String(localized: "Note (optional)", table: table)
        static let notePlaceholder = String(localized: "What happened?", table: table)
        static let calmIsGoal = String(localized: "Calm, neutral behavior is the goal — not interaction!", table: table)

        // Fear protocol
        static let fearProtocolTitle = String(localized: "Tips for Fearful Reactions", table: table)
        static let fearProtocolTip1 = String(localized: "Don't force interaction — increase distance", table: table)
        static let fearProtocolTip2 = String(localized: "Pair the stimulus with treats (look, treat, look away)", table: table)
        static let fearProtocolTip3 = String(localized: "Keep sessions very short", table: table)
        static let fearProtocolTip4 = String(localized: "End on a positive note if possible", table: table)
        static let fearProtocolTip5 = String(localized: "Consult a professional trainer if fear persists", table: table)
        static let understood = String(localized: "Understood", table: table)

        // Item states
        static let notStarted = String(localized: "Not started", table: table)
        static let inProgress = String(localized: "In progress", table: table)
        static let almostThere = String(localized: "Almost there", table: table)
        static let comfortableState = String(localized: "Comfortable", table: table)
        static let needsPractice = String(localized: "Needs practice", table: table)

        // Walk suggestions
        static let walkSuggestionsTitle = String(localized: "Watch for during walk", table: table)
        static let walkSuggestionsTip = String(localized: "Tap to log exposure", table: table)
        static let seeAll = String(localized: "See all", table: table)
        static func showMore(_ count: Int) -> String {
            String(localized: "Show \(count) more", table: table)
        }
        static let showLess = String(localized: "Show less", table: table)

        // Last exposure
        static func lastExposure(date: String) -> String {
            String(localized: "Last: \(date)", table: table)
        }
        static func exposureCount(_ count: Int) -> String {
            String(localized: "\(count) exposures", table: table)
        }

        // Categories (for fallback if not localized in seed data)
        static let categoryPeople = String(localized: "People", table: table)
        static let categoryAnimals = String(localized: "Animals", table: table)
        static let categoryVehicles = String(localized: "Vehicles", table: table)
        static let categorySounds = String(localized: "Sounds", table: table)
        static let categoryEnvironments = String(localized: "Environments", table: table)
        static let categorySurfaces = String(localized: "Surfaces", table: table)
        static let categoryHandling = String(localized: "Handling", table: table)
        static let categoryObjects = String(localized: "Objects", table: table)
        static let categoryWeather = String(localized: "Weather", table: table)

        // Empty state
        static let noExposuresYet = String(localized: "No exposures logged yet", table: table)
        static let tapToLogFirst = String(localized: "Tap to log your first exposure", table: table)

        // Week timeline
        static let socializationWindowTitle = String(localized: "Socialization Window", table: table)
        static let complete = String(localized: "Complete", table: table)
        static let current = String(localized: "Current", table: table)
        static let upcoming = String(localized: "Upcoming", table: table)
        static func weeksLeft(_ weeks: Int) -> String {
            String(localized: "\(weeks) weeks left", table: table)
        }
        static func thisWeekProgress(_ count: Int) -> String {
            String(localized: "\(count) exposures this week", table: table)
        }
    }
}
