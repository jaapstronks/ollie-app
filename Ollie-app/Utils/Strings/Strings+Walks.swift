//
//  Strings+Walks.swift
//  Ollie-app
//
//  Walks, locations, and spots strings

import Foundation

extension Strings {

    // MARK: - Walks
    enum Walks {
        // Walk schedule labels
        static let earlyMorning = String(localized: "Early morning")
        static let morningWalk = String(localized: "Morning walk")
        static let midMorning = String(localized: "Mid-morning")
        static let lunchWalk = String(localized: "Lunch walk")
        static let earlyAfternoon = String(localized: "Early afternoon")
        static let afternoonWalk = String(localized: "Afternoon walk")
        static let lateAfternoon = String(localized: "Late afternoon")
        static let eveningWalk = String(localized: "Evening walk")
        static let lateEvening = String(localized: "Late evening")
        static let nightWalk = String(localized: "Night walk")

        // Walk progress
        static func walksProgress(completed: Int, total: Int) -> String {
            String(localized: "\(completed) of \(total) walks")
        }
        static let nextWalk = String(localized: "Next walk")
        static let walksDone = String(localized: "All walks done for today!")
        static func nextWalkSuggestion(time: String) -> String {
            String(localized: "Suggested: ~\(time)")
        }
        static func overdueBy(minutes: Int) -> String {
            String(localized: "\(minutes) min overdue")
        }
        static let noWalkDataYet = String(localized: "Log your first walk to start tracking")
    }

    // MARK: - Walk Locations
    enum WalkLocations {
        static let location = String(localized: "Location")
        static let here = String(localized: "Here")
        static let pickSpot = String(localized: "Pick a spot")
        static let savedSpots = String(localized: "Saved spots")
        static let favorites = String(localized: "Favorites")
        static let recent = String(localized: "Recent")
        static let useCurrentLocation = String(localized: "Use current location")
        static let nameThisSpot = String(localized: "Name this spot")
        static let spotNamePlaceholder = String(localized: "e.g. Park, Trail, Corner")
        static let saveSpot = String(localized: "Save spot")
        static let noFavorites = String(localized: "No favorite spots yet")
        static let noRecentSpots = String(localized: "No recent spots")
        static let addToFavorites = String(localized: "Add to favorites")
        static let removeFromFavorites = String(localized: "Remove from favorites")
        static let deleteSpot = String(localized: "Delete spot")
        static let favoriteSpots = String(localized: "Favorite spots")
        static let manageSpots = String(localized: "Manage spots")
        static let gettingLocation = String(localized: "Getting location...")
        static let locationCaptured = String(localized: "Location captured")
        static let optional = String(localized: "(optional)")
        static let walkLocation = String(localized: "Walk location")
        static let addSpot = String(localized: "Add spot")

        // Spot categories
        static let categoryPark = String(localized: "Park")
        static let categoryTrail = String(localized: "Trail")
        static let categoryNeighborhood = String(localized: "Neighborhood")
        static let categoryBeach = String(localized: "Beach")
        static let categoryForest = String(localized: "Forest")
        static let categoryOther = String(localized: "Other")

        // Errors
        static let locationNotAuthorized = String(localized: "Location access not authorized")
        static let locationUnavailable = String(localized: "Location unavailable")
        static let locationTimeout = String(localized: "Location request timed out")
        static let enableLocationInSettings = String(localized: "Enable location in Settings to capture walk spots")

        // Visit count
        static func visitCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 visit")
            } else {
                return String(localized: "\(count) visits")
            }
        }

        // Map
        static let showOnMap = String(localized: "Show on map")
        static let openInMaps = String(localized: "Open in Maps")
    }

    // MARK: - Spot Detail
    enum SpotDetail {
        static let addSpot = String(localized: "Add Spot")
        static let visits = String(localized: "Visits")
        static let photos = String(localized: "Photos")
        static let created = String(localized: "Created")
        static let deleteConfirmMessage = String(localized: "This will permanently delete this spot.")
        static let notesOptional = String(localized: "Notes (optional)")
        static let recapture = String(localized: "Recapture")
        static let tryAgain = String(localized: "Try again")
        static let pickOnMap = String(localized: "Pick on map")
        static let selectLocation = String(localized: "Select Location")
        static let moveMapToSelect = String(localized: "Move map to position the pin")
        static let photosHere = String(localized: "Photos here")
        static let noPhotosHint = String(localized: "No photos yet. Take one on your next visit!")
    }

    // MARK: - Edit Walk
    enum EditWalk {
        static let title = String(localized: "Edit Walk")
        static let deleteWalk = String(localized: "Delete Walk")
        static let deleteConfirmMessage = String(localized: "This will permanently delete this walk.")
        static let changeSpot = String(localized: "Change")
    }

    // MARK: - Walks Tab
    enum WalksTab {
        static let title = String(localized: "Walks")
        static let walks = String(localized: "walks")
        static let todaysWalks = String(localized: "Today's walks")
        static let noWalksToday = String(localized: "No walks logged today")
        static let startWalk = String(localized: "Start a walk")
        static let yourSpots = String(localized: "Your spots")
        static let nearbySpots = String(localized: "Nearby spots")
        static let allSpots = String(localized: "All spots")
        static let walkWeather = String(localized: "Walk weather")
        static let goodTimeForWalk = String(localized: "Good time for a walk")
        static let notIdealForWalk = String(localized: "Not ideal for a walk")

        static func walksCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 walk")
            } else {
                return String(localized: "\(count) walks")
            }
        }

        static func totalDuration(_ minutes: Int) -> String {
            String(localized: "\(minutes) min total")
        }
    }
}
