//
//  PoopCalculations.swift
//  Ollie-app
//
//  Pattern-based poop tracking — learns from the dog's actual behavior
//  Provides subtle awareness without nagging

import Foundation
import OllieShared
import SwiftUI

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

// MARK: - Poop Calculations

struct PoopCalculations {

    // MARK: - Configuration

    /// Minimum days of history needed for pattern analysis
    static let minDaysForPattern = 3

    /// Days of history to analyze
    static let patternAnalysisDays = 14

    /// Gap multiplier for "gentle" reminder (median × this)
    static let gentleGapMultiplier = 1.5

    /// Gap multiplier for "attention" level (median × this)
    static let attentionGapMultiplier = 2.0

    /// Absolute max daytime gap before showing attention (8 hours)
    static let absoluteMaxDaytimeGapMinutes = 8 * 60

    /// Minutes after walk to check for poop correlation
    static let postWalkWindowMinutes = 30

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
    /// - Parameters:
    ///   - todayEvents: Today's events
    ///   - historicalEvents: Events from the past 14 days (for pattern analysis)
    ///   - ageInWeeks: Puppy's age in weeks
    ///   - currentTime: Current time (for testing)
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
        let pattern = analyzePattern(events: historicalEvents, currentTime: currentTime)
        let hasPattern = pattern.daysAnalyzed >= minDaysForPattern

        // Get today's poop events
        let todayPoops = todayEvents.poop().today().chronological()

        let todayCount = todayPoops.count
        let lastPoopTime = todayPoops.last?.time

        // Calculate expected range (blend age-based with pattern if available)
        let ageBasedRange = expectedDailyRange(ageInWeeks: ageInWeeks)
        let expectedRange: ClosedRange<Int>
        if hasPattern {
            // Use pattern median ± 1, but don't go below age-based minimum
            let patternLower = max(ageBasedRange.lowerBound, Int(pattern.medianDailyCount) - 1)
            let patternUpper = max(patternLower, Int(pattern.medianDailyCount.rounded()) + 1)
            expectedRange = patternLower...patternUpper
        } else {
            expectedRange = ageBasedRange
        }

        // Calculate daytime gap since last poop
        let daytimeGap = calculateDaytimeGapMinutes(
            from: lastPoopTime,
            to: currentTime
        )

        // Check for recent walk without poop
        let recentWalkWithoutPoop = checkRecentWalkWithoutPoop(
            todayEvents: todayEvents,
            lastPoopTime: lastPoopTime,
            currentTime: currentTime
        )

        // Determine urgency and message
        let (urgency, message) = determineUrgencyAndMessage(
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
        let sortedCounts = dailyCounts.sorted()
        let medianDaily: Double
        if sortedCounts.count % 2 == 0 {
            let mid = sortedCounts.count / 2
            medianDaily = Double(sortedCounts[mid - 1] + sortedCounts[mid]) / 2.0
        } else {
            medianDaily = Double(sortedCounts[sortedCounts.count / 2])
        }

        // Calculate daytime gaps
        let daytimeGaps = calculateDaytimeGaps(poopEvents: poopEvents, currentTime: currentTime)
        let medianGap: Int
        if daytimeGaps.isEmpty {
            medianGap = 0
        } else {
            let sortedGaps = daytimeGaps.sorted()
            if sortedGaps.count % 2 == 0 {
                let mid = sortedGaps.count / 2
                medianGap = (sortedGaps[mid - 1] + sortedGaps[mid]) / 2
            } else {
                medianGap = sortedGaps[sortedGaps.count / 2]
            }
        }

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

    // MARK: - Gap Calculations

    /// Calculate daytime-only gaps between poop events
    private static func calculateDaytimeGaps(poopEvents: [PuppyEvent], currentTime: Date) -> [Int] {
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
    private static func checkRecentWalkWithoutPoop(
        todayEvents: [PuppyEvent],
        lastPoopTime: Date?,
        currentTime: Date
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

    // MARK: - Urgency Determination

    private static func determineUrgencyAndMessage(
        todayCount: Int,
        expectedRange: ClosedRange<Int>,
        daytimeGapMinutes: Int?,
        pattern: PoopPattern?,
        recentWalkWithoutPoop: Bool,
        hour: Int
    ) -> (PoopUrgency, String?) {

        // Early morning (before 9am) - just show info if no poop yet
        if hour < 9 && todayCount == 0 {
            return (.info, Strings.PoopStatus.noPoopYetEarly)
        }

        // Check for recent walk without poop (gentle note, not alarming)
        if recentWalkWithoutPoop && todayCount < expectedRange.lowerBound {
            return (.gentle, Strings.PoopStatus.walkCompletedNoPoop)
        }

        // Check daytime gap against pattern or absolute max
        if let gap = daytimeGapMinutes, let patternData = pattern {
            let medianGap = patternData.medianDaytimeGapMinutes

            if medianGap > 0 {
                // Attention: gap exceeds 2x median (unusual for this dog)
                if gap >= Int(Double(medianGap) * attentionGapMultiplier) {
                    return (.attention, Strings.PoopStatus.longerThanUsual)
                }

                // Gentle: gap exceeds 1.5x median
                if gap >= Int(Double(medianGap) * gentleGapMultiplier) {
                    return (.gentle, nil)
                }
            }
        }

        // Absolute max gap (fallback when no pattern)
        if let gap = daytimeGapMinutes, gap >= absoluteMaxDaytimeGapMinutes {
            return (.attention, Strings.PoopStatus.longGap)
        }

        // Evening check: below expected and getting late
        if hour >= 18 && todayCount < expectedRange.lowerBound {
            return (.info, Strings.PoopStatus.belowExpected)
        }

        // No poop yet today after first walk completed
        let hasHadWalk = recentWalkWithoutPoop || hour >= 10  // Assume walk by 10am
        if todayCount == 0 && hasHadWalk && hour >= 10 {
            return (.info, Strings.PoopStatus.noPoopYet)
        }

        // All good
        return (.good, nil)
    }

    // MARK: - Display Helpers

    /// Format time since last poop
    static func formatTimeSince(_ lastPoopTime: Date?, currentTime: Date = Date()) -> String? {
        guard let lastTime = lastPoopTime else { return nil }

        let minutes = currentTime.minutesSince(lastTime)

        if minutes < 60 {
            return Strings.PoopStatus.minutesAgo(minutes)
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return Strings.PoopStatus.hoursAgo(hours)
            }
            return Strings.PoopStatus.hoursMinutesAgo(hours: hours, minutes: mins)
        }
    }

    /// Get icon name for urgency level
    static func iconName(for urgency: PoopUrgency) -> String {
        switch urgency {
        case .hidden:
            return "moon.fill"
        case .good:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle"
        case .gentle:
            return "exclamationmark.circle"
        case .attention:
            return "exclamationmark.circle.fill"
        }
    }

    /// Get icon color for urgency level
    static func iconColor(for urgency: PoopUrgency) -> Color {
        switch urgency {
        case .hidden:
            return .gray
        case .good:
            return .ollieSuccess
        case .info:
            return .secondary
        case .gentle:
            return .ollieWarning
        case .attention:
            return .ollieWarning
        }
    }
}
