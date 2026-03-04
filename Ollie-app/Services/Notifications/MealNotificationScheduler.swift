//
//  MealNotificationScheduler.swift
//  Otis-app
//
//  Handles scheduling meal reminder notifications
//

import Foundation
import OtisShared
import UserNotifications
import os

/// Scheduler for meal reminder notifications (fixed daily times)
@MainActor
final class MealNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "meal_"

    private let logger = Logger.otis(category: "MealNotificationScheduler")

    private var notificationCenter: UNUserNotificationCenter {
        NotificationSchedulerHelpers.notificationCenter
    }

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        let suppression = NotificationSuppressionManager.shared

        // minutesOffset: 0 = at time, negative = after meal time (overdue), positive = before
        let minutesOffset = profile.notificationSettings.mealReminders.minutesOffset
        let todayMealEvents = events.meals()

        // Smart suppression: Check if any meal was logged very recently (within 5 min)
        // User just fed the puppy, don't nag about other meals right away
        if let lastMeal = todayMealEvents.last {
            let minutesSinceMeal = Int(Date().timeIntervalSince(lastMeal.time) / 60)
            if minutesSinceMeal < 5 {
                logger.debug("Suppressing meal notifications: meal logged \(minutesSinceMeal) min ago")
                return
            }
        }

        // Smart suppression: Don't notify during stale logging (user hasn't been logging)
        if isStaleLogging(events: events) {
            logger.debug("Suppressing meal notifications: stale logging detected")
            return
        }

        for portion in profile.mealSchedule.portions {
            guard let targetTimeStr = portion.targetTime,
                  let (hour, minute) = NotificationSchedulerHelpers.parseTimeString(targetTimeStr) else { continue }

            // Check if this meal was already logged today
            let mealAlreadyLogged = todayMealEvents.contains { event in
                let eventHour = Calendar.current.component(.hour, from: event.time)
                let eventMinute = Calendar.current.component(.minute, from: event.time)
                let eventMinutes = eventHour * 60 + eventMinute
                let targetMinutes = hour * 60 + minute
                return abs(eventMinutes - targetMinutes) <= 30
            }

            if mealAlreadyLogged { continue }

            // Calculate notification time (subtract offset: negative offset = later time)
            var notifyMinute = minute - minutesOffset
            var notifyHour = hour
            while notifyMinute < 0 {
                notifyMinute += 60
                notifyHour -= 1
            }
            while notifyMinute >= 60 {
                notifyMinute -= 60
                notifyHour += 1
            }
            if notifyHour < 0 {
                notifyHour += 24
            }
            if notifyHour >= 24 {
                notifyHour -= 24
            }

            // Check if notification time has already passed today
            let now = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            let currentMinutes = currentHour * 60 + currentMinute
            let notifyMinutes = notifyHour * 60 + notifyMinute

            if notifyMinutes <= currentMinutes { continue }

            let minutesUntilFire = notifyMinutes - currentMinutes

            // Smart suppression: If user just used app and notification would fire soon, skip it
            if suppression.shouldSuppressForAppUsage(minutesUntilFire: minutesUntilFire) {
                logger.debug("Suppressing meal notification for \(portion.label): app recently used")
                continue
            }

            // Smart suppression: Check quiet hours (meals aren't urgent enough to override)
            var fireDate = calendar.startOfDay(for: now)
            fireDate = calendar.date(byAdding: .hour, value: notifyHour, to: fireDate) ?? fireDate
            fireDate = calendar.date(byAdding: .minute, value: notifyMinute, to: fireDate) ?? fireDate
            if suppression.shouldSuppressForQuietHours(fireTime: fireDate, settings: profile.notificationSettings) {
                logger.debug("Suppressing meal notification for \(portion.label): quiet hours")
                continue
            }

            let content = UNMutableNotificationContent()
            // Use different title if it's overdue
            if minutesOffset < 0 {
                content.title = Strings.PushNotifications.mealOverdueTitle
            } else {
                content.title = Strings.PushNotifications.mealTimeTitle
            }
            content.body = Strings.PushNotifications.mealReminder(name: profile.name, meal: portion.label)
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = notifyHour
            dateComponents.minute = notifyMinute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "\(notificationPrefix)\(portion.id.uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                logger.debug("Scheduled meal notification for \(portion.label) at \(notifyHour):\(notifyMinute)")
            } catch {
                logger.error("Failed to schedule meal reminder for \(portion.label): \(error.localizedDescription)")
            }
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
