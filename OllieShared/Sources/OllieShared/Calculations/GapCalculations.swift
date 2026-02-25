//
//  GapCalculations.swift
//  OllieShared
//
//  Gap analysis calculations ported from web app's gaps.js

import Foundation

/// A single gap between potty events
public struct PottyGap: Equatable, Sendable {
    public let startTime: Date
    public let endTime: Date
    public let durationMinutes: Int
    public let startLocation: EventLocation?
    public let endLocation: EventLocation?

    public init(startTime: Date, endTime: Date, durationMinutes: Int, startLocation: EventLocation?, endLocation: EventLocation?) {
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.startLocation = startLocation
        self.endLocation = endLocation
    }

    public var isOutdoorToOutdoor: Bool {
        startLocation == .buiten && endLocation == .buiten
    }

    public var endedIndoor: Bool {
        endLocation == .binnen
    }
}

/// Statistics about potty gaps
public struct GapStats: Equatable, Sendable {
    public let count: Int
    public let minMinutes: Int
    public let maxMinutes: Int
    public let avgMinutes: Int
    public let medianMinutes: Int
    public let outdoorCount: Int
    public let indoorCount: Int

    public init(count: Int, minMinutes: Int, maxMinutes: Int, avgMinutes: Int, medianMinutes: Int, outdoorCount: Int, indoorCount: Int) {
        self.count = count
        self.minMinutes = minMinutes
        self.maxMinutes = maxMinutes
        self.avgMinutes = avgMinutes
        self.medianMinutes = medianMinutes
        self.outdoorCount = outdoorCount
        self.indoorCount = indoorCount
    }

    public var outdoorPercentage: Int {
        guard count > 0 else { return 0 }
        return (outdoorCount * 100) / count
    }

    public static var empty: GapStats {
        GapStats(
            count: 0,
            minMinutes: 0,
            maxMinutes: 0,
            avgMinutes: 0,
            medianMinutes: 0,
            outdoorCount: 0,
            indoorCount: 0
        )
    }
}

/// Gap calculation utilities
public struct GapCalculations {

    public static let daytimeStartHour = 7
    public static let daytimeEndHour = 23
    public static let maxGapMinutes = 8 * 60

    // MARK: - Public Methods

    /// Calculate gaps between potty events
    public static func calculatePottyGaps(
        events: [PuppyEvent],
        filterOvernight: Bool = true
    ) -> [PottyGap] {
        let pottyEvents = events.pee().chronological()

        guard pottyEvents.count >= 2 else { return [] }

        var gaps: [PottyGap] = []

        for i in 1..<pottyEvents.count {
            let start = pottyEvents[i - 1]
            let end = pottyEvents[i]
            let duration = Int(end.time.timeIntervalSince(start.time) / 60)

            if filterOvernight {
                if duration > maxGapMinutes {
                    continue
                }
                if !isDaytimeGap(start: start.time, end: end.time) {
                    continue
                }
            }

            let gap = PottyGap(
                startTime: start.time,
                endTime: end.time,
                durationMinutes: duration,
                startLocation: start.location,
                endLocation: end.location
            )
            gaps.append(gap)
        }

        return gaps
    }

    /// Calculate statistics from gaps
    public static func calculateGapStats(gaps: [PottyGap]) -> GapStats {
        guard !gaps.isEmpty else { return .empty }

        let durations = gaps.map { $0.durationMinutes }.sorted()

        let minVal = durations.first ?? 0
        let maxVal = durations.last ?? 0
        let sum = durations.reduce(0, +)
        let avg = sum / durations.count

        let median: Int
        if durations.count % 2 == 0 {
            let mid = durations.count / 2
            median = (durations[mid - 1] + durations[mid]) / 2
        } else {
            median = durations[durations.count / 2]
        }

        let outdoorCount = gaps.filter { $0.endLocation == .buiten }.count
        let indoorCount = gaps.filter { $0.endLocation == .binnen }.count

        return GapStats(
            count: gaps.count,
            minMinutes: minVal,
            maxMinutes: maxVal,
            avgMinutes: avg,
            medianMinutes: median,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Get gaps for today only
    public static func todayGaps(events: [PuppyEvent]) -> [PottyGap] {
        return calculatePottyGaps(events: events.today(), filterOvernight: false)
    }

    /// Get gaps for the last N days
    public static func recentGaps(events: [PuppyEvent], days: Int = 7) -> [PottyGap] {
        return calculatePottyGaps(events: events.lastDays(days), filterOvernight: true)
    }

    /// Format duration for display
    /// - Note: Delegates to shared DurationFormatter for consistency
    public static func formatDuration(_ minutes: Int) -> String {
        DurationFormatter.format(minutes, style: .full)
    }

    // MARK: - Private Helpers

    private static func isDaytimeGap(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current

        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)

        let startInDaytime = startHour >= daytimeStartHour && startHour < daytimeEndHour
        let endInDaytime = endHour >= daytimeStartHour && endHour < daytimeEndHour

        return startInDaytime && endInDaytime
    }
}
