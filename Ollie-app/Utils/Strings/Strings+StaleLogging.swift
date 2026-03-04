//
//  Strings+StaleLogging.swift
//  Otis-app
//
//  Localized strings for stale logging feature
//

import Foundation

extension Strings {
    enum StaleLogging {
        // Banner content
        static let bannerTitle = String(localized: "Haven't logged in a while?", table: "StaleLogging")
        static let bannerSubtitle = String(localized: "That's okay! Tap below to start fresh.", table: "StaleLogging")

        // Actions
        static let startFresh = String(localized: "Start fresh", table: "StaleLogging")

        // Accessibility
        static let bannerAccessibilityLabel = String(localized: "Logging gap detected. Tap to start fresh.", table: "StaleLogging")
    }
}
