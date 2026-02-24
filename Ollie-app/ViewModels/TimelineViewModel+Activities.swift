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
        activityManager.currentActivity?.elapsedMinutes
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
        startActivity(type: .walk)
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
        endActivity(minutesAgo: minutesAgo, note: note)

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
        startActivity(type: .nap)
        HapticFeedback.medium()
    }

    /// End current nap
    func endNap(minutesAgo: Int = 0, note: String? = nil) {
        endActivity(minutesAgo: minutesAgo, note: note)
        HapticFeedback.success()
    }

    /// Get today's naps for display
    var todayNaps: [SleepSession] {
        let sleepEvents = events.sleeps()
        let wakeEvents = events.wakeUps()
        return SleepSession.fromEvents(sleeps: sleepEvents, wakeUps: wakeEvents)
    }
}

// MARK: - Activity Presentation

extension TimelineViewModel {

    /// Show the walk log sheet
    func showWalkLogSheet() {
        sheetCoordinator.presentSheet(.walkLog)
    }

    /// Show the end sleep sheet (for ending naps)
    func showEndSleepSheet() {
        sheetCoordinator.presentSheet(.endSleep)
    }

    /// Show the start activity sheet
    func showStartActivitySheet() {
        sheetCoordinator.presentSheet(.startActivity)
    }

    /// Show the end activity sheet
    func showEndActivitySheet() {
        sheetCoordinator.presentSheet(.endActivity)
    }
}
