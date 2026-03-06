//
//  CDRegressionLog+Extensions.swift
//  Ollie-app
//
//  Extensions for CDRegressionLog Core Data entity.
//  Provides conversion to/from RegressionLogEntry model.
//

import CoreData
import OtisShared

extension CDRegressionLog {

    // MARK: - Conversion to Model

    /// Convert Core Data entity to RegressionLogEntry model
    func toRegressionLogEntry() -> RegressionLogEntry? {
        guard let id = self.id,
              let skillId = self.skillId,
              !skillId.isEmpty,
              let occurredAt = self.occurredAt else {
            return nil
        }

        return RegressionLogEntry(
            id: id,
            skillId: skillId,
            occurredAt: occurredAt,
            previousTier: Int(self.previousTier),
            successRateAtFailure: self.successRateAtFailure,
            recoveredAt: self.recoveredAt,
            sessionsToRecover: self.sessionsToRecover.map { Int(truncating: $0) }
        )
    }

    // MARK: - Update from Model

    /// Update Core Data entity from RegressionLogEntry model
    func update(from entry: RegressionLogEntry) {
        self.id = entry.id
        self.skillId = entry.skillId
        self.occurredAt = entry.occurredAt
        self.previousTier = Int16(entry.previousTier)
        self.successRateAtFailure = entry.successRateAtFailure
        self.recoveredAt = entry.recoveredAt
        self.sessionsToRecover = entry.sessionsToRecover.map { NSNumber(value: $0) }
        self.modifiedAt = Date()
    }

    // MARK: - Factory Methods

    /// Create a new CDRegressionLog from a RegressionLogEntry
    @discardableResult
    static func create(from entry: RegressionLogEntry, in context: NSManagedObjectContext) -> CDRegressionLog {
        let cdEntry = CDRegressionLog(context: context)
        cdEntry.id = entry.id
        cdEntry.skillId = entry.skillId
        cdEntry.occurredAt = entry.occurredAt
        cdEntry.previousTier = Int16(entry.previousTier)
        cdEntry.successRateAtFailure = entry.successRateAtFailure
        cdEntry.recoveredAt = entry.recoveredAt
        cdEntry.sessionsToRecover = entry.sessionsToRecover.map { NSNumber(value: $0) }
        cdEntry.createdAt = Date()
        cdEntry.modifiedAt = Date()
        return cdEntry
    }

    // MARK: - Fetch Methods

    /// Fetch all regression log entries
    static func fetchAll(in context: NSManagedObjectContext) -> [CDRegressionLog] {
        let request = NSFetchRequest<CDRegressionLog>(entityName: "CDRegressionLog")
        request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching regression logs: \(error)")
            return []
        }
    }

    /// Fetch regression logs for a specific skill
    static func fetch(bySkillId skillId: String, in context: NSManagedObjectContext) -> [CDRegressionLog] {
        let request = NSFetchRequest<CDRegressionLog>(entityName: "CDRegressionLog")
        request.predicate = NSPredicate(format: "skillId == %@", skillId)
        request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching regression logs for skill \(skillId): \(error)")
            return []
        }
    }

    /// Fetch regression log by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDRegressionLog? {
        let request = NSFetchRequest<CDRegressionLog>(entityName: "CDRegressionLog")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching regression log by ID: \(error)")
            return nil
        }
    }

    /// Fetch recent regressions (within the specified number of days)
    static func fetchRecent(days: Int, in context: NSManagedObjectContext) -> [CDRegressionLog] {
        let request = NSFetchRequest<CDRegressionLog>(entityName: "CDRegressionLog")
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "occurredAt >= %@", cutoffDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent regression logs: \(error)")
            return []
        }
    }

    /// Fetch unrecovered regressions
    static func fetchUnrecovered(in context: NSManagedObjectContext) -> [CDRegressionLog] {
        let request = NSFetchRequest<CDRegressionLog>(entityName: "CDRegressionLog")
        request.predicate = NSPredicate(format: "recoveredAt == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching unrecovered regression logs: \(error)")
            return []
        }
    }

    /// Check if a regression log exists for a given ID
    static func exists(forId id: UUID, in context: NSManagedObjectContext) -> Bool {
        let request = NSFetchRequest<CDRegressionLog>(entityName: "CDRegressionLog")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
}
