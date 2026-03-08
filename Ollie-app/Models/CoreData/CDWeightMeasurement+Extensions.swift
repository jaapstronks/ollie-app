//
//  CDWeightMeasurement+Extensions.swift
//  Otis-app
//
//  Extensions for converting between WeightMeasurement and CDWeightMeasurement
//

@preconcurrency import CoreData
import OtisShared

// MARK: - StorableModel Conformance

extension WeightMeasurement: StorableModel {}

// MARK: - CDEntityConvertible Conformance

extension CDWeightMeasurement: CDEntityConvertible {
    typealias Model = WeightMeasurement

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllMeasurements(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    @discardableResult
    static func create(from measurement: WeightMeasurement, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdMeasurement = CDWeightMeasurement(context: context)
        cdMeasurement.update(from: measurement)
        return cdMeasurement
    }

    @discardableResult
    static func create(from measurement: WeightMeasurement, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDWeightMeasurement {
        let cdMeasurement = CDWeightMeasurement(context: context)
        cdMeasurement.update(from: measurement)
        cdMeasurement.profile = profile
        return cdMeasurement
    }

    func toModel() -> WeightMeasurement? {
        toWeightMeasurement()
    }
}

// MARK: - Core Data Operations

extension CDWeightMeasurement {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from WeightMeasurement struct
    func update(from measurement: WeightMeasurement) {
        self.id = measurement.id
        self.date = measurement.date
        self.weightKg = measurement.weightKg
        self.note = measurement.note
        self.createdAt = measurement.createdAt
        self.modifiedAt = Date()
    }

    // MARK: - Convert to Swift Struct

    /// Convert to WeightMeasurement struct
    func toWeightMeasurement() -> WeightMeasurement? {
        guard let id = self.id,
              let date = self.date,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return WeightMeasurement(
            id: id,
            date: date,
            weightKg: self.weightKg,
            note: self.note,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDWeightMeasurement {

    /// Fetch all measurements sorted by date (newest first)
    static func fetchAllMeasurements(in context: NSManagedObjectContext) -> [CDWeightMeasurement] {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWeightMeasurement.date, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch measurements for a specific profile, sorted by date (newest first)
    static func fetchMeasurements(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDWeightMeasurement] {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWeightMeasurement.date, ascending: false)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch measurements for a specific profile, sorted by date (oldest first - for chart display)
    static func fetchMeasurementsChronological(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDWeightMeasurement] {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWeightMeasurement.date, ascending: true)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch by ID (convenience method with correct return type)
    static func fetchMeasurement(byId id: UUID, in context: NSManagedObjectContext) -> CDWeightMeasurement? {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Count all measurements for a profile
    static func countMeasurements(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return context.performAndWait {
            (try? context.count(for: request)) ?? 0
        }
    }

    /// Fetch the latest measurement for a profile
    static func fetchLatest(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDWeightMeasurement? {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWeightMeasurement.date, ascending: false)]
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Fetch all measurements without a profile (for migration)
    static func fetchOrphanedMeasurements(in context: NSManagedObjectContext) -> [CDWeightMeasurement] {
        let request = NSFetchRequest<CDWeightMeasurement>(entityName: "CDWeightMeasurement")
        request.predicate = NSPredicate(format: "profile == nil")
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }
}
