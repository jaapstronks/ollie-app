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

        let minutesBefore = profile.notificationSettings.walkReminders.minutesBefore

        guard let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: profile.walkSchedule
        ) else {
            return
        }

        let notificationDate = suggestion.suggestedTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        let now = Date()

        if notificationDate <= now {
            if suggestion.isOverdue && suggestion.minutesUntilSuggested > -30 {
                await sendImmediateNotification(profile: profile, suggestion: suggestion)
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

    private func sendImmediateNotification(profile: PuppyProfile, suggestion: WalkSuggestion) async {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if suggestion.isOverdue {
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
