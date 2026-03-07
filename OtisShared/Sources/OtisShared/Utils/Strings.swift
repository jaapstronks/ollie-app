//
//  Strings.swift
//  OtisShared
//
//  All user-facing strings in one place for easy localization.
//  English is the development language. Dutch translations will be added later.
//
//  Usage: Text(Strings.Timeline.noEvents)
//  For interpolation: Text(Strings.Timeline.dayWith(puppyName: profile.name))

import Foundation

// MARK: - Localized Strings

public enum Strings {
    /// Bundle for localization - set this to your app's bundle to enable localization
    nonisolated(unsafe) public static var bundle: Bundle = .main

    // MARK: - Common
    public enum Common {
        public static var cancel: String { String(localized: "Cancel", bundle: Strings.bundle) }
        public static var save: String { String(localized: "Save", bundle: Strings.bundle) }
        public static var delete: String { String(localized: "Delete", bundle: Strings.bundle) }
        public static var done: String { String(localized: "Done", bundle: Strings.bundle) }
        public static var ok: String { String(localized: "OK", bundle: Strings.bundle) }
        public static var next: String { String(localized: "Next", bundle: Strings.bundle) }
        public static var back: String { String(localized: "Back", bundle: Strings.bundle) }
        public static var edit: String { String(localized: "Edit", bundle: Strings.bundle) }
        public static var undo: String { String(localized: "Undo", bundle: Strings.bundle) }
        public static var error: String { String(localized: "Error", bundle: Strings.bundle) }
        public static var loading: String { String(localized: "Loading...", bundle: Strings.bundle) }
        public static var log: String { String(localized: "Log", bundle: Strings.bundle) }
        public static var start: String { String(localized: "Start!", bundle: Strings.bundle) }
        public static var allow: String { String(localized: "Allow", bundle: Strings.bundle) }
        public static var on: String { String(localized: "On", bundle: Strings.bundle) }
        public static var off: String { String(localized: "Off", bundle: Strings.bundle) }

        // Time units
        public static var minutes: String { String(localized: "min", bundle: Strings.bundle) }
        public static var minutesFull: String { String(localized: "minutes", bundle: Strings.bundle) }
        public static var weeks: String { String(localized: "weeks", bundle: Strings.bundle) }
        public static var days: String { String(localized: "days", bundle: Strings.bundle) }
        public static var hours: String { String(localized: "hours", bundle: Strings.bundle) }

        // Relative dates
        public static var today: String { String(localized: "Today", bundle: Strings.bundle) }
        public static var yesterday: String { String(localized: "Yesterday", bundle: Strings.bundle) }
        public static var tomorrow: String { String(localized: "Tomorrow", bundle: Strings.bundle) }

        // Navigation
        public static var seeAll: String { String(localized: "See all", bundle: Strings.bundle) }
    }

    // MARK: - Duration (Natural Language)
    /// Natural language duration strings for notifications and conversational UI
    public enum Duration {
        public static var aMoment: String { String(localized: "a moment", bundle: Strings.bundle) }
        public static var aFewMinutes: String { String(localized: "a few minutes", bundle: Strings.bundle) }
        public static var halfAnHour: String { String(localized: "half an hour", bundle: Strings.bundle) }
        public static var anHour: String { String(localized: "an hour", bundle: Strings.bundle) }
        public static var anHourAndAHalf: String { String(localized: "an hour and a half", bundle: Strings.bundle) }
        public static var twoHours: String { String(localized: "two hours", bundle: Strings.bundle) }

        public static func minutesNatural(_ minutes: Int) -> String {
            String(localized: "\(minutes) minutes", bundle: Strings.bundle)
        }
        public static func aboutHours(_ hours: Int) -> String {
            String(localized: "about \(hours) hours", bundle: Strings.bundle)
        }
        public static func hoursAndAHalf(_ hours: Int) -> String {
            String(localized: "\(hours) and a half hours", bundle: Strings.bundle)
        }
    }

    // MARK: - App
    public enum App {
        public static var name: String { String(localized: "Otis", bundle: Strings.bundle) }
        public static var subtitle: String { String(localized: "Puppy Tracker", bundle: Strings.bundle) }
        public static var tagline: String { String(localized: "Puppyhood is chaos. Otis brings the calm.", bundle: Strings.bundle) }
    }

    // MARK: - Lifecycle
    /// Strings for lifecycle-aware terminology
    /// Use these to avoid hardcoding "puppy" throughout the app
    public enum Lifecycle {
        // Phase labels
        public static var puppy: String { String(localized: "Puppy", bundle: Strings.bundle) }
        public static var teenage: String { String(localized: "Adolescent", bundle: Strings.bundle) }
        public static var adult: String { String(localized: "Adult", bundle: Strings.bundle) }
        public static var senior: String { String(localized: "Senior", bundle: Strings.bundle) }

        // Generic terms based on phase
        public enum Terms {
            /// "puppy" - for young dogs
            public static var puppy: String { String(localized: "puppy", bundle: Strings.bundle) }
            /// "dog" - for older dogs
            public static var dog: String { String(localized: "dog", bundle: Strings.bundle) }
            /// "puppy's" - possessive for young dogs
            public static var puppyPossessive: String { String(localized: "puppy's", bundle: Strings.bundle) }
            /// "dog's" - possessive for older dogs
            public static var dogPossessive: String { String(localized: "dog's", bundle: Strings.bundle) }
        }

        // Common phrases that need lifecycle awareness
        public enum Phrases {
            /// "Your puppy" or "Your dog" based on lifecycle
            public static func yourPet(isPuppy: Bool) -> String {
                isPuppy
                    ? String(localized: "Your puppy", bundle: Strings.bundle)
                    : String(localized: "Your dog", bundle: Strings.bundle)
            }

            /// "your puppy's" or "your dog's" based on lifecycle
            public static func yourPetPossessive(isPuppy: Bool) -> String {
                isPuppy
                    ? String(localized: "your puppy's", bundle: Strings.bundle)
                    : String(localized: "your dog's", bundle: Strings.bundle)
            }

            /// "{Name}'s day" - always uses the dog's actual name
            public static func petsDay(name: String) -> String {
                String(localized: "\(name)'s day", bundle: Strings.bundle)
            }
        }
    }

    // MARK: - Tabs
    public enum Tabs {
        public static var journal: String { String(localized: "Journal", bundle: Strings.bundle) }
        public static var stats: String { String(localized: "Stats", bundle: Strings.bundle) }
        public static var moments: String { String(localized: "Moments", bundle: Strings.bundle) }
        public static var settings: String { String(localized: "Settings", bundle: Strings.bundle) }
        public static var today: String { String(localized: "Today", bundle: Strings.bundle) }
        public static var insights: String { String(localized: "Insights", bundle: Strings.bundle) }
        public static var train: String { String(localized: "Train", bundle: Strings.bundle) }
        public static var walks: String { String(localized: "Walks", bundle: Strings.bundle) }
        public static var plan: String { String(localized: "Plan", bundle: Strings.bundle) }
    }

    // MARK: - Event Types
    public enum EventType {
        public static var eat: String { String(localized: "Eat", bundle: Strings.bundle) }
        public static var drink: String { String(localized: "Drink", bundle: Strings.bundle) }
        public static var pee: String { String(localized: "Pee", bundle: Strings.bundle) }
        public static var poop: String { String(localized: "Poop", bundle: Strings.bundle) }
        public static var sleep: String { String(localized: "Sleep", bundle: Strings.bundle) }
        public static var wakeUp: String { String(localized: "Wake up", bundle: Strings.bundle) }
        public static var walk: String { String(localized: "Walk", bundle: Strings.bundle) }
        public static var garden: String { String(localized: "Garden", bundle: Strings.bundle) }
        public static var training: String { String(localized: "Training", bundle: Strings.bundle) }
        public static var crate: String { String(localized: "Crate", bundle: Strings.bundle) }
        public static var social: String { String(localized: "Social", bundle: Strings.bundle) }
        public static var milestone: String { String(localized: "Milestone", bundle: Strings.bundle) }
        public static var behavior: String { String(localized: "Behavior", bundle: Strings.bundle) }
        public static var weight: String { String(localized: "Weight", bundle: Strings.bundle) }
        public static var moment: String { String(localized: "Moment", bundle: Strings.bundle) }
        public static var medication: String { String(localized: "Medication", bundle: Strings.bundle) }
    }

