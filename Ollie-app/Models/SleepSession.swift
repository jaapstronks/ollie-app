//
//  SleepSession.swift
//  Ollie-app
//
//  Display-only model for grouping sleep/wake events into sessions
//  Keeps data storage as separate events for web app compatibility

import Foundation

/// A sleep session combining slapen + ontwaken events for display
/// This is a virtual grouping - events are still stored separately in JSONL
struct SleepSession: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date?  // nil = ongoing sleep
    let startEventId: UUID
    let endEventId: UUID?

    /// Whether this is an ongoing sleep (no wake event yet)
    var isOngoing: Bool {
        endTime == nil
    }

    /// Duration in minutes (calculated from current time if ongoing)
    var durationMinutes: Int {
        let end = endTime ?? Date()
        return end.minutesSince(startTime)
    }

    /// Formatted duration string (e.g., "45 min" or "1u30m")
    var durationString: String {
        let minutes = durationMinutes
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h\(mins)m"
        }
    }

    /// Whether this qualifies as a short nap (< 15 min)
    var isShortNap: Bool {
        !isOngoing && durationMinutes < SleepCalculations.napThresholdMinutes
    }

    // MARK: - Session Building

    /// Build sleep sessions from a list of events
    /// Groups slapen + ontwaken events by sleepSessionId, falling back to time-based matching
    static func buildSessions(from events: [PuppyEvent]) -> [SleepSession] {
        let sleepEvents = events.sleeps()
        let wakeEvents = events.wakes()

        var sessions: [SleepSession] = []
        var matchedWakeIds: Set<UUID> = []

        for sleepEvent in sleepEvents {
            // Try to find matching wake event by sleepSessionId first
            var matchingWake: PuppyEvent?

            if let sessionId = sleepEvent.sleepSessionId {
                matchingWake = wakeEvents.first {
                    $0.sleepSessionId == sessionId && !matchedWakeIds.contains($0.id)
                }
            }

            // Fall back to time-based matching: first wake event after this sleep
            if matchingWake == nil {
                matchingWake = wakeEvents
                    .filter { $0.time > sleepEvent.time && !matchedWakeIds.contains($0.id) }
                    .sorted { $0.time < $1.time }
                    .first
            }

            if let wake = matchingWake {
                matchedWakeIds.insert(wake.id)
            }

            let session = SleepSession(
                id: sleepEvent.sleepSessionId ?? sleepEvent.id,
                startTime: sleepEvent.time,
                endTime: matchingWake?.time,
                startEventId: sleepEvent.id,
                endEventId: matchingWake?.id
            )
            sessions.append(session)
        }

        return sessions.sorted { $0.startTime < $1.startTime }
    }

    /// Find the ongoing sleep session (if any)
    static func ongoingSession(from events: [PuppyEvent]) -> SleepSession? {
        buildSessions(from: events).first { $0.isOngoing }
    }

    /// Get the sleepSessionId for an ongoing sleep (to attach to wake event)
    static func ongoingSleepSessionId(from events: [PuppyEvent]) -> UUID? {
        let sleepEvents = events.sleeps().reverseChronological()
        let wakeEvents = events.wakes()

        // Find the most recent sleep event that doesn't have a matching wake
        for sleepEvent in sleepEvents {
            let hasMatchingWake: Bool
            if let sessionId = sleepEvent.sleepSessionId {
                hasMatchingWake = wakeEvents.contains { $0.sleepSessionId == sessionId }
            } else {
                // Fall back: check if any wake event is after this sleep
                hasMatchingWake = wakeEvents.contains { $0.time > sleepEvent.time }
            }

            if !hasMatchingWake {
                return sleepEvent.sleepSessionId ?? sleepEvent.id
            }
        }
        return nil
    }
}
