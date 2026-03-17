//
//  SyncHelpers.swift
//  OtisShared
//
//  Shared utilities for CloudKit sync operations.
//  Extracted from EntitySyncHandlers to eliminate duplication.
//

import CloudKit
import CoreData
import Foundation
import os

// MARK: - UUID Extraction

/// Extract UUID from record name format "RecordType:UUID"
/// - Parameter recordName: The record name in format "RecordType:UUID" or just "UUID"
/// - Returns: The extracted UUID, or a new UUID if extraction fails
public func extractUUID(from recordName: String) -> UUID {
    if let colonIndex = recordName.firstIndex(of: ":") {
        let uuidString = String(recordName[recordName.index(after: colonIndex)...])
        return UUID(uuidString: uuidString) ?? UUID()
    }
    return UUID(uuidString: recordName) ?? UUID()
}

// MARK: - System Fields Encoding

/// Encode CKRecord system fields for storage in Core Data
/// - Parameter record: The CKRecord whose system fields should be encoded
/// - Returns: Encoded data, or nil if encoding fails
public func encodeSystemFields(from record: CKRecord) -> Data? {
    let coder = NSKeyedArchiver(requiringSecureCoding: true)
    record.encodeSystemFields(with: coder)
    return coder.encodedData
}

// MARK: - Record Restoration

/// Restore a CKRecord from stored system fields or create a new one
/// - Parameters:
///   - systemFields: The stored system fields data (may be nil)
///   - expectedRecordName: The expected record name for validation
///   - recordType: The CloudKit record type
///   - zoneID: The CloudKit zone ID
///   - onMismatch: Closure called when restored record name doesn't match expected
/// - Returns: A restored or newly created CKRecord
public func restoreOrCreateRecord(
    systemFields: Data?,
    expectedRecordName: String,
    recordType: String,
    zoneID: CKRecordZone.ID,
    onMismatch: (() -> Void)? = nil
) -> CKRecord {
    let recordID = CKRecord.ID(recordName: expectedRecordName, zoneID: zoneID)

    // Try to restore from system fields first
    if let systemFields = systemFields,
       let coder = try? NSKeyedUnarchiver(forReadingFrom: systemFields) {
        coder.requiresSecureCoding = true
        if let restored = CKRecord(coder: coder) {
            coder.finishDecoding()
            // Only use restored record if the record name matches our expected format
            if restored.recordID.recordName == expectedRecordName {
                return restored
            } else {
                // Record name mismatch - notify caller and create new record
                onMismatch?()
                return CKRecord(recordType: recordType, recordID: recordID)
            }
        }
    }

    // No stored system fields or restoration failed - create new record
    return CKRecord(recordType: recordType, recordID: recordID)
}

// MARK: - Entity Fetching

/// Fetch an entity by ID from Core Data
/// - Parameters:
///   - entityName: The Core Data entity name
///   - id: The UUID to search for
///   - context: The managed object context
///   - targetStore: Optional persistent store to search in (for shared records)
/// - Returns: The fetched entity, or nil if not found
@MainActor
public func fetchEntity(
    entityName: String,
    id: UUID,
    in context: NSManagedObjectContext,
    targetStore: NSPersistentStore? = nil
) -> NSManagedObject? {
    let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
    request.fetchLimit = 1

    // When targetStore is specified, only search in that store
    if let store = targetStore {
        request.affectedStores = [store]
    }

    return try? context.fetch(request).first
}

/// Fetch an existing entity or create a new one
/// - Parameters:
///   - entityName: The Core Data entity name
///   - id: The UUID to search for / assign to new entity
///   - context: The managed object context
///   - targetStore: Optional persistent store for assigning shared records.
///                  When specified, only searches in this store (prevents cross-store matches).
/// - Returns: The existing or newly created entity
@MainActor
public func fetchOrCreateEntity(
    entityName: String,
    id: UUID,
    in context: NSManagedObjectContext,
    targetStore: NSPersistentStore? = nil
) -> NSManagedObject? {
    let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
    request.fetchLimit = 1

    // When targetStore is specified, only search in that store
    // This prevents finding entities in the wrong store (e.g., private vs shared)
    if let store = targetStore {
        request.affectedStores = [store]
    }

    if let existing = try? context.fetch(request).first {
        return existing
    }

    // Create new entity
    guard let entityDesc = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
        return nil
    }

    let entity = NSManagedObject(entity: entityDesc, insertInto: context)
    entity.setValue(id, forKey: "id")

    // Assign to the correct store for shared records
    if let store = targetStore {
        context.assign(entity, to: store)
    }

    return entity
}

// MARK: - File System Helpers

/// Get the documents directory URL
public func getDocumentsDirectory() -> URL? {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
}

/// Ensure a directory exists, creating it if necessary
/// - Parameter url: The directory URL to create
/// - Throws: File system error if creation fails
public func ensureDirectoryExists(at url: URL) throws {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: url.path) {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

/// Save a file from a source URL to a destination, overwriting if necessary
/// - Parameters:
///   - sourceURL: The source file URL
///   - destinationURL: The destination file URL
/// - Throws: File system error if copy fails
public func saveFile(from sourceURL: URL, to destinationURL: URL) throws {
    let fileManager = FileManager.default

    // Ensure destination directory exists
    let destinationDir = destinationURL.deletingLastPathComponent()
    try ensureDirectoryExists(at: destinationDir)

    // Remove existing file if present
    if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
    }

    // Copy from source to destination
    try fileManager.copyItem(at: sourceURL, to: destinationURL)
}
