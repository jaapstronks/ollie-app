//
//  CoverageGapFilter.swift
//  OllieShared
//
//  Helper functions for filtering calculations during coverage gaps
//

import Foundation

/// Utility functions for filtering calculations during coverage gaps
public struct CoverageGapFilter {

    /// Check if an interval spans any coverage gap
    /// Used to exclude intervals that cross coverage gaps from statistics
    public static func intervalSpansGap(start: Date, end: Date, gaps: [PuppyEvent]) -> Bool {
        let coverageGaps = gaps.filter { $0.type == .coverageGap }
        return coverageGaps.contains { gap in
            let gapStart = gap.time
            let gapEnd = gap.endTime ?? Date.distantFuture
            // Overlap exists if interval starts before gap ends AND interval ends after gap starts
            return start < gapEnd && end > gapStart
        }
    }

    /// Filter potty gap intervals, excluding those that span coverage gaps
    /// Returns filtered gaps and count of excluded intervals
    public static func filterPottyGaps(
        gaps: [(start: Date, end: Date, minutes: Int)],
        coverageGaps: [PuppyEvent]
    ) -> (filtered: [(start: Date, end: Date, minutes: Int)], excludedCount: Int) {
        let filtered = gaps.filter { gap in
            !intervalSpansGap(start: gap.start, end: gap.end, gaps: coverageGaps)
        }
        let excludedCount = gaps.count - filtered.count
        return (filtered, excludedCount)
    }

    /// Check if a specific time falls within any coverage gap
    public static func isTimeCoveredByGap(_ time: Date, gaps: [PuppyEvent]) -> Bool {
        let coverageGaps = gaps.filter { $0.type == .coverageGap }
        return coverageGaps.contains { gap in
            let gapStart = gap.time
            let gapEnd = gap.endTime ?? Date.distantFuture
            return time >= gapStart && time <= gapEnd
        }
    }

    /// Get coverage gaps that overlap with a date range
    public static func gapsOverlapping(start: Date, end: Date, gaps: [PuppyEvent]) -> [PuppyEvent] {
        let coverageGaps = gaps.filter { $0.type == .coverageGap }
        return coverageGaps.filter { gap in
            let gapStart = gap.time
            let gapEnd = gap.endTime ?? Date.distantFuture
            return gapStart <= end && gapEnd >= start
        }
    }

    /// Filter events to exclude those that occurred during coverage gaps
    public static func filterEventsOutsideGaps(events: [PuppyEvent], gaps: [PuppyEvent]) -> [PuppyEvent] {
        return events.filter { event in
            !isTimeCoveredByGap(event.time, gaps: gaps)
        }
    }

    /// Check if there's an active (ongoing) coverage gap
    public static func hasActiveGap(gaps: [PuppyEvent]) -> Bool {
        return gaps.contains { $0.type == .coverageGap && $0.endTime == nil }
    }

    /// Get the currently active coverage gap if any
    public static func activeGap(gaps: [PuppyEvent]) -> PuppyEvent? {
        return gaps.first { $0.type == .coverageGap && $0.endTime == nil }
    }
}
