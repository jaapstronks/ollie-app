//
//  DocumentStore.swift
//  Ollie-app
//
//  Manages documents with Core Data and automatic CloudKit sync
//  Documents are stored per-profile and images sync automatically via CloudKit

import Foundation
import CoreData
import OllieShared
import Combine
import UIKit
import os

/// Manages documents with Core Data and automatic CloudKit sync
@MainActor
class DocumentStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var documents: [Document] = []
    @Published private(set) var isSyncing = false

    /// Last error that occurred during a store operation (for UI display)
    @Published private(set) var lastError: (message: String, date: Date)?

    /// Clear the last error (call when user dismisses error banner)
    func clearError() {
        lastError = nil
    }

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private weak var profileStore: ProfileStore?
    private let logger = Logger.ollie(category: "DocumentStore")
    private var cancellables = Set<AnyCancellable>()

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Computed Properties

    /// Count of all documents for current profile
    var documentCount: Int {
        documents.count
    }

    /// Documents grouped by type
    var documentsByType: [DocumentType: [Document]] {
        Dictionary(grouping: documents, by: { $0.type })
    }

    /// Expired documents
    var expiredDocuments: [Document] {
        documents.filter { $0.isExpired }
    }

    /// Documents expiring soon (within 30 days)
    var expiringDocuments: [Document] {
        documents.filter { $0.expiresSoon }
    }

    // MARK: - Init

    init(
        persistenceController: PersistenceController = .shared,
        profileStore: ProfileStore? = nil
    ) {
        self.persistenceController = persistenceController
        self.profileStore = profileStore
        setupObservers()
        loadDocuments()
    }

    /// Set the profile store (for when it's not available at init time)
    func setProfileStore(_ profileStore: ProfileStore) {
        self.profileStore = profileStore
        loadDocuments()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe CloudKit remote changes
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change for documents")
        loadDocuments()
    }

    // MARK: - Profile Access

    /// Get the current CDPuppyProfile from Core Data
    private func getCurrentProfile() -> CDPuppyProfile? {
        guard let profileId = profileStore?.profile?.id else {
            logger.warning("No profile available for document operations")
            return nil
        }
        return CDPuppyProfile.fetch(byId: profileId, in: viewContext)
    }

    // MARK: - Document Loading

    func loadDocuments() {
        guard let profile = getCurrentProfile() else {
            documents = []
            return
        }

        let cdDocuments = CDDocument.fetchDocuments(for: profile, in: viewContext)
        documents = cdDocuments.compactMap { $0.toDocument() }
        logger.info("Loaded \(self.documents.count) documents for profile")
    }

    // MARK: - CRUD Operations

    /// Add a new document with optional image
    /// - Parameters:
    ///   - document: The document metadata
    ///   - image: Optional image to attach
    /// - Returns: `true` if the document was saved successfully
    @discardableResult
    func addDocument(_ document: Document, image: UIImage? = nil) -> Bool {
        guard let profile = getCurrentProfile() else {
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        let cdDocument = CDDocument.create(from: document, profile: profile, in: viewContext)

        // Set image if provided
        if let image = image {
            cdDocument.setImage(image)
        }

        do {
            try persistenceController.save()
            // Reload to get the updated document with hasImage flag
            loadDocuments()
            lastError = nil
            logger.info("Added document: \(document.displayTitle)")
            return true
        } catch {
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to add document: \(error.localizedDescription)")
            return false
        }
    }

    /// Update an existing document
    /// - Parameters:
    ///   - document: The updated document metadata
    ///   - image: New image (nil to keep existing, pass explicit UIImage to replace)
    ///   - removeImage: Set to true to remove the existing image
    /// - Returns: `true` if the document was updated successfully
    @discardableResult
    func updateDocument(_ document: Document, image: UIImage? = nil, removeImage: Bool = false) -> Bool {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            logger.warning("Document not found for update: \(document.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        cdDocument.update(from: document)

        // Handle image updates
        if removeImage {
            cdDocument.setImage(nil)
        } else if let image = image {
            cdDocument.setImage(image)
        }
        // If neither removeImage nor new image, keep existing

        do {
            try persistenceController.save()
            loadDocuments()
            lastError = nil
            logger.info("Updated document: \(document.displayTitle)")
            return true
        } catch {
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to update document: \(error.localizedDescription)")
            return false
        }
    }

    /// Delete a document (images are deleted automatically via Core Data)
    /// - Returns: `true` if the document was deleted successfully
    @discardableResult
    func deleteDocument(_ document: Document) -> Bool {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            logger.warning("Document not found for deletion: \(document.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        viewContext.delete(cdDocument)

        do {
            try persistenceController.save()
            documents.removeAll { $0.id == document.id }
            lastError = nil
            logger.info("Deleted document: \(document.displayTitle)")
            return true
        } catch {
            viewContext.rollback()
            lastError = (Strings.Common.deleteFailed, Date())
            logger.error("Failed to delete document: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Image Access

    /// Load the full-size image for a document
    func loadImage(for document: Document) -> UIImage? {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            return nil
        }
        return cdDocument.getImage()
    }

    /// Load the thumbnail image for a document
    func loadThumbnail(for document: Document) -> UIImage? {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            return nil
        }
        return cdDocument.getThumbnail()
    }

    /// Load thumbnail by document ID (useful for async loading)
    func loadThumbnail(forDocumentId id: UUID) -> UIImage? {
        guard let cdDocument = CDDocument.fetch(byId: id, in: viewContext) else {
            return nil
        }
        return cdDocument.getThumbnail()
    }

    /// Load full image by document ID
    func loadImage(forDocumentId id: UUID) -> UIImage? {
        guard let cdDocument = CDDocument.fetch(byId: id, in: viewContext) else {
            return nil
        }
        return cdDocument.getImage()
    }

    // MARK: - Filtering & Queries

    /// Get documents by type
    func documents(ofType type: DocumentType) -> [Document] {
        documents.filter { $0.type == type }
    }

    /// Get document by ID
    func document(withId id: UUID) -> Document? {
        documents.first { $0.id == id }
    }

    /// Get documents expiring within a number of days
    func expiringDocuments(withinDays days: Int) -> [Document] {
        let now = Date()
        guard let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now) else {
            return []
        }

        return documents.filter { document in
            guard let expiry = document.expiryDate else { return false }
            return expiry > now && expiry <= futureDate
        }.sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
    }

    // MARK: - CloudKit Sync

    /// Force refresh documents from Core Data (useful after CloudKit sync)
    func syncFromCloud() async {
        viewContext.refreshAllObjects()
        loadDocuments()
    }

    // MARK: - Migration Support

    /// Migrate orphaned documents to the current profile
    /// Call this once after updating the Core Data model to add profile relationships
    func migrateOrphanedDocuments() {
        guard let profile = getCurrentProfile() else { return }

        let orphanedDocuments = CDDocument.fetchAllDocumentsForMigration(in: viewContext)
            .filter { $0.profile == nil }

        guard !orphanedDocuments.isEmpty else { return }

        logger.info("Migrating \(orphanedDocuments.count) orphaned documents to current profile")

        for cdDocument in orphanedDocuments {
            cdDocument.profile = profile
        }

        do {
            try persistenceController.save()
            loadDocuments()
            logger.info("Successfully migrated orphaned documents")
        } catch {
            viewContext.rollback()
            logger.error("Failed to migrate orphaned documents: \(error.localizedDescription)")
        }
    }
}
