//
//  PottyNotificationScheduler.swift
//  Otis-app
//
//  Handles scheduling potty reminder notifications
//

import Foundation
import OtisShared
import UserNotifications
import os

/// Scheduler for potty reminder notifications (dynamic, based on prediction)
@MainActor
final class PottyNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "potty_"

    private let logger = Logger.otis(category: "PottyNotificationScheduler")

    private var notificationCenter: UNUserNotificationCenter {
        NotificationSchedulerHelpers.notificationCenter
    }

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        let suppression = NotificationSuppressionManager.shared

        // Calculate historical gap stats for pattern-based predictions
        let gaps = GapCalculations.recentGaps(events: events, days: 7)
        let gapStats = GapCalculations.calculateGapStats(gaps: gaps)

        let prediction = PredictionCalculations.calculatePrediction(
            events: events,
            config: profile.predictionConfig,
            gapStats: gapStats
        )

        // Smart suppression: Don't notify if puppy just went outside
        // The "justWent" state means < 15 min since last potty - no need to nag
        if case .justWent = prediction.urgency {
            logger.debug("Suppressing potty notification: just went outside")
            return
        }

        // Smart suppression: Don't notify during coverage gaps (tracking paused)
        if case .coverageGap = prediction.urgency {
            logger.debug("Suppressing potty notification: coverage gap active")
            return
        }

        let minutesBefore = profile.notificationSettings.pottyReminders.urgencyLevel.minutesBefore

        guard let minutesSinceLast = prediction.minutesSinceLast else { return }

        let minutesRemaining = prediction.expectedGapMinutes - minutesSinceLast
        let minutesUntilNotification = minutesRemaining - minutesBefore

        // Check if we should send immediate notification (overdue/soon)
        guard minutesUntilNotification > 0 else {
            if minutesRemaining <= minutesBefore && minutesRemaining > -10 {
                // Smart suppression: Rate limit immediate notifications
                if suppression.shouldSuppressForRateLimit(prefix: notificationPrefix) {
                    logger.debug("Suppressing immediate potty notification: rate limited")
                    return
                }
                await sendImmediateNotification(profile: profile, minutesRemaining: minutesRemaining)
                suppression.recordNotificationSent(prefix: notificationPrefix)
            }
            return
        }

        // Smart suppression: If user just used app and notification would fire soon, skip it
        if suppression.shouldSuppressForAppUsage(minutesUntilFire: minutesUntilNotification) {
            logger.debug("Suppressing potty notification: app recently used")
            return
        }

        // Smart suppression: Check quiet hours (but allow urgent/overdue notifications)
        let fireTime = Date().addingTimeInterval(TimeInterval(minutesUntilNotification * 60))
        let isUrgent = prediction.urgency.isUrgent
        if !isUrgent && suppression.shouldSuppressForQuietHours(fireTime: fireTime, settings: profile.notificationSettings) {
            logger.debug("Suppressing potty notification: quiet hours")
            return
        }

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch profile.notificationSettings.pottyReminders.urgencyLevel {
        case .attention:
            content.title = Strings.PushNotifications.pottyAlarmTitle
            content.body = Strings.PushNotifications.needsToPeeIn(name: profile.name, minutes: minutesBefore)
        case .soon:
            content.title = Strings.PushNotifications.pottyAlarmTitle
            content.body = Strings.PushNotifications.needsToPeeSoon(name: profile.name)
        case .overdue:
            content.title = Strings.PushNotifications.goOutsideNowTitle
            content.body = Strings.PushNotifications.needsToPeeNow(name: profile.name)
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(minutesUntilNotification * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationSchedulerHelpers.identifier(prefix: notificationPrefix),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            logger.debug("Scheduled potty notification for \(minutesUntilNotification) minutes from now")
        } catch {
            logger.error("Failed to schedule potty reminder: \(error.localizedDescription)")
        }
    }

    private func sendImmediateNotification(profile: PuppyProfile, minutesRemaining: Int) async {
        let title: String
        let body: String

        if minutesRemaining <= 0 {
            title = Strings.PushNotifications.goOutsideNowTitle
            body = Strings.PushNotifications.needsToPeeNow(name: profile.name)
        } else if minutesRemaining <= 10 {
            title = Strings.PushNotifications.pottyAlarmTitle
            body = Strings.PushNotifications.needsToPeeSoon(name: profile.name)
        } else {
            title = Strings.PushNotifications.pottyAlarmTitle
            body = Strings.PushNotifications.needsToPeeIn(name: profile.name, minutes: minutesRemaining)
        }

        let success = await NotificationSchedulerHelpers.sendImmediateNotification(
            title: title,
            body: body,
            prefix: notificationPrefix
        )

        if !success {
            logger.error("Failed to send immediate potty notification")
        }
    }
}
