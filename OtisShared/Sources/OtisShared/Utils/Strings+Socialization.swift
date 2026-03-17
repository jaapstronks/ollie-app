//
//  Strings+Socialization.swift
//  OtisShared
//
//  Socialization checklist and exposure tracking strings.
//

import Foundation

extension Strings {
    // MARK: - Socialization
    public enum Socialization {
        public static var title: String { String(localized: "Socialization", bundle: Strings.bundle) }
        public static var sectionTitle: String { String(localized: "Socialization Checklist", bundle: Strings.bundle) }
        public static var comfortable: String { String(localized: "comfortable", bundle: Strings.bundle) }
        public static func progressLabel(current: Int, total: Int) -> String {
            String(localized: "\(current) / \(total) comfortable", bundle: Strings.bundle)
        }
        public static func categoryProgress(completed: Int, total: Int) -> String {
            String(localized: "\(completed)/\(total)", bundle: Strings.bundle)
        }
        public static var windowPeak: String { String(localized: "Critical socialization period", bundle: Strings.bundle) }
        public static var windowOpen: String { String(localized: "In the socialization window", bundle: Strings.bundle) }
        public static var windowClosing: String { String(localized: "Window closing soon", bundle: Strings.bundle) }
        public static var windowJustClosed: String { String(localized: "Window just closed", bundle: Strings.bundle) }
        public static var windowClosed: String { String(localized: "Past socialization window", bundle: Strings.bundle) }
        public static func weeksRemaining(_ weeks: Int) -> String {
            String(localized: "\(weeks) weeks remaining", bundle: Strings.bundle)
        }
        public static var distanceFar: String { String(localized: "Far", bundle: Strings.bundle) }
        public static var distanceNear: String { String(localized: "Near", bundle: Strings.bundle) }
        public static var distanceDirect: String { String(localized: "Direct", bundle: Strings.bundle) }
        public static var distanceFarDescription: String { String(localized: "Observed from a distance", bundle: Strings.bundle) }
        public static var distanceNearDescription: String { String(localized: "Close but no contact", bundle: Strings.bundle) }
        public static var distanceDirectDescription: String { String(localized: "Direct interaction", bundle: Strings.bundle) }
        public static var reactionPositive: String { String(localized: "Positive", bundle: Strings.bundle) }
        public static var reactionNeutral: String { String(localized: "Neutral", bundle: Strings.bundle) }
        public static var reactionUnsure: String { String(localized: "Unsure", bundle: Strings.bundle) }
        public static var reactionFearful: String { String(localized: "Fearful", bundle: Strings.bundle) }
        public static var reactionPositiveDescription: String { String(localized: "Curious, relaxed, playful", bundle: Strings.bundle) }
        public static var reactionNeutralDescription: String { String(localized: "Calm, no reaction — this is the goal!", bundle: Strings.bundle) }
        public static var reactionUnsureDescription: String { String(localized: "Hesitant, ears back, tail low", bundle: Strings.bundle) }
        public static var reactionFearfulDescription: String { String(localized: "Hiding, trembling, trying to escape", bundle: Strings.bundle) }
        public static var logExposure: String { String(localized: "Log Exposure", bundle: Strings.bundle) }
        public static var distance: String { String(localized: "Distance", bundle: Strings.bundle) }
        public static var reaction: String { String(localized: "Reaction", bundle: Strings.bundle) }
        public static var noteOptional: String { String(localized: "Note (optional)", bundle: Strings.bundle) }
        public static var notePlaceholder: String { String(localized: "What happened?", bundle: Strings.bundle) }
        public static var calmIsGoal: String { String(localized: "Calm, neutral behavior is the goal — not interaction!", bundle: Strings.bundle) }
        public static var fearProtocolTitle: String { String(localized: "Tips for Fearful Reactions", bundle: Strings.bundle) }
        public static var fearProtocolTip1: String { String(localized: "Don't force interaction — increase distance", bundle: Strings.bundle) }
        public static var fearProtocolTip2: String { String(localized: "Pair the stimulus with treats (look, treat, look away)", bundle: Strings.bundle) }
        public static var fearProtocolTip3: String { String(localized: "Keep sessions very short", bundle: Strings.bundle) }
        public static var fearProtocolTip4: String { String(localized: "End on a positive note if possible", bundle: Strings.bundle) }
        public static var fearProtocolTip5: String { String(localized: "Consult a professional trainer if fear persists", bundle: Strings.bundle) }
        public static var understood: String { String(localized: "Understood", bundle: Strings.bundle) }
        public static var notStarted: String { String(localized: "Not started", bundle: Strings.bundle) }
        public static var inProgress: String { String(localized: "In progress", bundle: Strings.bundle) }
        public static var almostThere: String { String(localized: "Almost there", bundle: Strings.bundle) }
        public static var comfortableState: String { String(localized: "Comfortable", bundle: Strings.bundle) }
        public static var walkSuggestionsTitle: String { String(localized: "Watch for during walk", bundle: Strings.bundle) }
        public static var walkSuggestionsTip: String { String(localized: "Tap to log exposure", bundle: Strings.bundle) }
        public static func lastExposure(date: String) -> String {
            String(localized: "Last: \(date)", bundle: Strings.bundle)
        }
        public static func exposureCount(_ count: Int) -> String {
            String(localized: "\(count) exposures", bundle: Strings.bundle)
        }
        public static var categoryPeople: String { String(localized: "People", bundle: Strings.bundle) }
        public static var categoryAnimals: String { String(localized: "Animals", bundle: Strings.bundle) }
        public static var categoryVehicles: String { String(localized: "Vehicles", bundle: Strings.bundle) }
        public static var categorySounds: String { String(localized: "Sounds", bundle: Strings.bundle) }
        public static var categoryEnvironments: String { String(localized: "Environments", bundle: Strings.bundle) }
        public static var categorySurfaces: String { String(localized: "Surfaces", bundle: Strings.bundle) }
        public static var categoryHandling: String { String(localized: "Handling", bundle: Strings.bundle) }
        public static var categoryObjects: String { String(localized: "Objects", bundle: Strings.bundle) }
        public static var categoryWeather: String { String(localized: "Weather", bundle: Strings.bundle) }
        public static var noExposuresYet: String { String(localized: "No exposures logged yet", bundle: Strings.bundle) }
        public static var tapToLogFirst: String { String(localized: "Tap to log your first exposure", bundle: Strings.bundle) }
    }
}
