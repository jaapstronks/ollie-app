//
//  NotificationScheduling.swift
//  Ollie-app
//
//  Protocol and shared types for notification scheduling
//

import Foundation
import OllieShared
import UserNotifications

/// Protocol for notification schedulers
@MainActor
protocol NotificationScheduler {
    /// The notification identifier prefix for this scheduler type
    var notificationPrefix: String { get }

    /// Schedule notifications based on current state
    func schedule(events: [PuppyEvent], profile: PuppyProfile) async

    /// Cancel all pending notifications from this scheduler
    func cancel() async
}

/// Default implementation for cancel()
extension NotificationScheduler {
    func cancel() async {
        await NotificationSchedulerHelpers.cancelNotifications(withPrefix: notificationPrefix)
    }
}

/// Shared notification utilities
@MainActor
enum NotificationSchedulerHelpers {
    static let notificationCenter = UNUserNotificationCenter.current()

    /// Cancel notifications with a specific prefix
    static func cancelNotifications(withPrefix prefix: String) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let toRemove = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }

        if !toRemove.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    /// Parse time string like "08:00" into (hour, minute) tuple
    static func parseTimeString(_ timeStr: String) -> (hour: Int, minute: Int)? {
        timeStr.parseTimeComponents()
    }

    /// Create a notification identifier with prefix
    static func identifier(prefix: String) -> String {
        "\(prefix)\(UUID().uuidString)"
    }
}
