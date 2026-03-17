//
//  CDGroomingActivity+Extensions.swift
//  Otis-app
//
//  Extensions for converting between GroomingActivity and CDGroomingActivity
//

@preconcurrency import CoreData
import OtisShared

// MARK: - StorableModel Conformance

extension GroomingActivity: StorableModel {}

// MARK: - CDEntityConvertible Conformance

extension CDGroomingActivity: CDEntityConvertible {
    typealias Model = GroomingActivity

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllActivities(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    @discardableResult
    static func create(from activity: GroomingActivity, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdActivity = CDGroomingActivity(context: context)
        cdActivity.update(from: activity)
        return cdActivity
    }

    @discardableResult
    static func create(from activity: GroomingActivity, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDGroomingActivity {
        let cdActivity = CDGroomingActivity(context: context)
        cdActivity.update(from: activity)
        cdActivity.profile = profile
        return cdActivity
    }

    func toModel() -> GroomingActivity? {
        toGroomingActivity()
    }
}

// MARK: - Core Data Operations

extension CDGroomingActivity {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from GroomingActivity struct
    func update(from activity: GroomingActivity) {
        self.id = activity.id
        self.type = activity.type.rawValue
        self.intervalDays = Int32(activity.intervalDays)
        self.lastCompleted = activity.lastCompleted
        self.isEnabled = activity.isEnabled
        self.note = activity.note
        self.createdAt = activity.createdAt
        self.modifiedAt = Date()
    }

    // MARK: - Convert to Swift Struct

    /// Convert to GroomingActivity struct
    func toGroomingActivity() -> GroomingActivity? {
        guard let id = self.id,
              let typeString = self.type,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        guard let type = GroomingType(rawValue: typeString) else {
            return nil
        }

        return GroomingActivity(
            id: id,
            type: type,
            intervalDays: Int(self.intervalDays),
            lastCompleted: self.lastCompleted,
            isEnabled: self.isEnabled,
            note: self.note,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDGroomingActivity {

    /// Fetch all activities sorted by type
    static func fetchAllActivities(in context: NSManagedObjectContext) -> [CDGroomingActivity] {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDGroomingActivity.type, ascending: true)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch activities for a specific profile, sorted by type
    static func fetchActivities(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDGroomingActivity] {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDGroomingActivity.type, ascending: true)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch activity by type for a profile
    static func fetchActivity(for profile: CDPuppyProfile, type: GroomingType, in context: NSManagedObjectContext) -> CDGroomingActivity? {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.predicate = NSPredicate(format: "profile == %@ AND type == %@", profile, type.rawValue)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Fetch by ID (convenience method with correct return type)
    static func fetchActivity(byId id: UUID, in context: NSManagedObjectContext) -> CDGroomingActivity? {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Count all activities for a profile
    static func countActivities(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return context.performAndWait {
            (try? context.count(for: request)) ?? 0
        }
    }

    /// Fetch all activities without a profile (for migration)
    static func fetchOrphanedActivities(in context: NSManagedObjectContext) -> [CDGroomingActivity] {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.predicate = NSPredicate(format: "profile == nil")
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }
}
