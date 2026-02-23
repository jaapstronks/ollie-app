//
//  WalkSession.swift
//  OllieShared
//
//  Display-only model for grouping walk events with child potty events

import Foundation

/// A walk session combining a walk event with its contained potty events
public struct WalkSession: Identifiable, Sendable {
    public let id: UUID
    public let walkEvent: PuppyEvent
    public let childPottyEvents: [PuppyEvent]

    public init(id: UUID, walkEvent: PuppyEvent, childPottyEvents: [PuppyEvent]) {
        self.id = id
        self.walkEvent = walkEvent
        self.childPottyEvents = childPottyEvents
    }

    /// Start time of the walk
    public var startTime: Date { walkEvent.time }

    /// Duration in minutes (from walk event)
    public var durationMinutes: Int? { walkEvent.durationMin }

    /// Spot name (if walk was at a saved spot)
    public var spotName: String? { walkEvent.spotName }

    /// Note attached to the walk
    public var note: String? { walkEvent.note }

    /// Whether a pee occurred during the walk
    public var didPee: Bool {
        childPottyEvents.contains { $0.type == .plassen }
    }

    /// Whether a poop occurred during the walk
    public var didPoop: Bool {
        childPottyEvents.contains { $0.type == .poepen }
    }

    /// All event IDs in this session
    public var allEventIds: Set<UUID> {
        Set([walkEvent.id] + childPottyEvents.map(\.id))
    }

    /// Formatted duration string
    public var durationString: String? {
        guard let minutes = durationMinutes else { return nil }
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
}
