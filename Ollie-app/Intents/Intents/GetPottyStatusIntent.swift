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

        // Use widget data which is synced by the main app
        guard let widgetData = store.loadWidgetData() else {
            return .result(dialog: "No data available. Please open the Ollie app to sync.")
        }

        // Check if we have any potty data
        guard let lastPeeTime = widgetData.lastPlasTime else {
            return .result(dialog: "No potty events logged for \(profile.name) yet.")
        }

        let locationText = widgetData.lastPlasLocation == "buiten" ? "outside" : "inside"
        let peeText = formatTimeAgo(from: lastPeeTime, type: "peed", location: locationText)

        return .result(dialog: "\(profile.name): \(peeText).")
    }

    private func formatTimeAgo(from time: Date, type: String, location: String) -> String {
        let minutesAgo = Int(Date().timeIntervalSince(time) / 60)

        if minutesAgo < 1 {
            return "just \(type) \(location)"
        } else if minutesAgo < 60 {
            return "\(type) \(location) \(minutesAgo) min ago"
        } else {
            let hours = minutesAgo / 60
            let mins = minutesAgo % 60
            if mins > 0 {
                return "\(type) \(location) \(hours)h \(mins)m ago"
            } else {
                return "\(type) \(location) \(hours)h ago"
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

        // Use widget data which is synced by the main app
        guard let widgetData = store.loadWidgetData() else {
            return .result(dialog: "No data available. Please open the Ollie app to sync.")
        }

        var statusParts: [String] = []

        // 1. Sleep status
        if widgetData.isCurrentlySleeping, let sleepStart = widgetData.sleepStartTime {
            let minutesAsleep = Int(Date().timeIntervalSince(sleepStart) / 60)
            statusParts.append(formatSleepDuration(minutesAsleep, isAsleep: true))
        } else if let lastWake = widgetData.lastWakeTime {
            let minutesAwake = Int(Date().timeIntervalSince(lastWake) / 60)
            statusParts.append(formatSleepDuration(minutesAwake, isAsleep: false))
        }

        // 2. Potty status (compact)
        if let lastPeeTime = widgetData.lastPlasTime {
            statusParts.append("Last pee \(formatCompactTime(from: lastPeeTime))")
        }

        // 3. Today's activity summary
        var todayParts: [String] = []
        if widgetData.mealsLoggedToday > 0 {
            let meals = widgetData.mealsLoggedToday
            todayParts.append("\(meals) meal\(meals == 1 ? "" : "s")")
        }
        if let lastWalkTime = widgetData.lastWalkTime {
            // Check if the walk was today
            if Calendar.current.isDateInToday(lastWalkTime) {
                todayParts.append("walked \(formatCompactTime(from: lastWalkTime))")
            }
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
