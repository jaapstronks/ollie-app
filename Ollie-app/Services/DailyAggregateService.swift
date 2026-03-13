//
//  DailyAggregateService.swift
//  Otis-app
//
//  Manages pre-computed daily aggregates for fast stats access.
//
//  Performance Impact:
//  - Reading 7-day stats: ~1,700ms -> ~10ms (reads 7 small records vs 1,500+ events)
//  - Logging 1 event: ~1,700ms -> ~50ms (only recomputes 1 day)
//
//  The aggregates are local cache (syncable="NO") - each device computes its own
//  from synced events. This avoids conflict resolution and keeps events as source of truth.
//

import Foundation
import CoreData
import OtisShared
import os
import Sentry

/// Shared instance holder to avoid MainActor issues
private enum DailyAggregateServiceHolder {
    @MainActor static let shared = DailyAggregateService()
}

/// Service for managing pre-computed daily aggregates
/// Note: Not ObservableObject since it's a utility service with no published state
@MainActor
final class DailyAggregateService {

    // MARK: - Shared Instance

    /// Shared instance for use when not injected
    static var shared: DailyAggregateService {
        DailyAggregateServiceHolder.shared
    }

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private let logger = Logger.otis(category: "DailyAggregateService")

    // MARK: - Configuration

    /// How many days of aggregates to keep (older ones cleaned up)
    private let retentionDays = 90

    /// Whether to use aggregates or fall back to raw computation
    /// Set to false to disable aggregates (for debugging)
    private var useAggregates = true

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Public API

    /// Get aggregates for a date range, computing any missing ones
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    ///   - profileId: Profile ID
    ///   - events: Events to use for computation (should cover from-1 day to to+1 day for sleep)
    /// - Returns: Array of DayStats for each day in range
    func getAggregates(
        from startDate: Date,
        to endDate: Date,
        profileId: UUID,
        events: [PuppyEvent]
    ) async -> [DayStats] {
        let span = CrashReporter.startTransaction(
            name: "Get Daily Aggregates",
            operation: "aggregate.read"
        )
        defer { span?.finish() }

        let calendar = Calendar.current
        let context = persistenceController.viewContext

        // Fetch existing aggregates
        let fetchSpan = span?.startChild(operation: "db.query", description: "Fetch Aggregates")
        let existing = CDDailyAggregate.fetchRange(
            from: startDate,
            to: endDate,
            profileId: profileId,
            in: context
        )
        fetchSpan?.finish()

        // Build lookup by date
        var aggregatesByDate: [Date: CDDailyAggregate] = [:]
        for aggregate in existing {
            if let date = aggregate.date {
                aggregatesByDate[calendar.startOfDay(for: date)] = aggregate
            }
        }

        // Find max modifiedAt in events for staleness check
        let maxEventModifiedAt = events.map { $0.modifiedAt }.max()

        // Build day stats, computing missing or stale aggregates
        var dayStats: [DayStats] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let rangeEnd = calendar.startOfDay(for: endDate)

        let computeSpan = span?.startChild(operation: "aggregate.compute", description: "Compute Missing")

        while currentDate <= rangeEnd {
            if let aggregate = aggregatesByDate[currentDate],
               let maxMod = maxEventModifiedAt,
               !aggregate.isStale(comparedTo: maxMod) {
                // Use cached aggregate
                dayStats.append(aggregate.toDayStats())
            } else {
                // Compute and cache
                let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDate)!

                // Filter events for this day and previous (for sleep)
                let dayEvents = events.filter { event in
                    event.time >= previousDay && event.time < dayEnd
                }

                let stats = computeDayStats(
                    date: currentDate,
                    events: dayEvents,
                    allEvents: events,
                    profileId: profileId,
                    previousDayAggregate: aggregatesByDate[previousDay],
                    in: context
                )
                dayStats.append(stats)
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        computeSpan?.finish()

        // Save any new aggregates
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                logger.error("Failed to save aggregates: \(error.localizedDescription)")
            }
        }

