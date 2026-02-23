//
//  SleepSession.swift
//  OllieShared
//
//  Display-only model for grouping sleep/wake events into sessions

import Foundation

/// A sleep session combining slapen + ontwaken events for display
public struct SleepSession: Identifiable, Sendable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date?
    public let startEventId: UUID
    public let endEventId: UUID?

    public init(id: UUID, startTime: Date, endTime: Date?, startEventId: UUID, endEventId: UUID?) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startEventId = startEventId
        self.endEventId = endEventId
    }

    /// Whether this is an ongoing sleep
    public var isOngoing: Bool {
        endTime == nil
    }

    /// Duration in minutes
    public var durationMinutes: Int {
        let end = endTime ?? Date()
        return Int(end.timeIntervalSince(startTime) / 60)
    }

    /// Formatted duration string
    public var durationString: String {
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
    public var isShortNap: Bool {
        !isOngoing && durationMinutes < 15
    }

    // MARK: - Session Building

    /// Build sleep sessions from a list of events
    public static func buildSessions(from events: [PuppyEvent]) -> [SleepSession] {
        let sleepEvents = events.sleeps()
        let wakeEvents = events.wakes()

        var sessions: [SleepSession] = []
        var matchedWakeIds: Set<UUID> = []

        for sleepEvent in sleepEvents {
            var matchingWake: PuppyEvent?

            if let sessionId = sleepEvent.sleepSessionId {
                matchingWake = wakeEvents.first {
                    $0.sleepSessionId == sessionId && !matchedWakeIds.contains($0.id)
                }
            }

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

    /// Find the ongoing sleep session
    public static func ongoingSession(from events: [PuppyEvent]) -> SleepSession? {
        buildSessions(from: events).first { $0.isOngoing }
    }

    /// Get the sleepSessionId for an ongoing sleep
    public static func ongoingSleepSessionId(from events: [PuppyEvent]) -> UUID? {
        let sleepEvents = events.sleeps().reverseChronological()
        let wakeEvents = events.wakes()

        for sleepEvent in sleepEvents {
            let hasMatchingWake: Bool
            if let sessionId = sleepEvent.sleepSessionId {
                hasMatchingWake = wakeEvents.contains { $0.sleepSessionId == sessionId }
            } else {
                hasMatchingWake = wakeEvents.contains { $0.time > sleepEvent.time }
            }

            if !hasMatchingWake {
                return sleepEvent.sleepSessionId ?? sleepEvent.id
            }
        }
        return nil
    }
}
