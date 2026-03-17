//
//  Strings+Walks.swift
//  Otis-app
//
//  Walks, locations, and spots strings

import Foundation

private let table = "Walks"

extension Strings {

    // MARK: - Walks
    enum Walks {
        // Walk schedule labels
        static let earlyMorning = String(localized: "Early morning", table: table)
        static let morningWalk = String(localized: "Morning walk", table: table)
        static let midMorning = String(localized: "Mid-morning", table: table)
        static let lunchWalk = String(localized: "Lunch walk", table: table)
        static let earlyAfternoon = String(localized: "Early afternoon", table: table)
        static let afternoonWalk = String(localized: "Afternoon walk", table: table)
        static let lateAfternoon = String(localized: "Late afternoon", table: table)
        static let eveningWalk = String(localized: "Evening walk", table: table)
        static let lateEvening = String(localized: "Late evening", table: table)
        static let nightWalk = String(localized: "Night walk", table: table)

        // Walk progress
        static func walksProgress(completed: Int, total: Int) -> String {
            String(localized: "\(completed) of \(total) walks", table: table)
        }
        static let nextWalk = String(localized: "Next walk", table: table)
        static let walksDone = String(localized: "All walks done for today!", table: table)
        static func nextWalkSuggestion(time: String) -> String {
            String(localized: "Suggested: ~\(time)", table: table)
        }
        static func overdueBy(minutes: Int) -> String {
            String(localized: "\(minutes) min overdue", table: table)
        }
        static let noWalkDataYet = String(localized: "Log your first walk to start tracking", table: table)
    }

    // MARK: - Walk Locations
    enum WalkLocations {
        static let location = String(localized: "Location", table: table)
        static let here = String(localized: "Here", table: table)
        static let pickSpot = String(localized: "Pick a spot", table: table)
        static let savedSpots = String(localized: "Saved spots", table: table)
        static let favorites = String(localized: "Favorites", table: table)
        static let recent = String(localized: "Recent", table: table)
        static let useCurrentLocation = String(localized: "Use current location", table: table)
        static let nameThisSpot = String(localized: "Name this spot", table: table)
        static let spotNamePlaceholder = String(localized: "e.g. Park, Trail, Corner", table: table)
        static let saveSpot = String(localized: "Save spot", table: table)
        static let noSavedSpots = String(localized: "No saved spots yet", table: table)
        static let noRecentSpots = String(localized: "No recent spots", table: table)
        static let deleteSpot = String(localized: "Delete spot", table: table)
        static let savedPlaces = String(localized: "Saved places", table: table)
        static let manageSpots = String(localized: "Manage spots", table: table)
        static let gettingLocation = String(localized: "Getting location...", table: table)
        static let locationCaptured = String(localized: "Location captured", table: table)
        static let optional = String(localized: "(optional)", table: table)
        static let walkLocation = String(localized: "Walk location", table: table)
        static let addSpot = String(localized: "Add spot", table: table)

        // Spot categories
        static let categoryPark = String(localized: "Park", table: table)
        static let categoryTrail = String(localized: "Trail", table: table)
        static let categoryNeighborhood = String(localized: "Neighborhood", table: table)
        static let categoryBeach = String(localized: "Beach", table: table)
        static let categoryForest = String(localized: "Forest", table: table)
        static let categoryOther = String(localized: "Other", table: table)

        // Errors (nonisolated for use in LocalizedError conformance - hardcoded table name)
        nonisolated static let locationNotAuthorized = String(localized: "Location access not authorized", table: "Walks")
        nonisolated static let locationUnavailable = String(localized: "Location unavailable", table: "Walks")
        nonisolated static let locationTimeout = String(localized: "Location request timed out", table: "Walks")
        static let enableLocationInSettings = String(localized: "Enable location in Settings to capture walk spots", table: table)