        return dayStats
    }

    /// Recompute aggregate for a specific date
    /// Call this when events for that day are modified
    func recompute(
        date: Date,
        profileId: UUID,
        events: [PuppyEvent]
    ) async {
        let context = persistenceController.viewContext
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart)!
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        // Get previous day aggregate for streak calculation
        let previousAggregate = CDDailyAggregate.fetch(
            for: previousDay,
            profileId: profileId,
            in: context
        )

        // Filter events for this day and previous (for sleep)
        let dayEvents = events.filter { event in
            event.time >= previousDay && event.time < dayEnd
        }

        _ = computeDayStats(
            date: dayStart,
            events: dayEvents,
            allEvents: events,
            profileId: profileId,
            previousDayAggregate: previousAggregate,
            in: context
        )

        // Save
        if context.hasChanges {
            do {
                try context.save()
                logger.debug("Recomputed aggregate for \(dayStart)")
            } catch {
                logger.error("Failed to save recomputed aggregate: \(error.localizedDescription)")
            }
        }
    }

    /// Invalidate aggregate for a specific date (will be recomputed on next access)
    func invalidate(date: Date, profileId: UUID) {
        let context = persistenceController.viewContext
        CDDailyAggregate.delete(for: date, profileId: profileId, in: context)

        if context.hasChanges {
            try? context.save()
        }
    }

    /// Invalidate all aggregates for a profile
    func invalidateAll(profileId: UUID) {
        let context = persistenceController.viewContext
        CDDailyAggregate.deleteAll(profileId: profileId, in: context)

        if context.hasChanges {
            try? context.save()
        }
        logger.info("Invalidated all aggregates for profile")
    }

    /// Clean up old aggregates beyond retention period
    func cleanupOld(profileId: UUID) {
        let context = persistenceController.viewContext
        let deleted = CDDailyAggregate.cleanupOld(
            keepDays: retentionDays,
            profileId: profileId,
            in: context
        )

        if context.hasChanges {
            try? context.save()
        }

        if deleted > 0 {
            logger.info("Cleaned up \(deleted) old aggregates")
        }
    }

    /// Pre-populate aggregates for the last N days (run on app update)
    func prepopulate(
        days: Int,
        profileId: UUID,
        events: [PuppyEvent]
    ) async {
        let calendar = Calendar.current
        let today = Date()

        logger.info("Pre-populating aggregates for last \(days) days")

        for daysAgo in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            await recompute(date: date, profileId: profileId, events: events)
        }

        cleanupOld(profileId: profileId)
    }

    /// Get merged gap stats from aggregates
    /// - Returns: Combined GapStats from all aggregates in range
    func getMergedGapStats(
        from startDate: Date,
        to endDate: Date,
        profileId: UUID
    ) -> GapStats {
        let context = persistenceController.viewContext
        let aggregates = CDDailyAggregate.fetchRange(
            from: startDate,
            to: endDate,
            profileId: profileId,
            in: context
        )

        // Merge all gap durations and compute combined stats
        let allGapDurations = aggregates.flatMap { $0.getGapDurations() }.sorted()

        guard !allGapDurations.isEmpty else { return .empty }

        let minVal = allGapDurations.first ?? 0
        let maxVal = allGapDurations.last ?? 0
        let sum = allGapDurations.reduce(0, +)
        let avg = sum / allGapDurations.count

        let median: Int
        if allGapDurations.count % 2 == 0 {
            let mid = allGapDurations.count / 2
            median = (allGapDurations[mid - 1] + allGapDurations[mid]) / 2
        } else {
            median = allGapDurations[allGapDurations.count / 2]
        }

        // Sum up outdoor/indoor counts from aggregates
        var outdoorCount = 0
        var indoorCount = 0
        for aggregate in aggregates {
            outdoorCount += Int(aggregate.outdoorPotty)
            indoorCount += Int(aggregate.indoorPotty)
        }

        return GapStats(
            count: allGapDurations.count,
            minMinutes: minVal,
            maxMinutes: maxVal,
            avgMinutes: avg,
            medianMinutes: median,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    // MARK: - Private Methods

    /// Compute stats for a single day and store in aggregate
    private func computeDayStats(
        date: Date,
        events: [PuppyEvent],
        allEvents: [PuppyEvent],
        profileId: UUID,
        previousDayAggregate: CDDailyAggregate?,
        in context: NSManagedObjectContext
    ) -> DayStats {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let previousDayStart = calendar.date(byAdding: .day, value: -1, to: dayStart)!

        // Filter to just this day's events
        let todayEvents = events.filter { event in
            event.time >= dayStart && event.time < dayEnd
        }

        // Filter previous day events for sleep calculation
        let previousDayEvents = events.filter { event in
            event.time >= previousDayStart && event.time < dayStart
        }

        // Count stats
        var outdoorPotty = 0
        var indoorPotty = 0
        var meals = 0
        var walks = 0
        var trainingSessions = 0

        for event in todayEvents {
            let isPotty = event.type == .plassen || event.type == .poepen

            if isPotty && event.location == .buiten {
                outdoorPotty += 1
            } else if isPotty && event.location == .binnen {
                indoorPotty += 1
            }

            if event.type == .eten {
                meals += 1
            }

            if event.type == .uitlaten {
                walks += 1
            }

            if event.type == .training {
                trainingSessions += 1
            }
        }

        // Calculate sleep using combined events
        let sleepMinutes = WeekCalculations.calculateDaySleepMinutes(
            date: date,
            todayEvents: todayEvents,
            previousDayEvents: previousDayEvents
        )

        // Calculate gaps for this day
        let gaps = GapCalculations.calculatePottyGaps(events: todayEvents, filterOvernight: true)
        let gapDurations = gaps.map { $0.durationMinutes }.sorted()

        // Calculate streak at end of day
        let previousStreak = Int(previousDayAggregate?.streakAtEndOfDay ?? 0)
        let streak = calculateStreakAtEndOfDay(
            previousStreak: previousStreak,
            todayPottyEvents: todayEvents.filter { $0.type == .plassen || $0.type == .poepen }
        )

        // Get max modifiedAt for staleness tracking
        let maxModifiedAt = todayEvents.map { $0.modifiedAt }.max()

        // Upsert aggregate
        _ = CDDailyAggregate.upsert(
            date: date,
            profileId: profileId,
            outdoorPotty: outdoorPotty,
            indoorPotty: indoorPotty,
            meals: meals,
            walks: walks,
            sleepMinutes: sleepMinutes,
            trainingSessions: trainingSessions,
            gapDurations: gapDurations,
            streak: streak,
            lastEventModifiedAt: maxModifiedAt,
            in: context
        )

        return DayStats(
            date: date,
            outdoorPotty: outdoorPotty,
            indoorPotty: indoorPotty,
            meals: meals,
            walks: walks,
            sleepHours: Double(sleepMinutes) / 60.0,
            trainingSessions: trainingSessions
        )
    }

    /// Calculate outdoor potty streak at end of day
    private func calculateStreakAtEndOfDay(
        previousStreak: Int,
        todayPottyEvents: [PuppyEvent]
    ) -> Int {
        var streak = previousStreak

        // Process potty events chronologically
        let chronological = todayPottyEvents.sorted { $0.time < $1.time }

        for event in chronological {
            if event.location == .buiten {
                streak += 1
            } else {
                // Indoor accident resets streak
                streak = 0
            }
        }

        return streak
    }
}
