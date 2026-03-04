//
//  NotificationScheduling.swift
//  Otis-app
//
//  Protocol and shared types for notification scheduling
//

import Foundation
import OtisShared
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

    /// Send an immediate notification (fires after 1 second)
    /// - Parameters:
    ///   - title: The notification title
    ///   - body: The notification body text
    ///   - prefix: The notification prefix for the identifier
    /// - Returns: `true` if the notification was added successfully
    @discardableResult
    static func sendImmediateNotification(
        title: String,
        body: String,
        prefix: String
    ) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(prefix: prefix),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Smart Notification Suppression

/// Manages smart notification suppression rules to prevent annoying notifications
@MainActor
final class NotificationSuppressionManager {
    static let shared = NotificationSuppressionManager()

    /// Minutes to suppress notifications after app was actively used
    private let appUsageSuppressMinutes: Int = 3

    /// Minimum minutes between notifications of the same type
    private let rateLimitMinutes: Int = 5

    /// Last time the app was actively used (user viewing the app)
    private var lastAppUsageTime: Date?

    /// Last notification time per type (keyed by notification prefix)
    private var lastNotificationTimes: [String: Date] = [:]

    private init() {}

    // MARK: - App Usage Tracking

    /// Call this when the app becomes active (user is viewing the app)
    func recordAppUsage() {
        lastAppUsageTime = Date()
    }

    /// Check if we should suppress notifications because app was just used
    /// - Parameter minutesUntilFire: Minutes until the notification would fire
    /// - Returns: true if notification should be suppressed
    func shouldSuppressForAppUsage(minutesUntilFire: Int) -> Bool {
        guard let lastUsage = lastAppUsageTime else { return false }

        let minutesSinceUsage = Int(Date().timeIntervalSince(lastUsage) / 60)

        // If user used app recently and notification would fire soon, suppress it
        // User already saw the status cards, no need to notify immediately after
        if minutesSinceUsage < appUsageSuppressMinutes && minutesUntilFire < appUsageSuppressMinutes {
            return true
        }

        return false
    }

    // MARK: - Rate Limiting

    /// Record that a notification was sent for a given type
    func recordNotificationSent(prefix: String) {
        lastNotificationTimes[prefix] = Date()
    }

    /// Check if we should suppress due to rate limiting (same type sent recently)
    /// - Parameter prefix: The notification type prefix
    /// - Returns: true if notification should be suppressed
    func shouldSuppressForRateLimit(prefix: String) -> Bool {
        guard let lastTime = lastNotificationTimes[prefix] else { return false }

        let minutesSinceLast = Int(Date().timeIntervalSince(lastTime) / 60)
        return minutesSinceLast < rateLimitMinutes
    }

    /// Check if a notification at a given time would be in quiet hours
    /// - Parameters:
    ///   - fireTime: When the notification would fire
    ///   - settings: The notification settings with quiet hours config
    /// - Returns: true if notification should be suppressed for quiet hours
    func shouldSuppressForQuietHours(fireTime: Date, settings: NotificationSettings) -> Bool {
        settings.isInQuietHours(fireTime)
    }

    /// Reset all tracking (e.g., when settings change)
    func reset() {
        lastAppUsageTime = nil
        lastNotificationTimes.removeAll()
    }
}
