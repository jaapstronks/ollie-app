//
//  WalkCalculations.swift
//  Ollie-app
//
//  Calculations for grouping walks with their contained potty events

import Foundation

struct WalkCalculations {

    /// Group walk events with their child potty events into WalkSessions
    /// - Parameter events: All events for the day
    /// - Returns: Array of WalkSession objects for display
    static func walkSessions(from events: [PuppyEvent]) -> [WalkSession] {
        // Get all walk events
        let walkEvents = events.walks()

        return walkEvents.compactMap { walkEvent -> WalkSession? in
            // Find potty events that belong to this walk
            let childPottyEvents = events.filter { event in
                event.parentWalkId == walkEvent.id &&
                (event.type == .plassen || event.type == .poepen)
            }

            return WalkSession(
                id: walkEvent.id,
                walkEvent: walkEvent,
                childPottyEvents: childPottyEvents
            )
        }
    }

    /// Get IDs of potty events that are contained within walks
    /// These should be filtered out from the regular event list to avoid duplicates
    /// - Parameter events: All events for the day
    /// - Returns: Set of event IDs that are contained in walks
    static func containedPottyEventIds(from events: [PuppyEvent]) -> Set<UUID> {
        let pottyEvents = events.filter { event in
            event.parentWalkId != nil &&
            (event.type == .plassen || event.type == .poepen)
        }
        return Set(pottyEvents.map(\.id))
    }

    /// Calculate the midpoint timestamp for a potty event during a walk
    /// This ensures predictions still work correctly
    /// - Parameters:
    ///   - walkStart: Start time of the walk
    ///   - durationMin: Duration of the walk in minutes
    /// - Returns: Timestamp at the midpoint of the walk
    static func pottyTimestamp(walkStart: Date, durationMin: Int) -> Date {
        let midpointMinutes = Double(durationMin) / 2.0
        return walkStart.addingTimeInterval(midpointMinutes * 60)
    }

    /// Get IDs of walk events that have been grouped into sessions
    /// - Parameter events: All events for the day
    /// - Returns: Set of walk event IDs
    static func walkEventIds(from events: [PuppyEvent]) -> Set<UUID> {
        Set(events.walks().map(\.id))
    }
}
