//
//  PoopModels.swift
//  Ollie-app
//
//  Data models for poop status and pattern tracking
//

import Foundation

// MARK: - Poop Status Model

/// Current poop status with pattern-aware insights
struct PoopStatus: Equatable {
    let todayCount: Int
    let expectedRange: ClosedRange<Int>
    let lastPoopTime: Date?
    let daytimeMinutesSinceLast: Int?
    let recentWalkWithoutPoop: Bool
    let urgency: PoopUrgency
    let message: String?

    /// Whether we have enough history to show pattern info
    let hasPatternData: Bool

    /// Median daily count from history (nil if no pattern data)
    let patternDailyMedian: Double?
}

// MARK: - Urgency Levels

/// Urgency levels — designed to be subtle, not alarming
enum PoopUrgency: Equatable {
    case hidden          // Night time (23:00-06:00)
    case good            // On track, nothing to note
    case info            // Informational (e.g., "no poop yet today")
    case gentle          // Gentle reminder (long gap, or walk without poop)
    case attention       // Worth noting (unusually long gap based on pattern)
}

// MARK: - Pattern Analysis Results

/// Historical poop pattern data
struct PoopPattern: Equatable {
    let medianDailyCount: Double
    let medianDaytimeGapMinutes: Int
    let typicalPostWalkPoopRate: Double  // 0-1, how often poop follows walk
    let daysAnalyzed: Int

    static var empty: PoopPattern {
        PoopPattern(
            medianDailyCount: 0,
            medianDaytimeGapMinutes: 0,
            typicalPostWalkPoopRate: 0,
            daysAnalyzed: 0
        )
    }
}
