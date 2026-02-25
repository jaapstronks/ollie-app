//
//  NapNotificationScheduler.swift
//  Ollie-app
//
//  Handles scheduling nap reminder notifications
//

import Foundation
import OllieShared
import UserNotifications
import os

/// Scheduler for nap reminder notifications (state-based)
@MainActor
final class NapNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "nap_"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger.ollie(category: "NapNotificationScheduler")

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        let sleepState = SleepCalculations.currentSleepState(events: events)
        let threshold = profile.notificationSettings.napReminders.awakeThresholdMinutes

        guard case .awake(_, let durationMin) = sleepState else {
            return
        }

        let minutesUntilThreshold = threshold - durationMin

        guard minutesUntilThreshold > 0 else {
            await sendImmediateNotification(profile: profile, durationMin: durationMin)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = Strings.PushNotifications.napNeededTitle
        content.body = Strings.PushNotifications.napNeededBody(name: profile.name, minutes: threshold)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(minutesUntilThreshold * 60),
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
            logger.error("Failed to schedule nap reminder: \(error.localizedDescription)")
        }
    }

    private func sendImmediateNotification(profile: PuppyProfile, durationMin: Int) async {
        let content = UNMutableNotificationContent()
        content.title = Strings.PushNotifications.napNeededTitle
        content.body = Strings.PushNotifications.napNeededBody(name: profile.name, minutes: durationMin)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationSchedulerHelpers.identifier(prefix: notificationPrefix),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            logger.error("Failed to send nap reminder: \(error.localizedDescription)")
        }
    }
}
