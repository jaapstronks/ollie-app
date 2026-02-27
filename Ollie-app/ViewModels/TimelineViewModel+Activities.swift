//
//  TimelineViewModel+Activities.swift
//  Ollie-app
//
//  Extension containing activity tracking methods (walks and naps)
//  Extracted from TimelineViewModel to improve code organization
//

import Foundation
import OllieShared
import SwiftUI

// MARK: - Activity State Helpers

extension TimelineViewModel {

    /// Duration of current activity in minutes
    var currentActivityDuration: Int? {
        activityManager.currentActivity?.durationMinutes
    }

    /// Type of current activity
    var currentActivityType: ActivityType? {
        activityManager.currentActivity?.type
    }

    /// Start time of current activity
    var currentActivityStartTime: Date? {
        activityManager.currentActivity?.startTime
    }

    /// Whether any activity is in progress
    var hasActivityInProgress: Bool {
        activityManager.currentActivity != nil
    }
}

// MARK: - Walk Activity Helpers

extension TimelineViewModel {

    /// Start a walk activity
    func startWalk() {
        activityManager.startActivity(type: .walk)
        HapticFeedback.medium()
    }

    /// End current walk with potty events
    func endWalkWithPotty(
        minutesAgo: Int = 0,
        note: String? = nil,
        didPee: Bool = false,
        didPoop: Bool = false,
        peeLocation: EventLocation = .buiten,
        poopLocation: EventLocation = .buiten
    ) {
        // End the walk activity
        _ = activityManager.endActivity(minutesAgo: minutesAgo, note: note)

        // Log potty events if needed
        let eventTime = Date().addingTimeInterval(-Double(minutesAgo) * 60)

        if didPee {
            logEvent(type: .plassen, time: eventTime, location: peeLocation)
        }

        if didPoop {
            logEvent(type: .poepen, time: eventTime, location: poopLocation)
        }

        HapticFeedback.success()
    }

    /// Get today's walks for display
    var todayWalks: [PuppyEvent] {
        events.walks()
    }
}

// MARK: - Nap Activity Helpers

extension TimelineViewModel {

    /// Start a nap activity
    func startNap() {
        activityManager.startActivity(type: .nap)
        HapticFeedback.medium()
    }

    /// End current nap
    func endNap(minutesAgo: Int = 0, note: String? = nil) {
        _ = activityManager.endActivity(minutesAgo: minutesAgo, note: note)
        HapticFeedback.success()
    }

    /// Get today's naps for display
    var todayNaps: [SleepSession] {
        SleepSession.buildSessions(from: events)
    }
}

// MARK: - Activity Management

extension TimelineViewModel {

    /// Start an activity with a specific type and start time
    func startActivity(type: ActivityType, startTime: Date) {
        activityManager.startActivity(type: type, startTime: startTime)
        HapticFeedback.medium()
    }

    /// End the current activity
    func endActivity(minutesAgo: Int = 0, note: String? = nil) {
        _ = activityManager.endActivity(minutesAgo: minutesAgo, note: note)
        HapticFeedback.success()
        sheetCoordinator.dismissSheet()
    }

    /// Cancel/discard the current activity without logging
    func cancelActivity() {
        _ = activityManager.cancelActivity()
        HapticFeedback.medium()
        sheetCoordinator.dismissSheet()
    }

    /// Log wake up event at a specific time
    func logWakeUp(time: Date) {
        // Find the ongoing sleep session to link the wake event
        let recentEvents = getRecentEvents()
        let sleepSessionId = SleepSession.ongoingSleepSessionId(from: recentEvents)

        // End any in-progress nap activity
        _ = activityManager.prepareWakeUp()

        // Log the wake-up event
        logEvent(type: .ontwaken, time: time, sleepSessionId: sleepSessionId)
        HapticFeedback.success()
    }
}

// MARK: - Activity Presentation

extension TimelineViewModel {

    /// Show the walk log sheet
    func showWalkLogSheet() {
        sheetCoordinator.presentSheet(.walkLog)
    }

    /// Show the end sleep sheet (for ending naps)
    func showEndSleepSheet(startTime: Date = Date()) {
        sheetCoordinator.presentSheet(.endSleep(startTime))
    }

    /// Show the start activity sheet
    func showStartActivitySheet(type: ActivityType = .walk) {
        sheetCoordinator.presentSheet(.startActivity(type))
    }

    /// Show the end activity sheet
    func showEndActivitySheet() {
        sheetCoordinator.presentSheet(.endActivity)
    }
}
