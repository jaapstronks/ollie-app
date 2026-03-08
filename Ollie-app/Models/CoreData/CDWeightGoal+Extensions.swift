//
//  CDWeightGoal+Extensions.swift
//  Otis-app
//
//  Extensions for converting between WeightGoal and CDWeightGoal
//

@preconcurrency import CoreData
import OtisShared

// MARK: - StorableModel Conformance

extension WeightGoal: StorableModel {}

// MARK: - CDEntityConvertible Conformance

extension CDWeightGoal: CDEntityConvertible {
    typealias Model = WeightGoal

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllGoals(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDWeightGoal>(entityName: "CDWeightGoal")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    @discardableResult
    static func create(from goal: WeightGoal, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdGoal = CDWeightGoal(context: context)
        cdGoal.update(from: goal)
        return cdGoal
    }

    @discardableResult
    static func create(from goal: WeightGoal, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDWeightGoal {
        let cdGoal = CDWeightGoal(context: context)
        cdGoal.update(from: goal)
        cdGoal.profile = profile
        return cdGoal
    }

    func toModel() -> WeightGoal? {
        toWeightGoal()
    }
}

// MARK: - Core Data Operations

extension CDWeightGoal {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from WeightGoal struct
    func update(from goal: WeightGoal) {
        self.id = goal.id
        self.targetWeightKg = goal.targetWeightKg
        self.startWeightKg = goal.startWeightKg
        self.startDate = goal.startDate
        self.targetDate = goal.targetDate
        self.isActive = goal.isActive
        self.note = goal.note
        self.createdAt = goal.createdAt
        self.modifiedAt = Date()
    }

    // MARK: - Convert to Swift Struct

    /// Convert to WeightGoal struct
    func toWeightGoal() -> WeightGoal? {
        guard let id = self.id,
              let startDate = self.startDate,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return WeightGoal(
            id: id,
            targetWeightKg: self.targetWeightKg,
            startWeightKg: self.startWeightKg,
            startDate: startDate,
            targetDate: self.targetDate,
            isActive: self.isActive,
            note: self.note,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDWeightGoal {

    /// Fetch all goals sorted by start date (newest first)
    static func fetchAllGoals(in context: NSManagedObjectContext) -> [CDWeightGoal] {
        let request = NSFetchRequest<CDWeightGoal>(entityName: "CDWeightGoal")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWeightGoal.startDate, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch goals for a specific profile, sorted by start date (newest first)
    static func fetchGoals(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDWeightGoal] {
        let request = NSFetchRequest<CDWeightGoal>(entityName: "CDWeightGoal")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWeightGoal.startDate, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch the active goal for a profile
    static func fetchActiveGoal(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDWeightGoal? {
        let request = NSFetchRequest<CDWeightGoal>(entityName: "CDWeightGoal")
        request.predicate = NSPredicate(format: "profile == %@ AND isActive == YES", profile)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Fetch by ID (convenience method with correct return type)
    static func fetchGoal(byId id: UUID, in context: NSManagedObjectContext) -> CDWeightGoal? {
        let request = NSFetchRequest<CDWeightGoal>(entityName: "CDWeightGoal")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Count all goals for a profile
    static func countGoals(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDWeightGoal>(entityName: "CDWeightGoal")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return context.performAndWait {
            (try? context.count(for: request)) ?? 0
        }
    }

    /// Fetch all goals without a profile (for migration)
    static func fetchOrphanedGoals(in context: NSManagedObjectContext) -> [CDWeightGoal] {
        let request = NSFetchRequest<CDWeightGoal>(entityName: "CDWeightGoal")
        request.predicate = NSPredicate(format: "profile == nil")
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }
}
