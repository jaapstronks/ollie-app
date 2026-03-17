//
//  Strings+Exploration.swift
//  Otis-app
//
//  Exploration and fog of war map strings

import Foundation

private let table = "Walks"

extension Strings {

    // MARK: - Exploration (Fog of War)

    enum Exploration {
        // Settings
        static let sectionTitle = String(localized: "Exploration Map", table: table)
        static let fogOverlayToggle = String(localized: "Show Exploration Fog", table: table)
        static let fogOverlayDescription = String(localized: "Reveals map areas as you walk", table: table)

        // Stats
        static let exploredArea = String(localized: "Explored area", table: table)
        static let tilesExplored = String(localized: "Areas explored", table: table)

        // First time
        static let firstTimeExploring = String(localized: "Start walking to reveal the map!", table: table)

        // Milestones (for future phases)
        static let newAreaDiscovered = String(localized: "New area discovered!", table: table)

        static func exploredAreaValue(_ area: String) -> String {
            String(localized: "\(area) explored", table: table)
        }
    }
}
