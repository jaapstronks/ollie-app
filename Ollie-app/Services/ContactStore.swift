//
//  ContactStore.swift
//  Ollie-app
//
//  Manages dog contacts with Core Data and automatic CloudKit sync

import Foundation
import CoreData
import OllieShared
import Combine
import os

/// Manages dog contacts with Core Data and automatic CloudKit sync
@MainActor
class ContactStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var contacts: [DogContact] = []
    @Published private(set) var isSyncing = false
    /// Last error that occurred during a store operation (for UI display)
    @Published private(set) var lastError: (message: String, date: Date)? = nil

    /// Clear the last error (call when user dismisses error banner)
    func clearError() {
        lastError = nil
    }

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "ContactStore")
    private var cancellables = Set<AnyCancellable>()

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Computed Properties

    /// Count of all contacts
    var contactCount: Int {
        contacts.count
    }

    /// Contacts grouped by type
    var contactsByType: [ContactType: [DogContact]] {
        Dictionary(grouping: contacts, by: { $0.contactType })
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadContacts()
        setupRemoteChangeObserver()
    }

    // MARK: - Setup

    private func setupRemoteChangeObserver() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change for contacts")
        loadContacts()
    }

    // MARK: - Contact Loading

    private func loadContacts() {
        let cdContacts = CDDogContact.fetchAllContacts(in: viewContext)
        contacts = cdContacts.compactMap { $0.toContact() }
        logger.info("Loaded \(self.contacts.count) contacts from Core Data")
    }

    // MARK: - CRUD Operations

    /// Add a new contact
    /// - Returns: `true` if the contact was saved successfully, `false` otherwise
    @discardableResult
    func addContact(_ contact: DogContact) -> Bool {
        _ = CDDogContact.create(from: contact, in: viewContext)

        do {
            try persistenceController.save()
            // Only update in-memory state after confirming persistence succeeded
            contacts.append(contact)
            contacts.sort { $0.createdAt > $1.createdAt }
            lastError = nil
            logger.info("Added contact: \(contact.name)")
            return true
        } catch {
            // Rollback the unsaved Core Data change
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to add contact: \(error.localizedDescription)")
            return false
        }
    }

    /// Update an existing contact
    /// - Returns: `true` if the contact was updated successfully, `false` otherwise
    @discardableResult
    func updateContact(_ contact: DogContact) -> Bool {
        guard let cdContact = CDDogContact.fetch(byId: contact.id, in: viewContext) else {
            logger.warning("Contact not found for update: \(contact.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        cdContact.update(from: contact)

        do {
            try persistenceController.save()
            // Only update in-memory state after confirming persistence succeeded
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = contact
            }
            lastError = nil
            logger.info("Updated contact: \(contact.name)")
            return true
        } catch {
            // Rollback the unsaved Core Data change
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to update contact: \(error.localizedDescription)")
            return false
        }
    }

    /// Delete a contact
    /// - Returns: `true` if the contact was deleted successfully, `false` otherwise
    @discardableResult
    func deleteContact(_ contact: DogContact) -> Bool {
        guard let cdContact = CDDogContact.fetch(byId: contact.id, in: viewContext) else {
            logger.warning("Contact not found for deletion: \(contact.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        viewContext.delete(cdContact)

        do {
            try persistenceController.save()
            // Only update in-memory state after confirming persistence succeeded
            contacts.removeAll { $0.id == contact.id }
            lastError = nil
            logger.info("Deleted contact: \(contact.name)")
            return true
        } catch {
            // Rollback the unsaved Core Data change
            viewContext.rollback()
            lastError = (Strings.Common.deleteFailed, Date())
            logger.error("Failed to delete contact: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Filtering & Queries

    /// Get contacts by type
    func contacts(ofType type: ContactType) -> [DogContact] {
        contacts.filter { $0.contactType == type }
    }

    /// Get contact by ID
    func contact(withId id: UUID) -> DogContact? {
        contacts.first { $0.id == id }
    }

    // MARK: - CloudKit Sync

    /// Sync contacts from CloudKit (no-op with automatic sync)
    func syncFromCloud() async {
        viewContext.refreshAllObjects()
        loadContacts()
    }
}
