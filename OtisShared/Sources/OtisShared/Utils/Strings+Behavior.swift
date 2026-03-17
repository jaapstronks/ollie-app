//
//  Strings+Behavior.swift
//  OtisShared
//
//  Behavior incident tracking and support strings.
//

import Foundation

extension Strings {
    // MARK: - Behavior Incidents
    public enum Behavior {
        // Sheet titles
        public static var title: String { String(localized: "Log Behavior", bundle: Strings.bundle) }
        public static var logIncident: String { String(localized: "Log Incident", bundle: Strings.bundle) }
        public static var whatHappened: String { String(localized: "What happened?", bundle: Strings.bundle) }
        public static var selectCategory: String { String(localized: "Select category", bundle: Strings.bundle) }
        public static var trigger: String { String(localized: "Trigger", bundle: Strings.bundle) }
        public static var triggerPlaceholder: String { String(localized: "What triggered this?", bundle: Strings.bundle) }
        public static var intensity: String { String(localized: "Intensity", bundle: Strings.bundle) }
        public static var howIntense: String { String(localized: "How intense was it?", bundle: Strings.bundle) }
        public static var outcome: String { String(localized: "Outcome", bundle: Strings.bundle) }
        public static var whatHappenedAfter: String { String(localized: "What happened after?", bundle: Strings.bundle) }
        public static var context: String { String(localized: "Context", bundle: Strings.bundle) }
        public static var whereDidItHappen: String { String(localized: "Where did it happen?", bundle: Strings.bundle) }
        public static var notes: String { String(localized: "Notes", bundle: Strings.bundle) }
        public static var notesPlaceholder: String { String(localized: "Any other details...", bundle: Strings.bundle) }

        // Category labels
        public static var categoryReactivity: String { String(localized: "Reactivity", bundle: Strings.bundle) }
        public static var categoryAnxiety: String { String(localized: "Anxiety", bundle: Strings.bundle) }
        public static var categoryDestructive: String { String(localized: "Destructive", bundle: Strings.bundle) }
        public static var categoryBarking: String { String(localized: "Barking", bundle: Strings.bundle) }
        public static var categoryGuarding: String { String(localized: "Guarding", bundle: Strings.bundle) }
        public static var categoryJumping: String { String(localized: "Jumping", bundle: Strings.bundle) }
        public static var categoryPulling: String { String(localized: "Pulling", bundle: Strings.bundle) }
        public static var categoryRecall: String { String(localized: "Recall Issues", bundle: Strings.bundle) }
        public static var categoryMouthing: String { String(localized: "Mouthing", bundle: Strings.bundle) }
        public static var categoryFearful: String { String(localized: "Fearful", bundle: Strings.bundle) }

        // Category descriptions
        public static var descReactivity: String { String(localized: "Lunging, barking at triggers", bundle: Strings.bundle) }
        public static var descAnxiety: String { String(localized: "Panting, pacing, whining", bundle: Strings.bundle) }
        public static var descDestructive: String { String(localized: "Chewing, digging inappropriately", bundle: Strings.bundle) }
        public static var descBarking: String { String(localized: "Excessive vocalization", bundle: Strings.bundle) }
        public static var descGuarding: String { String(localized: "Protecting resources aggressively", bundle: Strings.bundle) }
        public static var descJumping: String { String(localized: "Jumping on people", bundle: Strings.bundle) }
        public static var descPulling: String { String(localized: "Pulling hard on leash", bundle: Strings.bundle) }
        public static var descRecall: String { String(localized: "Not coming when called", bundle: Strings.bundle) }
        public static var descMouthing: String { String(localized: "Inappropriate mouthing or nipping", bundle: Strings.bundle) }
        public static var descFearful: String { String(localized: "Cowering, hiding, trembling", bundle: Strings.bundle) }

