//
//  WalkNotificationScheduler.swift
//  Ollie-app
//
//  Handles scheduling walk reminder notifications
//

import Foundation
import OllieShared
import UserNotifications
import os

/// Scheduler for walk reminder notifications (dynamic smart scheduling)
@MainActor
final class WalkNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "walk_"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger.ollie(category: "WalkNotificationScheduler")

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        // minutesOffset: 0 = at time, negative = after walk time (overdue), positive = before
        let minutesOffset = profile.notificationSettings.walkReminders.minutesOffset

        guard let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: profile.walkSchedule
        ) else {
            return
        }

        // Subtract offset (negative offset = later notification time)
        let notificationDate = suggestion.suggestedTime.addingTimeInterval(TimeInterval(-minutesOffset * 60))
        let now = Date()
        let isOverdueNotification = minutesOffset < 0

        if notificationDate <= now {
            // If we missed the notification window, send immediate if within 30 min
            if suggestion.minutesUntilSuggested > -30 {
                await sendImmediateNotification(profile: profile, suggestion: suggestion, isOverdue: isOverdueNotification || suggestion.isOverdue)
            }
            return
        }

        let timeInterval = notificationDate.timeIntervalSince(now)
        guard timeInterval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = Strings.PushNotifications.walkTimeTitle
        content.body = Strings.PushNotifications.walkReminder(name: profile.name)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationSchedulerHelpers.identifier(prefix: notificationPrefix),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            logger.error("Failed to schedule smart walk reminder: \(error.localizedDescription)")
        }
    }

    private func sendImmediateNotification(profile: PuppyProfile, suggestion: WalkSuggestion, isOverdue: Bool) async {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if isOverdue {
            content.title = Strings.PushNotifications.walkTimeTitle
            content.body = "\(profile.name) - \(suggestion.label) (\(Strings.Upcoming.overdue))"
        } else {
            content.title = Strings.PushNotifications.walkTimeTitle
            content.body = Strings.PushNotifications.walkReminder(name: profile.name)
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationSchedulerHelpers.identifier(prefix: notificationPrefix),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            logger.error("Failed to send immediate walk notification: \(error.localizedDescription)")
        }
    }
}
