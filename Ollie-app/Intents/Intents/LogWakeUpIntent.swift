//
//  LogWakeUpIntent.swift
//  Ollie-app
//
//  App Intent for logging wake up events via Siri/Shortcuts

import AppIntents
import OllieShared

/// Log that your puppy woke up
struct LogWakeUpIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Wake Up"
    static var description = IntentDescription("Log that your puppy woke up")
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

        // Check if puppy was sleeping and get the sleep event for session linking
        let ongoingSleep = store.ongoingSleepEvent()

        if ongoingSleep == nil {
            return .result(dialog: "\(profile.name) wasn't logged as sleeping. Logging wake up anyway.")
        }

        // Link wake event to the sleep session
        let sleepSessionId = ongoingSleep?.sleepSessionId ?? ongoingSleep?.id

        let event = PuppyEvent.wake(sleepSessionId: sleepSessionId)

        do {
            try store.addEvent(event)

            // Calculate sleep duration from the ongoing sleep event
            if let lastSleep = ongoingSleep {
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
