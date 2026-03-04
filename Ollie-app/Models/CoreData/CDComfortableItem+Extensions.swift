//
//  CDComfortableItem+Extensions.swift
//  Otis-app
//
//  Extensions for converting between ComfortableItem and CDComfortableItem
//

import CoreData
import OtisShared

extension CDComfortableItem {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from ComfortableItem struct
    func update(from item: ComfortableItem) {
        self.id = item.id
        self.itemId = item.itemId
        self.comfortableAt = item.comfortableAt
        self.method = item.method.rawValue
        self.modifiedAt = item.modifiedAt
    }

    /// Create a new CDComfortableItem from a ComfortableItem struct
    static func create(from item: ComfortableItem, in context: NSManagedObjectContext) -> CDComfortableItem {
        let cdItem = CDComfortableItem(context: context)
        cdItem.update(from: item)
        return cdItem
    }

    // MARK: - Convert to Swift Struct

    /// Convert to ComfortableItem struct
    func toComfortableItem() -> ComfortableItem? {
        guard let id = self.id,
              let itemId = self.itemId,
              let comfortableAt = self.comfortableAt,
              let methodString = self.method,
              let method = ComfortableItem.ComfortMethod(rawValue: methodString),
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return ComfortableItem(
            id: id,
            itemId: itemId,
            comfortableAt: comfortableAt,
            method: method,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDComfortableItem {

    /// Fetch all comfortable items
    static func fetchAll(in context: NSManagedObjectContext) -> [CDComfortableItem] {
        let request = NSFetchRequest<CDComfortableItem>(entityName: "CDComfortableItem")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDComfortableItem.comfortableAt, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Fetch by item ID
    static func fetch(byItemId itemId: String, in context: NSManagedObjectContext) -> CDComfortableItem? {
        let request = NSFetchRequest<CDComfortableItem>(entityName: "CDComfortableItem")
        request.predicate = NSPredicate(format: "itemId == %@", itemId)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Check if an item is marked comfortable
    static func isComfortable(_ itemId: String, in context: NSManagedObjectContext) -> Bool {
        let request = NSFetchRequest<CDComfortableItem>(entityName: "CDComfortableItem")
        request.predicate = NSPredicate(format: "itemId == %@", itemId)
        request.fetchLimit = 1

        return ((try? context.count(for: request)) ?? 0) > 0
    }

    /// Delete comfortable item by itemId
    static func delete(byItemId itemId: String, in context: NSManagedObjectContext) {
        if let existing = fetch(byItemId: itemId, in: context) {
            context.delete(existing)
        }
    }
}
