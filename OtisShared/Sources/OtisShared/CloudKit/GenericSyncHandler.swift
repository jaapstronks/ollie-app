//
//  GenericSyncHandler.swift
//  OtisShared
//
//  Generic sync handler for simple entities with standard fields.
//  Use this as a base for entities that don't need custom logic.
//

import CloudKit
import CoreData
import Foundation
import os

// MARK: - Field Mapping

/// Describes how a Core Data field maps to CloudKit
public struct FieldMapping {
    public enum FieldType {
        case string
        case date
        case int
        case double
        case bool
        case uuid
        case data   // Large binary data stored as CKAsset (images, PDFs)
        case bytes  // Small binary data stored as raw bytes (config JSON, settings)
        case reference(entityName: String)
    }

    public let type: FieldType
    public let cloudKey: String?  // nil means same as Core Data key

    public init(_ type: FieldType, cloudKey: String? = nil) {
        self.type = type
        self.cloudKey = cloudKey
    }
}

// MARK: - Generic Sync Handler

/// Generic sync handler for simple entities with standard fields
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
open class GenericSyncHandler<T>: EntitySyncHandler, @unchecked Sendable {
    open class var recordType: String { fatalError("Subclass must override") }

    public let entityName: String
    public let fieldMappings: [String: FieldMapping]
    private let logger: Logger

