//
//  EventDataProvider.swift
//  Otis-app
//
//  Centralized event data provider with intelligent caching.
//  Replaces individual service fetches with a single shared cache.
//
//  Problem Solved:
//  - TimelineStatsCache fetches 8 + 15 days
//  - PredictionService fetches 1 + 7 + 30 days
//  - NotificationService fetches 2 days
//  - All these overlap and hit Core Data separately
//
//  Solution:
//  - Single fetch for max range (30 days)
//  - Filter in memory for smaller ranges
//  - Cache invalidated on event changes
//

import Foundation
import Combine
import OtisShared
import Sentry

/// Centralized event data provider with intelligent caching
/// Services should use this instead of fetching directly from EventStore
@MainActor
final class EventDataProvider: ObservableObject {

    // MARK: - Global Refresh Lock
    // PERF: Prevents multiple EventDataProvider instances from refreshing simultaneously
    private static var isGlobalRefreshInProgress = false
    private static var lastGlobalRefreshTime: Date = .distantPast

    // MARK: - Dependencies

    private let eventStore: EventStore

    // MARK: - Cached Data
    // PERFORMANCE: Using manual backing storage to batch objectWillChange notifications
    // Instead of triggering per-property, we send a single notification after all updates

    /// Today's events (from EventStore's in-memory array, always fresh)
    var todayEvents: [PuppyEvent] { _todayEvents }
    private var _todayEvents: [PuppyEvent] = []

    /// Events from yesterday + today (2 days) - for predictions, notifications
    var recentEvents: [PuppyEvent] { _recentEvents }
    private var _recentEvents: [PuppyEvent] = []

    /// Events from past 7 days - for historical patterns
    var weekEvents: [PuppyEvent] { _weekEvents }
    private var _weekEvents: [PuppyEvent] = []

    /// Events from past 8 days - for stats cache
    var eightDayEvents: [PuppyEvent] { _eightDayEvents }
    private var _eightDayEvents: [PuppyEvent] = []

    /// Events from past 15 days - for extended stats, walk analysis
    var extendedEvents: [PuppyEvent] { _extendedEvents }
    private var _extendedEvents: [PuppyEvent] = []

    /// Events from past 30 days - for streaks, full history
    var monthEvents: [PuppyEvent] { _monthEvents }
    private var _monthEvents: [PuppyEvent] = []

    /// Whether data is currently being refreshed
    var isRefreshing: Bool { _isRefreshing }
    private var _isRefreshing: Bool = false

    // MARK: - Cache State

    /// Last time historical data was refreshed
    private var lastHistoricalRefresh: Date?

    /// Active refresh task (cancelled if new refresh requested)
    private var refreshTask: Task<Void, Never>?

    /// Flag to prevent concurrent refreshes
    private var isRefreshInProgress: Bool = false

    /// How long cached historical data remains valid
    /// PERFORMANCE: Increased from 30s to 120s - data only changes when user logs events
    private let cacheValidDuration: TimeInterval = 120 // seconds

    /// Subscription to EventStore changes
    private var eventStoreCancellable: AnyCancellable?

    // MARK: - Initialization

    init(eventStore: EventStore) {
        self.eventStore = eventStore

        // Subscribe to event changes via NotificationCenter
        // When events change, update today's events immediately and schedule historical refresh
        // Note: EventStore is @Observable, not ObservableObject, so we use notifications
        eventStoreCancellable = NotificationCenter.default.publisher(for: .eventsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }

                // Update today's events immediately (triggers single objectWillChange)
                self._todayEvents = self.eventStore.events
                self.objectWillChange.send()

                // Invalidate historical cache and schedule refresh
                self.invalidateAndRefresh()
            }

