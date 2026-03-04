//
//  TrainingSession.swift
//  Otis-app
//
//  Groups training events that occur within a short time window
//  for cleaner timeline display

import Foundation
import OtisShared

/// A training session combining multiple training events logged within a time window
struct TrainingSession: Identifiable, Equatable {
    let id: UUID
    let events: [PuppyEvent]

    init(id: UUID = UUID(), events: [PuppyEvent]) {
        self.id = id
        self.events = events
    }

    /// Start time of the first training event
    var startTime: Date {
        events.map(\.time).min() ?? Date()
    }

    /// End time of the last training event
    var endTime: Date {
        events.map(\.time).max() ?? Date()
    }

    /// Unique skill names practiced in this session
    var skillNames: [String] {
        var seen = Set<String>()
        return events.compactMap(\.exercise).filter { seen.insert($0).inserted }
    }

    /// Number of training events in this session
    var count: Int {
        events.count
    }

    /// All event IDs in this session
    var eventIds: Set<UUID> {
        Set(events.map(\.id))
    }

    // MARK: - Session Building

    /// Time window for grouping training events (15 minutes)
    private static let groupingWindowMinutes: Double = 15

    /// Build training sessions from a list of events
    /// Groups consecutive training events that occur within the time window
    static func buildSessions(from events: [PuppyEvent]) -> [TrainingSession] {
        let trainingEvents = events
            .filter { $0.type == .training }
            .sorted { $0.time < $1.time }

        guard !trainingEvents.isEmpty else { return [] }

        var sessions: [TrainingSession] = []
        var currentGroup: [PuppyEvent] = []

        for event in trainingEvents {
            if currentGroup.isEmpty {
                currentGroup.append(event)
            } else {
                // Check if this event is within the time window of the last event
                let lastTime = currentGroup.last!.time
                let gap = event.time.timeIntervalSince(lastTime) / 60  // in minutes

                if gap <= groupingWindowMinutes {
                    currentGroup.append(event)
                } else {
                    // Gap too large - finalize current group and start new one
                    if currentGroup.count >= 2 {
                        sessions.append(TrainingSession(events: currentGroup))
                    }
                    currentGroup = [event]
                }
            }
        }

        // Don't forget the last group
        if currentGroup.count >= 2 {
            sessions.append(TrainingSession(events: currentGroup))
        }

        return sessions
    }
}
