//
//  ActivityTrackingManager.swift
//  Ollie-app
//
//  Manages activity tracking state and logic (walks and naps)
//

import Combine
import Foundation
import OllieShared
import SwiftUI

// MARK: - Activity Tracking Protocol

/// Protocol for activity tracking actions
protocol ActivityTrackingActions {
    func startActivity(type: ActivityType, startTime: Date)
    func endActivity(minutesAgo: Int, note: String?)
    func cancelActivity()
    func logWakeUp(time: Date)
}

// MARK: - Activity Tracking Manager

/// Manages in-progress activity tracking (walks and naps)
/// Used by TimelineViewModel to handle activity lifecycle
@MainActor
class ActivityTrackingManager: ObservableObject {
    /// Currently in-progress activity (walk or nap)
    @Published var currentActivity: InProgressActivity?

    /// Callback to log an event (delegated to TimelineViewModel)
    var onLogEvent: ((EventType, Date?, EventLocation?, String?, Int?, UUID?) -> Void)?

    /// Callback when activity is dismissed
    var onDismiss: (() -> Void)?

    /// Callback to delete an event by sleep session ID
    var onDeleteSleepEvent: ((UUID) -> PuppyEvent?)?

    /// Whether a walk is currently in progress
    var isWalkInProgress: Bool {
        currentActivity?.type == .walk
    }

    /// Whether a nap is currently in progress
    var isNapInProgress: Bool {
        currentActivity?.type == .nap
    }

    // MARK: - Activity Actions

    /// Start a new activity (walk or nap)
    /// - Parameters:
    ///   - type: The type of activity to start
    ///   - startTime: Optional custom start time (defaults to now)
    func startActivity(type: ActivityType, startTime: Date = Date()) {
        var sleepSessionId: UUID? = nil

        // For naps, log the sleep event immediately so it appears in timeline
        if type == .nap {
            sleepSessionId = UUID()
            onLogEvent?(.slapen, startTime, nil, nil, nil, sleepSessionId)
        }

        currentActivity = InProgressActivity(
            type: type,
            startTime: startTime,
            sleepSessionId: sleepSessionId
        )

        onDismiss?()
        HapticFeedback.success()
    }

    /// Update the start time of the current activity
    /// Used when user edits the sleep event in the timeline
    func updateActivityStartTime(to newTime: Date) {
        guard currentActivity != nil else { return }
        currentActivity?.startTime = newTime
    }

    /// End the current activity
    func endActivity(minutesAgo: Int, note: String?) -> (sleepSessionId: UUID?, sleepEvent: PuppyEvent?)? {
        guard let activity = currentActivity else { return nil }

        let endTime = Date().addingTimeInterval(-Double(minutesAgo) * 60)
        let duration = Int(endTime.timeIntervalSince(activity.startTime) / 60)

        if activity.type == .nap {
            // For naps, sleep was already logged at start - just log wake event
            onLogEvent?(.ontwaken, endTime, nil, nil, nil, activity.sleepSessionId)

            // Return info for updating note if needed
            currentActivity = nil
            onDismiss?()
            HapticFeedback.success()
            return (activity.sleepSessionId, nil)
        } else {
            // For walks, log the walk event at start time
            onLogEvent?(
                .uitlaten,
                activity.startTime,
                .buiten,
                note,
                max(1, duration),
                nil
            )
        }

        currentActivity = nil
        onDismiss?()
        HapticFeedback.success()
        return nil
    }

    /// Cancel/discard the current activity without logging
    func cancelActivity() -> (shouldDeleteSleep: Bool, sessionId: UUID?)? {
        // If cancelling a nap, need to delete the sleep event
        if let activity = currentActivity,
           activity.type == .nap,
           let sessionId = activity.sleepSessionId {
            currentActivity = nil
            onDismiss?()
            return (true, sessionId)
        }

        currentActivity = nil
        onDismiss?()
        return nil
    }

    /// Log a wake-up event
    /// - Returns: The sleep session ID from the current activity if available
    func prepareWakeUp() -> UUID? {
        guard let activity = currentActivity, activity.type == .nap else {
            return nil
        }
        let sessionId = activity.sleepSessionId
        currentActivity = nil
        return sessionId
    }
}

// MARK: - TimelineViewModel Extension

extension TimelineViewModel {
    /// Convenience to check if an activity is in progress
    var hasActiveActivity: Bool {
        currentActivity != nil
    }

    /// Get the elapsed time for the current activity
    func activityElapsedTime() -> TimeInterval? {
        guard let activity = currentActivity else { return nil }
        return Date().timeIntervalSince(activity.startTime)
    }

    /// Get formatted elapsed time string
    func activityElapsedString() -> String? {
        guard let elapsed = activityElapsedTime() else { return nil }
        let minutes = Int(elapsed / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}
