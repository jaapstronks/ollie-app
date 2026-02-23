//
//  LogSleepIntent.swift
//  Ollie-app
//
//  App Intent for logging sleep events via Siri/Shortcuts

import AppIntents

/// Log that your puppy is sleeping
struct LogSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Sleep"
    static var description = IntentDescription("Log that your puppy is sleeping")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        guard profile.canLogEvents else {
            return .result(dialog: "Your free trial has ended. Please upgrade in the Ollie app to continue logging.")
        }

        // Check if already sleeping
        if store.isCurrentlySleeping() {
            return .result(dialog: "\(profile.name) is already sleeping. Say '\(profile.name) woke up' when they wake.")
        }

        // Generate a sleepSessionId to link this sleep with its future wake event
        let sleepSessionId = UUID()

        let event = PuppyEvent(
            time: Date(),
            type: .slapen,
            sleepSessionId: sleepSessionId
        )

        do {
            try store.addEvent(event)
            return .result(dialog: "\(profile.name) is sleeping - logged. Say '\(profile.name) woke up' when they wake.")
        } catch {
            return .result(dialog: "Failed to log sleep: \(error.localizedDescription)")
        }
    }
}
