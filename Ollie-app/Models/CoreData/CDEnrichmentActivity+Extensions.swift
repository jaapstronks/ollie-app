//
//  CDEnrichmentActivity+Extensions.swift
//  Otis-app
//
//  Extensions for converting between EnrichmentActivity and CDEnrichmentActivity
//

@preconcurrency import CoreData
import OtisShared

// MARK: - StorableModel Conformance

extension EnrichmentActivity: StorableModel {}

// MARK: - CDEntityConvertible Conformance

extension CDEnrichmentActivity: CDEntityConvertible {
    typealias Model = EnrichmentActivity

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllActivities(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDEnrichmentActivity>(entityName: "CDEnrichmentActivity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    @discardableResult
    static func create(from activity: EnrichmentActivity, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdActivity = CDEnrichmentActivity(context: context)
        cdActivity.update(from: activity)
        return cdActivity
    }

    @discardableResult
    static func create(from activity: EnrichmentActivity, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDEnrichmentActivity {
        let cdActivity = CDEnrichmentActivity(context: context)
        cdActivity.update(from: activity)
        cdActivity.profile = profile
        return cdActivity
    }

    func toModel() -> EnrichmentActivity? {
        toEnrichmentActivity()
    }
}

// MARK: - Core Data Operations

extension CDEnrichmentActivity {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from EnrichmentActivity struct
    func update(from activity: EnrichmentActivity) {
        self.id = activity.id
        self.type = activity.type.rawValue
        self.completedAt = activity.completedAt
        if let minutes = activity.durationMinutes {
            self.durationMinutes = Int32(minutes)
        }
        self.note = activity.note
        self.createdAt = activity.createdAt
        self.modifiedAt = Date()
    }

    // MARK: - Convert to Swift Struct

    /// Convert to EnrichmentActivity struct
    func toEnrichmentActivity() -> EnrichmentActivity? {
        guard let id = self.id,
              let typeString = self.type,
              let completedAt = self.completedAt,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        guard let type = EnrichmentType(rawValue: typeString) else {
            return nil
        }

        let durationMinutes = self.durationMinutes > 0 ? Int(self.durationMinutes) : nil

        return EnrichmentActivity(
            id: id,
            type: type,
            completedAt: completedAt,
            durationMinutes: durationMinutes,
            note: self.note,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDEnrichmentActivity {

    /// Fetch all activities sorted by completed date (newest first)
    static func fetchAllActivities(in context: NSManagedObjectContext) -> [CDEnrichmentActivity] {
        let request = NSFetchRequest<CDEnrichmentActivity>(entityName: "CDEnrichmentActivity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEnrichmentActivity.completedAt, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch activities for a specific profile, sorted by completed date (newest first)
    static func fetchActivities(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDEnrichmentActivity] {
        let request = NSFetchRequest<CDEnrichmentActivity>(entityName: "CDEnrichmentActivity")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEnrichmentActivity.completedAt, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch recent activities (within last N days)
    static func fetchRecent(for profile: CDPuppyProfile, days: Int, in context: NSManagedObjectContext) -> [CDEnrichmentActivity] {
        let request = NSFetchRequest<CDEnrichmentActivity>(entityName: "CDEnrichmentActivity")
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "profile == %@ AND completedAt >= %@", profile, cutoffDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDEnrichmentActivity.completedAt, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch by ID (convenience method with correct return type)
    static func fetchActivity(byId id: UUID, in context: NSManagedObjectContext) -> CDEnrichmentActivity? {
        let request = NSFetchRequest<CDEnrichmentActivity>(entityName: "CDEnrichmentActivity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Count all activities for a profile
    static func countActivities(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDEnrichmentActivity>(entityName: "CDEnrichmentActivity")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return context.performAndWait {
            (try? context.count(for: request)) ?? 0
        }
    }

    /// Fetch all activities without a profile (for migration)
    static func fetchOrphanedActivities(in context: NSManagedObjectContext) -> [CDEnrichmentActivity] {
        let request = NSFetchRequest<CDEnrichmentActivity>(entityName: "CDEnrichmentActivity")
        request.predicate = NSPredicate(format: "profile == nil")
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }
}
