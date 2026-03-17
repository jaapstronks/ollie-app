//
//  FirstWeekNotificationScheduler.swift
//  Ollie-app
//
//  Handles first-week specific notifications for retention and engagement.
//  These supplement the trial notifications with gentler, engagement-focused nudges.
//

import Foundation
import OtisShared
import UserNotifications
import os

/// Scheduler for first-week engagement notifications
@MainActor
final class FirstWeekNotificationScheduler {
    let notificationPrefix = "first_week_"

    private let logger = Logger.otis(category: "FirstWeekNotificationScheduler")
    private var notificationCenter: UNUserNotificationCenter {
        NotificationSchedulerHelpers.notificationCenter
    }

    /// Schedule first-week notifications based on current state
    /// Called from NotificationService.refreshNotifications
    func schedule(profile: PuppyProfile, events: [PuppyEvent]) async {
        await cancel()

        let service = FirstWeekExperienceService.shared
        service.refreshCounts(from: events)

        // Only schedule during first week
        guard service.isFirstWeek else { return }

        let calendar = Calendar.current
        let now = Date()
        let puppyName = profile.name

        switch service.daysSinceOnboarding {
        case 0:
            // Day 0: If no events after 2 hours, send gentle nudge
            if !events.contains(where: { $0.type != .coverageGap }) {
                await scheduleIfNeeded(
                    id: "day0_first_log",
                    title: Strings.FirstWeek.howIsPuppy(name: puppyName),
                    body: Strings.FirstWeek.tapToLog,
                    afterMinutes: 120,
                    from: now
                )
            }

        case 1:
            // Day 1 morning: Welcome back
            await scheduleMorningNotification(
                id: "day1_morning",
                title: Strings.FirstWeek.goodMorning,
                body: Strings.FirstWeek.readyToTrack(name: puppyName),
                at: 8
            )

            // Day 1 evening: Rescue if no events today
            let todayEvents = events.filter { calendar.isDateInToday($0.time) && $0.type != .coverageGap }
            if todayEvents.isEmpty {
                await scheduleEveningNotification(
                    id: "day1_evening",
                    title: Strings.FirstWeek.dontForgetToLog(name: puppyName),
                    body: Strings.FirstWeek.evenQuickLogHelps,
                    at: 18
                )
            }

        case 2:
            // Day 2: Patterns emerging notification (morning)
            if service.shouldShowPottyPredictions {
                await scheduleMorningNotification(
                    id: "day2_patterns",
                    title: Strings.FirstWeek.patternsEmergingTitle,
                    body: Strings.FirstWeek.patternsEmergingSubtitle(name: puppyName),
                    at: 9
                )
            }

        case 3:
            // Day 3: Streak notification
            await scheduleMorningNotification(
                id: "day3_streak",
                title: Strings.FirstWeek.dayStreak(days: 3),
                body: Strings.FirstWeek.keepStreakGoing,
                at: 8
            )

        case 5:
            // Day 5: Week recap tease
            let daysLeft = 7 - service.daysSinceOnboarding
            await scheduleMorningNotification(
                id: "day5_recap_tease",
                title: Strings.FirstWeek.weekRecapTeaseTitle,
                body: Strings.FirstWeek.weekRecapTeaseSubtitle(daysLeft: daysLeft),
                at: 9
            )

        default:
            // Day 4, 6, 7: Let regular notifications handle it
            break
        }
    }

    // MARK: - Helpers

    private func scheduleIfNeeded(
        id: String,
        title: String,
        body: String,
        afterMinutes: Int,
        from: Date
    ) async {
        let fireDate = from.addingTimeInterval(TimeInterval(afterMinutes * 60))

        // Don't schedule if already past
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fireDate.timeIntervalSince(Date()),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(notificationPrefix)\(id)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            logger.debug("Scheduled first-week notification: \(id)")
        } catch {
            logger.error("Failed to schedule first-week notification \(id): \(error.localizedDescription)")
        }
    }

    private func scheduleMorningNotification(
        id: String,
        title: String,
        body: String,
        at hour: Int
    ) async {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0

        guard let fireDate = calendar.date(from: components),
              fireDate > Date() else {
            return
        }

        await scheduleIfNeeded(
            id: id,
            title: title,
            body: body,
            afterMinutes: Int(fireDate.timeIntervalSince(Date()) / 60),
            from: Date()
        )
    }

    private func scheduleEveningNotification(
        id: String,
        title: String,
        body: String,
        at hour: Int
    ) async {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0

        guard let fireDate = calendar.date(from: components),
              fireDate > Date() else {
            return
        }

        await scheduleIfNeeded(
            id: id,
            title: title,
            body: body,
            afterMinutes: Int(fireDate.timeIntervalSince(Date()) / 60),
            from: Date()
        )
    }

    /// Cancel all first-week notifications
    func cancel() async {
        await NotificationSchedulerHelpers.cancelNotifications(withPrefix: notificationPrefix)
    }
}
