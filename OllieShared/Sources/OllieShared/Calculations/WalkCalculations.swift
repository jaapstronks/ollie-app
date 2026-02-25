//
//  WalkCalculations.swift
//  OllieShared
//
//  Calculations for grouping walks with their contained potty events

import Foundation

public struct WalkCalculations {

    /// Group walk events with their child potty events into WalkSessions
    public static func walkSessions(from events: [PuppyEvent]) -> [WalkSession] {
        let walkEvents = events.walks()

        return walkEvents.compactMap { walkEvent -> WalkSession? in
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

    /// Get IDs of potty events contained within walks
    public static func containedPottyEventIds(from events: [PuppyEvent]) -> Set<UUID> {
        let pottyEvents = events.filter { event in
            event.parentWalkId != nil &&
            (event.type == .plassen || event.type == .poepen)
        }
        return Set(pottyEvents.map(\.id))
    }

    /// Calculate the midpoint timestamp for a potty event during a walk
    public static func pottyTimestamp(walkStart: Date, durationMin: Int) -> Date {
        let midpointMinutes = Double(durationMin) / 2.0
        return walkStart.addingTimeInterval(midpointMinutes * 60)
    }

    /// Get IDs of walk events
    public static func walkEventIds(from events: [PuppyEvent]) -> Set<UUID> {
        Set(events.walks().map(\.id))
    }
}
