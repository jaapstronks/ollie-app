//
//  CDExploredTile+Extensions.swift
//  Otis-app
//
//  Extensions for converting between ExploredTile and CDExploredTile
//

@preconcurrency import CoreData
import OtisShared

// MARK: - CDEntityConvertible Conformance

extension CDExploredTile: CDEntityConvertible {
    typealias Model = ExploredTile

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllTiles(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDExploredTile>(entityName: "CDExploredTile")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        nonisolated(unsafe) var result: CDExploredTile?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    @discardableResult
    static func create(from tile: ExploredTile, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdTile = CDExploredTile(context: context)
        cdTile.update(from: tile)
        return cdTile
    }

    func toModel() -> ExploredTile? {
        toExploredTile()
    }
}

// MARK: - Core Data Operations

extension CDExploredTile {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from ExploredTile struct
    func update(from tile: ExploredTile) {
        self.id = tile.id
        self.tileKey = tile.tileKey
        self.walkCount = Int32(tile.walkCount)
        self.firstExploredAt = tile.firstExploredAt
        self.lastExploredAt = tile.lastExploredAt
        self.createdAt = tile.createdAt
        self.modifiedAt = tile.modifiedAt
    }

    // MARK: - Convert to Swift Struct

    /// Convert to ExploredTile struct
    func toExploredTile() -> ExploredTile? {
        guard let id = self.id,
              let tileKey = self.tileKey,
              let firstExploredAt = self.firstExploredAt,
              let lastExploredAt = self.lastExploredAt,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return ExploredTile(
            id: id,
            tileKey: tileKey,
            walkCount: Int(self.walkCount),
            firstExploredAt: firstExploredAt,
            lastExploredAt: lastExploredAt,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDExploredTile {

    /// Fetch all explored tiles
    static func fetchAllTiles(in context: NSManagedObjectContext) -> [CDExploredTile] {
        let request = NSFetchRequest<CDExploredTile>(entityName: "CDExploredTile")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDExploredTile.lastExploredAt, ascending: false)
        ]

        nonisolated(unsafe) var results: [CDExploredTile] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch all explored tiles for a specific profile
    static func fetchAllTiles(forProfile profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDExploredTile] {
        let request = NSFetchRequest<CDExploredTile>(entityName: "CDExploredTile")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDExploredTile.lastExploredAt, ascending: false)
        ]

        nonisolated(unsafe) var results: [CDExploredTile] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch a tile by its key for a specific profile
    static func fetchTile(byKey tileKey: String, forProfile profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDExploredTile? {
        let request = NSFetchRequest<CDExploredTile>(entityName: "CDExploredTile")
        request.predicate = NSPredicate(format: "tileKey == %@ AND profile == %@", tileKey, profile)
        request.fetchLimit = 1

        nonisolated(unsafe) var result: CDExploredTile?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Fetch all tile keys for a specific profile (fast query for Set building)
    static func fetchAllTileKeys(forProfile profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Set<String> {
        let request = NSFetchRequest<NSDictionary>(entityName: "CDExploredTile")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["tileKey"]

        nonisolated(unsafe) var results: [NSDictionary] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }

        return Set(results.compactMap { $0["tileKey"] as? String })
    }
}
