//
//  ActivityTrackingManager.swift
//  Otis-app
//
//  Manages activity tracking state and logic (walks and naps)
//

import ActivityKit
import Combine
import Foundation
import OtisShared
import SwiftUI

// MARK: - Event Log Request

/// Parameters for logging an event from activity tracking
struct EventLogRequest {
    let type: EventType
    let time: Date?
    let location: EventLocation?
    let note: String?
    let durationMin: Int?
    let sleepSessionId: UUID?
    let napLocation: NapLocation?

    init(
        type: EventType,
        time: Date? = nil,
        location: EventLocation? = nil,
        note: String? = nil,
        durationMin: Int? = nil,
        sleepSessionId: UUID? = nil,
        napLocation: NapLocation? = nil
    ) {
        self.type = type
        self.time = time
        self.location = location
        self.note = note
        self.durationMin = durationMin
        self.sleepSessionId = sleepSessionId
        self.napLocation = napLocation
    }
}

// MARK: - Activity Tracking Manager

/// Manages in-progress activity tracking (walks and naps)
/// Used by TimelineViewModel to handle activity lifecycle
@Observable
@MainActor
class ActivityTrackingManager {
    /// Currently in-progress activity (walk or nap)
    var currentActivity: InProgressActivity?

    /// Callback to log an event (delegated to TimelineViewModel)
    @ObservationIgnored
    var onLogEvent: ((EventLogRequest) -> Void)?

    /// Callback when activity is dismissed
    @ObservationIgnored
    var onDismiss: (() -> Void)?

    /// Callback to delete an event by sleep session ID
    @ObservationIgnored
    var onDeleteSleepEvent: ((UUID) -> PuppyEvent?)?

    /// Callback to get the puppy name for Live Activities
    @ObservationIgnored
    var getPuppyName: (() -> String)?

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
    ///   - napLocation: Optional location for naps (crate, dog bed, etc.)
    func startActivity(type: ActivityType, startTime: Date = Date(), napLocation: NapLocation? = nil) {
        var sleepSessionId: UUID? = nil

        // For naps, log the sleep event immediately so it appears in timeline
        if type == .nap {
            sleepSessionId = UUID()
            onLogEvent?(EventLogRequest(type: .slapen, time: startTime, sleepSessionId: sleepSessionId, napLocation: napLocation))
        }

        currentActivity = InProgressActivity(
            type: type,
            startTime: startTime,
            sleepSessionId: sleepSessionId,
            napLocation: napLocation
        )

        // Start Live Activity for naps
        if type == .nap, let sessionId = sleepSessionId {
            startNapLiveActivity(startTime: startTime, activityId: sessionId)
        }

        onDismiss?()
        HapticFeedback.success()
    }

    // MARK: - Live Activity Support

    /// Start a nap Live Activity
    private func startNapLiveActivity(startTime: Date, activityId: UUID) {
        guard #available(iOS 16.1, *) else {
            print("⚠️ [LiveActivity] iOS 16.1+ required for Live Activities")
            return
        }

        let puppyName = getPuppyName?() ?? "Puppy"
        print("🌙 [LiveActivity] Starting nap Live Activity for \(puppyName)")
        LiveActivityManager.shared.startNapActivity(
            puppyName: puppyName,
            startTime: startTime,
            activityId: activityId
        )
    }

    /// End the current nap Live Activity
    private func endNapLiveActivity() {
        guard #available(iOS 16.1, *) else { return }

        LiveActivityManager.shared.endNapActivity()
    }

    /// Update the start time of the current activity
    /// Used when user edits the sleep event in the timeline
    func updateActivityStartTime(to newTime: Date) {
        guard currentActivity != nil else { return }
        currentActivity?.startTime = newTime
    }

    /// End the current activity
    /// Returns sleep session info for naps so the caller can update the sleep event with duration
    func endActivity(minutesAgo: Int, note: String?) -> (sleepSessionId: UUID?, startTime: Date?, durationMin: Int)? {
        guard let activity = currentActivity else { return nil }

        let endTime = Date().addingTimeInterval(-Double(minutesAgo) * 60)
        let duration = max(1, Int(endTime.timeIntervalSince(activity.startTime) / 60))

        if activity.type == .nap {
            // End the Live Activity
            endNapLiveActivity()

            // For naps, don't log a wake event - caller will update the sleep event with duration
            currentActivity = nil
            onDismiss?()
            HapticFeedback.success()
            // Return info for caller to update the sleep event
            return (activity.sleepSessionId, activity.startTime, duration)
        } else {
            // For walks, log the walk event at start time
            onLogEvent?(EventLogRequest(
                type: .uitlaten,
                time: activity.startTime,
                location: .buiten,
                note: note,
                durationMin: duration
            ))
        }

        currentActivity = nil
        onDismiss?()
        HapticFeedback.success()
        return nil
    }

    /// Cancel/discard the current activity without logging
    func cancelActivity() -> (shouldDeleteSleep: Bool, sessionId: UUID?)? {
        // If cancelling a nap, need to delete the sleep event and end Live Activity
        if let activity = currentActivity,
           activity.type == .nap,
           let sessionId = activity.sleepSessionId {
            endNapLiveActivity()
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

        // End the Live Activity
        endNapLiveActivity()

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