        // Visit count
        static func visitCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 visit", table: table)
            } else {
                return String(localized: "\(count) visits", table: table)
            }
        }

        // Map
        static let showOnMap = String(localized: "Show on map", table: table)
        static let openInMaps = String(localized: "Open in Maps", table: table)
    }

    // MARK: - Spot Detail
    enum SpotDetail {
        static let addSpot = String(localized: "Add Spot", table: table)
        static let visits = String(localized: "Visits", table: table)
        static let photos = String(localized: "Photos", table: table)
        static let created = String(localized: "Created", table: table)
        static let deleteConfirmMessage = String(localized: "This will permanently delete this spot.", table: table)
        static let notesOptional = String(localized: "Notes (optional)", table: table)
        static let photoOptional = String(localized: "Photo (optional)", table: table)
        static let recapture = String(localized: "Recapture", table: table)
        static let tryAgain = String(localized: "Try again", table: table)
        static let pickOnMap = String(localized: "Pick on map", table: table)
        static let selectLocation = String(localized: "Select Location", table: table)
        static let moveMapToSelect = String(localized: "Move map to position the pin", table: table)
        static let photosHere = String(localized: "Photos here", table: table)
        static let noPhotosHint = String(localized: "No photos yet. Take one on your next visit!", table: table)

        // Place personality stats
        static let firstVisited = String(localized: "First visited", table: table)
        static let dogsMet = String(localized: "Dogs met", table: table)
        static let pottySuccesses = String(localized: "Potty successes", table: table)
        static let placeStats = String(localized: "Place stats", table: table)
    }

    // MARK: - Edit Walk
    enum EditWalk {
        static let title = String(localized: "Edit Walk", table: table)
        static let deleteWalk = String(localized: "Delete Walk", table: table)
        static let deleteConfirmMessage = String(localized: "This will permanently delete this walk.", table: table)
        static let changeSpot = String(localized: "Change", table: table)
    }

    // MARK: - Walk Target Nudge
    enum WalkNudge {
        static let title = String(localized: "Walk schedule review", table: table)

        /// Formats the average into natural language like "about 5" or "5 to 6"
        static func formatAverage(_ average: Double) -> String {
            let rounded = Int(average.rounded())
            let decimal = average - Double(Int(average))

            // 4.8-5.2 → "about 5", 5.3-5.8 → "5 to 6"
            if decimal >= 0.3 && decimal <= 0.8 {
                return String(localized: "\(rounded) to \(rounded + 1)", table: table, comment: "Range format like '5 to 6'")
            } else {
                return String(localized: "about \(rounded)", table: table, comment: "Approximate format like 'about 5'")
            }
        }

        static func subtitle(actual: String, target: Int) -> String {
            String(localized: "You log \(actual) walks per day, but your target is \(target). Adjust?", table: table)
        }
        static let keepTarget = String(localized: "Keep it", table: table)
        static let adjustSchedule = String(localized: "Adjust", table: table)
    }

    // MARK: - Walk Summary Card
    enum WalkSummary {
        static let title = String(localized: "This Week", table: table)

        static func minutes(_ count: Int) -> String {
            String(localized: "\(count) min", table: table)
        }

        static func hours(_ hours: Double) -> String {
            let rounded = String(format: "%.1f", hours)
            return String(localized: "\(rounded) hours", table: table)
        }

        static func daysProgress(days: Int) -> String {
            String(localized: "\(days)/7 days", table: table)
        }

        static func accessibilityLabel(walks: Int, days: Int) -> String {
            String(localized: "Weekly walk summary: \(walks) walks over \(days) days", table: table)
        }
    }

    // MARK: - Walks Tab
    enum WalksTab {
        static let title = String(localized: "Walks", table: table)
        static let walks = String(localized: "walks", table: table)
        static let todaysWalks = String(localized: "Today's walks", table: table)
        static let noWalksToday = String(localized: "No walks logged today", table: table)
        static let startWalk = String(localized: "Start a walk", table: table)
        static let yourSpots = String(localized: "Your spots", table: table)
        static let nearbySpots = String(localized: "Nearby spots", table: table)
        static let allSpots = String(localized: "All spots", table: table)
        static let walkWeather = String(localized: "Walk weather", table: table)
        static let goodTimeForWalk = String(localized: "Good time for a walk", table: table)
        static let notIdealForWalk = String(localized: "Not ideal for a walk", table: table)

        static func walksCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 walk", table: table)
            } else {
                return String(localized: "\(count) walks", table: table)
            }
        }

        static func totalDuration(_ minutes: Int) -> String {
            String(localized: "\(minutes) min total", table: table)
        }
    }

    // MARK: - Walk Map (GPS Tracking)
    enum WalkMap {
        static let duration = String(localized: "Duration", table: table)
        static let distance = String(localized: "Distance", table: table)
        static let endWalk = String(localized: "End Walk", table: table)
        static let endWalkQuestion = String(localized: "End this walk?", table: table)
    }
}
