//
//  CDDailyAggregate+Extensions.swift
//  Otis-app
//
//  Extensions for CDDailyAggregate - local cache of daily statistics.
//  syncable="NO" - this is computed from synced events, each device maintains its own cache.
//

@preconcurrency import CoreData
import OtisShared

extension CDDailyAggregate {

    // MARK: - Fetch Methods

    /// Fetch aggregate for a specific date and profile
    nonisolated static func fetch(
        for date: Date,
        profileId: UUID,
        in context: NSManagedObjectContext
    ) -> CDDailyAggregate? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        let request = NSFetchRequest<CDDailyAggregate>(entityName: "CDDailyAggregate")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "profileId == %@", profileId as CVarArg),
            NSPredicate(format: "date == %@", dayStart as CVarArg)
        ])
        request.fetchLimit = 1

        nonisolated(unsafe) var result: CDDailyAggregate?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Fetch aggregates for a date range
    nonisolated static func fetchRange(
        from startDate: Date,
        to endDate: Date,
        profileId: UUID,
        in context: NSManagedObjectContext
    ) -> [CDDailyAggregate] {
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: startDate)
        let rangeEnd = calendar.startOfDay(for: endDate)

        let request = NSFetchRequest<CDDailyAggregate>(entityName: "CDDailyAggregate")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "profileId == %@", profileId as CVarArg),
            NSPredicate(format: "date >= %@ AND date <= %@", rangeStart as CVarArg, rangeEnd as CVarArg)
        ])
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        nonisolated(unsafe) var results: [CDDailyAggregate] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch all aggregates for a profile (for cleanup)
    nonisolated static func fetchAll(
        profileId: UUID,
        in context: NSManagedObjectContext
    ) -> [CDDailyAggregate] {
        let request = NSFetchRequest<CDDailyAggregate>(entityName: "CDDailyAggregate")
        request.predicate = NSPredicate(format: "profileId == %@", profileId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        nonisolated(unsafe) var results: [CDDailyAggregate] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    // MARK: - Upsert

    /// Create or update aggregate for a date
    nonisolated static func upsert(
        date: Date,
        profileId: UUID,
        outdoorPotty: Int,
        indoorPotty: Int,
        meals: Int,
        walks: Int,
        sleepMinutes: Int,
        trainingSessions: Int,
        gapDurations: [Int],
        streak: Int,
        lastEventModifiedAt: Date?,
        in context: NSManagedObjectContext
    ) -> CDDailyAggregate {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Try to find existing
        let existing = fetch(for: dayStart, profileId: profileId, in: context)

        nonisolated(unsafe) var aggregate: CDDailyAggregate!

        context.performAndWait {
            if let existingAggregate = existing {
                aggregate = existingAggregate
            } else {
                aggregate = CDDailyAggregate(context: context)
                aggregate.id = UUID()
                aggregate.date = dayStart
                aggregate.profileId = profileId
            }

            aggregate.outdoorPotty = Int32(outdoorPotty)
            aggregate.indoorPotty = Int32(indoorPotty)
            aggregate.meals = Int32(meals)
            aggregate.walks = Int32(walks)
            aggregate.sleepMinutes = Int32(sleepMinutes)
            aggregate.trainingSessions = Int32(trainingSessions)
            aggregate.streakAtEndOfDay = Int32(streak)
            aggregate.lastEventModifiedAt = lastEventModifiedAt
            aggregate.computedAt = Date()

            // Encode gap durations as JSON
            if !gapDurations.isEmpty {
                aggregate.sortedGapDurations = try? JSONEncoder().encode(gapDurations)
            } else {
                aggregate.sortedGapDurations = nil
            }
        }

        return aggregate
    }

    // MARK: - Conversion

    /// Convert to DayStats struct
    func toDayStats() -> DayStats {
        DayStats(
            date: date ?? Date(),
            outdoorPotty: Int(outdoorPotty),
            indoorPotty: Int(indoorPotty),
            meals: Int(meals),
            walks: Int(walks),
            sleepHours: Double(sleepMinutes) / 60.0,
            trainingSessions: Int(trainingSessions)
        )
    }

    /// Get decoded gap durations array
    func getGapDurations() -> [Int] {
        guard let data = sortedGapDurations else { return [] }
        return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
    }

    // MARK: - Staleness Check

    /// Check if this aggregate is stale compared to the latest event modification
    func isStale(comparedTo maxEventModifiedAt: Date) -> Bool {
        guard let lastModified = lastEventModifiedAt else {
            // No modification date stored, consider stale
            return true
        }
        // Stale if events have been modified after this aggregate was computed
        return maxEventModifiedAt > lastModified
    }

    // MARK: - Cleanup

    /// Delete aggregates older than a certain number of days
    nonisolated static func cleanupOld(
        keepDays: Int,
        profileId: UUID,
        in context: NSManagedObjectContext
    ) -> Int {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -keepDays, to: Date()) ?? Date()

        let request = NSFetchRequest<CDDailyAggregate>(entityName: "CDDailyAggregate")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "profileId == %@", profileId as CVarArg),
            NSPredicate(format: "date < %@", cutoffDate as CVarArg)
        ])

        nonisolated(unsafe) var count = 0
        context.performAndWait {
            guard let oldAggregates = try? context.fetch(request) else { return }
            count = oldAggregates.count
            for aggregate in oldAggregates {
                context.delete(aggregate)
            }
        }
        return count
    }

    /// Delete aggregate for a specific date (used when invalidating)
    nonisolated static func delete(
        for date: Date,
        profileId: UUID,
        in context: NSManagedObjectContext
    ) {
        guard let aggregate = fetch(for: date, profileId: profileId, in: context) else { return }
        context.performAndWait {
            context.delete(aggregate)
        }
    }

    /// Delete all aggregates for a profile
    nonisolated static func deleteAll(
        profileId: UUID,
        in context: NSManagedObjectContext
    ) {
        let request = NSFetchRequest<CDDailyAggregate>(entityName: "CDDailyAggregate")
        request.predicate = NSPredicate(format: "profileId == %@", profileId as CVarArg)

        context.performAndWait {
            guard let aggregates = try? context.fetch(request) else { return }
            for aggregate in aggregates {
                context.delete(aggregate)
            }
        }
    }
}
