//
//  NotificationService.swift
//  Ollie-app
//
//  Manages scheduling and canceling smart notifications
//

import Foundation
import UserNotifications
import Combine

/// Service for managing smart puppy notifications
@MainActor
class NotificationService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isAuthorized: Bool = false

    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification identifier prefixes
    private enum NotificationPrefix {
        static let potty = "potty_"
        static let meal = "meal_"
        static let nap = "nap_"
        static let walk = "walk_"
    }

    // MARK: - Initialization

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Handling

    /// Check current notification authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    // MARK: - Refresh All Notifications

    /// Refresh all notifications based on current state
    /// Called after event logging or settings changes
    func refreshNotifications(
        events: [PuppyEvent],
        profile: PuppyProfile
    ) async {
        guard profile.notificationSettings.isEnabled && isAuthorized else {
            // If master toggle is off or not authorized, cancel all
            await cancelAllNotifications()
            return
        }

        let settings = profile.notificationSettings

        // Refresh each notification type
        if settings.pottyReminders.isEnabled {
            await schedulePottyReminder(events: events, profile: profile)
        } else {
            await cancelNotifications(withPrefix: NotificationPrefix.potty)
        }

        if settings.mealReminders.isEnabled {
            await scheduleMealReminders(profile: profile, events: events)
        } else {
            await cancelNotifications(withPrefix: NotificationPrefix.meal)
        }

        if settings.napReminders.isEnabled {
            await scheduleNapReminder(events: events, profile: profile)
        } else {
            await cancelNotifications(withPrefix: NotificationPrefix.nap)
        }

        if settings.walkReminders.isEnabled {
            await scheduleWalkReminders(profile: profile, events: events)
        } else {
            await cancelNotifications(withPrefix: NotificationPrefix.walk)
        }
    }

    // MARK: - Potty Reminders (Dynamic)

    private func schedulePottyReminder(
        events: [PuppyEvent],
        profile: PuppyProfile
    ) async {
        // Cancel existing potty notifications
        await cancelNotifications(withPrefix: NotificationPrefix.potty)

        let prediction = PredictionCalculations.calculatePrediction(
            events: events,
            config: profile.predictionConfig
        )

        // Calculate when to notify based on urgency level setting
        let minutesBefore = profile.notificationSettings.pottyReminders.urgencyLevel.minutesBefore

        guard let minutesSinceLast = prediction.minutesSinceLast else { return }

        let minutesRemaining = prediction.expectedGapMinutes - minutesSinceLast
        let minutesUntilNotification = minutesRemaining - minutesBefore

        // Don't schedule if time has already passed
        guard minutesUntilNotification > 0 else {
            // If we should have already notified, send immediately
            if minutesRemaining <= minutesBefore && minutesRemaining > -10 {
                await sendImmediatePottyNotification(
                    profile: profile,
                    minutesRemaining: minutesRemaining
                )
            }
            return
        }

        // Schedule for future
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch profile.notificationSettings.pottyReminders.urgencyLevel {
        case .attention:
            content.title = "Plasalarm"
            content.body = "\(profile.name) moet over ~\(minutesBefore) min plassen"
        case .soon:
            content.title = "Plasalarm!"
            content.body = "\(profile.name) moet zo plassen!"
        case .overdue:
            content.title = "Nu naar buiten!"
            content.body = "\(profile.name) moet nu plassen!"
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(minutesUntilNotification * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(NotificationPrefix.potty)\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule potty reminder: \(error)")
        }
    }

    private func sendImmediatePottyNotification(
        profile: PuppyProfile,
        minutesRemaining: Int
    ) async {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if minutesRemaining <= 0 {
            content.title = "Nu naar buiten!"
            content.body = "\(profile.name) moet nu plassen!"
        } else if minutesRemaining <= 10 {
            content.title = "Plasalarm!"
            content.body = "\(profile.name) moet zo plassen!"
        } else {
            content.title = "Plasalarm"
            content.body = "\(profile.name) moet over ~\(minutesRemaining) min plassen"
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(NotificationPrefix.potty)\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send immediate potty notification: \(error)")
        }
    }

    // MARK: - Meal Reminders (Fixed Daily)

    private func scheduleMealReminders(
        profile: PuppyProfile,
        events: [PuppyEvent]
    ) async {
        // Cancel existing meal notifications
        await cancelNotifications(withPrefix: NotificationPrefix.meal)

        let minutesBefore = profile.notificationSettings.mealReminders.minutesBefore
        let todayMealEvents = events.filter { $0.type == .eten }

        for portion in profile.mealSchedule.portions {
            guard let targetTimeStr = portion.targetTime,
                  let (hour, minute) = parseTimeString(targetTimeStr) else { continue }

            // Check if this meal was already logged today
            let mealAlreadyLogged = todayMealEvents.contains { event in
                let eventHour = Calendar.current.component(.hour, from: event.time)
                let eventMinute = Calendar.current.component(.minute, from: event.time)
                // Consider meal logged if event is within 30 min of target time
                let eventMinutes = eventHour * 60 + eventMinute
                let targetMinutes = hour * 60 + minute
                return abs(eventMinutes - targetMinutes) <= 30
            }

            if mealAlreadyLogged { continue }

            // Calculate notification time (target time minus minutesBefore)
            var notifyMinute = minute - minutesBefore
            var notifyHour = hour
            if notifyMinute < 0 {
                notifyMinute += 60
                notifyHour -= 1
            }
            if notifyHour < 0 {
                notifyHour += 24
            }

            // Check if notification time has already passed today
            let now = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            let currentMinutes = currentHour * 60 + currentMinute
            let notifyMinutes = notifyHour * 60 + notifyMinute

            // Skip if notification time has passed
            if notifyMinutes <= currentMinutes { continue }

            let content = UNMutableNotificationContent()
            content.title = "Tijd voor eten!"
            content.body = "\(portion.label): \(portion.amount)"
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = notifyHour
            dateComponents.minute = notifyMinute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false  // Don't repeat, we'll reschedule tomorrow
            )

            let request = UNNotificationRequest(
                identifier: "\(NotificationPrefix.meal)\(portion.id.uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to schedule meal reminder for \(portion.label): \(error)")
            }
        }
    }

    // MARK: - Nap Reminders (State-based)

    private func scheduleNapReminder(
        events: [PuppyEvent],
        profile: PuppyProfile
    ) async {
        // Cancel existing nap notifications
        await cancelNotifications(withPrefix: NotificationPrefix.nap)

        let sleepState = SleepCalculations.currentSleepState(events: events)
        let threshold = profile.notificationSettings.napReminders.awakeThresholdMinutes

        guard case .awake(_, let durationMin) = sleepState else {
            // Not awake, no need to schedule
            return
        }

        let minutesUntilThreshold = threshold - durationMin

        // If already past threshold, send soon
        guard minutesUntilThreshold > 0 else {
            let content = UNMutableNotificationContent()
            content.title = "Dutje nodig?"
            content.body = "\(profile.name) is al \(durationMin) minuten wakker"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(NotificationPrefix.nap)\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to send nap reminder: \(error)")
            }
            return
        }

        // Schedule for when threshold is reached
        let content = UNMutableNotificationContent()
        content.title = "Dutje nodig?"
        content.body = "\(profile.name) is al \(threshold) minuten wakker"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(minutesUntilThreshold * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(NotificationPrefix.nap)\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule nap reminder: \(error)")
        }
    }

    // MARK: - Walk Reminders (Dynamic Smart Scheduling)

    /// Schedule walk reminder based on smart suggestion
    /// Instead of fixed scheduled times, calculates next walk ~2h after last logged walk
    private func scheduleWalkReminders(
        profile: PuppyProfile,
        events: [PuppyEvent]
    ) async {
        // Cancel existing walk notifications
        await cancelNotifications(withPrefix: NotificationPrefix.walk)

        let minutesBefore = profile.notificationSettings.walkReminders.minutesBefore

        // Use smart walk suggestion instead of fixed schedule
        guard let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: profile.walkSchedule
        ) else {
            // No more walks suggested for today (past 22:00 or day complete)
            return
        }

        // Calculate notification time (suggested time minus reminder buffer)
        let notificationDate = suggestion.suggestedTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        let now = Date()

        // If notification time has already passed
        if notificationDate <= now {
            // If suggestion is overdue but within reasonable window, notify soon
            if suggestion.isOverdue && suggestion.minutesUntilSuggested > -30 {
                await sendImmediateWalkNotification(profile: profile, suggestion: suggestion)
            }
            return
        }

        // Calculate time interval until notification
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
            identifier: "\(NotificationPrefix.walk)\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule smart walk reminder: \(error)")
        }
    }

    /// Send immediate notification when walk is due or overdue
    private func sendImmediateWalkNotification(
        profile: PuppyProfile,
        suggestion: WalkSuggestion
    ) async {
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
            identifier: "\(NotificationPrefix.walk)\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send immediate walk notification: \(error)")
        }
    }

    // MARK: - Cancellation

    /// Cancel all scheduled notifications
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Cancel notifications with a specific prefix
    private func cancelNotifications(withPrefix prefix: String) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let toRemove = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }

        if !toRemove.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    // MARK: - Helpers

    /// Parse time string like "08:00" into (hour, minute) tuple
    private func parseTimeString(_ timeStr: String) -> (hour: Int, minute: Int)? {
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        return (hour, minute)
    }

    // MARK: - Debug

    /// Get all pending notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}
