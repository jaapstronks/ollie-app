//
//  WalkNotificationScheduler.swift
//  Otis-app
//
//  Handles scheduling walk reminder notifications
//

import Foundation
import OtisShared
import UserNotifications
import os

/// Scheduler for walk reminder notifications (dynamic smart scheduling)
@MainActor
final class WalkNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "walk_"

    private let logger = Logger.otis(category: "WalkNotificationScheduler")

    private var notificationCenter: UNUserNotificationCenter {
        NotificationSchedulerHelpers.notificationCenter
    }

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        let suppression = NotificationSuppressionManager.shared

        // minutesOffset: 0 = at time, negative = after walk time (overdue), positive = before
        let minutesOffset = profile.notificationSettings.walkReminders.minutesOffset

        guard let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: profile.walkSchedule
        ) else {
            return
        }

        // Smart suppression: Check if walk was completed recently (within 30 min)
        if let lastWalk = events.walks().last {
            let minutesSinceWalk = Int(Date().timeIntervalSince(lastWalk.time) / 60)
            if minutesSinceWalk < 30 {
                logger.debug("Suppressing walk notification: walk completed \(minutesSinceWalk) min ago")
                return
            }
        }

        // Smart suppression: Don't notify during stale logging (user hasn't been logging)
        if isStaleLogging(events: events) {
            logger.debug("Suppressing walk notification: stale logging detected")
            return
        }

        // Subtract offset (negative offset = later notification time)
        let notificationDate = suggestion.suggestedTime.addingTimeInterval(TimeInterval(-minutesOffset * 60))
        let now = Date()
        let isOverdueNotification = minutesOffset < 0

        if notificationDate <= now {
            // If we missed the notification window, send immediate if within 30 min
            if suggestion.minutesUntilSuggested > -30 {
                // Smart suppression: Rate limit immediate notifications
                if suppression.shouldSuppressForRateLimit(prefix: notificationPrefix) {
                    logger.debug("Suppressing immediate walk notification: rate limited")
                    return
                }
                await sendImmediateNotification(profile: profile, suggestion: suggestion, isOverdue: isOverdueNotification || suggestion.isOverdue)
                suppression.recordNotificationSent(prefix: notificationPrefix)
            }
            return
        }

        let timeInterval = notificationDate.timeIntervalSince(now)
        guard timeInterval > 0 else { return }

        let minutesUntilFire = Int(timeInterval / 60)
        let aiAdjusted = AINudgeOrchestrator.shared.notificationPolicyAdjustment(
            kind: .walkReminder,
            baselineMinutesUntilFire: minutesUntilFire,
            profile: profile,
            recentEvents: events,
            isUrgent: false,
            allowSkip: true
        )
        if aiAdjusted.skip {
            logger.debug("Skipping walk notification based on AI timing decision")
            return
        }

        // Smart suppression: If user just used app and notification would fire soon, skip it
        if suppression.shouldSuppressForAppUsage(minutesUntilFire: aiAdjusted.minutesUntilFire) {
            logger.debug("Suppressing walk notification: app recently used")
            return
        }

        // Smart suppression: Check quiet hours (walks aren't urgent enough to override)
        let adjustedFireTime = now.addingTimeInterval(TimeInterval(aiAdjusted.minutesUntilFire * 60))
        if suppression.shouldSuppressForQuietHours(fireTime: adjustedFireTime, settings: profile.notificationSettings) {
            logger.debug("Suppressing walk notification: quiet hours")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = Strings.PushNotifications.walkTimeTitle
        content.body = Strings.PushNotifications.walkReminder(name: profile.name)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(aiAdjusted.minutesUntilFire * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationSchedulerHelpers.identifier(prefix: notificationPrefix),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            logger.debug("Scheduled walk notification for \(aiAdjusted.minutesUntilFire) minutes from now")
        } catch {
            logger.error("Failed to schedule smart walk reminder: \(error.localizedDescription)")
        }
    }

    private func sendImmediateNotification(profile: PuppyProfile, suggestion: WalkSuggestion, isOverdue: Bool) async {
        let body: String
        if isOverdue {
            body = "\(profile.name) - \(suggestion.label) (\(Strings.Upcoming.overdue))"
        } else {
            body = Strings.PushNotifications.walkReminder(name: profile.name)
        }

        let success = await NotificationSchedulerHelpers.sendImmediateNotification(
            title: Strings.PushNotifications.walkTimeTitle,
            body: body,
            prefix: notificationPrefix
        )

        if !success {
            logger.error("Failed to send immediate walk notification")
        }
    }

    /// Check if logging has gone stale (no events for too long during daytime)
    private func isStaleLogging(events: [PuppyEvent]) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Only check during daytime hours (7 AM - 11 PM)
        guard currentHour >= 7 && currentHour < 23 else {
            return false
        }

        // Find the last event (excluding coverage gaps)
        let lastEvent = events
            .filter { $0.type != .coverageGap }
            .max(by: { $0.time < $1.time })

        guard let lastEventTime = lastEvent?.time else {
            return false
        }

        // Check if 4+ hours since last event
        let hoursSinceLastEvent = now.timeIntervalSince(lastEventTime) / 3600
        return hoursSinceLastEvent >= 4
    }
}
