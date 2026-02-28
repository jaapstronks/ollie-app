//
//  Strings.swift
//  OllieShared
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
    public static var bundle: Bundle = .main

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

    // MARK: - App
    public enum App {
        public static var name: String { String(localized: "Ollie", bundle: Strings.bundle) }
        public static var subtitle: String { String(localized: "Puppy Tracker", bundle: Strings.bundle) }
        public static var tagline: String { String(localized: "Puppyhood is chaos. Ollie brings the calm.", bundle: Strings.bundle) }
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
        public static var sharingDescription: String { String(localized: "Share your puppy's data with your partner so you can both track and log events.", bundle: Strings.bundle) }
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
        public static var noMedicationsHint: String { String(localized: "Tap to add your puppy's medications", bundle: Strings.bundle) }
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
        public static var categoryDogPark: String { String(localized: "Dog park", bundle: Strings.bundle) }
        public static var categoryOffLeash: String { String(localized: "Off-leash area", bundle: Strings.bundle) }
        public static var categoryDogBeach: String { String(localized: "Dog beach", bundle: Strings.bundle) }
        public static var categoryDogForest: String { String(localized: "Dog forest", bundle: Strings.bundle) }
        public static var categoryDogFriendly: String { String(localized: "Dog-friendly park", bundle: Strings.bundle) }
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
}
