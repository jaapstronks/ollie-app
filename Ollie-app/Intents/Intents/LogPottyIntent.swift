//
//  LogPottyIntent.swift
//  Ollie-app
//
//  App Intent for logging potty events via Siri/Shortcuts

import AppIntents
import OllieShared

/// Log a potty event (pee or poop) with location
struct LogPottyIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Potty"
    static var description = IntentDescription("Log when your puppy peed or pooped")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Type", description: "Pee or poop")
    var pottyType: PottyTypeEntity

    @Parameter(title: "Location", description: "Inside or outside")
    var location: LocationEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$pottyType) \(\.$location)")
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

        let event = PuppyEvent.potty(
            type: pottyType.eventType,
            location: location.eventLocation
        )

        do {
            try store.addEvent(event)

            let typeText = pottyType.eventType == .plassen ? "pee" : "poop"
            let locationText = location.eventLocation == .buiten ? "outside" : "inside"

            return .result(dialog: "Logged \(typeText) \(locationText) for \(profile.name)")
        } catch {
            return .result(dialog: "Failed to log event: \(error.localizedDescription)")
        }
    }
}

/// Quick shortcut for logging pee outside (most common action)
struct LogPeeOutsideIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Pee Outside"
    static var description = IntentDescription("Quickly log that your puppy peed outside")
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

        let event = PuppyEvent.potty(type: .plassen, location: .buiten)

        do {
            try store.addEvent(event)
            return .result(dialog: "Logged pee outside for \(profile.name)")
        } catch {
            return .result(dialog: "Failed to log event: \(error.localizedDescription)")
        }
    }
}

/// Quick shortcut for logging poop outside
struct LogPoopOutsideIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Poop Outside"
    static var description = IntentDescription("Quickly log that your puppy pooped outside")
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

        let event = PuppyEvent.potty(type: .poepen, location: .buiten)

        do {
            try store.addEvent(event)
            return .result(dialog: "Logged poop outside for \(profile.name)")
        } catch {
            return .result(dialog: "Failed to log event: \(error.localizedDescription)")
        }
    }
}