    // MARK: - Event Locations
    public enum EventLocation {
        public static var outside: String { String(localized: "Outside", bundle: Strings.bundle) }
        public static var inside: String { String(localized: "Inside", bundle: Strings.bundle) }
    }

    // MARK: - Nap Locations
    public enum NapLocation {
        public static var crate: String { String(localized: "Crate", bundle: Strings.bundle) }
        public static var dogBed: String { String(localized: "Dog bed", bundle: Strings.bundle) }
        public static var other: String { String(localized: "Other", bundle: Strings.bundle) }
        public static var wherePrompt: String { String(localized: "Where?", bundle: Strings.bundle) }
    }

    // MARK: - Size Categories
    public enum SizeCategory {
        public static var small: String { String(localized: "Small (<10kg)", bundle: Strings.bundle) }
        public static var medium: String { String(localized: "Medium (10-25kg)", bundle: Strings.bundle) }
        public static var large: String { String(localized: "Large (25-45kg)", bundle: Strings.bundle) }
        public static var extraLarge: String { String(localized: "Extra large (>45kg)", bundle: Strings.bundle) }

        public static var smallExamples: String { String(localized: "Chihuahua, Maltese, Yorkshire Terrier", bundle: Strings.bundle) }
        public static var mediumExamples: String { String(localized: "Beagle, Cocker Spaniel, Border Collie", bundle: Strings.bundle) }
        public static var largeExamples: String { String(localized: "Labrador, Golden Retriever, German Shepherd", bundle: Strings.bundle) }
        public static var extraLargeExamples: String { String(localized: "Bernese Mountain Dog, Great Dane, Saint Bernard", bundle: Strings.bundle) }
    }

    // MARK: - Gender
    public enum Gender {
        public static var male: String { String(localized: "Male", bundle: Strings.bundle) }
        public static var female: String { String(localized: "Female", bundle: Strings.bundle) }
        public static var preferNotToSay: String { String(localized: "Prefer not to say", bundle: Strings.bundle) }
    }

    // MARK: - Pronouns
    /// Pronouns for referring to dogs based on their gender setting
    public enum Pronouns {
        // Subject pronouns
        public static var he: String { String(localized: "he", bundle: Strings.bundle) }
        public static var she: String { String(localized: "she", bundle: Strings.bundle) }
        public static var they: String { String(localized: "they", bundle: Strings.bundle) }

        // Object pronouns
        public static var him: String { String(localized: "him", bundle: Strings.bundle) }
        public static var her: String { String(localized: "her", bundle: Strings.bundle) }
        public static var them: String { String(localized: "them", bundle: Strings.bundle) }

        // Possessive pronouns
        public static var his: String { String(localized: "his", bundle: Strings.bundle) }
        public static var hers: String { String(localized: "her", bundle: Strings.bundle, comment: "Possessive pronoun for female dogs") }
        public static var their: String { String(localized: "their", bundle: Strings.bundle) }

        // Reflexive pronouns
        public static var himself: String { String(localized: "himself", bundle: Strings.bundle) }
        public static var herself: String { String(localized: "herself", bundle: Strings.bundle) }
        public static var themselves: String { String(localized: "themselves", bundle: Strings.bundle) }
    }

    // MARK: - Meals
    public enum Meals {
        public static var title: String { String(localized: "Edit meals", bundle: Strings.bundle) }
        public static var numberOfMeals: String { String(localized: "Number of meals", bundle: Strings.bundle) }
        public static var mealsPerDay: String { String(localized: "Meals per day", bundle: Strings.bundle) }
        public static func perDay(_ count: Int) -> String {
            String(localized: "\(count)x per day", bundle: Strings.bundle)
        }
        public static var mealsSection: String { String(localized: "Meals", bundle: Strings.bundle) }
        public static var name: String { String(localized: "Name", bundle: Strings.bundle) }
        public static var amount: String { String(localized: "Amount", bundle: Strings.bundle) }
        public static var amountExample: String { String(localized: "e.g. 80g", bundle: Strings.bundle) }
        public static var time: String { String(localized: "Time", bundle: Strings.bundle) }
        public static var breakfast: String { String(localized: "Breakfast", bundle: Strings.bundle) }
        public static var lunch: String { String(localized: "Lunch", bundle: Strings.bundle) }
        public static var afternoon: String { String(localized: "Afternoon", bundle: Strings.bundle) }
        public static var dinner: String { String(localized: "Dinner", bundle: Strings.bundle) }
        public static var morning: String { String(localized: "Morning", bundle: Strings.bundle) }
        public static var evening: String { String(localized: "Evening", bundle: Strings.bundle) }
        public static func mealNumber(_ n: Int) -> String {
            String(localized: "Meal \(n)", bundle: Strings.bundle)
        }
    }

    // MARK: - Timeline
    public enum Timeline {
        public static var previousDay: String { String(localized: "Previous day", bundle: Strings.bundle) }
        public static var nextDay: String { String(localized: "Next day", bundle: Strings.bundle) }
        public static func dateLabel(date: String) -> String {
            String(localized: "Date: \(date)", bundle: Strings.bundle)
        }
        public static var noEvents: String { String(localized: "No events yet", bundle: Strings.bundle) }
        public static var tapToLog: String { String(localized: "Tap below to log the first one", bundle: Strings.bundle) }
        public static var deleteConfirmTitle: String { String(localized: "Delete?", bundle: Strings.bundle) }
        public static func deleteConfirmMessage(event: String, time: String) -> String {
            String(localized: "Are you sure you want to delete '\(event)' from \(time)?", bundle: Strings.bundle)
        }
        public static var eventDeleted: String { String(localized: "Event deleted", bundle: Strings.bundle) }
        public static var undoAccessibility: String { String(localized: "Double-tap Undo to restore", bundle: Strings.bundle) }
        public static var goToTodayHint: String { String(localized: "Double-tap to go to today", bundle: Strings.bundle) }
    }

    // MARK: - Cloud Sharing
    public enum CloudSharing {
        public static var iCloudUnavailable: String { String(localized: "iCloud unavailable", bundle: Strings.bundle) }
        public static var sharedData: String { String(localized: "Shared data", bundle: Strings.bundle) }
        public static var viewingOthersData: String { String(localized: "You're viewing someone else's data", bundle: Strings.bundle) }
        public static var shared: String { String(localized: "Shared", bundle: Strings.bundle) }
        public static var noParticipants: String { String(localized: "No participants yet", bundle: Strings.bundle) }
        public static var manageSharing: String { String(localized: "Manage sharing", bundle: Strings.bundle) }
        public static var stopSharing: String { String(localized: "Stop sharing", bundle: Strings.bundle) }
        public static var shareWithPartner: String { String(localized: "Share with partner", bundle: Strings.bundle) }
        public static var inviteAnother: String { String(localized: "Invite another person", bundle: Strings.bundle) }
        public static var sharing: String { String(localized: "Sharing", bundle: Strings.bundle) }
        public static func sharingDescription(name: String) -> String {
            String(localized: "Share \(name)'s data with your partner so you can both track and log events.", bundle: Strings.bundle)
        }
        /// Legacy static version
        public static var sharingDescription: String { String(localized: "Share data with your partner so you can both track and log events.", bundle: Strings.bundle) }
        public static var stopSharingConfirm: String { String(localized: "Are you sure you want to stop sharing? The other person will lose access.", bundle: Strings.bundle) }
        public static func lastSynced(time: String) -> String {
            String(localized: "Synced \(time)", bundle: Strings.bundle)
        }

