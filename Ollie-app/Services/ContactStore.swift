//
//  ContactStore.swift
//  Otis-app
//
//  Manages dog contacts with Core Data and automatic CloudKit sync

import Foundation
import CoreData
import OtisShared

/// Manages dog contacts with Core Data and automatic CloudKit sync
@MainActor
final class ContactStore: CRUDStore<DogContact, CDDogContact> {

    // MARK: - Sort Order

    override var sortOrder: StoreSortOrder<DogContact> {
        .descending(\.createdAt)
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "ContactStore")
    }

    // MARK: - Backward-Compatible Aliases

    /// Alias for items (backward compatibility)
    var contacts: [DogContact] { items }

    /// Count of all contacts
    var contactCount: Int { itemCount }

    /// Contacts grouped by type
    var contactsByType: [ContactType: [DogContact]] {
        Dictionary(grouping: items, by: { $0.contactType })
    }

    // MARK: - Backward-Compatible CRUD

    /// Add a new contact (backward-compatible alias)
    @discardableResult
    func addContact(_ contact: DogContact) -> Bool {
        add(contact)
    }

    /// Update an existing contact (backward-compatible alias)
    @discardableResult
    func updateContact(_ contact: DogContact) -> Bool {
        update(contact)
    }

    /// Delete a contact (backward-compatible alias)
    @discardableResult
    func deleteContact(_ contact: DogContact) -> Bool {
        delete(contact)
    }

    // MARK: - Filtering & Queries

    /// Get contacts by type
    func contacts(ofType type: ContactType) -> [DogContact] {
        filter { $0.contactType == type }
    }

    /// Get contact by ID (backward-compatible alias)
    func contact(withId id: UUID) -> DogContact? {
        item(withId: id)
    }
}
