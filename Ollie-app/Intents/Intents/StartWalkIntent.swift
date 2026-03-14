//
//  StartWalkIntent.swift
//  Otis-app
//
//  App Intent for starting a walk with GPS tracking via Siri/Shortcuts/Widget
//

import AppIntents
import OtisShared

/// Start a walk with your puppy - opens the app for GPS tracking
struct StartWalkIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Walk"
    static let description = IntentDescription("Start a walk with GPS tracking")

    // Opens the app to show the walk map view
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Otis app first.")
        }

        guard profile.canLogEvents else {
            return .result(dialog: "Your free trial has ended. Please upgrade in the Otis app to continue logging.")
        }

        // Store the pending walk start - the app will pick this up when it opens
        store.setPendingWalkStart()

        return .result(dialog: "Starting walk with \(profile.name)...")
    }
}

/// End the current walk
struct EndWalkIntent: AppIntent {
    static let title: LocalizedStringResource = "End Walk"
    static let description = IntentDescription("End the current walk")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Otis app first.")
        }

        // For now, just inform the user - actual walk ending needs the app
        // because we need the start time from ActivityTrackingManager
        return .result(dialog: "Please end the walk in the \(profile.name) app to save the route.")
    }
}