        // Intensity levels
        public static var intensityMild: String { String(localized: "Mild", bundle: Strings.bundle) }
        public static var intensityLow: String { String(localized: "Low", bundle: Strings.bundle) }
        public static var intensityModerate: String { String(localized: "Moderate", bundle: Strings.bundle) }
        public static var intensityHigh: String { String(localized: "High", bundle: Strings.bundle) }
        public static var intensitySevere: String { String(localized: "Severe", bundle: Strings.bundle) }

        // Intensity descriptions
        public static var intensityMildDesc: String { String(localized: "Brief, easily redirected", bundle: Strings.bundle) }
        public static var intensityLowDesc: String { String(localized: "Noticeable but manageable", bundle: Strings.bundle) }
        public static var intensityModerateDesc: String { String(localized: "Required intervention", bundle: Strings.bundle) }
        public static var intensityHighDesc: String { String(localized: "Difficult to manage", bundle: Strings.bundle) }
        public static var intensitySevereDesc: String { String(localized: "Extreme, concerning", bundle: Strings.bundle) }

        // Outcome labels
        public static var outcomeRedirected: String { String(localized: "Redirected successfully", bundle: Strings.bundle) }
        public static var outcomeEscalated: String { String(localized: "Escalated", bundle: Strings.bundle) }
        public static var outcomeSelfResolved: String { String(localized: "Calmed on their own", bundle: Strings.bundle) }
        public static var outcomeRemoved: String { String(localized: "Had to remove from situation", bundle: Strings.bundle) }
        public static var outcomeManaged: String { String(localized: "Managed but challenging", bundle: Strings.bundle) }

        // Context labels
        public static var contextHome: String { String(localized: "Home", bundle: Strings.bundle) }
        public static var contextWalk: String { String(localized: "On a walk", bundle: Strings.bundle) }
        public static var contextPark: String { String(localized: "At the park", bundle: Strings.bundle) }
        public static var contextVet: String { String(localized: "Vet clinic", bundle: Strings.bundle) }
        public static var contextCar: String { String(localized: "In the car", bundle: Strings.bundle) }
        public static var contextPublic: String { String(localized: "Public place", bundle: Strings.bundle) }
        public static var contextOther: String { String(localized: "Other", bundle: Strings.bundle) }

        // Common triggers
        public static var triggerOtherDogs: String { String(localized: "Other dogs", bundle: Strings.bundle) }
        public static var triggerStrangers: String { String(localized: "Strangers", bundle: Strings.bundle) }
        public static var triggerBicycles: String { String(localized: "Bicycles", bundle: Strings.bundle) }
        public static var triggerVehicles: String { String(localized: "Vehicles", bundle: Strings.bundle) }
        public static var triggerChildren: String { String(localized: "Children", bundle: Strings.bundle) }
        public static var triggerAlone: String { String(localized: "Being alone", bundle: Strings.bundle) }
        public static var triggerLoudNoises: String { String(localized: "Loud noises", bundle: Strings.bundle) }
        public static var triggerNewEnvironment: String { String(localized: "New environment", bundle: Strings.bundle) }
        public static var triggerCarRides: String { String(localized: "Car rides", bundle: Strings.bundle) }
        public static var triggerVetVisit: String { String(localized: "Vet visit", bundle: Strings.bundle) }
        public static var triggerBoredom: String { String(localized: "Boredom", bundle: Strings.bundle) }
        public static var triggerTeething: String { String(localized: "Teething", bundle: Strings.bundle) }
        public static var triggerExcess: String { String(localized: "Excess energy", bundle: Strings.bundle) }
        public static var triggerDoorbell: String { String(localized: "Doorbell", bundle: Strings.bundle) }
        public static var triggerPassersby: String { String(localized: "Passersby", bundle: Strings.bundle) }
        public static var triggerAttentionSeeking: String { String(localized: "Attention seeking", bundle: Strings.bundle) }
        public static var triggerFood: String { String(localized: "Food", bundle: Strings.bundle) }
        public static var triggerToys: String { String(localized: "Toys", bundle: Strings.bundle) }
        public static var triggerBed: String { String(localized: "Bed/resting spot", bundle: Strings.bundle) }
        public static var triggerOwner: String { String(localized: "Owner", bundle: Strings.bundle) }
        public static var triggerHighValueTreats: String { String(localized: "High-value treats", bundle: Strings.bundle) }
        public static var triggerGreeting: String { String(localized: "Greeting people", bundle: Strings.bundle) }
        public static var triggerExcitement: String { String(localized: "Excitement", bundle: Strings.bundle) }
        public static var triggerScents: String { String(localized: "Interesting scents", bundle: Strings.bundle) }
        public static var triggerSquirrels: String { String(localized: "Squirrels/wildlife", bundle: Strings.bundle) }
        public static var triggerDistractions: String { String(localized: "Distractions", bundle: Strings.bundle) }
        public static var triggerPlay: String { String(localized: "During play", bundle: Strings.bundle) }
        public static var triggerOverstimulation: String { String(localized: "Overstimulation", bundle: Strings.bundle) }
        public static var triggerObjects: String { String(localized: "Unfamiliar objects", bundle: Strings.bundle) }

