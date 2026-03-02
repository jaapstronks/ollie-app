//
//  WakeUpSoonNotificationScheduler.swift
//  Otis-app
//
//  Handles scheduling "waking up soon" notifications based on average nap duration
//  Sends notification X minutes before expected wake time, including pending walk/meal info
//

import Foundation
import OtisShared
import UserNotifications
import os

/// Scheduler for "waking up soon" notifications (predictive, based on average nap duration)
@MainActor
final class WakeUpSoonNotificationScheduler: NotificationScheduler {
    let notificationPrefix = "wakeup_"

    private let logger = Logger.otis(category: "WakeUpSoonNotificationScheduler")

    private var notificationCenter: UNUserNotificationCenter {
        NotificationSchedulerHelpers.notificationCenter
    }

    func schedule(events: [PuppyEvent], profile: PuppyProfile) async {
        await cancel()

        let suppression = NotificationSuppressionManager.shared
        let sleepState = SleepCalculations.currentSleepState(events: events)
        let minutesBefore = profile.notificationSettings.napReminders.wakeUpSoonMinutesBefore

        // Only schedule if currently sleeping
        guard case .sleeping(let since, _) = sleepState else {
            return
        }

        // Get average nap duration (need at least 3 completed naps for prediction)
        guard let averageNapDuration = SleepCalculations.averageNapDuration(events: events, minSessions: 3) else {
            logger.debug("Not enough nap data to predict wake time")
            return
        }

        // Calculate expected wake time and notification time
        let expectedWakeTime = since.addingTimeInterval(TimeInterval(averageNapDuration * 60))
        let notificationTime = expectedWakeTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        let now = Date()

        // Smart suppression: Check quiet hours (wake-up predictions aren't urgent)
        // Don't wake the owner at 4 AM just because puppy might wake soon
        if suppression.shouldSuppressForQuietHours(fireTime: notificationTime, settings: profile.notificationSettings) {
            logger.debug("Suppressing wake-up notification: quiet hours")
            return
        }

        // Don't schedule if notification time has already passed
        guard notificationTime > now else {
            // If we're past notification time but before expected wake, send immediate
            // (but still respect quiet hours - already checked above)
            if expectedWakeTime > now {
                await sendImmediateNotification(
                    profile: profile,
                    events: events,
                    expectedWakeTime: expectedWakeTime
                )
            }
            return
        }

        // Calculate time interval until notification
        let timeInterval = notificationTime.timeIntervalSince(now)
        guard timeInterval > 0 else { return }

        // Build notification content with pending actions
        let content = buildNotificationContent(
            profile: profile,
            events: events,
            expectedWakeTime: expectedWakeTime
        )

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
            logger.info("Scheduled wake-up notification for \(Int(timeInterval / 60)) minutes from now")
        } catch {
            logger.error("Failed to schedule wake-up notification: \(error.localizedDescription)")
        }
    }

    private func sendImmediateNotification(
        profile: PuppyProfile,
        events: [PuppyEvent],
        expectedWakeTime: Date
    ) async {
        let content = buildNotificationContent(
            profile: profile,
            events: events,
            expectedWakeTime: expectedWakeTime
        )

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationSchedulerHelpers.identifier(prefix: notificationPrefix),
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            logger.error("Failed to send immediate wake-up notification: \(error.localizedDescription)")
        }
    }

    private func buildNotificationContent(
        profile: PuppyProfile,
        events: [PuppyEvent],
        expectedWakeTime: Date
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = Strings.PushNotifications.wakingUpSoonTitle
        content.sound = .default

        // Check what's pending: walk, meal, or potty
        let walkIsDue = isWalkDue(events: events, profile: profile, at: expectedWakeTime)
        let mealIsDue = isMealDue(events: events, profile: profile, at: expectedWakeTime)
        let pottyIsUrgent = isPottyUrgent(events: events, profile: profile)

        // Build body with pending actions
        if pottyIsUrgent {
            content.body = Strings.PushNotifications.wakingUpSoonWithPotty(name: profile.name)
        } else if walkIsDue && mealIsDue {
            content.body = Strings.PushNotifications.wakingUpSoonWithWalkAndMeal(name: profile.name)
        } else if walkIsDue {
            content.body = Strings.PushNotifications.wakingUpSoonWithWalk(name: profile.name)
        } else if mealIsDue {
            content.body = Strings.PushNotifications.wakingUpSoonWithMeal(name: profile.name)
        } else {
            content.body = Strings.PushNotifications.wakingUpSoonBody(name: profile.name)
        }

        return content
    }

    // MARK: - Pending Action Checks

    private func isWalkDue(events: [PuppyEvent], profile: PuppyProfile, at time: Date) -> Bool {
        guard let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: profile.walkSchedule,
            date: time
        ) else {
            return false
        }
        // Walk is due if suggested time is at or before expected wake time (or overdue)
        return suggestion.isOverdue || suggestion.minutesUntilSuggested <= 0
    }

    private func isMealDue(events: [PuppyEvent], profile: PuppyProfile, at time: Date) -> Bool {
        let calendar = Calendar.current
        let checkHour = calendar.component(.hour, from: time)
        let checkMinute = calendar.component(.minute, from: time)
        let checkMinutes = checkHour * 60 + checkMinute

        let todayMealEvents = events.meals()

        for portion in profile.mealSchedule.portions {
            guard let targetTimeStr = portion.targetTime,
                  let (hour, minute) = NotificationSchedulerHelpers.parseTimeString(targetTimeStr) else { continue }

            let targetMinutes = hour * 60 + minute

            // Check if this meal was already logged
            let mealAlreadyLogged = todayMealEvents.contains { event in
                let eventHour = calendar.component(.hour, from: event.time)
                let eventMinute = calendar.component(.minute, from: event.time)
                let eventMinutes = eventHour * 60 + eventMinute
                return abs(eventMinutes - targetMinutes) <= 30
            }

            if mealAlreadyLogged { continue }

            // Meal is due if target time is at or before check time
            if targetMinutes <= checkMinutes {
                return true
            }
        }

        return false
    }

    private func isPottyUrgent(events: [PuppyEvent], profile: PuppyProfile) -> Bool {
        let gaps = GapCalculations.recentGaps(events: events, days: 7)
        let gapStats = GapCalculations.calculateGapStats(gaps: gaps)
        let prediction = PredictionCalculations.calculatePrediction(
            events: events,
            config: profile.predictionConfig,
            gapStats: gapStats
        )

        return prediction.urgency.isUrgent
    }
}
