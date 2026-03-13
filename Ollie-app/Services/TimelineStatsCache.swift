//
//  TimelineStatsCache.swift
//  Otis-app
//
//  Extracted from TimelineViewModel - manages cached stats to avoid recomputation
//  Optimized: Uses shared EventDataProvider instead of direct Core Data fetches
//

import Foundation
import OtisShared
import Combine
import Sentry

/// Manages cached timeline statistics to avoid expensive recomputation on every frame
/// Extracted from TimelineViewModel to separate concerns
///
/// Performance optimization: Uses DailyAggregateService to read pre-computed
/// daily stats instead of calculating from raw events. This reduces week stats
/// computation from ~1.7s to ~10ms.
@MainActor
final class TimelineStatsCache: ObservableObject {

    // MARK: - Global Computation Lock
    // PERF: Prevents multiple TimelineStatsCache instances from computing simultaneously
    // This handles the case where SwiftUI creates multiple ViewModel instances
    private static var isGlobalComputationInProgress = false
    private static var lastGlobalComputationTime: Date = .distantPast

    // MARK: - Dependencies

    private let eventDataProvider: EventDataProvider
    private let profileStore: ProfileStore
    private let dailyAggregateService: DailyAggregateService

    // MARK: - Cached Stats
    // PERFORMANCE: Using manual backing storage to batch objectWillChange notifications
    // Instead of triggering per-property, we send a single notification after all updates

    /// Cached pattern analysis (updated when events change)
    var patternAnalysis: PatternAnalysis? { _patternAnalysis }
    private var _patternAnalysis: PatternAnalysis?

    /// Cached recent events for stats (7 days)
    var recentEvents: [PuppyEvent] { _recentEvents }
    private var _recentEvents: [PuppyEvent] = []

    /// Cached week stats for insights view
    var weekStats: [DayStats] { _weekStats }
    private var _weekStats: [DayStats] = []

    /// Cached recent walks (7 days)
    var recentWalks: [PuppyEvent] { _recentWalks }
    private var _recentWalks: [PuppyEvent] = []

    /// Cached walk stats for the week
    var weekWalkStats: (count: Int, totalMinutes: Int) { _weekWalkStats }
    private var _weekWalkStats: (count: Int, totalMinutes: Int) = (0, 0)

    /// Cached rolling walk stats (14 days) for adaptive walk target nudges
    var walkStats: WalkStats? { _walkStats }
    private var _walkStats: WalkStats?

    /// Cached gap stats for potty predictions (7 days)
    /// PERF: Avoids recalculating on every pottyPrediction access
    var gapStats: GapStats { _gapStats }
    private var _gapStats: GapStats = GapStats(
        count: 0,
        minMinutes: 0,
        maxMinutes: 0,
        avgMinutes: 0,
        medianMinutes: 0,
        outdoorCount: 0,
        indoorCount: 0
    )

    /// Whether stats are currently being computed
    var isLoading: Bool { _isLoading }
    private var _isLoading: Bool = false

    // MARK: - Internal State

    /// Last time stats were computed (for debouncing)
    private var lastStatsUpdate: Date?

    /// Active computation task (cancelled if new refresh requested)
    private var computationTask: Task<Void, Never>?

    // MARK: - Init

    init(
        eventDataProvider: EventDataProvider,
        profileStore: ProfileStore,
        dailyAggregateService: DailyAggregateService
    ) {
        self.eventDataProvider = eventDataProvider
        self.profileStore = profileStore
        self.dailyAggregateService = dailyAggregateService
    }

    // MARK: - Public Methods

