//
//  Strings+TrainingSession.swift
//  Ollie-app
//
//  Localized strings for training session mode
//

import Foundation

extension Strings {

    // MARK: - Training Session
    enum TrainingSession {
        // Session header
        static let clicker = String(localized: "Clicker")

        // Counter
        static let click = String(localized: "Click")
        static let clicks = String(localized: "clicks")

        // Toggles
        static let sound = String(localized: "Sound")
        static let vibration = String(localized: "Vibration")

        // Actions
        static let startTraining = String(localized: "Start Training")
        static let endSession = String(localized: "End Session")

        // Exit confirmation
        static let exitConfirmationTitle = String(localized: "End Session?")
        static let exitConfirmationMessage = String(localized: "You have an active training session. Would you like to save it before exiting?")
        static let exitWithoutSaving = String(localized: "Exit Without Saving")
        static let saveAndExit = String(localized: "Save & Exit")

        // Accessibility
        static let clickerAccessibilityLabel = String(localized: "Clicker button")
        static let clickerAccessibilityHint = String(localized: "Double tap to mark behavior")

        // Info sheet
        static let viewInfo = String(localized: "Info")

        // Last session
        static func lastSession(date: String) -> String {
            String(localized: "Last session: \(date)")
        }
        static let noSessionsYet = String(localized: "No sessions yet")
    }
}
