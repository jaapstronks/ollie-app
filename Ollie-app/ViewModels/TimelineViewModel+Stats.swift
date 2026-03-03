//
//  TimelineViewModel+Stats.swift
//  Otis-app
//
//  Extension containing stats computed properties
//  Delegates to TodayStatsProvider for pure function logic
//

import Foundation
import OtisShared
import SwiftUI

// MARK: - Stats & Predictions

extension TimelineViewModel {

    // MARK: - Potty Stats

    /// Last plas (pee) event
    var lastPlasEvent: PuppyEvent? {
        eventStore.lastEvent(ofType: .plassen)
    }

    /// Minutes since the last plas event
    var minutesSinceLastPlas: Int? {
        guard let last = lastPlasEvent else { return nil }
        return Date().minutesSince(last.time)
    }

    /// Formatted text for time since last plas
    /// Delegates to TodayStatsProvider
    var timeSinceLastPlasText: String {
        TodayStatsProvider.formatTimeSinceLastPlas(minutes: minutesSinceLastPlas)
    }

    // MARK: - Sleep Stats

    /// Total sleep minutes today
    /// Delegates to TodayStatsProvider
    var totalSleepMinutesToday: Int {
        TodayStatsProvider.totalSleepMinutes(events: events)
    }

    /// Number of naps today
    /// Delegates to TodayStatsProvider
    var napCountToday: Int {
        TodayStatsProvider.napCount(events: events)
    }

    /// Sleep progress toward goal (0.0 - 1.0)
    /// Delegates to TodayStatsProvider
    var sleepProgress: Double {
        TodayStatsProvider.sleepProgress(events: events)
    }

    // MARK: - Poop Stats

    /// Today's poop count
    /// Delegates to TodayStatsProvider
    var poopCountToday: Int {
        TodayStatsProvider.poopCount(events: events)
    }

    /// Today's outdoor poop count
    /// Delegates to TodayStatsProvider
    var outdoorPoopCountToday: Int {
        TodayStatsProvider.outdoorPoopCount(events: events)
    }

    // MARK: - Potty Stats

    /// Today's pee count
    /// Delegates to TodayStatsProvider
    var peeCountToday: Int {
        TodayStatsProvider.peeCount(events: events)
    }

    /// Today's outdoor pee count
    /// Delegates to TodayStatsProvider
    var outdoorPeeCountToday: Int {
        TodayStatsProvider.outdoorPeeCount(events: events)
    }

    /// Today's indoor pee count (accidents)
    /// Delegates to TodayStatsProvider
    var indoorPeeCountToday: Int {
        TodayStatsProvider.indoorPeeCount(events: events)
    }

    /// Outdoor potty percentage today
    /// Delegates to TodayStatsProvider
    var outdoorPercentageToday: Int {
        TodayStatsProvider.outdoorPercentage(events: events)
    }

    // MARK: - Meal Stats

    /// Today's meal count
    /// Delegates to TodayStatsProvider
    var mealCountToday: Int {
        TodayStatsProvider.mealCount(events: events)
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
    /// Delegates to TodayStatsProvider
    var walkCountToday: Int {
        TodayStatsProvider.walkCount(events: events)
    }

    /// Total walk duration today (minutes)
    /// Delegates to TodayStatsProvider
    var totalWalkDurationToday: Int {
        TodayStatsProvider.totalWalkDuration(events: events)
    }
}

// MARK: - Stats Summary

extension TimelineViewModel {

    /// Summary of today's stats for display
    /// Kept for backward compatibility - delegates to TodayStatsProvider
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
    /// Delegates to TodayStatsProvider
    var todayStatsSummary: TodayStatsSummary {
        let stats = TodayStatsProvider.compute(events: events, profile: profileStore.profile)
        return TodayStatsSummary(
            peeCount: stats.peeCount,
            poopCount: stats.poopCount,
            mealCount: stats.mealCount,
            walkCount: stats.walkCount,
            sleepMinutes: stats.sleepMinutes,
            outdoorPercentage: stats.outdoorPercentage,
            accidentCount: stats.accidentCount
        )
    }

    /// Get full today's stats using TodayStatsProvider
    var todayStats: TodayStats {
        TodayStatsProvider.compute(events: events, profile: profileStore.profile)
    }
}
