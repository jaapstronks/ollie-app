//
//  TrialNotificationScheduler.swift
//  Otis-app
//
//  Handles scheduling trial touchpoint notifications (Day 3 and Day 12)
//

import Foundation
import OtisShared
import UserNotifications
import os

/// Scheduler for trial touchpoint notifications
@MainActor
final class TrialNotificationScheduler {
    let notificationPrefix = "trial_touchpoint_"

    private let logger = Logger.otis(category: "TrialNotificationScheduler")
    private let trialManager = TrialManager.shared

    private var notificationCenter: UNUserNotificationCenter {
        NotificationSchedulerHelpers.notificationCenter
    }

    /// Schedule trial touchpoint notifications
    /// Called from NotificationService.refreshNotifications
    func schedule() async {
        await cancel()

        guard trialManager.isTrialActive,
              let trialStartDate = trialManager.trialStartDate else {
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // Schedule notifications for touchpoints that show notifications
        for touchpoint in TrialTouchpoint.allCases where touchpoint.showsNotification {
            // Skip if already shown
            guard !trialManager.hasTouchpointBeenShown(touchpoint) else {
                continue
            }

            // Calculate when this touchpoint should fire (morning of that day)
            // Fire at 10:00 AM on the touchpoint day
            guard let touchpointDate = calendar.date(
                byAdding: .day,
                value: touchpoint.day - 1, // -1 because day 1 is start date
                to: calendar.startOfDay(for: trialStartDate)
            ) else { continue }

            // Set time to 10:00 AM
            var components = calendar.dateComponents([.year, .month, .day], from: touchpointDate)
            components.hour = 10
            components.minute = 0

            guard let fireDate = calendar.date(from: components),
                  fireDate > now else {
                continue
            }

            // Create notification content based on touchpoint
            let content = UNMutableNotificationContent()
            content.sound = .default

            switch touchpoint {
            case .day3Notification:
                content.title = Strings.Trial.day3NotificationTitle
                content.body = Strings.Trial.day3NotificationBody

            case .day12Warning:
                content.title = Strings.Trial.day12Title
                content.body = Strings.Trial.day12Subtitle(name: "your puppy")

            default:
                continue // Skip non-notification touchpoints
            }

            let timeInterval = fireDate.timeIntervalSince(now)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "\(notificationPrefix)\(touchpoint.rawValue)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                logger.debug("Scheduled trial notification for day \(touchpoint.day)")
            } catch {
                logger.error("Failed to schedule trial notification for day \(touchpoint.day): \(error.localizedDescription)")
            }
        }
    }

    /// Cancel all trial touchpoint notifications
    func cancel() async {
        await NotificationSchedulerHelpers.cancelNotifications(withPrefix: notificationPrefix)
    }
}
