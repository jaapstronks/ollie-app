//
//  CRUDStore.swift
//  Otis-app
//
//  Generic CRUD store base class to reduce boilerplate across stores.
//  Provides standard add/update/delete operations with Core Data.

import Foundation
import CoreData
import Combine
import OtisShared
import os

// MARK: - Storable Model Protocol

/// Protocol for domain models that can be stored in a CRUD store
protocol StorableModel: Identifiable where ID == UUID {
    /// Human-readable name for logging
    var displayName: String { get }
}

// MARK: - CD Entity Convertible Protocol

/// Protocol for Core Data entities that can convert to/from domain models
/// Note: Uses concrete return types instead of Self to work with non-final NSManagedObject subclasses
protocol CDEntityConvertible: NSManagedObject {
    associatedtype Model: StorableModel

    /// Create a new Core Data entity from a model
    @discardableResult
    static func create(from model: Model, in context: NSManagedObjectContext) -> NSManagedObject

    /// Fetch an entity by its ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> NSManagedObject?

    /// Fetch all entities
    static func fetchAll(in context: NSManagedObjectContext) -> [NSManagedObject]

    /// Update this entity from a model
    func update(from model: Model)

    /// Convert to domain model
    func toModel() -> Model?
}

// MARK: - Sort Order

/// Sort order configuration for CRUD stores
struct StoreSortOrder<Model> {
    private let sorter: ([Model]) -> [Model]

    /// No sorting (maintain insertion order)
    static var none: StoreSortOrder<Model> {
        StoreSortOrder { $0 }
    }

    /// Sort by a comparable key path ascending
    static func ascending<V: Comparable>(_ keyPath: KeyPath<Model, V>) -> StoreSortOrder<Model> {
        StoreSortOrder { $0.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] } }
    }

    /// Sort by a comparable key path descending
    static func descending<V: Comparable>(_ keyPath: KeyPath<Model, V>) -> StoreSortOrder<Model> {
        StoreSortOrder { $0.sorted { $0[keyPath: keyPath] > $1[keyPath: keyPath] } }
    }

    /// Custom sort using a comparison closure
    static func custom(_ comparator: @escaping (Model, Model) -> Bool) -> StoreSortOrder<Model> {
        StoreSortOrder { $0.sorted(by: comparator) }
    }

    /// Apply sorting to an array
    func sort(_ items: [Model]) -> [Model] {
        sorter(items)
    }
}

// MARK: - CRUD Store

/// Generic base class for CRUD stores with Core Data persistence.
/// Subclasses should override `performInitialLoad()` and `sortOrder`.
/// CloudKit sync is automatically enabled - record type is derived from Entity name.
@MainActor
class CRUDStore<Model: StorableModel, Entity: CDEntityConvertible>: BaseStore where Entity.Model == Model {

    // MARK: - State

    private(set) var items: [Model] = []

    /// Store identifier for notifications (uses class name)
    @ObservationIgnored
    private lazy var storeIdentifier: String = String(describing: type(of: self))

    // MARK: - CloudKit Sync

    /// Returns the CloudKit record type for sync
    /// Uses CD_ prefix to match NSPersistentCloudKitContainer legacy format
    override var cloudKitRecordType: String? {
        "CD_\(String(describing: Entity.self))"  // Returns "CD_CDDogContact", etc.
    }

    /// Protected method for subclasses to update items
    /// Use this when you need custom loading logic (e.g., profile-scoped fetching)
    func setItems(_ newItems: [Model]) {
        items = sortOrder.sort(newItems)
        notifyItemsDidChange()
    }

    /// Post notification when items change
    /// Used by ViewModels since @Observable doesn't support Combine publishers
    func notifyItemsDidChange() {
        NotificationCenter.default.post(
            name: .crudStoreItemsDidChange,
            object: self,
            userInfo: ["storeIdentifier": storeIdentifier]
        )
    }

    // MARK: - Sort Order

    /// Override to customize sort order. Default is no sorting.
    var sortOrder: StoreSortOrder<Model> { .none }

    // MARK: - Computed Properties

    /// Number of items in the store
    var itemCount: Int { items.count }

