//
//  PoopGapCalculator.swift
//  Ollie-app
//
//  Calculates daytime gaps between poop events
//

import Foundation
import OllieShared

/// Calculates daytime-only gaps between poop events
struct PoopGapCalculator {

    // MARK: - Gap Calculations

    /// Calculate daytime-only gaps between poop events
    static func calculateDaytimeGaps(poopEvents: [PuppyEvent], currentTime: Date) -> [Int] {
        guard poopEvents.count >= 2 else { return [] }

        var gaps: [Int] = []

        for i in 1..<poopEvents.count {
            let start = poopEvents[i - 1].time
            let end = poopEvents[i].time

            // Only count gaps within the same day or consecutive daytime periods
            let gap = calculateDaytimeGapMinutes(from: start, to: end)

            // Filter out overnight gaps (> 12 hours is definitely overnight)
            if let gap = gap, gap > 0 && gap < 12 * 60 {
                gaps.append(gap)
            }
        }

        return gaps
    }

    /// Calculate minutes between two times, excluding night hours
    /// Returns nil if the entire period is during night
    static func calculateDaytimeGapMinutes(from startTime: Date?, to endTime: Date) -> Int? {
        guard let start = startTime else { return nil }

        let calendar = Calendar.current
        var daytimeMinutes = 0
        var current = start

        // Iterate through the time range in 15-minute chunks
        while current < endTime {
            let hour = calendar.component(.hour, from: current)

            // Only count daytime hours (06:00 - 23:00)
            if !Constants.isNightTime(hour: hour) {
                daytimeMinutes += 15
            }

            current = current.addingTimeInterval(15 * 60)
        }

        return daytimeMinutes > 0 ? daytimeMinutes : nil
    }

    // MARK: - Walk Correlation

    /// Check if there was a recent walk without a subsequent poop
    static func checkRecentWalkWithoutPoop(
        todayEvents: [PuppyEvent],
        lastPoopTime: Date?,
        currentTime: Date,
        postWalkWindowMinutes: Int
    ) -> Bool {
        // Find the most recent walk today
        let todayWalks = todayEvents.walks().reverseChronological()

        guard let lastWalk = todayWalks.first else { return false }

        // Walk must have ended (check for duration or assume 30 min if none)
        let walkDuration = lastWalk.durationMin ?? 30
        let walkEndTime = lastWalk.time.addingTimeInterval(Double(walkDuration) * 60)

        // Walk must have ended within the window
        let minutesSinceWalkEnd = currentTime.minutesSince(walkEndTime)
        guard minutesSinceWalkEnd >= 0 && minutesSinceWalkEnd <= postWalkWindowMinutes else {
            return false
        }

        // Check if there was a poop during or after this walk
        if let lastPoop = lastPoopTime {
            // If last poop was during/after walk start, they did poop
            if lastPoop >= lastWalk.time {
                return false
            }
        }

        // Walk completed, no poop logged during/after it
        return true
    }
}
