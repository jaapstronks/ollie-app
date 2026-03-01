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

    /// End current nap by updating the sleep event's duration
    func endNap(minutesAgo: Int = 0, note: String? = nil) {
        if let napInfo = activityManager.endActivity(minutesAgo: minutesAgo, note: note) {
            // Find and update the sleep event with the duration
            updateSleepEventDuration(sessionId: napInfo.sleepSessionId, durationMin: napInfo.durationMin, note: note)
        }
        HapticFeedback.success()
    }

    /// Helper to update a sleep event's duration (single-event model)
    private func updateSleepEventDuration(sessionId: UUID?, durationMin: Int, note: String?) {
        // Find the sleep event by sessionId or most recent ongoing
        let recentEvents = getRecentEvents()
        guard let sleepEvent = recentEvents
            .filter({ $0.type == .slapen && $0.durationMin == nil })
            .first(where: { sessionId == nil || $0.sleepSessionId == sessionId || $0.id == sessionId })
        else { return }

        var updatedSleep = sleepEvent
        updatedSleep.durationMin = durationMin
        if let note = note, !note.isEmpty {
            updatedSleep.note = note
        }
        updateEvent(updatedSleep)
    }

    /// Get today's naps for display
    var todayNaps: [SleepSession] {
        SleepSession.buildSessions(from: events)
    }
}

// MARK: - Activity Management

extension TimelineViewModel {

    /// Start an activity with a specific type and start time
    func startActivity(type: ActivityType, startTime: Date, napLocation: NapLocation? = nil) {
        activityManager.startActivity(type: type, startTime: startTime, napLocation: napLocation)
        HapticFeedback.medium()
    }

    /// End the current activity
    func endActivity(minutesAgo: Int = 0, note: String? = nil) {
        if let napInfo = activityManager.endActivity(minutesAgo: minutesAgo, note: note) {
            // For naps, update the sleep event with duration
            updateSleepEventDuration(sessionId: napInfo.sleepSessionId, durationMin: napInfo.durationMin, note: note)
        }
        HapticFeedback.success()
        sheetCoordinator.dismissSheet()
    }

    /// Cancel/discard the current activity without logging
    func cancelActivity() {
        _ = activityManager.cancelActivity()
        HapticFeedback.medium()
        sheetCoordinator.dismissSheet()
    }

    /// End nap by updating the sleep event's duration (single-event model)
    func logWakeUp(time: Date) {
        let recentEvents = getRecentEvents()

        // Find the ongoing sleep event
        guard let sleepEvent = recentEvents
            .filter({ $0.type == .slapen && $0.durationMin == nil })
            .sorted(by: { $0.time > $1.time })
            .first else {
            // No ongoing sleep found - nothing to update
            HapticFeedback.error()
            return
        }

        // Calculate duration in minutes
        let durationMinutes = Int(time.timeIntervalSince(sleepEvent.time) / 60)

        // Update the sleep event with the duration
        var updatedSleep = sleepEvent
        updatedSleep.durationMin = max(1, durationMinutes)  // At least 1 minute

        // End any in-progress nap activity
        _ = activityManager.prepareWakeUp()

        // Save the updated sleep event (this replaces creating a wake event)
        updateEvent(updatedSleep)
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