    /// Whether the store is empty
    var isEmpty: Bool { items.isEmpty }

    // MARK: - CRUD Operations

    /// Add a new item
    /// - Returns: `true` if the item was saved successfully
    @discardableResult
    func add(_ item: Model) -> Bool {
        _ = Entity.create(from: item, in: viewContext)

        return performSave(operation: "Added \(item.displayName)", entityId: item.id) {
            items.append(item)
            items = sortOrder.sort(items)
        }
    }

    /// Update an existing item
    /// - Returns: `true` if the item was updated successfully
    @discardableResult
    func update(_ item: Model) -> Bool {
        guard let cdEntity = Entity.fetch(byId: item.id, in: viewContext) as? Entity else {
            logger.warning("Item not found for update: \(item.id)")
            setNotFoundError()
            return false
        }

        cdEntity.update(from: item)

        return performSave(operation: "Updated \(item.displayName)", entityId: item.id) {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            }
            items = sortOrder.sort(items)
        }
    }

    /// Delete an item
    /// - Returns: `true` if the item was deleted successfully
    @discardableResult
    func delete(_ item: Model) -> Bool {
        guard let cdEntity = Entity.fetch(byId: item.id, in: viewContext) as? Entity else {
            logger.warning("Item not found for deletion: \(item.id)")
            setNotFoundError()
            return false
        }

        viewContext.delete(cdEntity)

        return performDelete(operation: "Deleted \(item.displayName)", entityId: item.id) {
            items.removeAll { $0.id == item.id }
        }
    }

    /// Delete multiple items
    /// - Returns: `true` if all items were deleted successfully
    @discardableResult
    func deleteAll(_ itemsToDelete: [Model]) -> Bool {
        var allDeleted = true
        for item in itemsToDelete {
            if !delete(item) {
                allDeleted = false
            }
        }
        return allDeleted
    }

    // MARK: - Query Operations

    /// Find an item by ID
    func item(withId id: UUID) -> Model? {
        items.first { $0.id == id }
    }

    /// Check if an item exists
    func contains(id: UUID) -> Bool {
        items.contains { $0.id == id }
    }

    /// Filter items by a predicate
    func filter(_ predicate: (Model) -> Bool) -> [Model] {
        items.filter(predicate)
    }

    // MARK: - Data Loading

    /// Load all items from Core Data
    /// Subclasses can override for custom loading logic
    func loadItems() {
        let cdEntities = Entity.fetchAll(in: viewContext).compactMap { $0 as? Entity }
        items = cdEntities.compactMap { $0.toModel() }
        items = sortOrder.sort(items)
        logger.info("Loaded \(self.items.count) items")
        notifyItemsDidChange()
    }

    /// Default implementation reloads all items
    override func performInitialLoad() {
        loadItems()
    }
}

// MARK: - Profile-Scoped CRUD Store

/// Base class for CRUD stores that are scoped to a profile.
/// Items are filtered by the current profile.
@MainActor
class ProfileScopedCRUDStore<Model: StorableModel, Entity: CDEntityConvertible>: CRUDStore<Model, Entity>, ProfileAccessible where Entity.Model == Model {

    // MARK: - ProfileAccessible

    weak var profileStore: ProfileStore?

    // MARK: - Init

    init(
        persistenceController: PersistenceController = .shared,
        profileStore: ProfileStore? = nil,
        logCategory: String
    ) {
        self.profileStore = profileStore
        super.init(persistenceController: persistenceController, logCategory: logCategory)
    }

    /// Set the profile store (for when it's not available at init time)
    func setProfileStore(_ profileStore: ProfileStore) {
        configureProfileStore(profileStore)
    }
}

// MARK: - StorableModel Conformances

extension DogContact: StorableModel {
    var displayName: String { name }
}

extension WalkSpot: StorableModel {
    public var displayName: String { name }
}

extension Milestone: StorableModel {
    public var displayName: String { localizedLabel }
}

extension DogAppointment: StorableModel {
    public var displayName: String { title }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when a CRUDStore's items change
    /// UserInfo contains "storeIdentifier" key with the store class name
    static let crudStoreItemsDidChange = Notification.Name("crudStoreItemsDidChange")
}
