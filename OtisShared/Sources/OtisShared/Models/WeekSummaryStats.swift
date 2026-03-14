//
//  WeekSummaryStats.swift
//  OtisShared
//
//  Statistics for a weekly recap

import Foundation

/// Statistics for a weekly recap
public struct WeekSummaryStats: Identifiable, Sendable {
    public let id = UUID()
    public let weekStart: Date
    public let weekEnd: Date
    public let puppyName: String
    public let totalWalks: Int
    public let totalWalkMinutes: Int
    public let totalPottyEvents: Int
    public let outdoorPottyCount: Int
    public let totalTrainingSessions: Int
    public let totalSocialEvents: Int
    public let avgSleepHours: Double
    public let photoCount: Int
    public let dayStats: [DayStats]

    public init(
        weekStart: Date,
        weekEnd: Date,
        puppyName: String,
        totalWalks: Int,
        totalWalkMinutes: Int,
        totalPottyEvents: Int,
        outdoorPottyCount: Int,
        totalTrainingSessions: Int,
        totalSocialEvents: Int,
        avgSleepHours: Double,
        photoCount: Int,
        dayStats: [DayStats]
    ) {
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.puppyName = puppyName
        self.totalWalks = totalWalks
        self.totalWalkMinutes = totalWalkMinutes
        self.totalPottyEvents = totalPottyEvents
        self.outdoorPottyCount = outdoorPottyCount
        self.totalTrainingSessions = totalTrainingSessions
        self.totalSocialEvents = totalSocialEvents
        self.avgSleepHours = avgSleepHours
        self.photoCount = photoCount
        self.dayStats = dayStats
    }

    // MARK: - Computed Properties

    /// Outdoor potty percentage (0-100)
    public var outdoorPottyPercentage: Int {
        guard totalPottyEvents > 0 else { return 0 }
        return Int(round(Double(outdoorPottyCount) / Double(totalPottyEvents) * 100))
    }

    /// Formatted date range (e.g., "Feb 24 - Mar 2")
    public var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekStart)
        let end = formatter.string(from: weekEnd)
        return "\(start) - \(end)"
    }

    /// Short date range for compact display
    public var shortDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: weekStart)
    }

    /// Formatted walk duration (e.g., "3.5h" or "45m")
    public var formattedWalkDuration: String {
        if totalWalkMinutes >= 60 {
            let hours = Double(totalWalkMinutes) / 60.0
            let formatted = hours.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", hours)
                : String(format: "%.1f", hours)
            return "\(formatted)h"
        } else {
            return "\(totalWalkMinutes)m"
        }
    }

    /// Formatted average sleep hours
    public var formattedAvgSleep: String {
        if avgSleepHours >= 1 {
            return String(format: "%.1fh", avgSleepHours)
        } else {
            return String(format: "%.0fm", avgSleepHours * 60)
        }
    }

    /// Whether this week has meaningful data to show
    public var hasData: Bool {
        totalWalks > 0 || totalPottyEvents > 0 || totalTrainingSessions > 0 || totalSocialEvents > 0
    }

    /// Whether this was an achievement week (high potty percentage or many walks)
    public var hasAchievement: Bool {
        outdoorPottyPercentage >= 90 || totalWalks >= 14 || totalTrainingSessions >= 7
    }

    /// Best day of the week (most activity)
    public var bestDay: DayStats? {
        dayStats.max { lhs, rhs in
            let lhsScore = lhs.walks * 2 + lhs.trainingSessions * 3 + lhs.outdoorPotty
            let rhsScore = rhs.walks * 2 + rhs.trainingSessions * 3 + rhs.outdoorPotty
            return lhsScore < rhsScore
        }
    }
}
