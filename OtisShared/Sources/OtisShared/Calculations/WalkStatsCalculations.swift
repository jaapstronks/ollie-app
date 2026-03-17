//
//  WalkStatsCalculations.swift
//  OtisShared
//
//  Rolling walk statistics for adaptive walk target nudges
//

import Foundation

/// Rolling statistics about walk frequency
public struct WalkStats: Sendable {
    /// Number of days in the analysis period
    public let periodDays: Int

    /// Total walks logged in the period
    public let totalWalks: Int

    /// Number of days with at least one walk logged
    public let daysWithData: Int

    /// Average walks per day (based on days with data)
    public let averageWalksPerDay: Double

    /// User's configured target walks per day
    public let scheduledWalksPerDay: Int

    /// How far user is from target (negative = below target)
    /// e.g., -0.30 means 30% below target
    public var differenceFromTarget: Double {
        guard scheduledWalksPerDay > 0 else { return 0 }
        return (averageWalksPerDay - Double(scheduledWalksPerDay)) / Double(scheduledWalksPerDay)
    }

    /// Whether to show a nudge to adjust walk schedule
    /// Shows when: 7+ days of data AND 30%+ below target
    public var shouldShowNudge: Bool {
        daysWithData >= 7 && differenceFromTarget <= -0.30
    }

    public init(
        periodDays: Int,
        totalWalks: Int,
        daysWithData: Int,
        averageWalksPerDay: Double,
        scheduledWalksPerDay: Int
    ) {
        self.periodDays = periodDays
        self.totalWalks = totalWalks
        self.daysWithData = daysWithData
        self.averageWalksPerDay = averageWalksPerDay
        self.scheduledWalksPerDay = scheduledWalksPerDay
    }
}

/// Calculations for walk statistics
public struct WalkStatsCalculations {

    // MARK: - Public API

    /// Calculate rolling walk statistics over a period
    /// - Parameters:
    ///   - events: Events to analyze (should include at least `periodDays` worth of data)
    ///   - periodDays: Number of days to analyze (default: 14)
    ///   - scheduledWalksPerDay: User's configured target walks per day
    /// - Returns: Walk statistics, or nil if insufficient data
    public static func calculateRollingStats(
        from events: [PuppyEvent],
        periodDays: Int = 14,
        scheduledWalksPerDay: Int
    ) -> WalkStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let periodStart = today.addingDays(-periodDays)

        // Single pass: filter walks and group by day simultaneously
        var walksByDay: [Date: Int] = [:]
        var totalWalks = 0

        for event in events {
            guard event.type == .uitlaten else { continue }
            let eventDay = calendar.startOfDay(for: event.time)
            guard eventDay >= periodStart && eventDay < today else { continue }

            totalWalks += 1
            walksByDay[eventDay, default: 0] += 1
        }

        let daysWithData = walksByDay.count
        let averageWalksPerDay = daysWithData > 0 ? Double(totalWalks) / Double(daysWithData) : 0

        return WalkStats(
            periodDays: periodDays,
            totalWalks: totalWalks,
            daysWithData: daysWithData,
            averageWalksPerDay: averageWalksPerDay,
            scheduledWalksPerDay: scheduledWalksPerDay
        )
    }

    /// Optimized: Calculate using pre-categorized events
    public static func calculateRollingStats(
        categories: EventCategories,
        periodDays: Int = 14,
        scheduledWalksPerDay: Int
    ) -> WalkStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let periodStart = today.addingDays(-periodDays)

        // Use lightweight refs instead of full structs
        var walksByDay: [Date: Int] = [:]
        var totalWalks = 0

        for walkRef in categories.walks {
            let eventDay = calendar.startOfDay(for: walkRef.time)
            guard eventDay >= periodStart && eventDay < today else { continue }

            totalWalks += 1
            walksByDay[eventDay, default: 0] += 1
        }

        let daysWithData = walksByDay.count
        let averageWalksPerDay = daysWithData > 0 ? Double(totalWalks) / Double(daysWithData) : 0

        return WalkStats(
            periodDays: periodDays,
            totalWalks: totalWalks,
            daysWithData: daysWithData,
            averageWalksPerDay: averageWalksPerDay,
            scheduledWalksPerDay: scheduledWalksPerDay
        )
    }
}