    /// Refresh cached stats asynchronously (debounced, only if data changed)
    /// Heavy calculations run on background thread to avoid UI freezes
    /// - Parameter force: When true, uses shorter debounce (500ms vs 2s)
    func refresh(force: Bool = false) {
        let now = Date()

        // PERF: Global debounce across ALL TimelineStatsCache instances
        // This prevents multiple ViewModel instances from computing simultaneously
        let globalDebounce: TimeInterval = force ? 0.5 : 2.0
        if now.timeIntervalSince(Self.lastGlobalComputationTime) < globalDebounce {
            return
        }

        // Local debounce for this instance
        let localDebounce: TimeInterval = force ? 0.5 : 1.0
        if let lastUpdate = lastStatsUpdate, now.timeIntervalSince(lastUpdate) < localDebounce {
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

    /// Compute stats using pre-computed daily aggregates and cached events
    /// PERFORMANCE: Reads 7 aggregate records instead of processing 1,500+ events
    private func computeStatsAsync() async {
        // PERFORMANCE: Check debug toggle to skip expensive stats computation
        guard !PerformanceDebug.disableStatsRefresh else {
            if PerformanceDebug.logExpensiveOperations {
                print("[PERF] SKIPPED: TimelineStatsCache.computeStatsAsync (disabled by toggle)")
            }
            return
        }

        // PERF: Global lock to prevent multiple instances computing simultaneously
        guard !Self.isGlobalComputationInProgress else {
            return
        }
        Self.isGlobalComputationInProgress = true
        Self.lastGlobalComputationTime = Date()
        defer { Self.isGlobalComputationInProgress = false }

        // PERFORMANCE: Track stats computation time
        let statsTransaction = CrashReporter.startTransaction(
            name: "Compute Timeline Stats",
            operation: "stats.compute"
        )

        // PERF: Removed objectWillChange at START - only send when computation completes
        // This halves the number of view rebuilds triggered by stats computation
        _isLoading = true

        // Get events from shared cache (no DB fetch needed!)
        // EventDataProvider maintains these caches and refreshes them when events change
        let cacheSpan = statsTransaction?.startChild(
            operation: "cache.read",
            description: "Read Event Caches"
        )
        let allRecentEvents = eventDataProvider.eightDayEvents
        let extendedEvents = eventDataProvider.extendedEvents
        let walksPerDay = profileStore.profile?.walkSchedule.walksPerDay ?? 3
        let profileId = profileStore.profile?.id
        cacheSpan?.finish()

        // If cache is still refreshing, wait for it
        if eventDataProvider.isRefreshing {
            // Small delay to let cache populate
            try? await Task.sleep(for: .milliseconds(50))
        }

        // Check if cancelled
        guard !Task.isCancelled else {
            _isLoading = false
            // PERF: Don't send objectWillChange on cancellation - nothing changed
            statsTransaction?.finish()
            return
        }

        // PERFORMANCE: Read pre-computed daily aggregates instead of raw calculation
        let aggregateSpan = statsTransaction?.startChild(
            operation: "aggregate.read",
            description: "Read Daily Aggregates"
        )
        let sevenDaysAgo = Date().addingDays(-7)
        var weekStats: [DayStats] = []
        var gapStats: GapStats = .empty

        if let profileId = profileId {
            // Read aggregates (fast - 7 small records)
            weekStats = await dailyAggregateService.getAggregates(
                from: sevenDaysAgo,
                to: Date(),
                profileId: profileId,
                events: allRecentEvents
            )

            // Get merged gap stats from aggregates
            gapStats = dailyAggregateService.getMergedGapStats(
                from: sevenDaysAgo,
                to: Date(),
                profileId: profileId
            )
        } else {
            // Fallback: no profile, use raw calculation
            weekStats = WeekCalculations.calculateWeekStatsBatch(from: allRecentEvents)
            let gaps = GapCalculations.recentGaps(events: allRecentEvents.filter { $0.time >= sevenDaysAgo }, days: 7)
            gapStats = GapCalculations.calculateGapStats(gaps: gaps)
        }
        aggregateSpan?.finish()

        // Check if cancelled before rest of computation
        guard !Task.isCancelled else {
            _isLoading = false
            // PERF: Don't send objectWillChange on cancellation - nothing changed
            statsTransaction?.finish()
            return
        }

        // Move remaining computation to background thread
        let computeSpan = statsTransaction?.startChild(
            operation: "stats.background",
            description: "Background Computation"
        )
        let results = await Task.detached(priority: .userInitiated) {
            self.computeStatsBackground(
                allRecentEvents: allRecentEvents,
                extendedEvents: extendedEvents,
                walksPerDay: walksPerDay,
                weekStats: weekStats,
                gapStats: gapStats
            )
        }.value
        computeSpan?.finish()

        // Check if cancelled before updating UI
        guard !Task.isCancelled else {
            _isLoading = false
            // PERF: Don't send objectWillChange on cancellation - nothing changed
            statsTransaction?.finish()
            return
        }

        // PERFORMANCE: Update all properties without triggering individual objectWillChange
        // Then send a single notification at the end
        _recentEvents = results.recentEvents
        _patternAnalysis = results.patternAnalysis
        _weekStats = results.weekStats
        _recentWalks = results.recentWalks
        _weekWalkStats = results.weekWalkStats
        _walkStats = results.walkStats
        _gapStats = results.gapStats
        _isLoading = false

        // Single objectWillChange for all updates
        objectWillChange.send()

        statsTransaction?.finish()
    }

    /// Background computation - no UI access, pure data processing
    /// PERFORMANCE: weekStats and gapStats are pre-computed from aggregates
    private nonisolated func computeStatsBackground(
        allRecentEvents: [PuppyEvent],
        extendedEvents: [PuppyEvent],
        walksPerDay: Int,
        weekStats: [DayStats],
        gapStats: GapStats
    ) -> StatsResults {
        let sevenDaysAgo = Date().addingDays(-7)

        // Filter recent events (7 days)
        let recentEvents = allRecentEvents.filter { $0.time >= sevenDaysAgo }

        // Calculate pattern analysis
        let patternAnalysis = PatternCalculations.analyzePatterns(
            events: recentEvents,
            periodDays: 7
        )

        // weekStats already provided from aggregates (skip WeekCalculations.calculateWeekStatsBatch)

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

        // gapStats already provided from aggregates (skip GapCalculations)

        return StatsResults(
            recentEvents: recentEvents,
            patternAnalysis: patternAnalysis,
            weekStats: weekStats,
            recentWalks: recentWalks,
            weekWalkStats: weekWalkStats,
            walkStats: walkStats,
            gapStats: gapStats
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
        let gapStats: GapStats
    }
}
