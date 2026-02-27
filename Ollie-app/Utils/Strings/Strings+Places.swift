//
//  Strings+Places.swift
//  Ollie-app
//
//  Places tab strings (combined walks, spots, and moments)

import Foundation

private let table = "Places"

extension Strings {

    // MARK: - Places Tab
    enum Places {
        static let title = String(localized: "Places", table: table)

        // View mode toggle
        static let mapView = String(localized: "Map", table: table)
        static let timelineView = String(localized: "Timeline", table: table)

        // Sections
        static let favoriteSpots = String(localized: "Favorite spots", table: table)
        static let recentMoments = String(localized: "Recent moments", table: table)
        static let allSpots = String(localized: "All spots", table: table)

        // Empty states
        static let noSpotsYet = String(localized: "No spots saved yet", table: table)
        static let noSpotsHint = String(localized: "Save your favorite walk locations to see them here", table: table)
        static let noMomentsYet = String(localized: "No moments yet", table: table)
        static let noMomentsHint = String(localized: "Take photos of your adventures to see them here", table: table)
        static let noLocationData = String(localized: "No location", table: table)

        // Timeline
        static let momentsAndWalks = String(localized: "Moments & Walks", table: table)

        // Actions
        static let addSpot = String(localized: "Add spot", table: table)
        static let addMoment = String(localized: "Add moment", table: table)
        static let expandMap = String(localized: "Expand map", table: table)

        // Stats
        static func photoCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 photo", table: table)
            } else {
                return String(localized: "\(count) photos", table: table)
            }
        }
    }
}
