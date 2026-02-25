//
//  PoopUrgencyCalculator.swift
//  Ollie-app
//
//  Determines poop urgency level based on patterns and current state
//

import Foundation
import OllieShared

/// Determines poop urgency level and generates appropriate messages
struct PoopUrgencyCalculator {

    // MARK: - Configuration

    /// Gap multiplier for "gentle" reminder (median × this)
    static let gentleGapMultiplier = 1.5

    /// Gap multiplier for "attention" level (median × this)
    static let attentionGapMultiplier = 2.0

    /// Absolute max daytime gap before showing attention (8 hours)
    static let absoluteMaxDaytimeGapMinutes = 8 * 60

    // MARK: - Urgency Determination

    static func determineUrgencyAndMessage(
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
}
