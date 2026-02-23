//
//  WakeUpIntent.swift
//  OllieWidget
//
//  App Intent for interactive "Wake Up" button in Dynamic Island (iOS 17+)
//

import AppIntents
import Foundation

@available(iOS 17.0, *)
struct WakeUpIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Wake Up"
    static var description = IntentDescription("End the current nap and log wake-up")

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
        // Post notification for the app to handle
        NotificationCenter.default.post(
            name: .wakeUpFromLiveActivity,
            object: nil,
            userInfo: ["activityId": activityId]
        )

        return .result()
    }
}

// MARK: - Notification Name

extension Notification.Name {
    /// Posted when user taps Wake Up in Dynamic Island
    static let wakeUpFromLiveActivity = Notification.Name("wakeUpFromLiveActivity")
}