    public init(entityName: String, fieldMappings: [String: FieldMapping]) {
        self.entityName = entityName
        self.fieldMappings = fieldMappings
        self.logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "\(entityName)SyncHandler")
    }

    @MainActor
    public func fetchRecord(
        for identifier: String,
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async -> CKRecord? {
        let uuid = extractUUID(from: identifier)

        guard let entity = fetchEntity(entityName: entityName, id: uuid, in: context) else {
            logger.warning("\(self.entityName) not found for identifier: \(identifier)")
            return nil
        }

        return createRecord(from: entity, zoneID: zoneID)
    }

    @MainActor
    public func handleFetchedRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext,
        isShared: Bool,
        targetStore: NSPersistentStore? = nil
    ) async {
        let recordName = record.recordID.recordName
        let uuid = extractUUID(from: recordName)

        guard let entity = fetchOrCreateEntity(
            entityName: entityName,
            id: uuid,
            in: context,
            targetStore: targetStore
        ) else {
            logger.error("Could not find or create \(self.entityName) entity")
            return
        }

        updateEntity(entity, from: record, in: context, targetStore: targetStore)

        // Store system fields for conflict resolution
        if let systemFields = encodeSystemFields(from: record) {
            entity.setValue(systemFields, forKey: "ckRecordSystemFields")
        }
    }

    @MainActor
    public func handleDeletedRecord(
        recordID: String,
        in context: NSManagedObjectContext
    ) async {
        let uuid = extractUUID(from: recordID)

        if let entity = fetchEntity(entityName: entityName, id: uuid, in: context) {
            context.delete(entity)
            logger.info("Deleted \(self.entityName): \(recordID)")
        }
    }

    @MainActor
    public func handleSentRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext
    ) async {
        let recordName = record.recordID.recordName
        let uuid = extractUUID(from: recordName)

        if let entity = fetchEntity(entityName: entityName, id: uuid, in: context) {
            if let systemFields = encodeSystemFields(from: record) {
                entity.setValue(systemFields, forKey: "ckRecordSystemFields")
            }
        }
    }

    @MainActor
    public func handleZonePurge(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)

        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            logger.info("Purged \(entities.count) \(self.entityName) records")
        } catch {
            logger.error("Failed to purge \(self.entityName) records: \(error.localizedDescription)")
        }
    }

    @MainActor
    public func handleAccountSignOut(
        in context: NSManagedObjectContext
    ) async {
        await handleZonePurge(
            zoneID: CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName),
            in: context
        )
    }

    @MainActor
    public func handleEncryptedDataReset(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)

        do {
            let entities = try context.fetch(request)
            for entity in entities {
                entity.setValue(nil, forKey: "ckRecordSystemFields")

                if let id = entity.value(forKey: "id") as? UUID {
                    let recordType = type(of: self).recordType
                    let recordID = CKRecord.ID(
                        recordName: "\(recordType):\(id.uuidString)",
                        zoneID: zoneID
                    )
                    SyncCoordinator.shared.markPendingSave(recordID: recordID)
                }
            }
            logger.info("Queued \(entities.count) \(self.entityName) records for re-upload")
        } catch {
            logger.error("Failed to queue \(self.entityName) records for re-upload: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    @MainActor
    private func createRecord(from entity: NSManagedObject, zoneID: CKRecordZone.ID) -> CKRecord {
        guard let id = entity.value(forKey: "id") as? UUID else {
            fatalError("\(entityName) must have an id")
        }

        let recordType = type(of: self).recordType
        let expectedRecordName = "\(recordType):\(id.uuidString)"
        let systemFields = entity.value(forKey: "ckRecordSystemFields") as? Data

        let record = restoreOrCreateRecord(
            systemFields: systemFields,
            expectedRecordName: expectedRecordName,
            recordType: recordType,
            zoneID: zoneID
        ) {
            entity.setValue(nil, forKey: "ckRecordSystemFields")
            self.logger.info("Creating new record for \(self.entityName) \(id) - old record had different name")
        }

        for (coreDataKey, mapping) in fieldMappings {
            // Use CD_ prefix for NSPersistentCloudKitContainer compatibility
            let cloudKey = "CD_" + (mapping.cloudKey ?? coreDataKey)
            let value = entity.value(forKey: coreDataKey)

            switch mapping.type {
            case .string:
                record.setString(value as? String, forKey: cloudKey)
            case .date:
                record.setDate(value as? Date, forKey: cloudKey)
            case .int:
                record.setInt(value as? Int, forKey: cloudKey)
            case .double:
                record.setDouble(value as? Double, forKey: cloudKey)
            case .bool:
                record.setBool(value as? Bool, forKey: cloudKey)
            case .uuid:
                if let uuid = value as? UUID {
                    record.setString(uuid.uuidString, forKey: cloudKey)
                }
            case .data:
                record.setAsset(value as? Data, forKey: cloudKey)
            case .bytes:
                record.setData(value as? Data, forKey: cloudKey)
            case .reference(let refEntityName):
                // NSPersistentCloudKitContainer stores relationships as STRING, not CKRecord.Reference
                // Format: "CD_EntityName:UUID" - must match existing CloudKit schema
                if let relatedEntity = value as? NSManagedObject,
                   let relatedId = relatedEntity.value(forKey: "id") as? UUID {
                    let refRecordType = "CD_\(refEntityName)"
                    record.setString("\(refRecordType):\(relatedId.uuidString)", forKey: cloudKey)
                }
            }
        }

        return record
    }

    @MainActor
    private func updateEntity(_ entity: NSManagedObject, from record: CKRecord, in context: NSManagedObjectContext, targetStore: NSPersistentStore? = nil) {
        for (coreDataKey, mapping) in fieldMappings {
            // Use CD_ prefix for NSPersistentCloudKitContainer compatibility
            let cloudKey = "CD_" + (mapping.cloudKey ?? coreDataKey)

            switch mapping.type {
            case .string:
                entity.setValue(record.string(forKey: cloudKey), forKey: coreDataKey)
            case .date:
                entity.setValue(record.date(forKey: cloudKey), forKey: coreDataKey)
            case .int:
                entity.setValue(record.int(forKey: cloudKey), forKey: coreDataKey)
            case .double:
                entity.setValue(record.double(forKey: cloudKey), forKey: coreDataKey)
            case .bool:
                entity.setValue(record.bool(forKey: cloudKey), forKey: coreDataKey)
            case .uuid:
                if let uuidString = record.string(forKey: cloudKey) {
                    entity.setValue(UUID(uuidString: uuidString), forKey: coreDataKey)
                }
            case .data:
                entity.setValue(record.assetData(forKey: cloudKey), forKey: coreDataKey)
            case .bytes:
                entity.setValue(record.data(forKey: cloudKey), forKey: coreDataKey)
            case .reference(let refEntityName):
                // NSPersistentCloudKitContainer stores relationships as STRING, not CKRecord.Reference
                // Format: "CD_EntityName:UUID"
                if let refString = record.string(forKey: cloudKey) {
                    let refUUID = extractUUID(from: refString)
                    if let related = fetchEntity(entityName: refEntityName, id: refUUID, in: context, targetStore: targetStore) {
                        entity.setValue(related, forKey: coreDataKey)
                    }
                } else if let ref = record[cloudKey] as? CKRecord.Reference {
                    // Fallback for actual CKRecord.Reference (in case schema varies)
                    let refUUID = extractUUID(from: ref.recordID.recordName)
                    if let related = fetchEntity(entityName: refEntityName, id: refUUID, in: context, targetStore: targetStore) {
                        entity.setValue(related, forKey: coreDataKey)
                    }
                }
            }
        }
    }
}
