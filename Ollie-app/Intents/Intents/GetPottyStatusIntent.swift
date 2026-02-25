//
//  GetPottyStatusIntent.swift
//  Ollie-app
//
//  App Intent for querying potty status via Siri/Shortcuts

import AppIntents
import OllieShared

/// Query when the puppy last peed and pooped (combined)
struct GetPottyStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Potty Status"
    static var description = IntentDescription("Find out when your puppy last peed and pooped")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        let lastPee = store.lastEvent(ofType: .plassen)
        let lastPoop = store.lastEvent(ofType: .poepen)

        // No events at all
        if lastPee == nil && lastPoop == nil {
            return .result(dialog: "No potty events logged for \(profile.name) in the last week.")
        }

        var parts: [String] = []

        // Pee status
        if let pee = lastPee {
            let peeText = formatTimeAgo(from: pee.time, type: "peed", location: pee.location)
            parts.append(peeText)
        } else {
            parts.append("No pee logged recently")
        }

        // Poop status
        if let poop = lastPoop {
            let poopText = formatTimeAgo(from: poop.time, type: "pooped", location: poop.location)
            parts.append(poopText)
        } else {
            parts.append("no poop logged recently")
        }

        return .result(dialog: "\(profile.name): \(parts.joined(separator: ". ")).")
    }

    private func formatTimeAgo(from time: Date, type: String, location: EventLocation?) -> String {
        let minutesAgo = Int(Date().timeIntervalSince(time) / 60)
        let locationText = location == .buiten ? "outside" : "inside"

        if minutesAgo < 1 {
            return "just \(type) \(locationText)"
        } else if minutesAgo < 60 {
            return "\(type) \(locationText) \(minutesAgo) min ago"
        } else {
            let hours = minutesAgo / 60
            let mins = minutesAgo % 60
            if mins > 0 {
                return "\(type) \(locationText) \(hours)h \(mins)m ago"
            } else {
                return "\(type) \(locationText) \(hours)h ago"
            }
        }
    }
}

/// Comprehensive puppy status: sleep, potty, and daily activity
struct GetPuppyStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Puppy Status"
    static var description = IntentDescription("Get a complete status update on your puppy")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = IntentDataStore.shared

        guard let profile = store.loadProfile() else {
            return .result(dialog: "Please set up your puppy profile in the Ollie app first.")
        }

        var statusParts: [String] = []

        // 1. Sleep status
        if let sleepEvent = store.ongoingSleepEvent() {
            let minutesAsleep = Int(Date().timeIntervalSince(sleepEvent.time) / 60)
            statusParts.append(formatSleepDuration(minutesAsleep, isAsleep: true))
        } else if let lastWake = store.lastEvent(ofType: .ontwaken) {
            let minutesAwake = Int(Date().timeIntervalSince(lastWake.time) / 60)
            statusParts.append(formatSleepDuration(minutesAwake, isAsleep: false))
        }

        // 2. Potty status (compact)
        let lastPee = store.lastEvent(ofType: .plassen)
        let lastPoop = store.lastEvent(ofType: .poepen)

        var pottyParts: [String] = []
        if let pee = lastPee {
            pottyParts.append("pee \(formatCompactTime(from: pee.time))")
        }
        if let poop = lastPoop {
            pottyParts.append("poop \(formatCompactTime(from: poop.time))")
        }
        if !pottyParts.isEmpty {
            statusParts.append("Last \(pottyParts.joined(separator: ", "))")
        }

        // 3. Today's activity summary
        let todayEvents = store.readEvents(for: Date())
        let mealCount = todayEvents.ofType(.eten).count
        let walkCount = todayEvents.ofType(.uitlaten).count

        var todayParts: [String] = []
        if mealCount > 0 {
            todayParts.append("\(mealCount) meal\(mealCount == 1 ? "" : "s")")
        }
        if walkCount > 0 {
            todayParts.append("\(walkCount) walk\(walkCount == 1 ? "" : "s")")
        }
        if !todayParts.isEmpty {
            statusParts.append("Today: \(todayParts.joined(separator: ", "))")
        }

        if statusParts.isEmpty {
            return .result(dialog: "No recent activity logged for \(profile.name).")
        }

        return .result(dialog: "\(profile.name): \(statusParts.joined(separator: ". ")).")
    }

    private func formatSleepDuration(_ minutes: Int, isAsleep: Bool) -> String {
        let state = isAsleep ? "Asleep" : "Awake"
        if minutes < 1 {
            return isAsleep ? "Just fell asleep" : "Just woke up"
        } else if minutes < 60 {
            return "\(state) for \(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins > 0 {
                return "\(state) for \(hours)h \(mins)m"
            } else {
                return "\(state) for \(hours)h"
            }
        }
    }

    private func formatCompactTime(from time: Date) -> String {
        let minutesAgo = Int(Date().timeIntervalSince(time) / 60)
        if minutesAgo < 1 {
            return "just now"
        } else if minutesAgo < 60 {
            return "\(minutesAgo)m ago"
        } else {
            let hours = minutesAgo / 60
            return "\(hours)h ago"
        }
    }
}
