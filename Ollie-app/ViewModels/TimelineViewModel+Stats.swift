//
//  TimelineViewModel+Stats.swift
//  Ollie-app
//
//  Extension containing stats and predictions computed properties
//  Extracted from TimelineViewModel to improve code organization
//

import Foundation
import OllieShared
import SwiftUI

// MARK: - Stats & Predictions

extension TimelineViewModel {

    // MARK: - Potty Stats

    /// Last plas (pee) event
    var lastPlasEventComputed: PuppyEvent? {
        eventStore.lastEvent(ofType: .plassen)
    }

    /// Minutes since the last plas event
    var minutesSinceLastPlasComputed: Int? {
        guard let last = lastPlasEventComputed else { return nil }
        return Date().minutesSince(last.time)
    }

    /// Formatted text for time since last plas
    var timeSinceLastPlasTextComputed: String {
        guard let minutes = minutesSinceLastPlasComputed else {
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

    // MARK: - Sleep Stats

    /// Total sleep minutes today
    var totalSleepMinutesToday: Int {
        SleepCalculations.totalSleepToday(events: events)
    }

    /// Number of naps today
    var napCountToday: Int {
        events.sleeps().count
    }

    /// Sleep progress toward goal (0.0 - 1.0)
    var sleepProgress: Double {
        let goalMinutes = 18 * 60  // 18 hours
        return min(1.0, Double(totalSleepMinutesToday) / Double(goalMinutes))
    }

    // MARK: - Poop Stats

    /// Today's poop count
    var poopCountToday: Int {
        events.poop().count
    }

    /// Today's outdoor poop count
    var outdoorPoopCountToday: Int {
        events.poop().outdoor().count
    }

    // MARK: - Potty Stats

    /// Today's pee count
    var peeCountToday: Int {
        events.pee().count
    }

    /// Today's outdoor pee count
    var outdoorPeeCountToday: Int {
        events.outdoorPee().count
    }

    /// Today's indoor pee count (accidents)
    var indoorPeeCountToday: Int {
        events.pee().indoor().count
    }

    /// Outdoor potty percentage today
    var outdoorPercentageToday: Int {
        let total = peeCountToday
        guard total > 0 else { return 100 }
        return Int((Double(outdoorPeeCountToday) / Double(total)) * 100)
    }

    // MARK: - Meal Stats

    /// Today's meal count
    var mealCountToday: Int {
        events.meals().count
    }

    /// Expected meal count from profile
    var expectedMealCount: Int {
        profileStore.profile?.mealSchedule.mealsPerDay ?? 3
    }

    /// Whether all meals have been logged
    var allMealsLogged: Bool {
        mealCountToday >= expectedMealCount
    }

    // MARK: - Walk Stats

    /// Today's walk count
    var walkCountToday: Int {
        events.walks().count
    }

    /// Total walk duration today (minutes)
    var totalWalkDurationToday: Int {
        events.walks().compactMap { $0.durationMin }.reduce(0, +)
    }
}

// MARK: - Stats Summary

extension TimelineViewModel {

    /// Summary of today's stats for display
    struct TodayStatsSummary {
        let peeCount: Int
        let poopCount: Int
        let mealCount: Int
        let walkCount: Int
        let sleepMinutes: Int
        let outdoorPercentage: Int
        let accidentCount: Int
    }

    /// Get a summary of today's stats
    var todayStatsSummary: TodayStatsSummary {
        TodayStatsSummary(
            peeCount: peeCountToday,
            poopCount: poopCountToday,
            mealCount: mealCountToday,
            walkCount: walkCountToday,
            sleepMinutes: totalSleepMinutesToday,
            outdoorPercentage: outdoorPercentageToday,
            accidentCount: indoorPeeCountToday
        )
    }
}
