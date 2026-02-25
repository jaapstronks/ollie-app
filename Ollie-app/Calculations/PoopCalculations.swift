//
//  PoopCalculations.swift
//  Ollie-app
//
//  Pattern-based poop tracking — learns from the dog's actual behavior
//  Provides subtle awareness without nagging
//
//  Facade that delegates to focused calculators in Poop/ subdirectory

import Foundation
import OllieShared
import SwiftUI

// MARK: - Poop Calculations (Facade)

struct PoopCalculations {

    // MARK: - Configuration

    /// Minimum days of history needed for pattern analysis
    static let minDaysForPattern = 3

    /// Days of history to analyze
    static let patternAnalysisDays = 14

    /// Minutes after walk to check for poop correlation
    static let postWalkWindowMinutes = PoopPatternAnalyzer.postWalkWindowMinutes

    // MARK: - Age-Based Expectations

    /// Expected daily poop range based on age in weeks
    static func expectedDailyRange(ageInWeeks: Int) -> ClosedRange<Int> {
        switch ageInWeeks {
        case 0..<8:
            return 4...6  // Very young puppies
        case 8..<12:
            return 3...5  // 8-12 weeks
        case 12..<26:
            return 2...4  // 3-6 months
        case 26..<52:
            return 2...3  // 6-12 months
        default:
            return 1...2  // Adult
        }
    }

    // MARK: - Main Status Calculation

    /// Calculate current poop status
    static func calculateStatus(
        todayEvents: [PuppyEvent],
        historicalEvents: [PuppyEvent],
        ageInWeeks: Int,
        currentTime: Date = Date()
    ) -> PoopStatus {
        let hour = Calendar.current.component(.hour, from: currentTime)

        // Hidden during night hours
        if Constants.isNightTime(hour: hour) {
            return PoopStatus(
                todayCount: 0,
                expectedRange: expectedDailyRange(ageInWeeks: ageInWeeks),
                lastPoopTime: nil,
                daytimeMinutesSinceLast: nil,
                recentWalkWithoutPoop: false,
                urgency: .hidden,
                message: nil,
                hasPatternData: false,
                patternDailyMedian: nil
            )
        }

        // Analyze patterns from history
        let pattern = PoopPatternAnalyzer.analyzePattern(events: historicalEvents, currentTime: currentTime)
        let hasPattern = pattern.daysAnalyzed >= minDaysForPattern

        // Get today's poop events
        let todayPoops = todayEvents.poop().today().chronological()

        let todayCount = todayPoops.count
        let lastPoopTime = todayPoops.last?.time

        // Calculate expected range (blend age-based with pattern if available)
        let ageBasedRange = expectedDailyRange(ageInWeeks: ageInWeeks)
        let expectedRange: ClosedRange<Int>
        if hasPattern {
            let patternLower = max(ageBasedRange.lowerBound, Int(pattern.medianDailyCount) - 1)
            let patternUpper = max(patternLower, Int(pattern.medianDailyCount.rounded()) + 1)
            expectedRange = patternLower...patternUpper
        } else {
            expectedRange = ageBasedRange
        }

        // Calculate daytime gap since last poop
        let daytimeGap = PoopGapCalculator.calculateDaytimeGapMinutes(from: lastPoopTime, to: currentTime)

        // Check for recent walk without poop
        let recentWalkWithoutPoop = PoopGapCalculator.checkRecentWalkWithoutPoop(
            todayEvents: todayEvents,
            lastPoopTime: lastPoopTime,
            currentTime: currentTime,
            postWalkWindowMinutes: postWalkWindowMinutes
        )

        // Determine urgency and message
        let (urgency, message) = PoopUrgencyCalculator.determineUrgencyAndMessage(
            todayCount: todayCount,
            expectedRange: expectedRange,
            daytimeGapMinutes: daytimeGap,
            pattern: hasPattern ? pattern : nil,
            recentWalkWithoutPoop: recentWalkWithoutPoop,
            hour: hour
        )

        return PoopStatus(
            todayCount: todayCount,
            expectedRange: expectedRange,
            lastPoopTime: lastPoopTime,
            daytimeMinutesSinceLast: daytimeGap,
            recentWalkWithoutPoop: recentWalkWithoutPoop,
            urgency: urgency,
            message: message,
            hasPatternData: hasPattern,
            patternDailyMedian: hasPattern ? pattern.medianDailyCount : nil
        )
    }

    // MARK: - Delegated Methods (for backwards compatibility)

    static func analyzePattern(events: [PuppyEvent], currentTime: Date = Date()) -> PoopPattern {
        PoopPatternAnalyzer.analyzePattern(events: events, currentTime: currentTime)
    }

    static func calculateDaytimeGapMinutes(from startTime: Date?, to endTime: Date) -> Int? {
        PoopGapCalculator.calculateDaytimeGapMinutes(from: startTime, to: endTime)
    }

    static func formatTimeSince(_ lastPoopTime: Date?, currentTime: Date = Date()) -> String? {
        PoopDisplayHelpers.formatTimeSince(lastPoopTime, currentTime: currentTime)
    }

    static func iconName(for urgency: PoopUrgency) -> String {
        PoopDisplayHelpers.iconName(for: urgency)
    }

    static func iconColor(for urgency: PoopUrgency) -> Color {
        PoopDisplayHelpers.iconColor(for: urgency)
    }
}
