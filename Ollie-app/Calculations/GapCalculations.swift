//
//  GapCalculations.swift
//  Ollie-app
//
//  Gap analysis calculations ported from web app's gaps.js

import Foundation

/// A single gap between potty events
struct PottyGap: Equatable {
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    let startLocation: EventLocation?
    let endLocation: EventLocation?

    var isOutdoorToOutdoor: Bool {
        startLocation == .buiten && endLocation == .buiten
    }

    var endedIndoor: Bool {
        endLocation == .binnen
    }
}

/// Statistics about potty gaps
struct GapStats: Equatable {
    let count: Int
    let minMinutes: Int
    let maxMinutes: Int
    let avgMinutes: Int
    let medianMinutes: Int
    let outdoorCount: Int
    let indoorCount: Int

    var outdoorPercentage: Int {
        guard count > 0 else { return 0 }
        return (outdoorCount * 100) / count
    }

    static var empty: GapStats {
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
struct GapCalculations {

    /// Minimum hour for daytime gaps (exclude overnight)
    static let daytimeStartHour = 7

    /// Maximum hour for daytime gaps (exclude overnight)
    static let daytimeEndHour = 23

    /// Maximum gap to include (filter out overnight gaps)
    static let maxGapMinutes = 8 * 60  // 8 hours

    // MARK: - Public Methods

    /// Calculate gaps between potty events
    /// - Parameters:
    ///   - events: Array of puppy events
    ///   - filterOvernight: Whether to exclude overnight gaps (> 8 hours or outside 7-23:00)
    /// - Returns: Array of potty gaps
    static func calculatePottyGaps(
        events: [PuppyEvent],
        filterOvernight: Bool = true
    ) -> [PottyGap] {
        // Filter to potty events and sort chronologically
        let pottyEvents = events
            .filter { $0.type == .plassen }
            .sorted { $0.time < $1.time }

        guard pottyEvents.count >= 2 else { return [] }

        var gaps: [PottyGap] = []

        for i in 1..<pottyEvents.count {
            let start = pottyEvents[i - 1]
            let end = pottyEvents[i]
            let duration = end.time.minutesSince(start.time)

            // Skip if filtering overnight and this is an overnight gap
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
    /// - Parameter gaps: Array of potty gaps
    /// - Returns: Gap statistics
    static func calculateGapStats(gaps: [PottyGap]) -> GapStats {
        guard !gaps.isEmpty else { return .empty }

        let durations = gaps.map { $0.durationMinutes }.sorted()

        let minVal = durations.first ?? 0
        let maxVal = durations.last ?? 0
        let sum = durations.reduce(0, +)
        let avg = sum / durations.count

        // Calculate median
        let median: Int
        if durations.count % 2 == 0 {
            let mid = durations.count / 2
            median = (durations[mid - 1] + durations[mid]) / 2
        } else {
            median = durations[durations.count / 2]
        }

        // Count indoor vs outdoor
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
    /// - Parameter events: Array of puppy events
    /// - Returns: Array of potty gaps from today
    static func todayGaps(events: [PuppyEvent]) -> [PottyGap] {
        let todayEvents = events.filter { Calendar.current.isDateInToday($0.time) }
        return calculatePottyGaps(events: todayEvents, filterOvernight: false)
    }

    /// Get gaps for the last N days
    /// - Parameters:
    ///   - events: Array of puppy events
    ///   - days: Number of days to include
    /// - Returns: Array of potty gaps
    static func recentGaps(events: [PuppyEvent], days: Int = 7) -> [PottyGap] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let recentEvents = events.filter { $0.time >= cutoff }
        return calculatePottyGaps(events: recentEvents, filterOvernight: true)
    }

    /// Format duration for display
    static func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) uur"
            }
            return "\(hours)u \(mins)m"
        }
    }

    // MARK: - Private Helpers

    /// Check if a gap falls within daytime hours
    private static func isDaytimeGap(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current

        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)

        // Both start and end should be in daytime
        let startInDaytime = startHour >= daytimeStartHour && startHour < daytimeEndHour
        let endInDaytime = endHour >= daytimeStartHour && endHour < daytimeEndHour

        return startInDaytime && endInDaytime
    }
}
