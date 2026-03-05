//
//  TimelineStatsCache.swift
//  Otis-app
//
//  Extracted from TimelineViewModel - manages cached stats to avoid recomputation
//

import Foundation
import OtisShared
import Combine

/// Manages cached timeline statistics to avoid expensive recomputation on every frame
/// Extracted from TimelineViewModel to separate concerns
@MainActor
final class TimelineStatsCache: ObservableObject {

    // MARK: - Dependencies

    private let eventStore: EventStore
    private let profileStore: ProfileStore

    // MARK: - Cached Stats (Published for UI updates)

    /// Cached pattern analysis (updated when events change)
    @Published private(set) var patternAnalysis: PatternAnalysis?

    /// Cached recent events for stats (7 days)
    @Published private(set) var recentEvents: [PuppyEvent] = []

    /// Cached week stats for insights view
    @Published private(set) var weekStats: [DayStats] = []

    /// Cached recent walks (7 days)
    @Published private(set) var recentWalks: [PuppyEvent] = []

    /// Cached walk stats for the week
    @Published private(set) var weekWalkStats: (count: Int, totalMinutes: Int) = (0, 0)

    /// Cached rolling walk stats (14 days) for adaptive walk target nudges
    @Published private(set) var walkStats: WalkStats?

    // MARK: - Internal State

    /// Last time stats were computed (for debouncing)
    private var lastStatsUpdate: Date?

    // MARK: - Init

    init(eventStore: EventStore, profileStore: ProfileStore) {
        self.eventStore = eventStore
        self.profileStore = profileStore
    }

    // MARK: - Public Methods

    /// Refresh cached stats (debounced, only if data changed)
    /// - Parameter force: When true, bypasses debounce (use after event changes)
    func refresh(force: Bool = false) {
        // Debounce: only update if more than 1 second since last update
        // Skip debounce when force is true (e.g., after event edits)
        let now = Date()
        if !force, let lastUpdate = lastStatsUpdate, now.timeIntervalSince(lastUpdate) < 1.0 {
            return
        }
        lastStatsUpdate = now

        // Fetch 8 days of events in a single query (7 days + 1 for sleep overlap)
        // This is small enough to do synchronously for immediate UI updates
        let eightDaysAgo = Date().addingDays(-8)
        let allRecentEvents = eventStore.getEvents(from: eightDaysAgo, to: Date())

        // Update cached recent events (7 days)
        let sevenDaysAgo = Date().addingDays(-7)
        recentEvents = allRecentEvents.filter { $0.time >= sevenDaysAgo }

        // Update cached pattern analysis
        patternAnalysis = PatternCalculations.analyzePatterns(
            events: recentEvents,
            periodDays: 7
        )

        // Update cached week stats using optimized batch method (single partition instead of 7 queries)
        weekStats = WeekCalculations.calculateWeekStatsBatch(from: allRecentEvents)

        // Update cached recent walks (7 days)
        recentWalks = recentEvents.walks()

        // Update cached walk stats
        let totalWalkMinutes = recentWalks.compactMap { $0.durationMin }.reduce(0, +)
        weekWalkStats = (recentWalks.count, totalWalkMinutes)

        // Update rolling walk stats (14 days) for adaptive walk target nudges
        let fifteenDaysAgo = Date().addingDays(-15)  // 14 days + buffer
        let extendedEvents = eventStore.getEvents(from: fifteenDaysAgo, to: Date())
        if let profile = profileStore.profile {
            walkStats = WalkStatsCalculations.calculateRollingStats(
                from: extendedEvents,
                periodDays: 14,
                scheduledWalksPerDay: profile.walkSchedule.walksPerDay
            )
        } else {
            walkStats = nil
        }
    }
}
