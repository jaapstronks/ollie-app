//
//  LogWakeUpIntent.swift
//  Ollie-app
//
//  App Intent for logging wake up events via Siri/Shortcuts

import AppIntents

/// Log that your puppy woke up
struct LogWakeUpIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Wake Up"
    static var description = IntentDescription("Log that your puppy woke up")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        guard profile.canLogEvents else {
            return .result(dialog: "Your free trial has ended. Please upgrade in the Ollie app to continue logging.")
        }

        // Check if puppy was sleeping
        if !store.isCurrentlySleeping() {
            return .result(dialog: "\(profile.name) wasn't logged as sleeping. Logging wake up anyway.")
        }

        let event = PuppyEvent(
            time: Date(),
            type: .ontwaken
        )

        do {
            try store.addEvent(event)

            // Calculate sleep duration from last sleep event
            if let lastSleep = store.lastEvent(ofType: .slapen) {
                let duration = Int(Date().timeIntervalSince(lastSleep.time) / 60)
                if duration > 0 {
                    return .result(dialog: "\(profile.name) woke up after \(duration) minutes - logged!")
                }
            }

            return .result(dialog: "\(profile.name) woke up - logged!")
        } catch {
            return .result(dialog: "Failed to log wake up: \(error.localizedDescription)")
        }
    }
}
