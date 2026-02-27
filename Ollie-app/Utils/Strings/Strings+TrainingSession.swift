//
//  Strings+TrainingSession.swift
//  Ollie-app
//
//  Localized strings for training session mode
//

import Foundation

private let table = "TrainingSession"

extension Strings {

    // MARK: - Training Session
    enum TrainingSession {
        // Session header
        static let clicker = String(localized: "Clicker", table: table)

        // Counter
        static let click = String(localized: "Click", table: table)
        static let clicks = String(localized: "clicks", table: table)

        // Toggles
        static let sound = String(localized: "Sound", table: table)
        static let vibration = String(localized: "Vibration", table: table)

        // Actions
        static let startTraining = String(localized: "Start Training", table: table)
        static let endSession = String(localized: "End Session", table: table)

        // Exit confirmation
        static let exitConfirmationTitle = String(localized: "End Session?", table: table)
        static let exitConfirmationMessage = String(localized: "You have an active training session. Would you like to save it before exiting?", table: table)
        static let exitWithoutSaving = String(localized: "Exit Without Saving", table: table)
        static let saveAndExit = String(localized: "Save & Exit", table: table)

        // Accessibility
        static let clickerAccessibilityLabel = String(localized: "Clicker button", table: table)
        static let clickerAccessibilityHint = String(localized: "Double tap to mark behavior", table: table)
        static func clickCount(_ count: Int) -> String {
            String(localized: "\(count) clicks", table: table)
        }

        // Info sheet
        static let viewInfo = String(localized: "Info", table: table)

        // Last session
        static func lastSession(date: String) -> String {
            String(localized: "Last session: \(date)", table: table)
        }
        static let noSessionsYet = String(localized: "No sessions yet", table: table)
    }
}
