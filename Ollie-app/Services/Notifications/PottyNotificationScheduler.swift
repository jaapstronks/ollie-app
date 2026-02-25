//
//  PottyNotificationScheduler.swift
//  Ollie-app
//
//  Handles scheduling potty reminder notifications
//

import Foundation
import OllieShared
import UserNotifications
import os

/// Scheduler for potty reminder notifications (dynamic, based on prediction)
@MainActor
final class PottyNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "potty_"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger.ollie(category: "PottyNotificationScheduler")

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        let prediction = PredictionCalculations.calculatePrediction(
            events: events,
            config: profile.predictionConfig
        )

        let minutesBefore = profile.notificationSettings.pottyReminders.urgencyLevel.minutesBefore

        guard let minutesSinceLast = prediction.minutesSinceLast else { return }

        let minutesRemaining = prediction.expectedGapMinutes - minutesSinceLast
        let minutesUntilNotification = minutesRemaining - minutesBefore

        guard minutesUntilNotification > 0 else {
            if minutesRemaining <= minutesBefore && minutesRemaining > -10 {
                await sendImmediateNotification(profile: profile, minutesRemaining: minutesRemaining)
            }
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
        } catch {
            logger.error("Failed to schedule potty reminder: \(error.localizedDescription)")
        }
    }

    private func sendImmediateNotification(profile: PuppyProfile, minutesRemaining: Int) async {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if minutesRemaining <= 0 {
            content.title = Strings.PushNotifications.goOutsideNowTitle
            content.body = Strings.PushNotifications.needsToPeeNow(name: profile.name)
        } else if minutesRemaining <= 10 {
            content.title = Strings.PushNotifications.pottyAlarmTitle
            content.body = Strings.PushNotifications.needsToPeeSoon(name: profile.name)
        } else {
            content.title = Strings.PushNotifications.pottyAlarmTitle
            content.body = Strings.PushNotifications.needsToPeeIn(name: profile.name, minutes: minutesRemaining)
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
            logger.error("Failed to send immediate potty notification: \(error.localizedDescription)")
        }
    }
}
