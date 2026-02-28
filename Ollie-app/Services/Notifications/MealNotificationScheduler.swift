//
//  MealNotificationScheduler.swift
//  Ollie-app
//
//  Handles scheduling meal reminder notifications
//

import Foundation
import OllieShared
import UserNotifications
import os

/// Scheduler for meal reminder notifications (fixed daily times)
@MainActor
final class MealNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "meal_"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger.ollie(category: "MealNotificationScheduler")

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        // minutesOffset: 0 = at time, negative = after meal time (overdue), positive = before
        let minutesOffset = profile.notificationSettings.mealReminders.minutesOffset
        let todayMealEvents = events.meals()

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
            } catch {
                logger.error("Failed to schedule meal reminder for \(portion.label): \(error.localizedDescription)")
            }
        }
    }

}
