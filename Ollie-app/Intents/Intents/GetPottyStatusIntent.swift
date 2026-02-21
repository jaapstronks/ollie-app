//
//  GetPottyStatusIntent.swift
//  Ollie-app
//
//  App Intent for querying potty status via Siri/Shortcuts

import AppIntents

/// Query when the puppy last peed
struct GetPottyStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Potty Status"
    static var description = IntentDescription("Find out when your puppy last peed")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        guard let lastPee = store.lastEvent(ofType: .plassen) else {
            return .result(dialog: "No pee events logged for \(profile.name) in the last week.")
        }

        let minutesAgo = Int(Date().timeIntervalSince(lastPee.time) / 60)
        let locationText = lastPee.location == .buiten ? "outside" : "inside"

        if minutesAgo < 1 {
            return .result(dialog: "\(profile.name) just peed \(locationText).")
        } else if minutesAgo < 60 {
            return .result(dialog: "\(profile.name) peed \(locationText) \(minutesAgo) minutes ago.")
        } else {
            let hours = minutesAgo / 60
            let mins = minutesAgo % 60
            if mins > 0 {
                return .result(dialog: "\(profile.name) peed \(locationText) \(hours) hours and \(mins) minutes ago.")
            } else {
                return .result(dialog: "\(profile.name) peed \(locationText) \(hours) hours ago.")
            }
        }
    }
}

/// Query when the puppy last pooped
struct GetPoopStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Poop Status"
    static var description = IntentDescription("Find out when your puppy last pooped")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        guard let lastPoop = store.lastEvent(ofType: .poepen) else {
            return .result(dialog: "No poop events logged for \(profile.name) in the last week.")
        }

        let minutesAgo = Int(Date().timeIntervalSince(lastPoop.time) / 60)
        let locationText = lastPoop.location == .buiten ? "outside" : "inside"

        if minutesAgo < 1 {
            return .result(dialog: "\(profile.name) just pooped \(locationText).")
        } else if minutesAgo < 60 {
            return .result(dialog: "\(profile.name) pooped \(locationText) \(minutesAgo) minutes ago.")
        } else {
            let hours = minutesAgo / 60
            let mins = minutesAgo % 60
            if mins > 0 {
                return .result(dialog: "\(profile.name) pooped \(locationText) \(hours) hours and \(mins) minutes ago.")
            } else {
                return .result(dialog: "\(profile.name) pooped \(locationText) \(hours) hours ago.")
            }
        }
    }
}
