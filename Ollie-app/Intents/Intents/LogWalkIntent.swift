//
//  LogWalkIntent.swift
//  Ollie-app
//
//  App Intent for logging walk events via Siri/Shortcuts

import AppIntents
import OllieShared

/// Log a walk with optional duration
struct LogWalkIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Walk"
    static var description = IntentDescription("Log a walk with your puppy")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Duration (minutes)", description: "How long was the walk in minutes")
    var durationMinutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Log walk") {
            \.$durationMinutes
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        guard profile.canLogEvents else {
            return .result(dialog: "Your free trial has ended. Please upgrade in the Ollie app to continue logging.")
        }

        let event = PuppyEvent.walk(durationMin: durationMinutes)

        do {
            try store.addEvent(event)

            if let duration = durationMinutes {
                return .result(dialog: "Logged \(duration) minute walk with \(profile.name)")
            } else {
                return .result(dialog: "Logged walk with \(profile.name)")
            }
        } catch {
            return .result(dialog: "Failed to log walk: \(error.localizedDescription)")
        }
    }
}
