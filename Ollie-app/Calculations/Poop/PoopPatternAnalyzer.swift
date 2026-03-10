//
//  PoopPatternAnalyzer.swift
//  Otis-app
//
//  Analyzes historical poop patterns for pattern-aware predictions
//  Optimized: Uses EventCategories for single-pass event filtering
//

import Foundation
import OtisShared

/// Analyzes historical poop patterns
struct PoopPatternAnalyzer {

    /// Minutes after walk to check for poop correlation
    static let postWalkWindowMinutes = 30

    // MARK: - Pattern Analysis

    /// Analyze poop patterns from historical data
    static func analyzePattern(events: [PuppyEvent], currentTime: Date = Date()) -> PoopPattern {
        // Use optimized single-pass categorization
        let categories = events.categorized()
        return analyzePattern(categories: categories, currentTime: currentTime)
    }

    /// Optimized: Analyze patterns using pre-categorized events
    static func analyzePattern(categories: EventCategories, currentTime: Date = Date()) -> PoopPattern {
        // Filter poop refs to exclude today (lightweight - no struct copies)
        let todayStart = Calendar.current.startOfDay(for: currentTime)
        let poopRefs = categories.poops.filter { $0.time < todayStart }

        guard !poopRefs.isEmpty else { return .empty }

        // Group by day to calculate daily counts
        let calendar = Calendar.current
        var countsByDay: [Date: Int] = [:]
        for ref in poopRefs {
            let dayStart = calendar.startOfDay(for: ref.time)
            countsByDay[dayStart, default: 0] += 1
        }

        let dailyCounts = Array(countsByDay.values)
        let daysAnalyzed = countsByDay.count

        guard daysAnalyzed > 0 else { return .empty }

        // Calculate median daily count
        let medianDaily = calculateMedian(dailyCounts.map { Double($0) })

        // Calculate daytime gaps using refs
        let daytimeGaps = PoopGapCalculator.calculateDaytimeGaps(poopRefs: poopRefs, currentTime: currentTime)
        let medianGap = calculateMedianInt(daytimeGaps)

        // Calculate walk-poop correlation using refs
        let walkRefs = categories.walks
        let postWalkPoopRate = calculatePostWalkPoopRate(
            walkRefs: walkRefs,
            poopRefs: poopRefs
        )

        return PoopPattern(
            medianDailyCount: medianDaily,
            medianDaytimeGapMinutes: medianGap,
            typicalPostWalkPoopRate: postWalkPoopRate,
            daysAnalyzed: daysAnalyzed
        )
    }

    // MARK: - Walk Correlation

    /// Calculate how often poops follow walks (optimized with refs)
    private static func calculatePostWalkPoopRate(
        walkRefs: [EventRef],
        poopRefs: [EventRef]
    ) -> Double {
        guard !walkRefs.isEmpty else { return 0 }

        var walksWithPoop = 0

        for walk in walkRefs {
            let walkDuration = walk.durationMin ?? 30
            let walkEnd = walk.time.addingTimeInterval(Double(walkDuration) * 60)

            // Check if any poop occurred during this walk
            let poopDuringWalk = poopRefs.contains { poop in
                poop.time >= walk.time && poop.time <= walkEnd
            }

            if poopDuringWalk {
                walksWithPoop += 1
            }
        }

        return Double(walksWithPoop) / Double(walkRefs.count)
    }

    /// Legacy: Calculate using full PuppyEvent arrays
    private static func calculatePostWalkPoopRate(
        walkEvents: [PuppyEvent],
        poopEvents: [PuppyEvent]
    ) -> Double {
        guard !walkEvents.isEmpty else { return 0 }

        var walksWithPoop = 0

        for walk in walkEvents {
            let walkDuration = walk.durationMin ?? 30
            let walkEnd = walk.time.addingTimeInterval(Double(walkDuration) * 60)

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