        // Initial load (no notification needed yet)
        _todayEvents = eventStore.events
        Task {
            await refreshHistoricalData()
        }
    }

    // MARK: - Public API

    /// Force refresh all cached data
    /// - Parameter force: If true, bypasses cache validity check
    func refresh(force: Bool = false) {
        guard force || shouldRefreshHistorical else { return }
        invalidateAndRefresh()
    }

    /// Get events for a custom date range (uses cache if possible, fetches if needed)
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Events in the range, sorted by time descending
    func getEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // If range is within cached month, filter from cache
        let thirtyDaysAgo = now.addingDays(-30)
        if startDate >= thirtyDaysAgo && endDate <= now {
            // Combine historical (from cache) + today (from in-memory)
            let historicalEvents = monthEvents.filter { $0.time >= startDate && $0.time < startOfToday }
            let todayInRange = todayEvents.filter { $0.time >= startDate && $0.time <= endDate }
            return (historicalEvents + todayInRange).sorted { $0.time > $1.time }
        }

        // Range exceeds cache, need direct fetch
        return eventStore.getEvents(from: startDate, to: endDate)
    }

    /// Async version for ranges that might exceed cache
    func getEventsAsync(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // If range is within cached month, filter from cache
        let thirtyDaysAgo = now.addingDays(-30)
        if startDate >= thirtyDaysAgo && endDate <= now {
            let historicalEvents = monthEvents.filter { $0.time >= startDate && $0.time < startOfToday }
            let todayInRange = todayEvents.filter { $0.time >= startDate && $0.time <= endDate }
            return (historicalEvents + todayInRange).sorted { $0.time > $1.time }
        }

        // Range exceeds cache, need direct fetch
        return await eventStore.getEventsAsync(from: startDate, to: endDate)
    }

    // MARK: - Private Methods

    private var shouldRefreshHistorical: Bool {
        guard let lastRefresh = lastHistoricalRefresh else { return true }
        return Date().timeIntervalSince(lastRefresh) > cacheValidDuration
    }

    private func invalidateAndRefresh() {
        // Cancel any in-progress refresh
        refreshTask?.cancel()

        // Schedule new refresh with debounce
        // PERFORMANCE: Increased from 100ms to 300ms to better coalesce rapid changes
        refreshTask = Task {
            // Delay to coalesce rapid changes (app launch, bulk edits, etc.)
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            await refreshHistoricalData()
        }
    }

    /// Refresh all historical event ranges from Core Data
    private func refreshHistoricalData() async {
        // PERFORMANCE: Prevent concurrent refreshes (local)
        guard !isRefreshInProgress else {
            return
        }

        // PERF: Global lock to prevent multiple instances refreshing simultaneously
        let now = Date()
        guard !Self.isGlobalRefreshInProgress else {
            return
        }
        // Also enforce minimum interval between global refreshes
        guard now.timeIntervalSince(Self.lastGlobalRefreshTime) > 0.5 else {
            return
        }

        isRefreshInProgress = true
        Self.isGlobalRefreshInProgress = true
        Self.lastGlobalRefreshTime = now
        defer {
            isRefreshInProgress = false
            Self.isGlobalRefreshInProgress = false
        }

        // PERFORMANCE: Check debug toggle to skip expensive refresh
        guard !PerformanceDebug.disableHistoricalRefresh else {
            if PerformanceDebug.logExpensiveOperations {
                print("[PERF] SKIPPED: EventDataProvider.refreshHistoricalData (disabled by toggle)")
            }
            return
        }

        // PERFORMANCE: Track historical data refresh time
        let refreshTransaction = CrashReporter.startTransaction(
            name: "Refresh Historical Events",
            operation: "data.refresh"
        )

        // PERF: Removed objectWillChange at START - only send when refresh completes
        // This halves the number of view rebuilds triggered by data refresh
        _isRefreshing = true

        let calendar = Calendar.current
        // Reuse 'now' from global debounce check above
        let startOfToday = calendar.startOfDay(for: now)

        // Date boundaries
        let yesterday = now.addingDays(-1)
        let weekAgo = now.addingDays(-7)
        let eightDaysAgo = now.addingDays(-8)
        let fifteenDaysAgo = now.addingDays(-15)
        let monthAgo = now.addingDays(-30)

        // Single fetch for max range (30 days of historical data, excluding today)
        // Today's events come from EventStore's in-memory array
        let fetchSpan = refreshTransaction?.startChild(
            operation: "db.query",
            description: "Fetch 30-day Events"
        )
        let allHistoricalEvents = await eventStore.getEventsAsync(from: monthAgo, to: startOfToday)
        fetchSpan?.finish()

        guard !Task.isCancelled else {
            _isRefreshing = false
            // PERF: Don't send objectWillChange on cancellation - nothing changed
            refreshTransaction?.finish()
            return
        }

        // Derive all ranges from single fetch (no additional DB queries)
        // PERF: Filter progressively from largest to smallest set
        // Each filter operates on the previous (smaller) result, reducing total work
        let filterSpan = refreshTransaction?.startChild(
            operation: "data.filter",
            description: "Filter Date Ranges"
        )
        let monthHistorical = allHistoricalEvents
        let extendedHistorical = monthHistorical.filter { $0.time >= fifteenDaysAgo }
        let eightDayHistorical = extendedHistorical.filter { $0.time >= eightDaysAgo }
        let weekHistorical = eightDayHistorical.filter { $0.time >= weekAgo }
        let yesterdayHistorical = weekHistorical.filter { $0.time >= yesterday }

        // Combine with today's in-memory events for complete ranges
        let todayFiltered = todayEvents.filter { calendar.isDateInToday($0.time) }
        filterSpan?.finish()

        // PERFORMANCE: Update all properties without triggering individual objectWillChange
        // Then send a single notification at the end
        let sortSpan = refreshTransaction?.startChild(
            operation: "data.sort",
            description: "Sort Event Arrays"
        )
        _monthEvents = (monthHistorical + todayFiltered).sorted { $0.time > $1.time }
        _extendedEvents = (extendedHistorical + todayFiltered).sorted { $0.time > $1.time }
        _eightDayEvents = (eightDayHistorical + todayFiltered).sorted { $0.time > $1.time }
        _weekEvents = (weekHistorical + todayFiltered).sorted { $0.time > $1.time }
        _recentEvents = (yesterdayHistorical + todayFiltered).sorted { $0.time > $1.time }
        sortSpan?.finish()

        lastHistoricalRefresh = Date()
        _isRefreshing = false

        // Single objectWillChange for all updates
        objectWillChange.send()

        refreshTransaction?.finish()
    }
}
