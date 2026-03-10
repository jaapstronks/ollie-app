//
//  EventCategories.swift
//  OtisShared
//
//  Single-pass event categorization for efficient calculations.
//  Avoids repeated filter() calls that copy PuppyEvent structs.

import Foundation

/// Lightweight reference to an event for calculations.
/// Only stores the fields needed for most calculations, avoiding full struct copies.
public struct EventRef: Sendable {
    public let index: Int
    public let time: Date
    public let type: EventType
    public let location: EventLocation?
    public let durationMin: Int?

    public init(index: Int, event: PuppyEvent) {
        self.index = index
        self.time = event.time
        self.type = event.type
        self.location = event.location
        self.durationMin = event.durationMin
    }
}

/// Pre-categorized event indices for efficient access.
/// Built in a single O(n) pass over the events array.
public struct EventCategories: Sendable {
    /// All events as lightweight refs, sorted chronologically
    public let allRefs: [EventRef]

    /// Indices into allRefs for each event type
    public let peeIndices: [Int]
    public let poopIndices: [Int]
    public let sleepIndices: [Int]
    public let wakeIndices: [Int]
    public let mealIndices: [Int]
    public let walkIndices: [Int]
    public let drinkIndices: [Int]
    public let trainingIndices: [Int]
    public let socialIndices: [Int]

    /// Combined indices for common queries
    public let pottyIndices: [Int]
    public let sleepWakeIndices: [Int]

    // MARK: - Initialization

    /// Build categories from events in a single pass
    /// - Parameter events: Array of PuppyEvent (will be sorted chronologically)
    public init(events: [PuppyEvent]) {
        // Sort once, store as refs
        let sorted = events.sorted { $0.time < $1.time }
        var refs: [EventRef] = []
        refs.reserveCapacity(sorted.count)

        var pee: [Int] = []
        var poop: [Int] = []
        var sleep: [Int] = []
        var wake: [Int] = []
        var meal: [Int] = []
        var walk: [Int] = []
        var drink: [Int] = []
        var training: [Int] = []
        var social: [Int] = []
        var potty: [Int] = []
        var sleepWake: [Int] = []

        for (index, event) in sorted.enumerated() {
            let ref = EventRef(index: index, event: event)
            refs.append(ref)

            switch event.type {
            case .plassen:
                pee.append(index)
                potty.append(index)
            case .poepen:
                poop.append(index)
                potty.append(index)
            case .slapen:
                sleep.append(index)
                sleepWake.append(index)
            case .ontwaken:
                wake.append(index)
                sleepWake.append(index)
            case .eten:
                meal.append(index)
            case .uitlaten:
                walk.append(index)
            case .drinken:
                drink.append(index)
            case .training:
                training.append(index)
            case .sociaal:
                social.append(index)
            default:
                break
            }
        }

        self.allRefs = refs
        self.peeIndices = pee
        self.poopIndices = poop
        self.sleepIndices = sleep
        self.wakeIndices = wake
        self.mealIndices = meal
        self.walkIndices = walk
        self.drinkIndices = drink
        self.trainingIndices = training
        self.socialIndices = social
        self.pottyIndices = potty
        self.sleepWakeIndices = sleepWake
    }

    // MARK: - Accessors

    /// Get refs for pee events
    public var pees: [EventRef] {
        peeIndices.map { allRefs[$0] }
    }

    /// Get refs for poop events
    public var poops: [EventRef] {
        poopIndices.map { allRefs[$0] }
    }

    /// Get refs for all potty events
    public var pottyEvents: [EventRef] {
        pottyIndices.map { allRefs[$0] }
    }

    /// Get refs for sleep events
    public var sleeps: [EventRef] {
        sleepIndices.map { allRefs[$0] }
    }

    /// Get refs for wake events
    public var wakes: [EventRef] {
        wakeIndices.map { allRefs[$0] }
    }

    /// Get refs for sleep and wake events (already sorted)
    public var sleepWakeEvents: [EventRef] {
        sleepWakeIndices.map { allRefs[$0] }
    }

    /// Get refs for meal events
    public var meals: [EventRef] {
        mealIndices.map { allRefs[$0] }
    }

    /// Get refs for walk events
    public var walks: [EventRef] {
        walkIndices.map { allRefs[$0] }
    }

    /// Get refs for drink events
    public var drinks: [EventRef] {
        drinkIndices.map { allRefs[$0] }
    }

    /// Get refs for training events
    public var trainingSessions: [EventRef] {
        trainingIndices.map { allRefs[$0] }
    }

    /// Get refs for social events
    public var socialEvents: [EventRef] {
        socialIndices.map { allRefs[$0] }
    }

    // MARK: - Queries

    /// Find the first potty event after a given time within a window
    /// - Parameters:
    ///   - time: Start time to search from
    ///   - windowMinutes: Maximum minutes after time to search
    /// - Returns: The first matching potty event ref, or nil
    public func firstPottyAfter(time: Date, windowMinutes: Int = 30) -> EventRef? {
        let windowEnd = time.addingTimeInterval(Double(windowMinutes * 60))

        // Binary search for start position would be more efficient for large arrays,
        // but linear scan is fine for typical daily event counts (<100)
        for index in pottyIndices {
            let ref = allRefs[index]
            guard ref.time > time else { continue }
            guard ref.time <= windowEnd else { return nil }
            guard ref.location != nil else { continue }
            return ref
        }
        return nil
    }

    /// Check if there's an active coverage gap
    public func hasActiveCoverageGap(in events: [PuppyEvent]) -> Bool {
        // Coverage gaps need the full event, check the original array
        for ref in allRefs.reversed() {
            let event = events.first { $0.time == ref.time && $0.type == ref.type }
            if event?.type == .coverageGap && event?.endTime == nil {
                return true
            }
        }
        return false
    }
}

// MARK: - Array Extension for Quick Access

extension Array where Element == PuppyEvent {
    /// Create categorized indices for efficient repeated queries
    public func categorized() -> EventCategories {
        EventCategories(events: self)
    }
}
