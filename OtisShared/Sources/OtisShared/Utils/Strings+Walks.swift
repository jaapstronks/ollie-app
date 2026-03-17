//
//  Strings+Walks.swift
//  OtisShared
//
//  Walk tracking, locations, and schedule strings.
//

import Foundation

extension Strings {
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