        // iCloud status messages
        public static var iCloudStatusUnknown: String { String(localized: "iCloud status unknown", bundle: Strings.bundle) }
        public static var noICloudAccount: String { String(localized: "No iCloud account configured", bundle: Strings.bundle) }
        public static var iCloudRestricted: String { String(localized: "iCloud is restricted", bundle: Strings.bundle) }
        public static var iCloudTemporarilyUnavailable: String { String(localized: "iCloud temporarily unavailable", bundle: Strings.bundle) }
        public static var iCloudNotAvailable: String { String(localized: "iCloud not available", bundle: Strings.bundle) }
        public static var couldNotCheckICloudStatus: String { String(localized: "Could not check iCloud status", bundle: Strings.bundle) }
        public static var saveFailed: String { String(localized: "Save failed", bundle: Strings.bundle) }
        public static var deleteFailed: String { String(localized: "Delete failed", bundle: Strings.bundle) }

        // Participant status
        public static var statusPending: String { String(localized: "Invited", bundle: Strings.bundle) }
        public static var statusAccepted: String { String(localized: "Active", bundle: Strings.bundle) }
        public static var statusRemoved: String { String(localized: "Removed", bundle: Strings.bundle) }

        // Error messages
        public static var cloudKitNotAvailable: String { String(localized: "CloudKit is not available", bundle: Strings.bundle) }
        public static func saveFailedMessage(_ message: String) -> String {
            String(localized: "Save failed: \(message)", bundle: Strings.bundle)
        }
        public static func deleteFailedMessage(_ message: String) -> String {
            String(localized: "Delete failed: \(message)", bundle: Strings.bundle)
        }
        public static func syncFailedMessage(_ message: String) -> String {
            String(localized: "Sync failed: \(message)", bundle: Strings.bundle)
        }
        public static func migrationFailedMessage(_ message: String) -> String {
            String(localized: "Migration failed: \(message)", bundle: Strings.bundle)
        }
        public static var cannotShareAsParticipant: String { String(localized: "You cannot share as a participant", bundle: Strings.bundle) }
        public static var couldNotLoadShare: String { String(localized: "Could not load share", bundle: Strings.bundle) }
    }

    // MARK: - CloudKit Setup
    public enum CloudKitSetup {
        public static func setupFailed(_ error: String) -> String {
            String(localized: "Setup failed: \(error)", bundle: Strings.bundle)
        }
    }

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

    // MARK: - Walks
    public enum Walks {
        public static var earlyMorning: String { String(localized: "Early morning", bundle: Strings.bundle) }
        public static var morningWalk: String { String(localized: "Morning walk", bundle: Strings.bundle) }
        public static var midMorning: String { String(localized: "Mid-morning", bundle: Strings.bundle) }
        public static var lunchWalk: String { String(localized: "Lunch walk", bundle: Strings.bundle) }
        public static var earlyAfternoon: String { String(localized: "Early afternoon", bundle: Strings.bundle) }
        public static var afternoonWalk: String { String(localized: "Afternoon walk", bundle: Strings.bundle) }
        public static var lateAfternoon: String { String(localized: "Late afternoon", bundle: Strings.bundle) }
        public static var eveningWalk: String { String(localized: "Evening walk", bundle: Strings.bundle) }
        public static var lateEvening: String { String(localized: "Late evening", bundle: Strings.bundle) }
        public static var nightWalk: String { String(localized: "Night walk", bundle: Strings.bundle) }
        public static func walksProgress(completed: Int, total: Int) -> String {
            String(localized: "\(completed) of \(total) walks", bundle: Strings.bundle)
        }
        public static var nextWalk: String { String(localized: "Next walk", bundle: Strings.bundle) }
        public static var walksDone: String { String(localized: "All walks done for today!", bundle: Strings.bundle) }
        public static func nextWalkSuggestion(time: String) -> String {
            String(localized: "Suggested: ~\(time)", bundle: Strings.bundle)
        }
        public static func overdueBy(minutes: Int) -> String {
            String(localized: "\(minutes) min overdue", bundle: Strings.bundle)
        }
        public static var noWalkDataYet: String { String(localized: "Log your first walk to start tracking", bundle: Strings.bundle) }
    }

