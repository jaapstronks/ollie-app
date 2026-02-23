//
//  WalkSession.swift
//  Ollie-app
//
//  Display-only model for grouping walk events with child potty events
//  Keeps data storage as separate events for web app compatibility

import Foundation

/// A walk session combining a walk event with its contained potty events for display
/// This is a virtual grouping - events are still stored separately in JSONL
struct WalkSession: Identifiable {
    let id: UUID
    let walkEvent: PuppyEvent
    let childPottyEvents: [PuppyEvent]

    /// Start time of the walk
    var startTime: Date { walkEvent.time }

    /// Duration in minutes (from walk event)
    var durationMinutes: Int? { walkEvent.durationMin }

    /// Spot name (if walk was at a saved spot)
    var spotName: String? { walkEvent.spotName }

    /// Note attached to the walk
    var note: String? { walkEvent.note }

    /// Whether a pee occurred during the walk
    var didPee: Bool {
        childPottyEvents.contains { $0.type == .plassen }
    }

    /// Whether a poop occurred during the walk
    var didPoop: Bool {
        childPottyEvents.contains { $0.type == .poepen }
    }

    /// All event IDs in this session (walk + potty events)
    var allEventIds: Set<UUID> {
        Set([walkEvent.id] + childPottyEvents.map(\.id))
    }

    /// Formatted duration string (e.g., "15 min" or "1h30m")
    var durationString: String? {
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
