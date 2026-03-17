//
//  WakeUpIntent.swift
//  OtisWidget
//
//  App Intent for interactive "Wake Up" button in Dynamic Island (iOS 17+)
//

import AppIntents
import Foundation
import OtisShared

@available(iOS 17.0, *)
struct WakeUpIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Wake Up"
    static let description = IntentDescription("End the current nap and log wake-up")

    /// The activity ID to end
    @Parameter(title: "Activity ID")
    var activityId: String

    init() {
        self.activityId = ""
    }

    init(activityId: String) {
        self.activityId = activityId
    }

    func perform() async throws -> some IntentResult {
        // Write to App Groups UserDefaults for the main app to handle
        // NotificationCenter doesn't work across processes
        LiveActivitySharedState.shared.writePendingWakeUp(activityId: activityId)

        return .result()
    }
}

// MARK: - Notification Name (for in-process use)

extension Notification.Name {
    /// Posted when user taps Wake Up in Dynamic Island
    static let wakeUpFromLiveActivity = Notification.Name("wakeUpFromLiveActivity")
}
