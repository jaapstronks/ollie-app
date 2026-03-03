//
//  TodayStatsProvider.swift
//  Otis-app
//
//  Extracted from TimelineViewModel+Stats.swift
//  Pure functions for computing today's statistics from events
//

import Foundation
import OtisShared

/// Summary of today's stats for display
struct TodayStats {
    let peeCount: Int
    let outdoorPeeCount: Int
    let indoorPeeCount: Int
    let poopCount: Int
    let outdoorPoopCount: Int
    let mealCount: Int
    let expectedMealCount: Int
    let walkCount: Int
    let totalWalkMinutes: Int
    let sleepMinutes: Int
    let napCount: Int
    let outdoorPercentage: Int
    let accidentCount: Int
    let sleepProgress: Double

    /// Whether all meals have been logged
    var allMealsLogged: Bool {
        mealCount >= expectedMealCount
    }
}

/// Pure functions for computing statistics from events
/// Extracted from TimelineViewModel to improve testability
struct TodayStatsProvider {

    // MARK: - Main Stats Computation

    /// Compute all today's stats from events and profile
    static func compute(events: [PuppyEvent], profile: PuppyProfile?) -> TodayStats {
        let peeCount = events.pee().count
        let outdoorPeeCount = events.outdoorPee().count
        let indoorPeeCount = events.pee().indoor().count
        let poopCount = events.poop().count
        let outdoorPoopCount = events.poop().outdoor().count
        let mealCount = events.meals().count
        let expectedMealCount = profile?.mealSchedule.mealsPerDay ?? 3
        let walkCount = events.walks().count
        let totalWalkMinutes = events.walks().compactMap { $0.durationMin }.reduce(0, +)
        let sleepMinutes = SleepCalculations.totalSleepToday(events: events)
        let napCount = events.sleeps().count

        // Calculate outdoor percentage
        let outdoorPercentage: Int
        if peeCount > 0 {
            outdoorPercentage = Int((Double(outdoorPeeCount) / Double(peeCount)) * 100)
        } else {
            outdoorPercentage = 100
        }

        // Calculate sleep progress (toward 18 hour goal)
        let goalMinutes = 18 * 60  // 18 hours
        let sleepProgress = min(1.0, Double(sleepMinutes) / Double(goalMinutes))

        return TodayStats(
            peeCount: peeCount,
            outdoorPeeCount: outdoorPeeCount,
            indoorPeeCount: indoorPeeCount,
            poopCount: poopCount,
            outdoorPoopCount: outdoorPoopCount,
            mealCount: mealCount,
            expectedMealCount: expectedMealCount,
            walkCount: walkCount,
            totalWalkMinutes: totalWalkMinutes,
            sleepMinutes: sleepMinutes,
            napCount: napCount,
            outdoorPercentage: outdoorPercentage,
            accidentCount: indoorPeeCount,
            sleepProgress: sleepProgress
        )
    }

    // MARK: - Individual Stats (for backward compatibility)

    /// Today's pee count
    static func peeCount(events: [PuppyEvent]) -> Int {
        events.pee().count
    }

    /// Today's outdoor pee count
    static func outdoorPeeCount(events: [PuppyEvent]) -> Int {
        events.outdoorPee().count
    }

    /// Today's indoor pee count (accidents)
    static func indoorPeeCount(events: [PuppyEvent]) -> Int {
        events.pee().indoor().count
    }

    /// Today's poop count
    static func poopCount(events: [PuppyEvent]) -> Int {
        events.poop().count
    }

    /// Today's outdoor poop count
    static func outdoorPoopCount(events: [PuppyEvent]) -> Int {
        events.poop().outdoor().count
    }

    /// Today's meal count
    static func mealCount(events: [PuppyEvent]) -> Int {
        events.meals().count
    }

    /// Today's walk count
    static func walkCount(events: [PuppyEvent]) -> Int {
        events.walks().count
    }

    /// Total walk duration today (minutes)
    static func totalWalkDuration(events: [PuppyEvent]) -> Int {
        events.walks().compactMap { $0.durationMin }.reduce(0, +)
    }

    /// Total sleep minutes today
    static func totalSleepMinutes(events: [PuppyEvent]) -> Int {
        SleepCalculations.totalSleepToday(events: events)
    }

    /// Number of naps today
    static func napCount(events: [PuppyEvent]) -> Int {
        events.sleeps().count
    }

    /// Outdoor potty percentage today
    static func outdoorPercentage(events: [PuppyEvent]) -> Int {
        let total = events.pee().count
        guard total > 0 else { return 100 }
        return Int((Double(events.outdoorPee().count) / Double(total)) * 100)
    }

    /// Sleep progress toward goal (0.0 - 1.0)
    static func sleepProgress(events: [PuppyEvent]) -> Double {
        let goalMinutes = 18 * 60  // 18 hours
        let sleepMinutes = SleepCalculations.totalSleepToday(events: events)
        return min(1.0, Double(sleepMinutes) / Double(goalMinutes))
    }

    // MARK: - Time Formatting

    /// Format minutes since last plas as readable text
    static func formatTimeSinceLastPlas(minutes: Int?) -> String {
        guard let minutes = minutes else {
            return Strings.TimeFormat.noData
        }

        if minutes < 60 {
            return Strings.TimeFormat.minutesAgo(minutes)
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return Strings.TimeFormat.hoursAgo(hours)
            }
            return Strings.TimeFormat.hoursMinutesAgo(hours: hours, minutes: mins)
        }
    }
}
