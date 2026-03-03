//
//  Strings+Social.swift
//  Otis-app
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
        static let fearProtocolTitle = String(localized: "Building Confidence Together", table: table)
        static let fearProtocolTip1 = String(localized: "Give more space — distance is your friend", table: table)
        static let fearProtocolTip2 = String(localized: "Pair the stimulus with treats (look, treat, look away)", table: table)
        static let fearProtocolTip3 = String(localized: "Short sessions = big wins", table: table)
        static let fearProtocolTip4 = String(localized: "End on a positive note — even a small one counts", table: table)
        static let fearProtocolTip5 = String(localized: "A professional trainer can help if this continues", table: table)
        static let understood = String(localized: "Got it", table: table)

        // Item states
        static let notStarted = String(localized: "Not started", table: table)
        static let inProgress = String(localized: "In progress", table: table)
        static let almostThere = String(localized: "Almost there", table: table)
        static let comfortableState = String(localized: "Comfortable", table: table)
        static let needsPractice = String(localized: "Needs practice", table: table)

        // Walk suggestions
        static let walkSuggestionsTitle = String(localized: "Watch for during walk", table: table)
        static let walkSuggestionsTip = String(localized: "Tap to log exposure", table: table)
        static let watchFor = String(localized: "Things to watch for", table: table)
        static let seeAll = String(localized: "See all", table: table)
        static func showMore(_ count: Int) -> String {
            String(localized: "Show \(count) more", table: table)
        }
        static let showLess = String(localized: "Show less", table: table)

        // Last exposure
        static func lastExposure(date: String) -> String {
            String(localized: "Last: \(date)", table: table)
        }

        // Social event summary
        static func metName(_ name: String) -> String {
            String(localized: "Met \(name)", table: table, comment: "Summary for social event, e.g. 'Met Luna the Labrador'")
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

        // MARK: - Journey & Phases

        // Phase names
        static let phaseSettlingIn = String(localized: "Settling In", table: table)
        static let phaseFirstSteps = String(localized: "First Steps", table: table)
        static let phaseBuildingConfidence = String(localized: "Building Confidence", table: table)
        static let phasePeakWindow = String(localized: "Peak Window", table: table)
        static let phaseMaintenance = String(localized: "Maintenance", table: table)

        // Phase descriptions
        static let phaseSettlingInDesc = String(localized: "Focus on comfort and basic routine", table: table)
        static let phaseFirstStepsDesc = String(localized: "Home sounds, handling, household members", table: table)
        static let phaseBuildingConfidenceDesc = String(localized: "Neighborhood, common encounters", table: table)
        static let phasePeakWindowDesc = String(localized: "Expand variety, new experiences", table: table)
        static let phaseMaintenanceDesc = String(localized: "Fill gaps, reinforce positives", table: table)

        // Journey card
        static let seeYourJourney = String(localized: "See your journey", table: table)
        static let nextUp = String(localized: "Next up", table: table)
        static let quickCheckMode = String(localized: "Quick Check", table: table)
        static let quickCheckModeDesc = String(localized: "Tap items to mark comfortable", table: table)
        static func phaseProgress(comfortable: Int, total: Int) -> String {
            String(localized: "\(comfortable) of \(total) comfortable", table: table)
        }
        static func dayNumber(_ day: Int) -> String {
            String(localized: "Day \(day)", table: table)
        }
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)", table: table)
        }

        // First visit
        static let firstVisitTitle = String(localized: "Let's see where you're starting", table: table)
        static let firstVisitSubtitle = String(localized: "Your puppy has likely already experienced some things. Let's quickly mark what's familiar.", table: table)
        static let quickCheckButton = String(localized: "Quick check what's familiar", table: table)
        static let startFresh = String(localized: "Start from scratch", table: table)

        // Early milestones
        static let earlyMilestonesTitle = String(localized: "First Days Checklist", table: table)
        static let milestoneFirstNight = String(localized: "First night home", table: table)
        static let milestoneCrateIntro = String(localized: "Crate introduction", table: table)
        static let milestoneFirstOutdoorPotty = String(localized: "First outdoor potty", table: table)
        static let milestoneEatingRoutine = String(localized: "Eating routine", table: table)
        static let milestoneNameResponse = String(localized: "Responds to name", table: table)
        static let milestoneSettledIn = String(localized: "Settled in", table: table)

        // What is socialization info sheet
        static let infoTitle = String(localized: "What is Socialization?", table: table)
        static let infoGoalTitle = String(localized: "The Goal: Calm Neutrality", table: table)
        static let infoGoalBody = String(localized: "Socialization isn't about making your puppy love everything. It's about building calm neutrality — a dog that notices the world and thinks \"yeah, that's normal.\"", table: table)
        static let infoPositiveTitle = String(localized: "What \"positive\" actually means", table: table)
        static let infoPositiveBody = String(localized: "The puppy is exposed to something and nothing bad happens. She observes from a comfortable distance, maybe gets a treat for being calm, and you move on. That's the positive experience — the absence of stress.", table: table)
        static let infoTrapTitle = String(localized: "The over-socialization trap", table: table)
        static let infoTrapBody = String(localized: "Dog parks and \"go meet everyone\" creates excitement, not calm. At 8 months she's lunging at every dog she sees — which started as over-socialization.", table: table)
        static let infoDistanceTitle = String(localized: "Distance is your best tool", table: table)
        static let infoDistanceBody = String(localized: "Most socialization should be observation from a distance. Reward disengagement and looking back at you, not excitement.", table: table)
        static let infoPracticeTitle = String(localized: "In practice", table: table)
        static let infoPracticeBody = String(localized: "Sit near a playground at comfortable distance, reward calm watching. Parallel walks with calm adult dogs. Brief, controlled interactions only occasionally.", table: table)
        static let infoSummary = String(localized: "The goal: walk past a playground without breaking stride.", table: table)

        // Accessibility
        static let journeyTimelineLabel = String(localized: "Socialization journey timeline", table: table)
        static func phaseAccessibility(name: String, isCurrent: Bool) -> String {
            isCurrent
                ? String(localized: "\(name), current phase", table: table)
                : String(localized: "\(name)", table: table)
        }
    }
}
