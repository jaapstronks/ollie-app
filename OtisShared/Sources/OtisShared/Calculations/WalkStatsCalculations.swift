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

        // Filter to walks within the period (excluding today to avoid incomplete day)
        let periodStart = today.addingDays(-periodDays)
        let walks = events.walks().filter { event in
            let eventDay = calendar.startOfDay(for: event.time)
            return eventDay >= periodStart && eventDay < today
        }

        // Group walks by day
        var walksByDay: [Date: Int] = [:]
        for walk in walks {
            let day = calendar.startOfDay(for: walk.time)
            walksByDay[day, default: 0] += 1
        }

        let totalWalks = walks.count
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
