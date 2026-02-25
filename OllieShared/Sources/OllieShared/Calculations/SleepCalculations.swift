//
//  SleepCalculations.swift
//  OllieShared
//
//  Sleep state calculations ported from web app's sleep.js

import Foundation

/// Current sleep state of the puppy
public enum SleepState: Equatable, Sendable {
    case sleeping(since: Date, durationMin: Int)
    case awake(since: Date, durationMin: Int)
    case unknown

    public var isSleeping: Bool {
        if case .sleeping = self { return true }
        return false
    }

    public var isAwake: Bool {
        if case .awake = self { return true }
        return false
    }
}

/// Sleep calculation utilities
public struct SleepCalculations {

    public static let napThresholdMinutes = 15
    public static let maxAwakeMinutes = 60
    public static let awakeWarningMinutes = 45

    // MARK: - Public Methods

    /// Determine the current sleep state from events
    public static func currentSleepState(events: [PuppyEvent]) -> SleepState {
        let sleepEvents = events
            .filter { isSleepEvent($0.type) || isWakeEvent($0.type) }
            .sorted { $0.time < $1.time }

        guard let lastEvent = sleepEvents.last else {
            return .unknown
        }

        let now = Date()
        let durationMin = Int(now.timeIntervalSince(lastEvent.time) / 60)

        if isSleepEvent(lastEvent.type) {
            return .sleeping(since: lastEvent.time, durationMin: durationMin)
        } else if isWakeEvent(lastEvent.type) {
            return .awake(since: lastEvent.time, durationMin: durationMin)
        }

        return .unknown
    }

    /// Check if a sleep duration qualifies as a nap
    public static func isNap(durationMin: Int) -> Bool {
        durationMin < napThresholdMinutes
    }

    /// Calculate total sleep time today
    public static func totalSleepToday(events: [PuppyEvent]) -> Int {
        let sleepEvents = events
            .filter { isSleepEvent($0.type) || isWakeEvent($0.type) }
            .sorted { $0.time < $1.time }

        var totalMinutes = 0
        var sleepStartTime: Date?

        for event in sleepEvents {
            if isSleepEvent(event.type) {
                sleepStartTime = event.time
            } else if isWakeEvent(event.type), let start = sleepStartTime {
                let duration = Int(event.time.timeIntervalSince(start) / 60)
                totalMinutes += max(0, duration)
                sleepStartTime = nil
            }
        }

        if let start = sleepStartTime {
            let duration = Int(Date().timeIntervalSince(start) / 60)
            totalMinutes += max(0, duration)
        }

        return totalMinutes
    }

    /// Get the last sleep session
    public static func lastCompleteSleep(events: [PuppyEvent]) -> (start: Date, end: Date, durationMin: Int)? {
        let sleepEvents = events
            .filter { isSleepEvent($0.type) || isWakeEvent($0.type) }
            .sorted { $0.time < $1.time }

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

        let duration = Int(end.timeIntervalSince(start) / 60)
        return (start, end, duration)
    }

    /// Check if puppy recently woke from a significant nap
    public static func justWokeFromSignificantNap(events: [PuppyEvent], windowMinutes: Int = 20) -> Bool {
        guard let lastSleep = lastCompleteSleep(events: events) else {
            return false
        }

        guard lastSleep.durationMin >= napThresholdMinutes else {
            return false
        }

        let minutesSinceWake = Int(Date().timeIntervalSince(lastSleep.end) / 60)
        return minutesSinceWake <= windowMinutes
    }

    /// Calculate average nap duration from recent events, rounded to nearest 5 minutes
    /// Returns nil if not enough data
    public static func averageNapDuration(events: [PuppyEvent], minSessions: Int = 3) -> Int? {
        let sessions = SleepSession.buildSessions(from: events)
        let completedSessions = sessions.filter { !$0.isOngoing }

        guard completedSessions.count >= minSessions else {
            return nil
        }

        let totalMinutes = completedSessions.reduce(0) { $0 + $1.durationMinutes }
        let average = totalMinutes / completedSessions.count

        // Round to nearest 5 minutes
        return ((average + 2) / 5) * 5
    }

    /// Get default nap duration for logging UI
    /// Returns average if available, otherwise a sensible default (30 min)
    /// Caps at a duration that would end at current time
    public static func defaultNapDuration(events: [PuppyEvent], currentTime: Date = Date()) -> Int {
        let baseDuration = averageNapDuration(events: events) ?? 30

        // Round to nearest 5 minutes and ensure reasonable bounds
        let rounded = max(15, min(120, ((baseDuration + 2) / 5) * 5))

        return rounded
    }

    // MARK: - Private Helpers

    private static func isSleepEvent(_ type: EventType) -> Bool {
        type == .slapen || type == .bench
    }

    private static func isWakeEvent(_ type: EventType) -> Bool {
        type == .ontwaken
    }
}
