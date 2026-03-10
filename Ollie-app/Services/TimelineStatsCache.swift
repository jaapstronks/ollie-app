//
//  TimelineStatsCache.swift
//  Otis-app
//
//  Extracted from TimelineViewModel - manages cached stats to avoid recomputation
//  Optimized: Heavy calculations run on background thread to avoid UI freezes
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

    /// Whether stats are currently being computed
    @Published private(set) var isLoading: Bool = false

    // MARK: - Internal State

    /// Last time stats were computed (for debouncing)
    private var lastStatsUpdate: Date?

    /// Active computation task (cancelled if new refresh requested)
    private var computationTask: Task<Void, Never>?

    // MARK: - Init

    init(eventStore: EventStore, profileStore: ProfileStore) {
        self.eventStore = eventStore
        self.profileStore = profileStore
    }

    // MARK: - Public Methods

    /// Refresh cached stats asynchronously (debounced, only if data changed)
    /// Heavy calculations run on background thread to avoid UI freezes
    /// - Parameter force: When true, bypasses debounce (use after event changes)
    func refresh(force: Bool = false) {
        // Debounce: only update if more than 1 second since last update
        // Skip debounce when force is true (e.g., after event edits)
        let now = Date()
        if !force, let lastUpdate = lastStatsUpdate, now.timeIntervalSince(lastUpdate) < 1.0 {
            return
        }
        lastStatsUpdate = now

        // Cancel any in-progress computation
        computationTask?.cancel()

        // Start new background computation
        computationTask = Task {
            await computeStatsAsync()
        }
    }

    // MARK: - Private Methods

    /// Compute stats on background thread and update published properties on main thread
    private func computeStatsAsync() async {
        isLoading = true

        // Fetch events on main thread (EventStore may not be thread-safe)
        let eightDaysAgo = Date().addingDays(-8)
        let fifteenDaysAgo = Date().addingDays(-15)
        let allRecentEvents = eventStore.getEvents(from: eightDaysAgo, to: Date())
        let extendedEvents = eventStore.getEvents(from: fifteenDaysAgo, to: Date())
        let walksPerDay = profileStore.profile?.walkSchedule.walksPerDay ?? 3

        // Move heavy computation to background thread
        let results = await Task.detached(priority: .userInitiated) {
            self.computeStatsBackground(
                allRecentEvents: allRecentEvents,
                extendedEvents: extendedEvents,
                walksPerDay: walksPerDay
            )
        }.value

        // Check if cancelled before updating UI
        guard !Task.isCancelled else {
            isLoading = false
            return
        }

        // Update published properties on main thread
        self.recentEvents = results.recentEvents
        self.patternAnalysis = results.patternAnalysis
        self.weekStats = results.weekStats
        self.recentWalks = results.recentWalks
        self.weekWalkStats = results.weekWalkStats
        self.walkStats = results.walkStats
        self.isLoading = false
    }

    /// Background computation - no UI access, pure data processing
    private nonisolated func computeStatsBackground(
        allRecentEvents: [PuppyEvent],
        extendedEvents: [PuppyEvent],
        walksPerDay: Int
    ) -> StatsResults {
        let sevenDaysAgo = Date().addingDays(-7)

        // Filter recent events (7 days)
        let recentEvents = allRecentEvents.filter { $0.time >= sevenDaysAgo }

        // Calculate pattern analysis
        let patternAnalysis = PatternCalculations.analyzePatterns(
            events: recentEvents,
            periodDays: 7
        )

        // Calculate week stats using optimized batch method
        let weekStats = WeekCalculations.calculateWeekStatsBatch(from: allRecentEvents)

        // Filter recent walks
        let recentWalks = recentEvents.walks()

        // Calculate walk stats
        let totalWalkMinutes = recentWalks.compactMap { $0.durationMin }.reduce(0, +)
        let weekWalkStats = (recentWalks.count, totalWalkMinutes)

        // Calculate rolling walk stats (14 days)
        let walkStats = WalkStatsCalculations.calculateRollingStats(
            from: extendedEvents,
            periodDays: 14,
            scheduledWalksPerDay: walksPerDay
        )

        return StatsResults(
            recentEvents: recentEvents,
            patternAnalysis: patternAnalysis,
            weekStats: weekStats,
            recentWalks: recentWalks,
            weekWalkStats: weekWalkStats,
            walkStats: walkStats
        )
    }
}

// MARK: - Helper Types

extension TimelineStatsCache {
    /// Container for computed stats results (passed from background to main thread)
    private struct StatsResults: Sendable {
        let recentEvents: [PuppyEvent]
        let patternAnalysis: PatternAnalysis
        let weekStats: [DayStats]
        let recentWalks: [PuppyEvent]
        let weekWalkStats: (count: Int, totalMinutes: Int)
        let walkStats: WalkStats
    }
}