        // Trends view
        public static var trends: String { String(localized: "Behavior Trends", bundle: Strings.bundle) }
        public static var noIncidentsYet: String { String(localized: "No behavior incidents logged yet", bundle: Strings.bundle) }
        public static var trackPatterns: String { String(localized: "Track incidents to identify patterns", bundle: Strings.bundle) }
        public static var recentIncidents: String { String(localized: "Recent Incidents", bundle: Strings.bundle) }
        public static var thisWeek: String { String(localized: "This week", bundle: Strings.bundle) }
        public static var lastWeek: String { String(localized: "Last week", bundle: Strings.bundle) }
        public static func incidentCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 incident", bundle: Strings.bundle)
            }
            return String(localized: "\(count) incidents", bundle: Strings.bundle)
        }
    }

    // MARK: - Behavior Support Module
    /// Strings for the Behavior Support module in the Train tab
    public enum BehaviorSupport {
        // Card & Navigation
        public static var title: String { String(localized: "Behavior Support", bundle: Strings.bundle) }
        public static var subtitle: String { String(localized: "Track and manage behavior challenges", bundle: Strings.bundle) }
        public static var viewAll: String { String(localized: "View All", bundle: Strings.bundle) }
        public static var logIncident: String { String(localized: "Log Incident", bundle: Strings.bundle) }

        // Professional Disclaimer
        public static var disclaimerTitle: String { String(localized: "Professional Guidance Recommended", bundle: Strings.bundle) }
        public static var disclaimerBody: String { String(localized: "Behavior challenges can have medical or complex causes. We recommend working with a certified dog trainer or veterinary behaviorist for persistent issues. This guidance is educational only.", bundle: Strings.bundle) }
        public static var learnMore: String { String(localized: "Learn More", bundle: Strings.bundle) }

        // Active Issues
        public static var activeIssues: String { String(localized: "Active Issues", bundle: Strings.bundle) }
        public static var noActiveIssues: String { String(localized: "No behavior incidents logged recently", bundle: Strings.bundle) }
        public static var noActiveIssuesDescription: String { String(localized: "Log incidents when they happen to identify patterns and track progress", bundle: Strings.bundle) }

        // Trend indicators
        public static var trendImproving: String { String(localized: "Improving", bundle: Strings.bundle) }
        public static var trendStable: String { String(localized: "Stable", bundle: Strings.bundle) }
        public static var trendWorsening: String { String(localized: "Needs attention", bundle: Strings.bundle) }
        public static var trendNew: String { String(localized: "New this week", bundle: Strings.bundle) }

        // Time periods
        public static var last7Days: String { String(localized: "Last 7 days", bundle: Strings.bundle) }
        public static var last30Days: String { String(localized: "Last 30 days", bundle: Strings.bundle) }
        public static func incidentsThisWeek(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 incident this week", bundle: Strings.bundle)
            }
            return String(localized: "\(count) incidents this week", bundle: Strings.bundle)
        }

        // Interventions
        public static var interventions: String { String(localized: "What You're Trying", bundle: Strings.bundle) }
        public static var addIntervention: String { String(localized: "Add Intervention", bundle: Strings.bundle) }
        public static var noInterventions: String { String(localized: "No interventions added yet", bundle: Strings.bundle) }
        public static var noInterventionsDescription: String { String(localized: "Track what your trainer recommends or techniques you're trying", bundle: Strings.bundle) }
        public static var interventionPlaceholder: String { String(localized: "e.g., Counter-conditioning with treats", bundle: Strings.bundle) }

        // Progress
        public static var progress: String { String(localized: "Progress", bundle: Strings.bundle) }
        public static var progressNotes: String { String(localized: "Progress Notes", bundle: Strings.bundle) }
        public static var addNote: String { String(localized: "Add Note", bundle: Strings.bundle) }
        public static var progressSummary: String { String(localized: "Progress Summary", bundle: Strings.bundle) }
        public static var thisWeek: String { String(localized: "This Week", bundle: Strings.bundle) }
        public static var previousWeek: String { String(localized: "Previous Week", bundle: Strings.bundle) }
        public static var activePractice: String { String(localized: "Actively Practicing", bundle: Strings.bundle) }
        public static func fewerIncidents(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 fewer incident than last week", bundle: Strings.bundle)
            }
            return String(localized: "\(count) fewer incidents than last week", bundle: Strings.bundle)
        }
        public static func moreIncidents(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 more incident than last week", bundle: Strings.bundle)
            }
            return String(localized: "\(count) more incidents than last week", bundle: Strings.bundle)
        }
        public static var sameAsLastWeek: String { String(localized: "Same as last week", bundle: Strings.bundle) }

        // Common triggers summary
        public static var commonTriggers: String { String(localized: "Common Triggers", bundle: Strings.bundle) }

        // Accessibility
        public static var behaviorSupportAccessibilityLabel: String { String(localized: "Behavior support section showing active behavior issues and logging options", bundle: Strings.bundle) }

        // MARK: - Intervention Templates
        // Intervention names
        public static var interventionCounterConditioning: String { String(localized: "Counter-conditioning", bundle: Strings.bundle) }
        public static var interventionDesensitization: String { String(localized: "Desensitization", bundle: Strings.bundle) }
        public static var interventionBAT: String { String(localized: "BAT Training", bundle: Strings.bundle) }
        public static var interventionRelaxation: String { String(localized: "Relaxation Protocol", bundle: Strings.bundle) }
        public static var interventionManagement: String { String(localized: "Management Only", bundle: Strings.bundle) }
        public static var interventionAvoidTriggers: String { String(localized: "Avoid Triggers", bundle: Strings.bundle) }
        public static var interventionShorterWalks: String { String(localized: "Shorter Walks", bundle: Strings.bundle) }
        public static var interventionQuieterRoutes: String { String(localized: "Quieter Routes", bundle: Strings.bundle) }
        public static var interventionMoreExercise: String { String(localized: "More Exercise", bundle: Strings.bundle) }
        public static var interventionEnrichment: String { String(localized: "Mental Enrichment", bundle: Strings.bundle) }
        public static var interventionTradeUp: String { String(localized: "Trade-Up Game", bundle: Strings.bundle) }
        public static var interventionLeaveIt: String { String(localized: "Leave It Command", bundle: Strings.bundle) }
        public static var interventionInterrupter: String { String(localized: "Positive Interrupter", bundle: Strings.bundle) }
        public static var interventionCalming: String { String(localized: "Calming Signals", bundle: Strings.bundle) }
        public static var interventionThundershirt: String { String(localized: "Thundershirt/Anxiety Wrap", bundle: Strings.bundle) }
        public static var interventionMedication: String { String(localized: "Medication Support", bundle: Strings.bundle) }
        public static var interventionTrainer: String { String(localized: "Trainer Sessions", bundle: Strings.bundle) }
        public static var interventionCustom: String { String(localized: "Custom Intervention", bundle: Strings.bundle) }

        // Intervention descriptions
        public static var interventionCounterConditioningDesc: String { String(localized: "Pair the trigger with something positive (treats, play) to change emotional response", bundle: Strings.bundle) }
        public static var interventionDesensitizationDesc: String { String(localized: "Gradually expose to trigger at low intensity, increasing slowly over time", bundle: Strings.bundle) }
        public static var interventionBATDesc: String { String(localized: "Behavior Adjustment Training - give dog choice to disengage from trigger", bundle: Strings.bundle) }
        public static var interventionRelaxationDesc: String { String(localized: "Teach calm, relaxed behavior through structured protocol exercises", bundle: Strings.bundle) }
        public static var interventionManagementDesc: String { String(localized: "Prevent the behavior from occurring through environmental control", bundle: Strings.bundle) }
        public static var interventionAvoidTriggersDesc: String { String(localized: "Temporarily avoid known triggers while working on other interventions", bundle: Strings.bundle) }
        public static var interventionShorterWalksDesc: String { String(localized: "Reduce walk length to prevent over-threshold experiences", bundle: Strings.bundle) }
        public static var interventionQuieterRoutesDesc: String { String(localized: "Choose calmer routes with fewer triggers", bundle: Strings.bundle) }
        public static var interventionMoreExerciseDesc: String { String(localized: "Increase physical exercise to reduce excess energy", bundle: Strings.bundle) }
        public static var interventionEnrichmentDesc: String { String(localized: "Puzzle toys, sniff walks, training games for mental stimulation", bundle: Strings.bundle) }
        public static var interventionTradeUpDesc: String { String(localized: "Teach dropping items in exchange for higher-value rewards", bundle: Strings.bundle) }
        public static var interventionLeaveItDesc: String { String(localized: "Teach to ignore items or triggers on cue", bundle: Strings.bundle) }
        public static var interventionInterrupterDesc: String { String(localized: "A trained cue to redirect attention (e.g., emergency recall)", bundle: Strings.bundle) }
        public static var interventionCalmingDesc: String { String(localized: "Learn and respond to dog's calming signals appropriately", bundle: Strings.bundle) }
        public static var interventionThundershirtDesc: String { String(localized: "Pressure wrap to help with anxiety and fear responses", bundle: Strings.bundle) }
        public static var interventionMedicationDesc: String { String(localized: "Veterinary-prescribed medication support (always consult vet)", bundle: Strings.bundle) }
        public static var interventionTrainerDesc: String { String(localized: "Working with a certified professional dog trainer", bundle: Strings.bundle) }
        public static var interventionCustomDesc: String { String(localized: "Your own intervention or technique", bundle: Strings.bundle) }

        // Intervention logging
        public static var markPracticed: String { String(localized: "Mark Practiced", bundle: Strings.bundle) }
        public static var practicedToday: String { String(localized: "Practiced today", bundle: Strings.bundle) }
        public static func practicedCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "Practiced 1 time this week", bundle: Strings.bundle)
            }
            return String(localized: "Practiced \(count) times this week", bundle: Strings.bundle)
        }
        public static func lastPracticed(days: Int) -> String {
            if days == 0 {
                return String(localized: "Last practiced today", bundle: Strings.bundle)
            } else if days == 1 {
                return String(localized: "Last practiced yesterday", bundle: Strings.bundle)
            }
            return String(localized: "Last practiced \(days) days ago", bundle: Strings.bundle)
        }
        public static var selectIntervention: String { String(localized: "Select Intervention", bundle: Strings.bundle) }
        public static var suggestedInterventions: String { String(localized: "Suggested for this issue", bundle: Strings.bundle) }
        public static var allInterventions: String { String(localized: "All interventions", bundle: Strings.bundle) }
        public static var notesOptional: String { String(localized: "Notes (optional)", bundle: Strings.bundle) }
        public static var interventionNotes: String { String(localized: "What your trainer recommended or your plan", bundle: Strings.bundle) }
    }
}
