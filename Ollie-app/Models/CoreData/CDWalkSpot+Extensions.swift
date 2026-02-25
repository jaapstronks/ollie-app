//
//  CDWalkSpot+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between WalkSpot and CDWalkSpot
//

import CoreData
import OllieShared

extension CDWalkSpot {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from WalkSpot struct
    func update(from spot: WalkSpot) {
        self.id = spot.id
        self.name = spot.name
        self.latitude = spot.latitude
        self.longitude = spot.longitude
        self.createdAt = spot.createdAt
        self.modifiedAt = spot.modifiedAt
        self.isFavorite = spot.isFavorite
        self.notes = spot.notes
        self.visitCount = Int32(spot.visitCount)
    }

    /// Create a new CDWalkSpot from a WalkSpot struct
    static func create(from spot: WalkSpot, in context: NSManagedObjectContext) -> CDWalkSpot {
        let cdSpot = CDWalkSpot(context: context)
        cdSpot.update(from: spot)
        return cdSpot
    }

    // MARK: - Convert to Swift Struct

    /// Convert to WalkSpot struct
    func toWalkSpot() -> WalkSpot? {
        guard let id = self.id,
              let name = self.name,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return WalkSpot(
            id: id,
            name: name,
            latitude: self.latitude,
            longitude: self.longitude,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            isFavorite: self.isFavorite,
            notes: self.notes,
            visitCount: Int(self.visitCount)
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDWalkSpot {

    /// Fetch all walk spots
    static func fetchAllSpots(in context: NSManagedObjectContext) -> [CDWalkSpot] {
        let request = NSFetchRequest<CDWalkSpot>(entityName: "CDWalkSpot")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDWalkSpot.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \CDWalkSpot.visitCount, ascending: false)
        ]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch spot by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDWalkSpot? {
        let request = NSFetchRequest<CDWalkSpot>(entityName: "CDWalkSpot")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Fetch favorite spots
    static func fetchFavoriteSpots(in context: NSManagedObjectContext) -> [CDWalkSpot] {
        let request = NSFetchRequest<CDWalkSpot>(entityName: "CDWalkSpot")
        request.predicate = NSPredicate(format: "isFavorite == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWalkSpot.visitCount, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }
}
