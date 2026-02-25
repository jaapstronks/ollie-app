//
//  CDExposure+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between Exposure and CDExposure
//

import CoreData
import OllieShared

extension CDExposure {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from Exposure struct
    func update(from exposure: Exposure) {
        self.id = exposure.id
        self.itemId = exposure.itemId
        self.date = exposure.date
        self.distance = exposure.distance.rawValue
        self.reaction = exposure.reaction.rawValue
        self.note = exposure.note
        self.createdAt = exposure.createdAt
        self.modifiedAt = exposure.modifiedAt
    }

    /// Create a new CDExposure from an Exposure struct
    static func create(from exposure: Exposure, in context: NSManagedObjectContext) -> CDExposure {
        let cdExposure = CDExposure(context: context)
        cdExposure.update(from: exposure)
        return cdExposure
    }

    // MARK: - Convert to Swift Struct

    /// Convert to Exposure struct
    func toExposure() -> Exposure? {
        guard let id = self.id,
              let itemId = self.itemId,
              let date = self.date,
              let distanceString = self.distance,
              let distance = ExposureDistance(rawValue: distanceString),
              let reactionString = self.reaction,
              let reaction = SocializationReaction(rawValue: reactionString),
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return Exposure(
            id: id,
            itemId: itemId,
            date: date,
            distance: distance,
            reaction: reaction,
            note: self.note,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDExposure {

    /// Fetch all exposures
    static func fetchAllExposures(in context: NSManagedObjectContext) -> [CDExposure] {
        let request = NSFetchRequest<CDExposure>(entityName: "CDExposure")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExposure.date, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch exposures for a specific item
    static func fetchExposures(forItem itemId: String, in context: NSManagedObjectContext) -> [CDExposure] {
        let request = NSFetchRequest<CDExposure>(entityName: "CDExposure")
        request.predicate = NSPredicate(format: "itemId == %@", itemId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExposure.date, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch exposures for a specific date
    static func fetchExposures(for date: Date, in context: NSManagedObjectContext) -> [CDExposure] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let request = NSFetchRequest<CDExposure>(entityName: "CDExposure")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExposure.date, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch exposure by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDExposure? {
        let request = NSFetchRequest<CDExposure>(entityName: "CDExposure")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Count exposures for a specific item
    static func countExposures(forItem itemId: String, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDExposure>(entityName: "CDExposure")
        request.predicate = NSPredicate(format: "itemId == %@", itemId)

        return (try? context.count(for: request)) ?? 0
    }

    /// Fetch recent exposures (last N)
    static func fetchRecentExposures(limit: Int, in context: NSManagedObjectContext) -> [CDExposure] {
        let request = NSFetchRequest<CDExposure>(entityName: "CDExposure")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExposure.date, ascending: false)]
        request.fetchLimit = limit

        return (try? context.fetch(request)) ?? []
    }
}
