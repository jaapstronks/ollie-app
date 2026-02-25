//
//  NotificationService.swift
//  Ollie-app
//
//  Manages scheduling and canceling smart notifications
//  Orchestrates individual notification schedulers
//

import Foundation
import OllieShared
import UserNotifications
import Combine
import os

/// Service for managing smart puppy notifications
@MainActor
class NotificationService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isAuthorized: Bool = false

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger.ollie(category: "NotificationService")

    // Individual schedulers
    private let pottyScheduler = PottyNotificationScheduler()
    private let mealScheduler = MealNotificationScheduler()
    private let napScheduler = NapNotificationScheduler()
    private let walkScheduler = WalkNotificationScheduler()

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
            logger.error("Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Refresh All Notifications

    /// Refresh all notifications based on current state
    /// Called after event logging or settings changes
    /// - Parameter isWalkInProgress: When true, suppresses walk notifications since user is already walking
    func refreshNotifications(
        events: [PuppyEvent],
        profile: PuppyProfile,
        isWalkInProgress: Bool = false
    ) async {
        guard profile.notificationSettings.isEnabled && isAuthorized else {
            await cancelAllNotifications()
            return
        }

        let settings = profile.notificationSettings

        // Delegate to individual schedulers
        if settings.pottyReminders.isEnabled {
            await pottyScheduler.schedule(events: events, profile: profile)
        } else {
            await pottyScheduler.cancel()
        }

        if settings.mealReminders.isEnabled {
            await mealScheduler.schedule(events: events, profile: profile)
        } else {
            await mealScheduler.cancel()
        }

        if settings.napReminders.isEnabled {
            await napScheduler.schedule(events: events, profile: profile)
        } else {
            await napScheduler.cancel()
        }

        // Don't schedule walk notifications if a walk is already in progress
        if settings.walkReminders.isEnabled && !isWalkInProgress {
            await walkScheduler.schedule(events: events, profile: profile)
        } else {
            await walkScheduler.cancel()
        }
    }

    // MARK: - Cancellation

    /// Cancel all scheduled notifications
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Debug

    /// Get all pending notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}
