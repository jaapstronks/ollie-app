//
//  Strings+Places.swift
//  Ollie-app
//
//  Places tab strings (combined walks, spots, and moments)

import Foundation

extension Strings {

    // MARK: - Places Tab
    enum Places {
        static let title = String(localized: "Places")

        // View mode toggle
        static let mapView = String(localized: "Map")
        static let timelineView = String(localized: "Timeline")

        // Sections
        static let favoriteSpots = String(localized: "Favorite spots")
        static let recentMoments = String(localized: "Recent moments")
        static let allSpots = String(localized: "All spots")

        // Empty states
        static let noSpotsYet = String(localized: "No spots saved yet")
        static let noSpotsHint = String(localized: "Save your favorite walk locations to see them here")
        static let noMomentsYet = String(localized: "No moments yet")
        static let noMomentsHint = String(localized: "Take photos of your adventures to see them here")
        static let noLocationData = String(localized: "No location")

        // Timeline
        static let momentsAndWalks = String(localized: "Moments & Walks")

        // Actions
        static let addSpot = String(localized: "Add spot")
        static let addMoment = String(localized: "Add moment")
        static let expandMap = String(localized: "Expand map")

        // Stats
        static func photoCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 photo")
            } else {
                return String(localized: "\(count) photos")
            }
        }
    }
}
