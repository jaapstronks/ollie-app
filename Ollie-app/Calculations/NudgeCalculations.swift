//
//  NudgeCalculations.swift
//  Ollie-app
//
//  Nudge detection calculations for walk targets, crate usage, etc.
//  Extracted from CombinedStatusCalculations for better separation of concerns.
//

import Foundation
import OtisShared

/// Nudge detection calculations
enum NudgeCalculations {
    // MARK: - Constants

    /// Time window for crate nudge (8 AM - 8 PM)
    private static let crateNudgeWindowStart = 8
    private static let crateNudgeWindowEnd = 20

    // MARK: - Walk Target Nudge Detection

    /// Check if conditions are right to show the walk target nudge card
    /// Shows when: 7+ days of walk data AND 30%+ below target AND not dismissed in past 7 days
    /// - Parameters:
    ///   - walkStats: Rolling walk statistics (14-day window)
    ///   - dismissedDate: Date when user last dismissed this nudge (if any)
    /// - Returns: true if nudge should be shown
    static func shouldShowWalkTargetNudge(
        walkStats: WalkStats?,
        dismissedDate: Date?
    ) -> Bool {
        guard let stats = walkStats else { return false }

        // Require sufficient data (7+ days with walks logged)
        guard stats.daysWithData >= 7 else { return false }

        // Require significant difference from target (30%+ below)
        guard stats.differenceFromTarget <= -0.30 else { return false }

        // Don't show if dismissed within past 7 days
        if let dismissed = dismissedDate {
            let daysSinceDismissed = Calendar.current.dateComponents([.day], from: dismissed, to: Date()).day ?? 0
            if daysSinceDismissed < 7 {
                return false
            }
        }

        return true
    }

    // MARK: - Crate Nudge Detection

    /// Check if conditions are right to show a crate nap nudge
    /// Shows when:
    /// - Puppy is awake
    /// - At least one nap logged today
    /// - None of today's naps are in crate
    /// - User has logged crate naps before (established pattern)
    /// - Daytime hours (8 AM - 8 PM)
    /// - Returns: true if nudge should be shown
    static func shouldShowCrateNudge(
        sleepState: SleepState,
        todayEvents: [PuppyEvent],
        allEvents: [PuppyEvent]
    ) -> Bool {
        // Must be awake
        guard sleepState.isAwake else { return false }

        // Must be daytime hours
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        guard currentHour >= crateNudgeWindowStart && currentHour < crateNudgeWindowEnd else {
            return false
        }

        // Get today's naps (sleep events that are naps, not overnight sleep)
        let todayNaps = todayEvents.filter { event in
            guard event.type == .slapen else { return false }
            // Consider it a nap if it started after 6 AM (not overnight)
            let hour = calendar.component(.hour, from: event.time)
            return hour >= 6
        }

        // Must have at least one nap today
        guard !todayNaps.isEmpty else { return false }

        // None of today's naps should be in crate
        let todayCrateNaps = todayNaps.filter { $0.napLocation == .crate }
        guard todayCrateNaps.isEmpty else { return false }

        // User must have used crate before (established pattern)
        let allCrateNaps = allEvents.filter { event in
            event.type == .slapen && event.napLocation == .crate
        }
        guard !allCrateNaps.isEmpty else { return false }

        return true
    }
}
