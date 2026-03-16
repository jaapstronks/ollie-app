//
//  NotificationService.swift
//  Otis-app
//
//  Manages scheduling and canceling smart notifications
//  Orchestrates individual notification schedulers
//

import Foundation
import OtisShared
import UserNotifications
import Combine
import os

/// Service for managing smart puppy notifications
@Observable
@MainActor
class NotificationService {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isAuthorized: Bool = false

    @ObservationIgnored
    private let notificationCenter = UNUserNotificationCenter.current()
    @ObservationIgnored
    private let logger = Logger.otis(category: "NotificationService")

    // Individual schedulers (not observed - internal infrastructure)
    @ObservationIgnored
    private let pottyScheduler = PottyNotificationScheduler()
    @ObservationIgnored
    private let mealScheduler = MealNotificationScheduler()
    @ObservationIgnored
    private let napScheduler = NapNotificationScheduler()
    @ObservationIgnored
    private let wakeUpSoonScheduler = WakeUpSoonNotificationScheduler()
    @ObservationIgnored
    private let walkScheduler = WalkNotificationScheduler()
    @ObservationIgnored
    private let appointmentScheduler = AppointmentNotificationScheduler()
    @ObservationIgnored
    private let trialScheduler = TrialNotificationScheduler()
    @ObservationIgnored
    private let firstWeekScheduler = FirstWeekNotificationScheduler()

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
    /// - Parameters:
    ///   - events: Recent puppy events
    ///   - profile: The puppy profile
    ///   - appointments: Upcoming appointments to schedule reminders for
    ///   - isWalkInProgress: When true, suppresses walk notifications since user is already walking
    func refreshNotifications(
        events: [PuppyEvent],
        profile: PuppyProfile,
        appointments: [DogAppointment] = [],
        isWalkInProgress: Bool = false
    ) async {
        // Record app usage - user is viewing the app, so they already see status cards
        // This helps suppress redundant notifications that would fire right after closing the app
        NotificationSuppressionManager.shared.recordAppUsage()

        guard profile.notificationSettings.isEnabled && isAuthorized else {
            await cancelAllNotifications()
            return
        }

        // Check for active coverage gap - suppress all notifications while tracking is paused
        if CoverageGapFilter.hasActiveGap(gaps: events) {
            logger.info("Active coverage gap detected - suppressing all notifications")
            await cancelAllNotifications()
            return
        }

        let settings = profile.notificationSettings

        // Check sleep state - suppress walk/meal/nap notifications while sleeping
        // (follows same logic as status cards which show combined sleep card instead)
        let sleepState = SleepCalculations.currentSleepState(events: events)
        let isSleeping = sleepState.isSleeping

        // Delegate to individual schedulers
        // Potty notifications are still scheduled while sleeping (urgent potty shows in combined card)
        if settings.pottyReminders.isEnabled {
            await pottyScheduler.schedule(events: events, profile: profile)
        } else {
            await pottyScheduler.cancel()
        }

        // Don't send meal notifications while sleeping - meal can wait until wake up
        if settings.mealReminders.isEnabled && !isSleeping {
            await mealScheduler.schedule(events: events, profile: profile)
        } else {
            await mealScheduler.cancel()
        }

        // Nap reminders only make sense when awake (they remind to put puppy to sleep)
        // Wake-up-soon notifications only make sense when sleeping (predict wake time)
        if settings.napReminders.isEnabled {
            if isSleeping {
                // Cancel "time to nap" reminders while sleeping
                await napScheduler.cancel()
                // Schedule "waking up soon" notification if enabled
                if settings.napReminders.wakeUpSoonEnabled {
                    await wakeUpSoonScheduler.schedule(events: events, profile: profile)
                } else {
                    await wakeUpSoonScheduler.cancel()
                }
            } else {
                // Awake: schedule nap reminders, cancel wake-up notifications
                await napScheduler.schedule(events: events, profile: profile)
                await wakeUpSoonScheduler.cancel()
            }
        } else {
            await napScheduler.cancel()
            await wakeUpSoonScheduler.cancel()
        }

        // Don't schedule walk notifications if sleeping or walk already in progress
        if settings.walkReminders.isEnabled && !isWalkInProgress && !isSleeping {
            await walkScheduler.schedule(events: events, profile: profile)
        } else {
            await walkScheduler.cancel()
        }

        // Schedule appointment reminders
        if settings.appointmentReminders.isEnabled {
            await appointmentScheduler.schedule(appointments: appointments, profile: profile)
        } else {
            await appointmentScheduler.cancel()
        }

        // Schedule trial touchpoint notifications (Day 3 and Day 12)
        // These are always scheduled when trial is active - no user toggle
        await trialScheduler.schedule()

        // Schedule first-week engagement notifications
        // These provide gentle retention nudges during the critical first week
        await firstWeekScheduler.schedule(profile: profile, events: events)
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
