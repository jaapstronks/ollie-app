//
//  LogMealIntent.swift
//  Ollie-app
//
//  App Intent for logging meal events via Siri/Shortcuts

import AppIntents

/// Log that your puppy ate
struct LogMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Meal"
    static var description = IntentDescription("Log that your puppy ate")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        guard profile.canLogEvents else {
            return .result(dialog: "Your free trial has ended. Please upgrade in the Ollie app to continue logging.")
        }

        let event = PuppyEvent(
            time: Date(),
            type: .eten
        )

        do {
            try store.addEvent(event)
            return .result(dialog: "\(profile.name) ate - logged!")
        } catch {
            return .result(dialog: "Failed to log meal: \(error.localizedDescription)")
        }
    }
}
