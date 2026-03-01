//
//  DocumentStore.swift
//  Otis-app
//
//  Manages documents with Core Data and automatic CloudKit sync
//  Documents are stored per-profile and images sync automatically via CloudKit

import Foundation
import CoreData
import OtisShared
import Combine
import UIKit
import os

/// Manages documents with Core Data and automatic CloudKit sync
@MainActor
final class DocumentStore: BaseStore {

    // MARK: - Published State

    @Published private(set) var documents: [Document] = []

    // MARK: - Dependencies

    private weak var profileStore: ProfileStore?

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
        self.profileStore = profileStore
        super.init(persistenceController: persistenceController, logCategory: "DocumentStore")
    }

    /// Set the profile store (for when it's not available at init time)
    func setProfileStore(_ profileStore: ProfileStore) {
        self.profileStore = profileStore
        performInitialLoad()
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        guard let profile = getCurrentProfile() else {
            documents = []
            return
        }

        let cdDocuments = CDDocument.fetchDocuments(for: profile, in: viewContext)
        documents = cdDocuments.compactMap { $0.toDocument() }
        logger.info("Loaded \(self.documents.count) documents for profile")
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

    // MARK: - CRUD Operations

    /// Add a new document with optional image
    /// - Parameters:
    ///   - document: The document metadata
    ///   - image: Optional image to attach
    /// - Returns: `true` if the document was saved successfully
    @discardableResult
    func addDocument(_ document: Document, image: UIImage? = nil) -> Bool {
        guard let profile = getCurrentProfile() else {
            setError(Strings.Common.notFound)
            return false
        }

        let cdDocument = CDDocument.create(from: document, profile: profile, in: viewContext)

        // Set image if provided
        if let image = image {
            cdDocument.setImage(image)
        }

        return performSave(operation: "Added document: \(document.displayTitle)") {
            performInitialLoad()
        }
    }

    /// Add a new document with PDF data
    /// - Parameters:
    ///   - document: The document metadata
    ///   - pdfData: PDF data to attach
    /// - Returns: `true` if the document was saved successfully
    @discardableResult
    func addDocument(_ document: Document, pdfData: Data?) -> Bool {
        guard let profile = getCurrentProfile() else {
            setError(Strings.Common.notFound)
            return false
        }

        let cdDocument = CDDocument.create(from: document, profile: profile, in: viewContext)

        // Set PDF if provided
        if let pdfData = pdfData {
            cdDocument.setPDF(pdfData)
        }

        return performSave(operation: "Added PDF document: \(document.displayTitle)") {
            performInitialLoad()
        }
    }

    /// Update an existing document
    /// - Parameters:
    ///   - document: The updated document metadata
    ///   - image: New image (nil to keep existing, pass explicit UIImage to replace)
    ///   - removeAttachment: Set to true to remove the existing attachment (image or PDF)
    /// - Returns: `true` if the document was updated successfully
    @discardableResult
    func updateDocument(_ document: Document, image: UIImage? = nil, removeAttachment: Bool = false) -> Bool {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            logger.warning("Document not found for update: \(document.id)")
            setError(Strings.Common.notFound)
            return false
        }

        cdDocument.update(from: document)

        // Handle attachment updates
        if removeAttachment {
            cdDocument.clearAttachment()
        } else if let image = image {
            cdDocument.clearAttachment()
            cdDocument.setImage(image)
        }

        return performSave(operation: "Updated document: \(document.displayTitle)") {
            performInitialLoad()
        }
    }

    /// Update an existing document with PDF data
    /// - Parameters:
    ///   - document: The updated document metadata
    ///   - pdfData: New PDF data to attach
    /// - Returns: `true` if the document was updated successfully
    @discardableResult
    func updateDocument(_ document: Document, pdfData: Data?) -> Bool {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            logger.warning("Document not found for update: \(document.id)")
            setError(Strings.Common.notFound)
            return false
        }

        cdDocument.update(from: document)

        // Replace attachment with PDF
        if let pdfData = pdfData {
            cdDocument.clearAttachment()
            cdDocument.setPDF(pdfData)
        }

        return performSave(operation: "Updated document with PDF: \(document.displayTitle)") {
            performInitialLoad()
        }
    }

    /// Delete a document (images are deleted automatically via Core Data)
    /// - Returns: `true` if the document was deleted successfully
    @discardableResult
    func deleteDocument(_ document: Document) -> Bool {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            logger.warning("Document not found for deletion: \(document.id)")
            setError(Strings.Common.notFound)
            return false
        }

        viewContext.delete(cdDocument)

        return performDelete(operation: "Deleted document: \(document.displayTitle)") {
            documents.removeAll { $0.id == document.id }
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

    // MARK: - PDF Access

    /// Load PDF data for a document
    func loadPDFData(for document: Document) -> Data? {
        guard let cdDocument = CDDocument.fetch(byId: document.id, in: viewContext) else {
            return nil
        }
        return cdDocument.getPDFData()
    }

    /// Load PDF data by document ID
    func loadPDFData(forDocumentId id: UUID) -> Data? {
        guard let cdDocument = CDDocument.fetch(byId: id, in: viewContext) else {
            return nil
        }
        return cdDocument.getPDFData()
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

        performSave(operation: "Migrated orphaned documents") {
            performInitialLoad()
        }
    }
}
