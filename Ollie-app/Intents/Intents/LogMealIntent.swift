//
//  LogMealIntent.swift
//  Otis-app
//
//  App Intent for logging meal events via Siri/Shortcuts

import AppIntents
import OtisShared

/// Log that your puppy ate
struct LogMealIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Meal"
    static let description = IntentDescription("Log that your puppy ate")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Otis app first.")
        }

        guard profile.canLogEvents else {
            return .result(dialog: "Your free trial has ended. Please upgrade in the Otis app to continue logging.")
        }

        let event = PuppyEvent.meal()

        do {
            try store.addEvent(event)
            return .result(dialog: "\(profile.name) ate - logged!")
        } catch {
            return .result(dialog: "Failed to log meal: \(error.localizedDescription)")
        }
    }
}
