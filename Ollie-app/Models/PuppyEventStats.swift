//
//  PuppyEventStats.swift
//  Otis-app
//
//  Pre-computed statistics from a collection of PuppyEvents.
//  Use this to avoid repeated computation of common metrics.

import Foundation
import OtisShared

/// Pre-computed statistics from a collection of PuppyEvents
struct PuppyEventStats {

    // MARK: - Source Data

    /// The events used to compute these stats
    let events: [PuppyEvent]

    /// Time range covered by these events
    let dateRange: ClosedRange<Date>?

    // MARK: - Pre-computed Counts

    /// Total pee events
    let peeCount: Int

    /// Outdoor pee events
    let outdoorPeeCount: Int

    /// Indoor pee events (accidents)
    let indoorPeeCount: Int

    /// Total poop events
    let poopCount: Int

    /// Outdoor poop events
    let outdoorPoopCount: Int

    /// Indoor poop events
    let indoorPoopCount: Int

    /// Total meal events
    let mealCount: Int

    /// Total walk events
    let walkCount: Int

    /// Total walk duration in minutes
    let walkDurationMinutes: Int

    /// Total sleep events
    let sleepCount: Int

    /// Total sleep duration in minutes
    let sleepMinutes: Int

    /// Total training events
    let trainingCount: Int

    // MARK: - Computed Properties

    /// Total potty events (pee + poop)
    var totalPottyCount: Int {
        peeCount + poopCount
    }

    /// Outdoor potty rate (0.0 to 1.0)
    var outdoorPottyRate: Double {
        let total = peeCount + poopCount
        guard total > 0 else { return 1.0 }
        let outdoorCount = outdoorPeeCount + outdoorPoopCount
        return Double(outdoorCount) / Double(total)
    }

    /// Outdoor potty percentage (0-100)
    var outdoorPottyPercentage: Int {
        Int(outdoorPottyRate * 100)
    }

    /// Outdoor pee rate (0.0 to 1.0)
    var outdoorPeeRate: Double {
        guard peeCount > 0 else { return 1.0 }
        return Double(outdoorPeeCount) / Double(peeCount)
    }

    /// Outdoor pee percentage (0-100)
    var outdoorPeePercentage: Int {
        Int(outdoorPeeRate * 100)
    }

    /// Whether there were any accidents
    var hasAccidents: Bool {
        indoorPeeCount > 0 || indoorPoopCount > 0
    }

    /// Total accident count
    var accidentCount: Int {
        indoorPeeCount + indoorPoopCount
    }

    /// Sleep hours as formatted string
    var sleepHoursFormatted: String {
        let hours = sleepMinutes / 60
        let mins = sleepMinutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    // MARK: - Initializers

    /// Initialize with pre-computed values
    init(
        events: [PuppyEvent],
        dateRange: ClosedRange<Date>? = nil,
        peeCount: Int,
        outdoorPeeCount: Int,
        indoorPeeCount: Int,
        poopCount: Int,
        outdoorPoopCount: Int,
        indoorPoopCount: Int,
        mealCount: Int,
        walkCount: Int,
        walkDurationMinutes: Int,
        sleepCount: Int,
        sleepMinutes: Int,
        trainingCount: Int
    ) {
        self.events = events
        self.dateRange = dateRange
        self.peeCount = peeCount
        self.outdoorPeeCount = outdoorPeeCount
        self.indoorPeeCount = indoorPeeCount
        self.poopCount = poopCount
        self.outdoorPoopCount = outdoorPoopCount
        self.indoorPoopCount = indoorPoopCount
        self.mealCount = mealCount
        self.walkCount = walkCount
        self.walkDurationMinutes = walkDurationMinutes
        self.sleepCount = sleepCount
        self.sleepMinutes = sleepMinutes
        self.trainingCount = trainingCount
    }

    /// Compute stats from a collection of events
    init(from events: [PuppyEvent]) {
        self.events = events

        // Compute date range
        if let firstDate = events.map({ $0.time }).min(),
           let lastDate = events.map({ $0.time }).max() {
            self.dateRange = firstDate...lastDate
        } else {
            self.dateRange = nil
        }

        // Pre-filter for efficiency
        let peeEvents = events.pee()
        let poopEvents = events.poop()

        // Pee stats
        self.peeCount = peeEvents.count
        self.outdoorPeeCount = peeEvents.outdoor().count
        self.indoorPeeCount = peeEvents.indoor().count

        // Poop stats
        self.poopCount = poopEvents.count
        self.outdoorPoopCount = poopEvents.outdoor().count
        self.indoorPoopCount = poopEvents.indoor().count

        // Meal stats
        self.mealCount = events.meals().count

        // Walk stats
        let walks = events.walks()
        self.walkCount = walks.count
        self.walkDurationMinutes = walks.compactMap { $0.durationMin }.reduce(0, +)

        // Sleep stats
        let sleeps = events.sleeps()
        self.sleepCount = sleeps.count
        self.sleepMinutes = SleepCalculations.totalSleepToday(events: events)

        // Training stats
        self.trainingCount = events.filter { $0.type == .training }.count
    }

    // MARK: - Factory Methods

    /// Create stats for today's events
    static func today(from allEvents: [PuppyEvent]) -> PuppyEventStats {
        let todayEvents = allEvents.filter { Calendar.current.isDateInToday($0.time) }
        return PuppyEventStats(from: todayEvents)
    }

    /// Create stats for a specific date
    static func forDate(_ date: Date, from allEvents: [PuppyEvent]) -> PuppyEventStats {
        let calendar = Calendar.current
        let dateEvents = allEvents.filter { calendar.isDate($0.time, inSameDayAs: date) }
        return PuppyEventStats(from: dateEvents)
    }

    /// Create stats for the last N days
    static func lastDays(_ n: Int, from allEvents: [PuppyEvent]) -> PuppyEventStats {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -n, to: Date()) else {
            return PuppyEventStats(from: [])
        }
        let recentEvents = allEvents.filter { $0.time >= startDate }
        return PuppyEventStats(from: recentEvents)
    }

    /// Create stats for events in a date range
    static func forRange(_ range: ClosedRange<Date>, from allEvents: [PuppyEvent]) -> PuppyEventStats {
        let rangeEvents = allEvents.filter { range.contains($0.time) }
        return PuppyEventStats(from: rangeEvents)
    }

    // MARK: - Empty Stats

    /// Empty stats with no events
    static let empty = PuppyEventStats(
        events: [],
        dateRange: nil,
        peeCount: 0,
        outdoorPeeCount: 0,
        indoorPeeCount: 0,
        poopCount: 0,
        outdoorPoopCount: 0,
        indoorPoopCount: 0,
        mealCount: 0,
        walkCount: 0,
        walkDurationMinutes: 0,
        sleepCount: 0,
        sleepMinutes: 0,
        trainingCount: 0
    )
}

// MARK: - Equatable

extension PuppyEventStats: Equatable {
    static func == (lhs: PuppyEventStats, rhs: PuppyEventStats) -> Bool {
        // Compare computed values, not the events array (for performance)
        lhs.peeCount == rhs.peeCount &&
        lhs.outdoorPeeCount == rhs.outdoorPeeCount &&
        lhs.poopCount == rhs.poopCount &&
        lhs.outdoorPoopCount == rhs.outdoorPoopCount &&
        lhs.mealCount == rhs.mealCount &&
        lhs.walkCount == rhs.walkCount &&
        lhs.sleepMinutes == rhs.sleepMinutes &&
        lhs.trainingCount == rhs.trainingCount
    }
}
