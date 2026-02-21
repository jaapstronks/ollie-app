//
//  SleepCalculations.swift
//  Ollie-app
//
//  Sleep state calculations ported from web app's sleep.js

import Foundation

/// Current sleep state of the puppy
enum SleepState: Equatable {
    case sleeping(since: Date, durationMin: Int)
    case awake(since: Date, durationMin: Int)
    case unknown

    var isSleeping: Bool {
        if case .sleeping = self { return true }
        return false
    }

    var isAwake: Bool {
        if case .awake = self { return true }
        return false
    }
}

/// Sleep calculation utilities
struct SleepCalculations {

    /// Minimum nap duration in minutes to trigger post-sleep predictions
    static let napThresholdMinutes = 15

    /// Maximum awake time before suggesting a nap (in minutes)
    static let maxAwakeMinutes = 60

    /// Warning threshold before max awake time (in minutes)
    static let awakeWarningMinutes = 45

    // MARK: - Public Methods

    /// Determine the current sleep state from events
    /// - Parameter events: Array of puppy events (should include today + yesterday for cross-midnight)
    /// - Returns: Current sleep state
    static func currentSleepState(events: [PuppyEvent]) -> SleepState {
        // Filter to sleep-related events and sort chronologically
        let sleepEvents = events
            .filter { isSleepEvent($0.type) || isWakeEvent($0.type) }
            .sorted { $0.time < $1.time }

        guard let lastEvent = sleepEvents.last else {
            return .unknown
        }

        let now = Date()
        let durationMin = now.minutesSince(lastEvent.time)

        if isSleepEvent(lastEvent.type) {
            return .sleeping(since: lastEvent.time, durationMin: durationMin)
        } else if isWakeEvent(lastEvent.type) {
            return .awake(since: lastEvent.time, durationMin: durationMin)
        }

        return .unknown
    }

    /// Check if a sleep duration qualifies as a nap (short sleep)
    /// - Parameter durationMin: Duration in minutes
    /// - Returns: True if duration is less than the nap threshold
    static func isNap(durationMin: Int) -> Bool {
        durationMin < napThresholdMinutes
    }

    /// Calculate total sleep time today
    /// - Parameter events: Array of puppy events for today
    /// - Returns: Total sleep time in minutes
    static func totalSleepToday(events: [PuppyEvent]) -> Int {
        // Filter to sleep-related events and sort chronologically
        let sleepEvents = events
            .filter { isSleepEvent($0.type) || isWakeEvent($0.type) }
            .sorted { $0.time < $1.time }

        var totalMinutes = 0
        var sleepStartTime: Date?

        for event in sleepEvents {
            if isSleepEvent(event.type) {
                sleepStartTime = event.time
            } else if isWakeEvent(event.type), let start = sleepStartTime {
                let duration = event.time.minutesSince(start)
                totalMinutes += max(0, duration)
                sleepStartTime = nil
            }
        }

        // If currently sleeping, add time until now
        if let start = sleepStartTime {
            let duration = Date().minutesSince(start)
            totalMinutes += max(0, duration)
        }

        return totalMinutes
    }

    /// Get the last sleep session (for post-sleep trigger calculations)
    /// - Parameter events: Array of puppy events
    /// - Returns: Tuple of (sleepStart, sleepEnd, durationMin) or nil if no complete sleep found
    static func lastCompleteSleep(events: [PuppyEvent]) -> (start: Date, end: Date, durationMin: Int)? {
        let sleepEvents = events
            .filter { isSleepEvent($0.type) || isWakeEvent($0.type) }
            .sorted { $0.time < $1.time }

        // Find the last wake event and its preceding sleep event
        var lastSleepStart: Date?
        var lastSleepEnd: Date?

        for event in sleepEvents {
            if isSleepEvent(event.type) {
                lastSleepStart = event.time
            } else if isWakeEvent(event.type), lastSleepStart != nil {
                lastSleepEnd = event.time
            }
        }

        guard let start = lastSleepStart, let end = lastSleepEnd else {
            return nil
        }

        let duration = end.minutesSince(start)
        return (start, end, duration)
    }

    /// Check if puppy recently woke from a significant nap (for post-sleep potty trigger)
    /// - Parameters:
    ///   - events: Array of puppy events
    ///   - windowMinutes: Window to check for recent wake (default 20 min)
    /// - Returns: True if woke from nap >= 15 min within the window
    static func justWokeFromSignificantNap(events: [PuppyEvent], windowMinutes: Int = 20) -> Bool {
        guard let lastSleep = lastCompleteSleep(events: events) else {
            return false
        }

        // Check if nap was significant (>= 15 min)
        guard lastSleep.durationMin >= napThresholdMinutes else {
            return false
        }

        // Check if wake was within the window
        let minutesSinceWake = Date().minutesSince(lastSleep.end)
        return minutesSinceWake <= windowMinutes
    }

    // MARK: - Private Helpers

    /// Check if event type indicates sleep start
    private static func isSleepEvent(_ type: EventType) -> Bool {
        type == .slapen || type == .bench
    }

    /// Check if event type indicates wake
    private static func isWakeEvent(_ type: EventType) -> Bool {
        type == .ontwaken
    }
}