    // MARK: - Walk Locations
    public enum WalkLocations {
        public static var location: String { String(localized: "Location", bundle: Strings.bundle) }
        public static var here: String { String(localized: "Here", bundle: Strings.bundle) }
        public static var pickSpot: String { String(localized: "Pick a spot", bundle: Strings.bundle) }
        public static var savedSpots: String { String(localized: "Saved spots", bundle: Strings.bundle) }
        public static var favorites: String { String(localized: "Favorites", bundle: Strings.bundle) }
        public static var recent: String { String(localized: "Recent", bundle: Strings.bundle) }
        public static var useCurrentLocation: String { String(localized: "Use current location", bundle: Strings.bundle) }
        public static var nameThisSpot: String { String(localized: "Name this spot", bundle: Strings.bundle) }
        public static var spotNamePlaceholder: String { String(localized: "e.g. Park, Trail, Corner", bundle: Strings.bundle) }
        public static var saveSpot: String { String(localized: "Save spot", bundle: Strings.bundle) }
        public static var noFavorites: String { String(localized: "No favorite spots yet", bundle: Strings.bundle) }
        public static var noRecentSpots: String { String(localized: "No recent spots", bundle: Strings.bundle) }
        public static var addToFavorites: String { String(localized: "Add to favorites", bundle: Strings.bundle) }
        public static var removeFromFavorites: String { String(localized: "Remove from favorites", bundle: Strings.bundle) }
        public static var deleteSpot: String { String(localized: "Delete spot", bundle: Strings.bundle) }
        public static var favoriteSpots: String { String(localized: "Favorite spots", bundle: Strings.bundle) }
        public static var manageSpots: String { String(localized: "Manage spots", bundle: Strings.bundle) }
        public static var gettingLocation: String { String(localized: "Getting location...", bundle: Strings.bundle) }
        public static var locationCaptured: String { String(localized: "Location captured", bundle: Strings.bundle) }
        public static var optional: String { String(localized: "(optional)", bundle: Strings.bundle) }
        public static var walkLocation: String { String(localized: "Walk location", bundle: Strings.bundle) }
        public static var addSpot: String { String(localized: "Add spot", bundle: Strings.bundle) }
        public static var categoryPark: String { String(localized: "Park", bundle: Strings.bundle) }
        public static var categoryTrail: String { String(localized: "Trail", bundle: Strings.bundle) }
        public static var categoryNeighborhood: String { String(localized: "Neighborhood", bundle: Strings.bundle) }
        public static var categoryBeach: String { String(localized: "Beach", bundle: Strings.bundle) }
        public static var categoryForest: String { String(localized: "Forest", bundle: Strings.bundle) }
        public static var categoryOther: String { String(localized: "Other", bundle: Strings.bundle) }
        public static var locationNotAuthorized: String { String(localized: "Location access not authorized", bundle: Strings.bundle) }
        public static var locationUnavailable: String { String(localized: "Location unavailable", bundle: Strings.bundle) }
        public static var locationTimeout: String { String(localized: "Location request timed out", bundle: Strings.bundle) }
        public static var enableLocationInSettings: String { String(localized: "Enable location in Settings to capture walk spots", bundle: Strings.bundle) }
        public static func visitCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 visit", bundle: Strings.bundle)
            } else {
                return String(localized: "\(count) visits", bundle: Strings.bundle)
            }
        }
        public static var showOnMap: String { String(localized: "Show on map", bundle: Strings.bundle) }
        public static var openInMaps: String { String(localized: "Open in Maps", bundle: Strings.bundle) }
    }

    // MARK: - Medications
    public enum Medications {
        public static var title: String { String(localized: "Medications", bundle: Strings.bundle) }
        public static var addMedication: String { String(localized: "Add medication", bundle: Strings.bundle) }
        public static var editMedication: String { String(localized: "Edit medication", bundle: Strings.bundle) }
        public static var name: String { String(localized: "Name", bundle: Strings.bundle) }
        public static var instructions: String { String(localized: "Instructions", bundle: Strings.bundle) }
        public static var instructionsPlaceholder: String { String(localized: "Dosage, notes...", bundle: Strings.bundle) }
        public static var schedule: String { String(localized: "Schedule", bundle: Strings.bundle) }
        public static var daily: String { String(localized: "Daily", bundle: Strings.bundle) }
        public static var weekly: String { String(localized: "Weekly", bundle: Strings.bundle) }
        public static var times: String { String(localized: "Times", bundle: Strings.bundle) }
        public static var addTime: String { String(localized: "Add time", bundle: Strings.bundle) }
        public static var linkToMeal: String { String(localized: "Link to meal", bundle: Strings.bundle) }
        public static var startDate: String { String(localized: "Start date", bundle: Strings.bundle) }
        public static var endDate: String { String(localized: "End date", bundle: Strings.bundle) }
        public static var indefinitely: String { String(localized: "Indefinitely", bundle: Strings.bundle) }
        public static var untilDate: String { String(localized: "Until date", bundle: Strings.bundle) }
        public static var markAsDone: String { String(localized: "Slide to complete", bundle: Strings.bundle) }
        public static var overdue: String { String(localized: "Overdue", bundle: Strings.bundle) }
        public static var scheduled: String { String(localized: "scheduled", bundle: Strings.bundle) }
        public static var noMedications: String { String(localized: "No medications", bundle: Strings.bundle) }
        public static func noMedicationsHint(name: String) -> String {
            String(localized: "Tap to add \(name)'s medications", bundle: Strings.bundle)
        }
        /// Legacy static version
        public static var noMedicationsHint: String { String(localized: "Tap to add medications", bundle: Strings.bundle) }
        public static var active: String { String(localized: "Active", bundle: Strings.bundle) }
        public static var paused: String { String(localized: "Paused", bundle: Strings.bundle) }
        public static var icon: String { String(localized: "Icon", bundle: Strings.bundle) }
        public static var daysOfWeek: String { String(localized: "Days of week", bundle: Strings.bundle) }
        public static var duration: String { String(localized: "Duration", bundle: Strings.bundle) }
        public static var sunday: String { String(localized: "Sun", bundle: Strings.bundle) }
        public static var monday: String { String(localized: "Mon", bundle: Strings.bundle) }
        public static var tuesday: String { String(localized: "Tue", bundle: Strings.bundle) }
        public static var wednesday: String { String(localized: "Wed", bundle: Strings.bundle) }
        public static var thursday: String { String(localized: "Thu", bundle: Strings.bundle) }
        public static var friday: String { String(localized: "Fri", bundle: Strings.bundle) }
        public static var saturday: String { String(localized: "Sat", bundle: Strings.bundle) }
        public static func dayShort(_ index: Int) -> String {
            switch index {
            case 0: return sunday
            case 1: return monday
            case 2: return tuesday
            case 3: return wednesday
            case 4: return thursday
            case 5: return friday
            case 6: return saturday
            default: return ""
            }
        }
        public static var deleteConfirmTitle: String { String(localized: "Delete medication?", bundle: Strings.bundle) }
        public static var deleteConfirmMessage: String { String(localized: "This will remove the medication from your schedule.", bundle: Strings.bundle) }
    }

    // MARK: - Notification Settings
    public enum NotificationSettings {
        public static var title: String { String(localized: "Reminders", bundle: Strings.bundle) }
        public static var enableInSettings: String { String(localized: "Enable notifications in Settings to receive reminders.", bundle: Strings.bundle) }
        public static var notificationsDisabled: String { String(localized: "Notifications disabled", bundle: Strings.bundle) }
        public static var enableToReceive: String { String(localized: "Enable notifications to receive reminders", bundle: Strings.bundle) }
        public static var remindersDescription: String { String(localized: "Receive smart reminders for potty, meals, naps, and walks.", bundle: Strings.bundle) }
        public static var pottyReminders: String { String(localized: "Potty reminders", bundle: Strings.bundle) }
        public static var pottyAlarm: String { String(localized: "Potty alarm", bundle: Strings.bundle) }
        public static var mealReminder: String { String(localized: "Meal reminder", bundle: Strings.bundle) }
        public static var mealReminderDescription: String { String(localized: "Reminder before it's time for the next meal.", bundle: Strings.bundle) }
        public static var napNeeded: String { String(localized: "Nap needed", bundle: Strings.bundle) }
        public static func napReminderDescription(name: String) -> String {
            String(localized: "Reminder when \(name) has been awake too long.", bundle: Strings.bundle)
        }
        public static var walkReminders: String { String(localized: "Walk reminders", bundle: Strings.bundle) }
        public static var addWalk: String { String(localized: "Add walk", bundle: Strings.bundle) }
        public static var removeLast: String { String(localized: "Remove last", bundle: Strings.bundle) }
        public static var walks: String { String(localized: "Walks", bundle: Strings.bundle) }
        public static var walkReminderDescription: String { String(localized: "Reminder before it's time for a walk.", bundle: Strings.bundle) }
        public static var pottyLevelEarly: String { String(localized: "Early (~20 min)", bundle: Strings.bundle) }
        public static var pottyLevelSoon: String { String(localized: "Soon (~10 min)", bundle: Strings.bundle) }
        public static var pottyLevelOnTime: String { String(localized: "On time (0 min)", bundle: Strings.bundle) }
        public static var pottyLevelEarlyDesc: String { String(localized: "Reminder when ~20 minutes remaining", bundle: Strings.bundle) }
        public static var pottyLevelSoonDesc: String { String(localized: "Reminder when ~10 minutes remaining", bundle: Strings.bundle) }
        public static var pottyLevelOnTimeDesc: String { String(localized: "Reminder when it's time", bundle: Strings.bundle) }
    }

    // MARK: - Health
    public enum Health {
        public static var title: String { String(localized: "Health", bundle: Strings.bundle) }
        public static var weight: String { String(localized: "Weight", bundle: Strings.bundle) }
        public static var milestones: String { String(localized: "Milestones", bundle: Strings.bundle) }
        public static var noWeightData: String { String(localized: "No weight data yet", bundle: Strings.bundle) }
        public static var logFirstWeight: String { String(localized: "Log your first weight measurement", bundle: Strings.bundle) }
        public static var logWeight: String { String(localized: "Log weight", bundle: Strings.bundle) }
        public static var currentWeight: String { String(localized: "Current weight", bundle: Strings.bundle) }
        public static var growthCurve: String { String(localized: "Growth curve", bundle: Strings.bundle) }
        public static var referenceRange: String { String(localized: "Reference range", bundle: Strings.bundle) }
        public static var weightOnTrack: String { String(localized: "On track", bundle: Strings.bundle) }
        public static var weightAboveReference: String { String(localized: "Above reference", bundle: Strings.bundle) }
        public static var weightBelowReference: String { String(localized: "Below reference", bundle: Strings.bundle) }
        public static func sinceLast(_ delta: String) -> String {
            String(localized: "\(delta) since last", bundle: Strings.bundle)
        }
        public static func sincePrevious(_ delta: String, date: String) -> String {
            String(localized: "\(delta) since \(date)", bundle: Strings.bundle)
        }
        public static var weeks: String { String(localized: "Weeks", bundle: Strings.bundle) }
        public static var kg: String { String(localized: "kg", bundle: Strings.bundle) }
        public static func yourPet(isPuppy: Bool) -> String {
            isPuppy
                ? String(localized: "Your puppy", bundle: Strings.bundle)
                : String(localized: "Your dog", bundle: Strings.bundle)
        }
        /// Legacy static version for backward compatibility
        public static var yourPuppy: String { String(localized: "Your puppy", bundle: Strings.bundle) }
        public static var reference: String { String(localized: "Reference", bundle: Strings.bundle) }
        public static var done: String { String(localized: "Done", bundle: Strings.bundle) }
        public static var nextUp: String { String(localized: "Next up", bundle: Strings.bundle) }
        public static var future: String { String(localized: "Upcoming", bundle: Strings.bundle) }
        public static var overdue: String { String(localized: "Overdue", bundle: Strings.bundle) }
        public static var firstDewormingBreeder: String { String(localized: "First deworming (breeder)", bundle: Strings.bundle) }
        public static var firstVaccination: String { String(localized: "First vaccination (DHP + Lepto)", bundle: Strings.bundle) }
        public static var firstVetVisit: String { String(localized: "First vet visit", bundle: Strings.bundle) }
        public static var firstDewormingHome: String { String(localized: "First deworming (home)", bundle: Strings.bundle) }
        public static var secondVaccination: String { String(localized: "Second vaccination (DHP + Lepto + Rabies)", bundle: Strings.bundle) }
        public static var thirdVaccination: String { String(localized: "Third vaccination (cocktail)", bundle: Strings.bundle) }
        public static var neuteredDiscussion: String { String(localized: "Spay/neuter discussion with vet", bundle: Strings.bundle) }
        public static var yearlyVaccination: String { String(localized: "Yearly vaccination", bundle: Strings.bundle) }
        public static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)", bundle: Strings.bundle)
        }
        public static func monthNumber(_ month: Int) -> String {
            String(localized: "\(month) months", bundle: Strings.bundle)
        }
        public static var weightKg: String { String(localized: "Weight (kg)", bundle: Strings.bundle) }
        public static var enterWeight: String { String(localized: "Enter weight", bundle: Strings.bundle) }
        public static var weightPlaceholder: String { String(localized: "e.g. 8.5", bundle: Strings.bundle) }
    }

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

    // MARK: - Places Discovery
    public enum PlacesDiscovery {
        // Categories
        public static var categoryDogPark: String { String(localized: "Dog park", bundle: Strings.bundle) }
        public static var categoryOffLeash: String { String(localized: "Off-leash area", bundle: Strings.bundle) }
        public static var categoryDogBeach: String { String(localized: "Dog beach", bundle: Strings.bundle) }
        public static var categoryDogForest: String { String(localized: "Dog forest", bundle: Strings.bundle) }
        public static var categoryDogFriendly: String { String(localized: "Dog-friendly park", bundle: Strings.bundle) }
        public static var categoryVetClinic: String { String(localized: "Vet clinic", bundle: Strings.bundle) }
        public static var categoryPetStore: String { String(localized: "Pet store", bundle: Strings.bundle) }
        public static var categoryDogFriendlyCafe: String { String(localized: "Dog-friendly café", bundle: Strings.bundle) }

        // Filter groups
        public static var filterDogAreas: String { String(localized: "Dog Areas", bundle: Strings.bundle) }
        public static var filterVets: String { String(localized: "Vets", bundle: Strings.bundle) }
        public static var filterPetStores: String { String(localized: "Pet Stores", bundle: Strings.bundle) }
        public static var filterDogFriendly: String { String(localized: "Dog-Friendly", bundle: Strings.bundle) }
    }

    // MARK: - Walk Schedule
    public enum WalkSchedule {
        // Mode labels
        public static var modeFlexible: String { String(localized: "Flexible", bundle: Strings.bundle) }
        public static var modeStrict: String { String(localized: "Strict", bundle: Strings.bundle) }
        public static var modeFlexibleDescription: String { String(localized: "Walk times adjust based on when the last walk happened. Good for adapting to real-world timing.", bundle: Strings.bundle) }
        public static var modeStrictDescription: String { String(localized: "Walk times are fixed to the scheduled times. Useful for strict routines or multiple caretakers.", bundle: Strings.bundle) }

        // Duration rule labels
        public static func minutesPerMonthRule(_ minutes: Int) -> String {
            String(localized: "\(minutes) min per month of age", bundle: Strings.bundle)
        }
        public static func fixedMinutesRule(_ minutes: Int) -> String {
            String(localized: "Fixed: \(minutes) min max", bundle: Strings.bundle)
        }

        // Walk numbering
        public static func walkNumber(_ n: Int) -> String {
            String(localized: "Walk \(n)", bundle: Strings.bundle)
        }

        // Section headers
        public static var schedulingMode: String { String(localized: "Scheduling Mode", bundle: Strings.bundle) }
        public static var walksSection: String { String(localized: "Walks", bundle: Strings.bundle) }
        public static var timingSection: String { String(localized: "Timing", bundle: Strings.bundle) }
        public static var dayBoundaries: String { String(localized: "Day Boundaries", bundle: Strings.bundle) }
        public static var exerciseLimits: String { String(localized: "Exercise Limits", bundle: Strings.bundle) }

        // Editor labels
        public static var title: String { String(localized: "Walk Schedule", bundle: Strings.bundle) }
        public static var addWalk: String { String(localized: "Add walk", bundle: Strings.bundle) }
        public static var editWalk: String { String(localized: "Edit walk", bundle: Strings.bundle) }
        public static var intervalBetweenWalks: String { String(localized: "Interval between walks", bundle: Strings.bundle) }
        public static var firstWalkAfter: String { String(localized: "First walk after", bundle: Strings.bundle) }
        public static var lastWalkBefore: String { String(localized: "Last walk before", bundle: Strings.bundle) }
        public static var maxDurationPerWalk: String { String(localized: "Max duration per walk", bundle: Strings.bundle) }
        public static var minutesPerMonth: String { String(localized: "Minutes per month of age", bundle: Strings.bundle) }

        // Footer explanations
        public static var intervalFooter: String { String(localized: "In flexible mode, this is the minimum time between walks.", bundle: Strings.bundle) }
        public static func maxDurationFooter(age: Int, minutes: Int) -> String {
            String(localized: "At \(age) months: max \(minutes) min", bundle: Strings.bundle)
        }

        // Summary
        public static func walksPerDay(_ count: Int) -> String {
            String(localized: "\(count) walks/day", bundle: Strings.bundle)
        }
        public static func intervalSummary(_ minutes: Int) -> String {
            String(localized: "~\(minutes) min interval", bundle: Strings.bundle)
        }
    }

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

        // Interventions (Phase 2)
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

    // MARK: - Health Conditions

    /// Strings for health condition tracking (Brief 03)
    public enum HealthConditions {
        // Categories
        public static var categoryAllergyImmune: String { String(localized: "Allergies & Immune", bundle: Strings.bundle) }
        public static var categoryMusculoskeletal: String { String(localized: "Joints & Mobility", bundle: Strings.bundle) }
        public static var categoryEndocrine: String { String(localized: "Hormonal", bundle: Strings.bundle) }
        public static var categoryCardiac: String { String(localized: "Heart", bundle: Strings.bundle) }
        public static var categoryNeurological: String { String(localized: "Neurological", bundle: Strings.bundle) }
        public static var categoryDigestive: String { String(localized: "Digestive", bundle: Strings.bundle) }
        public static var categoryUrinary: String { String(localized: "Kidney & Urinary", bundle: Strings.bundle) }
        public static var categoryRespiratory: String { String(localized: "Respiratory", bundle: Strings.bundle) }
        public static var categoryEye: String { String(localized: "Eyes", bundle: Strings.bundle) }
        public static var categoryEar: String { String(localized: "Ears", bundle: Strings.bundle) }
        public static var categorySkin: String { String(localized: "Skin", bundle: Strings.bundle) }
        public static var categoryCognitive: String { String(localized: "Cognitive", bundle: Strings.bundle) }
        public static var categoryCancer: String { String(localized: "Cancer", bundle: Strings.bundle) }
        public static var categoryOther: String { String(localized: "Other", bundle: Strings.bundle) }

        // Condition types - Allergies & Immune
        public static var foodAllergy: String { String(localized: "Food Allergy", bundle: Strings.bundle) }
        public static var environmentalAllergy: String { String(localized: "Environmental Allergy", bundle: Strings.bundle) }
        public static var atopicDermatitis: String { String(localized: "Atopic Dermatitis", bundle: Strings.bundle) }
        public static var autoimmune: String { String(localized: "Autoimmune Disease", bundle: Strings.bundle) }

        // Condition types - Musculoskeletal
        public static var hipDysplasia: String { String(localized: "Hip Dysplasia", bundle: Strings.bundle) }
        public static var elbowDysplasia: String { String(localized: "Elbow Dysplasia", bundle: Strings.bundle) }
        public static var arthritis: String { String(localized: "Arthritis", bundle: Strings.bundle) }
        public static var luxatingPatella: String { String(localized: "Luxating Patella", bundle: Strings.bundle) }
        public static var ivdd: String { String(localized: "IVDD (Disc Disease)", bundle: Strings.bundle) }

        // Condition types - Endocrine
        public static var diabetes: String { String(localized: "Diabetes", bundle: Strings.bundle) }
        public static var hypothyroidism: String { String(localized: "Hypothyroidism", bundle: Strings.bundle) }
        public static var hyperthyroidism: String { String(localized: "Hyperthyroidism", bundle: Strings.bundle) }
        public static var cushings: String { String(localized: "Cushing's Disease", bundle: Strings.bundle) }
        public static var addisons: String { String(localized: "Addison's Disease", bundle: Strings.bundle) }

        // Condition types - Cardiac
        public static var heartMurmur: String { String(localized: "Heart Murmur", bundle: Strings.bundle) }
        public static var dilatedCardiomyopathy: String { String(localized: "Dilated Cardiomyopathy", bundle: Strings.bundle) }
        public static var mitralValveDisease: String { String(localized: "Mitral Valve Disease", bundle: Strings.bundle) }
        public static var congestiveHeartFailure: String { String(localized: "Congestive Heart Failure", bundle: Strings.bundle) }

        // Condition types - Neurological
        public static var epilepsy: String { String(localized: "Epilepsy", bundle: Strings.bundle) }
        public static var vestibularDisease: String { String(localized: "Vestibular Disease", bundle: Strings.bundle) }
        public static var degenerativeMyelopathy: String { String(localized: "Degenerative Myelopathy", bundle: Strings.bundle) }

        // Condition types - Digestive
        public static var ibd: String { String(localized: "Inflammatory Bowel Disease", bundle: Strings.bundle) }
        public static var pancreatitis: String { String(localized: "Pancreatitis", bundle: Strings.bundle) }
        public static var megaesophagus: String { String(localized: "Megaesophagus", bundle: Strings.bundle) }
        public static var exocrinePancreaticInsufficiency: String { String(localized: "Exocrine Pancreatic Insufficiency", bundle: Strings.bundle) }

        // Condition types - Urinary/Renal
        public static var chronicKidneyDisease: String { String(localized: "Chronic Kidney Disease", bundle: Strings.bundle) }
        public static var bladderStones: String { String(localized: "Bladder Stones", bundle: Strings.bundle) }
        public static var incontinence: String { String(localized: "Incontinence", bundle: Strings.bundle) }

        // Condition types - Respiratory
        public static var collapsedTrachea: String { String(localized: "Collapsed Trachea", bundle: Strings.bundle) }
        public static var laryngealParalysis: String { String(localized: "Laryngeal Paralysis", bundle: Strings.bundle) }
        public static var brachycephalicSyndrome: String { String(localized: "Brachycephalic Syndrome", bundle: Strings.bundle) }

        // Condition types - Eye
        public static var cataracts: String { String(localized: "Cataracts", bundle: Strings.bundle) }
        public static var glaucoma: String { String(localized: "Glaucoma", bundle: Strings.bundle) }
        public static var progressiveRetinalAtrophy: String { String(localized: "Progressive Retinal Atrophy", bundle: Strings.bundle) }
        public static var dryEye: String { String(localized: "Dry Eye (KCS)", bundle: Strings.bundle) }

        // Condition types - Ear
        public static var chronicOtitis: String { String(localized: "Chronic Ear Infections", bundle: Strings.bundle) }

        // Condition types - Skin
        public static var demodeticMange: String { String(localized: "Demodectic Mange", bundle: Strings.bundle) }
        public static var sebaceousAdenitis: String { String(localized: "Sebaceous Adenitis", bundle: Strings.bundle) }

        // Condition types - Cancer
        public static var mastCellTumor: String { String(localized: "Mast Cell Tumor", bundle: Strings.bundle) }
        public static var lymphoma: String { String(localized: "Lymphoma", bundle: Strings.bundle) }
        public static var osteosarcoma: String { String(localized: "Osteosarcoma", bundle: Strings.bundle) }
        public static var hemangiosarcoma: String { String(localized: "Hemangiosarcoma", bundle: Strings.bundle) }

        // Condition types - Cognitive
        public static var canineCognitiveDysfunction: String { String(localized: "Cognitive Dysfunction", bundle: Strings.bundle) }

        // Other
        public static var otherCondition: String { String(localized: "Other Condition", bundle: Strings.bundle) }

        // Severity levels
        public static var severityMild: String { String(localized: "Mild", bundle: Strings.bundle) }
        public static var severityModerate: String { String(localized: "Moderate", bundle: Strings.bundle) }
        public static var severitySevere: String { String(localized: "Severe", bundle: Strings.bundle) }
        public static var severityManaged: String { String(localized: "Managed", bundle: Strings.bundle) }

        // Status
        public static var statusActive: String { String(localized: "Active", bundle: Strings.bundle) }
        public static var statusMonitoring: String { String(localized: "Monitoring", bundle: Strings.bundle) }
        public static var statusResolved: String { String(localized: "Resolved", bundle: Strings.bundle) }
        public static var statusRemission: String { String(localized: "In Remission", bundle: Strings.bundle) }

        // Monitoring frequency
        public static var frequencyDaily: String { String(localized: "Daily", bundle: Strings.bundle) }
        public static var frequencyWeekly: String { String(localized: "Weekly", bundle: Strings.bundle) }
        public static var frequencyBiweekly: String { String(localized: "Every 2 weeks", bundle: Strings.bundle) }
        public static var frequencyMonthly: String { String(localized: "Monthly", bundle: Strings.bundle) }
        public static var frequencyQuarterly: String { String(localized: "Every 3 months", bundle: Strings.bundle) }

        // Risk levels
        public static var riskLow: String { String(localized: "Low Risk", bundle: Strings.bundle) }
        public static var riskModerate: String { String(localized: "Moderate Risk", bundle: Strings.bundle) }
        public static var riskHigh: String { String(localized: "High Risk", bundle: Strings.bundle) }
        public static var riskVeryHigh: String { String(localized: "Very High Risk", bundle: Strings.bundle) }

        // Warning signals
        public static var warningBreathingRate: String { String(localized: "Resting respiratory rate >30 breaths/min", bundle: Strings.bundle) }
        public static var warningNightCoughing: String { String(localized: "Coughing at night", bundle: Strings.bundle) }
        public static var warningPaleGums: String { String(localized: "Blue or pale gums", bundle: Strings.bundle) }
        public static var warningCollapse: String { String(localized: "Collapse or fainting", bundle: Strings.bundle) }
        public static var warningSuddenLethargy: String { String(localized: "Sudden lethargy or weakness", bundle: Strings.bundle) }
        public static var warningVomiting: String { String(localized: "Vomiting", bundle: Strings.bundle) }
        public static var warningSweetBreath: String { String(localized: "Sweet or fruity breath", bundle: Strings.bundle) }
        public static var warningDisorientation: String { String(localized: "Disorientation", bundle: Strings.bundle) }
        public static var warningClusterSeizures: String { String(localized: "Cluster seizures (2+ in 24 hours)", bundle: Strings.bundle) }
        public static var warningLongSeizure: String { String(localized: "Seizure lasting >5 minutes", bundle: Strings.bundle) }
        public static var warningNoRecovery: String { String(localized: "Not recovering between seizures", bundle: Strings.bundle) }
        public static var warningNotEating: String { String(localized: "Not eating for 24+ hours", bundle: Strings.bundle) }
        public static var warningWeakness: String { String(localized: "Weakness or lethargy", bundle: Strings.bundle) }
        public static var warningBadBreath: String { String(localized: "Ammonia-like breath", bundle: Strings.bundle) }

        // UI Labels
        public static var title: String { String(localized: "Health Conditions", bundle: Strings.bundle) }
        public static var addCondition: String { String(localized: "Add Condition", bundle: Strings.bundle) }
        public static var editCondition: String { String(localized: "Edit Condition", bundle: Strings.bundle) }
        public static var noConditions: String { String(localized: "No health conditions", bundle: Strings.bundle) }
        public static var noConditionsHint: String { String(localized: "Tap to add diagnosed conditions", bundle: Strings.bundle) }
        public static var diagnosedDate: String { String(localized: "Diagnosed", bundle: Strings.bundle) }
        public static var severity: String { String(localized: "Severity", bundle: Strings.bundle) }
        public static var status: String { String(localized: "Status", bundle: Strings.bundle) }
        public static var monitoringFrequency: String { String(localized: "Check-in frequency", bundle: Strings.bundle) }
        public static var vetRecommendations: String { String(localized: "Vet recommendations", bundle: Strings.bundle) }
        public static var linkedMedications: String { String(localized: "Linked medications", bundle: Strings.bundle) }
        public static var breedRelated: String { String(localized: "Breed-related", bundle: Strings.bundle) }
        public static var isGenetic: String { String(localized: "Genetic", bundle: Strings.bundle) }
        public static var needsReview: String { String(localized: "Needs review", bundle: Strings.bundle) }
        public static var lastReviewed: String { String(localized: "Last reviewed", bundle: Strings.bundle) }
        public static var markReviewed: String { String(localized: "Mark as reviewed", bundle: Strings.bundle) }
        public static var customName: String { String(localized: "Condition name", bundle: Strings.bundle) }
        public static var customNamePlaceholder: String { String(localized: "Enter condition name", bundle: Strings.bundle) }
    }

    // MARK: - Symptoms

    /// Strings for symptom tracking
    public enum Symptoms {
        // Categories
        public static var categoryMobility: String { String(localized: "Mobility", bundle: Strings.bundle) }
        public static var categoryNeurological: String { String(localized: "Neurological", bundle: Strings.bundle) }
        public static var categoryRespiratory: String { String(localized: "Respiratory", bundle: Strings.bundle) }
        public static var categoryDigestive: String { String(localized: "Digestive", bundle: Strings.bundle) }
        public static var categoryUrinary: String { String(localized: "Urinary", bundle: Strings.bundle) }
        public static var categorySkin: String { String(localized: "Skin & Coat", bundle: Strings.bundle) }
        public static var categoryEyes: String { String(localized: "Eyes", bundle: Strings.bundle) }
        public static var categoryEars: String { String(localized: "Ears", bundle: Strings.bundle) }
        public static var categoryGeneral: String { String(localized: "General", bundle: Strings.bundle) }
        public static var categoryBehavioral: String { String(localized: "Behavioral", bundle: Strings.bundle) }
        public static var categoryOther: String { String(localized: "Other", bundle: Strings.bundle) }

        // Urgency levels
        public static var urgencyEmergency: String { String(localized: "Emergency - Vet NOW", bundle: Strings.bundle) }
        public static var urgencySoon: String { String(localized: "See vet if persists", bundle: Strings.bundle) }
        public static var urgencyMonitor: String { String(localized: "Monitor and track", bundle: Strings.bundle) }

        // Mobility symptoms
        public static var limping: String { String(localized: "Limping", bundle: Strings.bundle) }
        public static var stiffness: String { String(localized: "Stiffness", bundle: Strings.bundle) }
        public static var difficultyRising: String { String(localized: "Difficulty rising", bundle: Strings.bundle) }
        public static var reluctanceToClimb: String { String(localized: "Reluctance to climb", bundle: Strings.bundle) }
        public static var bunnyHopping: String { String(localized: "Bunny hopping", bundle: Strings.bundle) }
        public static var lamenessRearLegs: String { String(localized: "Rear leg lameness", bundle: Strings.bundle) }
        public static var lamenessFrontLegs: String { String(localized: "Front leg lameness", bundle: Strings.bundle) }

        // Neurological symptoms
        public static var seizure: String { String(localized: "Seizure", bundle: Strings.bundle) }
        public static var trembling: String { String(localized: "Trembling", bundle: Strings.bundle) }
        public static var headTilt: String { String(localized: "Head tilt", bundle: Strings.bundle) }
        public static var circling: String { String(localized: "Circling", bundle: Strings.bundle) }
        public static var confusion: String { String(localized: "Confusion", bundle: Strings.bundle) }
        public static var disorientation: String { String(localized: "Disorientation", bundle: Strings.bundle) }
        public static var lossOfBalance: String { String(localized: "Loss of balance", bundle: Strings.bundle) }

        // Respiratory symptoms
        public static var coughing: String { String(localized: "Coughing", bundle: Strings.bundle) }
        public static var breathingDifficulty: String { String(localized: "Breathing difficulty", bundle: Strings.bundle) }
        public static var rapidBreathing: String { String(localized: "Rapid breathing", bundle: Strings.bundle) }
        public static var reverseSneezing: String { String(localized: "Reverse sneezing", bundle: Strings.bundle) }
        public static var wheezing: String { String(localized: "Wheezing", bundle: Strings.bundle) }

        // Digestive symptoms
        public static var vomiting: String { String(localized: "Vomiting", bundle: Strings.bundle) }
        public static var diarrhea: String { String(localized: "Diarrhea", bundle: Strings.bundle) }
        public static var constipation: String { String(localized: "Constipation", bundle: Strings.bundle) }
        public static var bloating: String { String(localized: "Bloating", bundle: Strings.bundle) }
        public static var appetiteLoss: String { String(localized: "Loss of appetite", bundle: Strings.bundle) }
        public static var excessiveGas: String { String(localized: "Excessive gas", bundle: Strings.bundle) }

        // Urinary symptoms
        public static var frequentUrination: String { String(localized: "Frequent urination", bundle: Strings.bundle) }
        public static var difficultyUrinating: String { String(localized: "Difficulty urinating", bundle: Strings.bundle) }
        public static var bloodInUrine: String { String(localized: "Blood in urine", bundle: Strings.bundle) }
        public static var accidents: String { String(localized: "Accidents in house", bundle: Strings.bundle) }

        // Skin symptoms
        public static var itching: String { String(localized: "Itching/Scratching", bundle: Strings.bundle) }
        public static var hotSpots: String { String(localized: "Hot spots", bundle: Strings.bundle) }
        public static var hairLoss: String { String(localized: "Hair loss", bundle: Strings.bundle) }
        public static var rash: String { String(localized: "Rash", bundle: Strings.bundle) }
        public static var dryCoat: String { String(localized: "Dry coat", bundle: Strings.bundle) }
        public static var excessiveShedding: String { String(localized: "Excessive shedding", bundle: Strings.bundle) }
        public static var pawLicking: String { String(localized: "Paw licking", bundle: Strings.bundle) }
        public static var faceRubbing: String { String(localized: "Face rubbing", bundle: Strings.bundle) }

        // Eye symptoms
        public static var eyeDischarge: String { String(localized: "Eye discharge", bundle: Strings.bundle) }
        public static var eyeRedness: String { String(localized: "Eye redness", bundle: Strings.bundle) }
        public static var cloudiness: String { String(localized: "Cloudiness in eye", bundle: Strings.bundle) }
        public static var squinting: String { String(localized: "Squinting", bundle: Strings.bundle) }
        public static var bumpingIntoThings: String { String(localized: "Bumping into things", bundle: Strings.bundle) }

        // Ear symptoms
        public static var earInfection: String { String(localized: "Ear infection signs", bundle: Strings.bundle) }
        public static var headShaking: String { String(localized: "Head shaking", bundle: Strings.bundle) }
        public static var earOdor: String { String(localized: "Ear odor", bundle: Strings.bundle) }
        public static var scratching: String { String(localized: "Ear scratching", bundle: Strings.bundle) }

        // General symptoms
        public static var lethargy: String { String(localized: "Lethargy", bundle: Strings.bundle) }
        public static var weakness: String { String(localized: "Weakness", bundle: Strings.bundle) }
        public static var weightLoss: String { String(localized: "Weight loss", bundle: Strings.bundle) }
        public static var weightGain: String { String(localized: "Weight gain", bundle: Strings.bundle) }
        public static var excessiveThirst: String { String(localized: "Excessive thirst", bundle: Strings.bundle) }
        public static var drooling: String { String(localized: "Drooling", bundle: Strings.bundle) }
        public static var badBreath: String { String(localized: "Bad breath", bundle: Strings.bundle) }
        public static var fainting: String { String(localized: "Fainting", bundle: Strings.bundle) }
        public static var exerciseIntolerance: String { String(localized: "Exercise intolerance", bundle: Strings.bundle) }
        public static var restlessness: String { String(localized: "Restlessness", bundle: Strings.bundle) }
        public static var panting: String { String(localized: "Excessive panting", bundle: Strings.bundle) }

        // Behavioral symptoms
        public static var anxiety: String { String(localized: "Anxiety", bundle: Strings.bundle) }
        public static var aggression: String { String(localized: "Aggression", bundle: Strings.bundle) }
        public static var hiding: String { String(localized: "Hiding", bundle: Strings.bundle) }
        public static var vocalization: String { String(localized: "Excessive vocalization", bundle: Strings.bundle) }

        // UI Labels
        public static var title: String { String(localized: "Log Symptom", bundle: Strings.bundle) }
        public static var selectSymptom: String { String(localized: "Select symptom", bundle: Strings.bundle) }
        public static var symptomHistory: String { String(localized: "Symptom History", bundle: Strings.bundle) }
        public static var noSymptoms: String { String(localized: "No symptoms logged", bundle: Strings.bundle) }
    }

    // MARK: - Allergies

    /// Strings for allergy tracking
    public enum Allergies {
        // Types
        public static var typeFood: String { String(localized: "Food", bundle: Strings.bundle) }
        public static var typeEnvironmental: String { String(localized: "Environmental", bundle: Strings.bundle) }
        public static var typeMedication: String { String(localized: "Medication", bundle: Strings.bundle) }
        public static var typeContact: String { String(localized: "Contact", bundle: Strings.bundle) }

        // Severity
        public static var severityMild: String { String(localized: "Mild", bundle: Strings.bundle) }
        public static var severityModerate: String { String(localized: "Moderate", bundle: Strings.bundle) }
        public static var severitySevere: String { String(localized: "Severe", bundle: Strings.bundle) }
        public static var severityLifeThreatening: String { String(localized: "Life-threatening", bundle: Strings.bundle) }

        // Severity descriptions
        public static var severityMildDesc: String { String(localized: "Minor symptoms, easily managed", bundle: Strings.bundle) }
        public static var severityModerateDesc: String { String(localized: "Noticeable symptoms, may need treatment", bundle: Strings.bundle) }
        public static var severitySevereDesc: String { String(localized: "Significant reaction, requires vet care", bundle: Strings.bundle) }
        public static var severityLifeThreateningDesc: String { String(localized: "Anaphylactic risk, immediate vet care", bundle: Strings.bundle) }

        // Common allergens - Food
        public static var allergenChicken: String { String(localized: "Chicken", bundle: Strings.bundle) }
        public static var allergenBeef: String { String(localized: "Beef", bundle: Strings.bundle) }
        public static var allergenPork: String { String(localized: "Pork", bundle: Strings.bundle) }
        public static var allergenLamb: String { String(localized: "Lamb", bundle: Strings.bundle) }
        public static var allergenFish: String { String(localized: "Fish", bundle: Strings.bundle) }
        public static var allergenDairy: String { String(localized: "Dairy", bundle: Strings.bundle) }
        public static var allergenEggs: String { String(localized: "Eggs", bundle: Strings.bundle) }
        public static var allergenWheat: String { String(localized: "Wheat", bundle: Strings.bundle) }
        public static var allergenCorn: String { String(localized: "Corn", bundle: Strings.bundle) }
        public static var allergenSoy: String { String(localized: "Soy", bundle: Strings.bundle) }
        public static var allergenRice: String { String(localized: "Rice", bundle: Strings.bundle) }

        // Common allergens - Environmental
        public static var allergenGrass: String { String(localized: "Grass", bundle: Strings.bundle) }
        public static var allergenPollen: String { String(localized: "Pollen", bundle: Strings.bundle) }
        public static var allergenDustMites: String { String(localized: "Dust mites", bundle: Strings.bundle) }
        public static var allergenMold: String { String(localized: "Mold", bundle: Strings.bundle) }
        public static var allergenFleas: String { String(localized: "Fleas", bundle: Strings.bundle) }

        // Common allergens - Contact
        public static var allergenLatex: String { String(localized: "Latex", bundle: Strings.bundle) }
        public static var allergenPlastics: String { String(localized: "Certain plastics", bundle: Strings.bundle) }
        public static var allergenFabrics: String { String(localized: "Certain fabrics", bundle: Strings.bundle) }

        // UI Labels
        public static var title: String { String(localized: "Allergies", bundle: Strings.bundle) }
        public static var addAllergy: String { String(localized: "Add Allergy", bundle: Strings.bundle) }
        public static var editAllergy: String { String(localized: "Edit Allergy", bundle: Strings.bundle) }
        public static var noAllergies: String { String(localized: "No known allergies", bundle: Strings.bundle) }
        public static var noAllergiesHint: String { String(localized: "Tap to add known allergies", bundle: Strings.bundle) }
        public static var allergen: String { String(localized: "Allergen", bundle: Strings.bundle) }
        public static var allergenPlaceholder: String { String(localized: "What causes the reaction?", bundle: Strings.bundle) }
        public static var reaction: String { String(localized: "Reaction", bundle: Strings.bundle) }
        public static var reactionPlaceholder: String { String(localized: "What happens? (itching, swelling, etc.)", bundle: Strings.bundle) }
        public static var confirmedDate: String { String(localized: "Confirmed date", bundle: Strings.bundle) }
        public static var commonAllergens: String { String(localized: "Common allergens", bundle: Strings.bundle) }
        public static var selectType: String { String(localized: "Allergy type", bundle: Strings.bundle) }
        public static var selectSeverity: String { String(localized: "Severity", bundle: Strings.bundle) }
    }
}
