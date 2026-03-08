//
//  CDRoutineItem+Extensions.swift
//  Otis-app
//
//  Extensions for converting between RoutineItem and CDRoutineItem
//

@preconcurrency import CoreData
import OtisShared

// MARK: - StorableModel Conformance

extension RoutineItem: StorableModel {}

// MARK: - CDEntityConvertible Conformance

extension CDRoutineItem: CDEntityConvertible {
    typealias Model = RoutineItem

    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject] {
        fetchAllItems(in: context)
    }

    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject? {
        let request = NSFetchRequest<CDRoutineItem>(entityName: "CDRoutineItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    @discardableResult
    static func create(from item: RoutineItem, in context: NSManagedObjectContext) -> NSManagedObject {
        let cdItem = CDRoutineItem(context: context)
        cdItem.update(from: item)
        return cdItem
    }

    @discardableResult
    static func create(from item: RoutineItem, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDRoutineItem {
        let cdItem = CDRoutineItem(context: context)
        cdItem.update(from: item)
        cdItem.profile = profile
        return cdItem
    }

    func toModel() -> RoutineItem? {
        toRoutineItem()
    }
}

// MARK: - Core Data Operations

extension CDRoutineItem {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from RoutineItem struct
    func update(from item: RoutineItem) {
        self.id = item.id
        self.label = item.label
        self.time = item.time
        self.category = item.category.rawValue
        self.isEnabled = item.isEnabled
        self.linkedEventType = item.linkedEventType
        self.sortOrder = Int32(item.sortOrder)
        self.createdAt = item.createdAt
        self.modifiedAt = Date()
    }

    // MARK: - Convert to Swift Struct

    /// Convert to RoutineItem struct
    func toRoutineItem() -> RoutineItem? {
        guard let id = self.id,
              let label = self.label,
              let categoryString = self.category,
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        let category = RoutineCategory(rawValue: categoryString) ?? .morning

        return RoutineItem(
            id: id,
            label: label,
            time: self.time,
            category: category,
            isEnabled: self.isEnabled,
            linkedEventType: self.linkedEventType,
            sortOrder: Int(self.sortOrder),
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDRoutineItem {

    /// Fetch all items sorted by sortOrder
    static func fetchAllItems(in context: NSManagedObjectContext) -> [CDRoutineItem] {
        let request = NSFetchRequest<CDRoutineItem>(entityName: "CDRoutineItem")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDRoutineItem.sortOrder, ascending: true)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch items for a specific profile, sorted by sortOrder
    static func fetchItems(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDRoutineItem] {
        let request = NSFetchRequest<CDRoutineItem>(entityName: "CDRoutineItem")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDRoutineItem.sortOrder, ascending: true)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Fetch by ID (convenience method with correct return type)
    static func fetchItem(byId id: UUID, in context: NSManagedObjectContext) -> CDRoutineItem? {
        let request = NSFetchRequest<CDRoutineItem>(entityName: "CDRoutineItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return context.performAndWait {
            try? context.fetch(request).first
        }
    }

    /// Fetch items by category
    static func fetchItems(for profile: CDPuppyProfile, category: RoutineCategory, in context: NSManagedObjectContext) -> [CDRoutineItem] {
        let request = NSFetchRequest<CDRoutineItem>(entityName: "CDRoutineItem")
        request.predicate = NSPredicate(format: "profile == %@ AND category == %@", profile, category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDRoutineItem.sortOrder, ascending: true)]
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }

    /// Count all items for a profile
    static func countItems(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDRoutineItem>(entityName: "CDRoutineItem")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return context.performAndWait {
            (try? context.count(for: request)) ?? 0
        }
    }

    /// Fetch all items without a profile (for migration)
    static func fetchOrphanedItems(in context: NSManagedObjectContext) -> [CDRoutineItem] {
        let request = NSFetchRequest<CDRoutineItem>(entityName: "CDRoutineItem")
        request.predicate = NSPredicate(format: "profile == nil")
        return context.performAndWait {
            (try? context.fetch(request)) ?? []
        }
    }
}
