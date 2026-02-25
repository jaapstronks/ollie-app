//
//  PoopPatternAnalyzer.swift
//  Ollie-app
//
//  Analyzes historical poop patterns for pattern-aware predictions
//

import Foundation
import OllieShared

/// Analyzes historical poop patterns
struct PoopPatternAnalyzer {

    /// Minutes after walk to check for poop correlation
    static let postWalkWindowMinutes = 30

    // MARK: - Pattern Analysis

    /// Analyze poop patterns from historical data
    static func analyzePattern(events: [PuppyEvent], currentTime: Date = Date()) -> PoopPattern {
        // Filter to poop events only, exclude today
        let allPoops = events.poop()
        let excludingToday = allPoops.filter { !$0.time.isToday }
        let poopEvents = excludingToday.chronological()

        guard !poopEvents.isEmpty else { return .empty }

        // Group by day to calculate daily counts
        let groupedByDay = poopEvents.groupedByDate()

        let dailyCounts = groupedByDay.values.map { $0.count }
        let daysAnalyzed = groupedByDay.count

        guard daysAnalyzed > 0 else { return .empty }

        // Calculate median daily count
        let medianDaily = calculateMedian(dailyCounts.map { Double($0) })

        // Calculate daytime gaps
        let daytimeGaps = PoopGapCalculator.calculateDaytimeGaps(poopEvents: poopEvents, currentTime: currentTime)
        let medianGap = calculateMedianInt(daytimeGaps)

        // Calculate walk-poop correlation
        let walkEvents = events.walks()
        let postWalkPoopRate = calculatePostWalkPoopRate(
            walkEvents: walkEvents,
            poopEvents: poopEvents
        )

        return PoopPattern(
            medianDailyCount: medianDaily,
            medianDaytimeGapMinutes: medianGap,
            typicalPostWalkPoopRate: postWalkPoopRate,
            daysAnalyzed: daysAnalyzed
        )
    }

    // MARK: - Walk Correlation

    /// Calculate how often poops follow walks
    private static func calculatePostWalkPoopRate(
        walkEvents: [PuppyEvent],
        poopEvents: [PuppyEvent]
    ) -> Double {
        guard !walkEvents.isEmpty else { return 0 }

        var walksWithPoop = 0

        for walk in walkEvents {
            let walkDuration = walk.durationMin ?? 30
            let walkEnd = walk.time.addingTimeInterval(Double(walkDuration) * 60)

            // Check if any poop occurred during this walk
            let poopDuringWalk = poopEvents.contains { poop in
                poop.time >= walk.time && poop.time <= walkEnd
            }

            if poopDuringWalk {
                walksWithPoop += 1
            }
        }

        return Double(walksWithPoop) / Double(walkEvents.count)
    }

    // MARK: - Helpers

    private static func calculateMedian(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        if sorted.count % 2 == 0 {
            let mid = sorted.count / 2
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[sorted.count / 2]
        }
    }

    private static func calculateMedianInt(_ values: [Int]) -> Int {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        if sorted.count % 2 == 0 {
            let mid = sorted.count / 2
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[sorted.count / 2]
        }
    }
}
