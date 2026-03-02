//
//  NapNotificationScheduler.swift
//  Otis-app
//
//  Handles scheduling nap reminder notifications
//

import Foundation
import OtisShared
import UserNotifications
import os

/// Scheduler for nap reminder notifications (state-based)
@MainActor
final class NapNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "nap_"

    private let logger = Logger.otis(category: "NapNotificationScheduler")

    private var notificationCenter: UNUserNotificationCenter {
        NotificationSchedulerHelpers.notificationCenter
    }

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        let suppression = NotificationSuppressionManager.shared
        let sleepState = SleepCalculations.currentSleepState(events: events)
        let threshold = profile.notificationSettings.napReminders.awakeThresholdMinutes

        guard case .awake(_, let durationMin) = sleepState else {
            return
        }

        let minutesUntilThreshold = threshold - durationMin

        guard minutesUntilThreshold > 0 else {
            // Smart suppression: Rate limit immediate notifications
            if suppression.shouldSuppressForRateLimit(prefix: notificationPrefix) {
                logger.debug("Suppressing immediate nap notification: rate limited")
                return
            }
            await sendImmediateNotification(profile: profile, durationMin: durationMin)
            suppression.recordNotificationSent(prefix: notificationPrefix)
            return
        }

        // Smart suppression: If user just used app and notification would fire soon, skip it
        if suppression.shouldSuppressForAppUsage(minutesUntilFire: minutesUntilThreshold) {
            logger.debug("Suppressing nap notification: app recently used")
            return
        }

        // Smart suppression: Check quiet hours (nap suggestions aren't urgent)
        let fireTime = Date().addingTimeInterval(TimeInterval(minutesUntilThreshold * 60))
        if suppression.shouldSuppressForQuietHours(fireTime: fireTime, settings: profile.notificationSettings) {
            logger.debug("Suppressing nap notification: quiet hours")
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
            logger.debug("Scheduled nap notification for \(minutesUntilThreshold) minutes from now")
        } catch {
            logger.error("Failed to schedule nap reminder: \(error.localizedDescription)")
        }
    }

    private func sendImmediateNotification(profile: PuppyProfile, durationMin: Int) async {
        let success = await NotificationSchedulerHelpers.sendImmediateNotification(
            title: Strings.PushNotifications.napNeededTitle,
            body: Strings.PushNotifications.napNeededBody(name: profile.name, minutes: durationMin),
            prefix: notificationPrefix
        )

        if !success {
            logger.error("Failed to send nap reminder")
        }
    }
}
