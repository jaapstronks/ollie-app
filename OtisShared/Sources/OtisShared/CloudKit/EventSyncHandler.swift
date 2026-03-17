//
//  EventSyncHandler.swift
//  OtisShared
//
//  Sync handler for PuppyEvent entities.
//  Handles conversion between CDPuppyEvent Core Data entities and CKRecords.
//

import CloudKit
import CoreData
import Foundation
import os

// MARK: - Event Sync Handler

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class EventSyncHandler: EntitySyncHandler, @unchecked Sendable {
    public static let recordType = RecordType.puppyEvent

    private let logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "EventSyncHandler")

    public init() {}

    @MainActor
    public func fetchRecord(
        for identifier: String,
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async -> CKRecord? {
        let uuid = extractUUID(from: identifier)

        guard let event = fetchEntity(entityName: "CDPuppyEvent", id: uuid, in: context) else {
            logger.warning("Event not found for identifier: \(identifier)")
            return nil
        }

        return createRecord(from: event, zoneID: zoneID)
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

        // Check if this record was deleted locally - reject if tombstoned
        if SyncCoordinator.shared.isTombstoned(recordName: recordName) {
            logger.warning("Rejecting tombstoned event from CloudKit: \(recordName)")
            return
        }

        // Check if entity already exists in the appropriate store
        // For shared records, only look in the shared store to avoid finding stale entities in the private store
        let existingEntity = fetchEntity(entityName: "CDPuppyEvent", id: uuid, in: context, targetStore: targetStore)
        let isNewEntity = existingEntity == nil

        guard let event = existingEntity ?? createEntity(entityName: "CDPuppyEvent", id: uuid, in: context, targetStore: targetStore) else {
            logger.error("Could not find or create CDPuppyEvent entity")
            return
        }

        if isNewEntity {
            // Log detailed info when creating new entities from CloudKit
            let eventType = record.string(forKey: "CD_type") ?? "unknown"
            let eventTime = record.date(forKey: "CD_time")
            let hasPhoto = record.string(forKey: "CD_photo") != nil
            logger.info("Creating event from CloudKit: id=\(uuid), type=\(eventType), time=\(String(describing: eventTime)), hasPhoto=\(hasPhoto), isShared=\(isShared)")
        }

        if targetStore != nil && isNewEntity {
            logger.debug("Assigned new event to shared store")
        }

        updateEntity(event, from: record, in: context, targetStore: targetStore)

        if let systemFields = encodeSystemFields(from: record) {
            event.setValue(systemFields, forKey: "ckRecordSystemFields")
        }
    }

    /// Create a new entity with the given ID
    @MainActor
    private func createEntity(
        entityName: String,
        id: UUID,
        in context: NSManagedObjectContext,
        targetStore: NSPersistentStore? = nil
    ) -> NSManagedObject? {
        guard let entityDesc = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            return nil
        }

        let entity = NSManagedObject(entity: entityDesc, insertInto: context)
        entity.setValue(id, forKey: "id")

        if let store = targetStore {
            context.assign(entity, to: store)
        }

        return entity
    }

    @MainActor
    public func handleDeletedRecord(
        recordID: String,
        in context: NSManagedObjectContext
    ) async {
        let uuid = extractUUID(from: recordID)

        if let event = fetchEntity(entityName: "CDPuppyEvent", id: uuid, in: context) {
            context.delete(event)
            logger.info("Deleted event: \(recordID)")
        }
    }

    @MainActor
    public func handleSentRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext
    ) async {
        let recordName = record.recordID.recordName
        let uuid = extractUUID(from: recordName)

        if let event = fetchEntity(entityName: "CDPuppyEvent", id: uuid, in: context) {
            if let systemFields = encodeSystemFields(from: record) {
                event.setValue(systemFields, forKey: "ckRecordSystemFields")
            }
        }
    }

    @MainActor
    public func handleZonePurge(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyEvent")

        do {
            let events = try context.fetch(request)
            for event in events {
                context.delete(event)
            }
            logger.info("Purged \(events.count) events")
        } catch {
            logger.error("Failed to purge events: \(error.localizedDescription)")
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
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyEvent")

        do {
            let events = try context.fetch(request)
            for event in events {
                event.setValue(nil, forKey: "ckRecordSystemFields")

                if let id = event.value(forKey: "id") as? UUID {
                    let recordID = CKRecord.ID(
                        recordName: "\(Self.recordType):\(id.uuidString)",
                        zoneID: zoneID
                    )
                    SyncCoordinator.shared.markPendingSave(recordID: recordID)
                }
            }
            logger.info("Queued \(events.count) events for re-upload")
        } catch {
            logger.error("Failed to queue events for re-upload: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private func createRecord(from event: NSManagedObject, zoneID: CKRecordZone.ID) -> CKRecord {
        guard let id = event.value(forKey: "id") as? UUID else {
            fatalError("Event must have an id")
        }

        let expectedRecordName = "\(Self.recordType):\(id.uuidString)"
        let systemFields = event.value(forKey: "ckRecordSystemFields") as? Data

        let record = restoreOrCreateRecord(
            systemFields: systemFields,
            expectedRecordName: expectedRecordName,
            recordType: Self.recordType,
            zoneID: zoneID
        ) {
            // On mismatch, clear old system fields
            event.setValue(nil, forKey: "ckRecordSystemFields")
            self.logger.info("Creating new record for event \(id) - old record had different name")
        }

        // Core fields - use CD_ prefix for NSPersistentCloudKitContainer compatibility
        record.setString(event.value(forKey: "type") as? String, forKey: "CD_type")
        record.setDate(event.value(forKey: "time") as? Date, forKey: "CD_time")
        record.setDate(event.value(forKey: "endTime") as? Date, forKey: "CD_endTime")
        record.setDate(event.value(forKey: "createdAt") as? Date, forKey: "CD_createdAt")
        record.setDate(event.value(forKey: "modifiedAt") as? Date, forKey: "CD_modifiedAt")
        record.setString(event.value(forKey: "note") as? String, forKey: "CD_note")
        record.setString(event.value(forKey: "location") as? String, forKey: "CD_location")
        record.setInt(event.value(forKey: "durationMin") as? Int, forKey: "CD_durationMin")

        // Location
        record.setDouble(event.value(forKey: "latitude") as? Double, forKey: "CD_latitude")
        record.setDouble(event.value(forKey: "longitude") as? Double, forKey: "CD_longitude")

        // Training fields
        record.setString(event.value(forKey: "exercise") as? String, forKey: "CD_exercise")
        record.setString(event.value(forKey: "result") as? String, forKey: "CD_result")
        record.setInt(event.value(forKey: "successReps") as? Int, forKey: "CD_successReps")
        record.setInt(event.value(forKey: "failedReps") as? Int, forKey: "CD_failedReps")
        record.setString(event.value(forKey: "trainingContext") as? String, forKey: "CD_trainingContext")
        record.setString(event.value(forKey: "skillPhase") as? String, forKey: "CD_skillPhase")

        // Social fields
        record.setString(event.value(forKey: "who") as? String, forKey: "CD_who")

        // Weight
        record.setDouble(event.value(forKey: "weightKg") as? Double, forKey: "CD_weightKg")

        // Sleep/nap
        record.setString(event.value(forKey: "napLocation") as? String, forKey: "CD_napLocation")
        if let sleepSessionId = event.value(forKey: "sleepSessionId") as? UUID {
            record.setString(sleepSessionId.uuidString, forKey: "CD_sleepSessionId")
        }

        // Walk/spot
        if let spotId = event.value(forKey: "spotId") as? UUID {
            record.setString(spotId.uuidString, forKey: "CD_spotId")
        }
        record.setString(event.value(forKey: "spotName") as? String, forKey: "CD_spotName")
        if let parentWalkId = event.value(forKey: "parentWalkId") as? UUID {
            record.setString(parentWalkId.uuidString, forKey: "CD_parentWalkId")
        }

        // Gap tracking
        record.setString(event.value(forKey: "gapType") as? String, forKey: "CD_gapType")
        record.setString(event.value(forKey: "gapLocation") as? String, forKey: "CD_gapLocation")

        // Media - paths only, actual files synced separately
        record.setString(event.value(forKey: "photo") as? String, forKey: "CD_photo")
        record.setString(event.value(forKey: "thumbnailPath") as? String, forKey: "CD_thumbnailPath")
        record.setString(event.value(forKey: "video") as? String, forKey: "CD_video")
        record.setBool(event.value(forKey: "cloudPhotoSynced") as? Bool, forKey: "CD_cloudPhotoSynced")
        record.setString(event.value(forKey: "cloudPhotoOwner") as? String, forKey: "CD_cloudPhotoOwner")

        // User tracking
        record.setString(event.value(forKey: "loggedBy") as? String, forKey: "CD_loggedBy")

        // Social likes (small JSON array, use raw bytes)
        record.setData(event.value(forKey: "likesData") as? Data, forKey: "CD_likesData")

        // Contact link
        if let linkedContactID = event.value(forKey: "linkedContactID") as? UUID {
            record.setString(linkedContactID.uuidString, forKey: "CD_linkedContactID")
        }

        // Profile reference - NSPersistentCloudKitContainer stores this as a STRING (record name), not Reference
        if let profile = event.value(forKey: "profile") as? NSManagedObject,
           let profileId = profile.value(forKey: "id") as? UUID {
            // Store as string to match CloudKit schema created by NSPersistentCloudKitContainer
            record.setString("\(RecordType.puppyProfile):\(profileId.uuidString)", forKey: "CD_profile")
        }

        return record
    }

    @MainActor
    private func updateEntity(_ event: NSManagedObject, from record: CKRecord, in context: NSManagedObjectContext, targetStore: NSPersistentStore? = nil) {
        // Core fields - use CD_ prefix for NSPersistentCloudKitContainer compatibility
        event.setValue(record.string(forKey: "CD_type"), forKey: "type")
        event.setValue(record.date(forKey: "CD_time"), forKey: "time")
        event.setValue(record.date(forKey: "CD_endTime"), forKey: "endTime")
        event.setValue(record.date(forKey: "CD_createdAt"), forKey: "createdAt")
        event.setValue(record.date(forKey: "CD_modifiedAt"), forKey: "modifiedAt")
        event.setValue(record.string(forKey: "CD_note"), forKey: "note")
        event.setValue(record.string(forKey: "CD_location"), forKey: "location")
        event.setValue(record.int(forKey: "CD_durationMin") ?? 0, forKey: "durationMin")

        // Location
        event.setValue(record.double(forKey: "CD_latitude") ?? 0, forKey: "latitude")
        event.setValue(record.double(forKey: "CD_longitude") ?? 0, forKey: "longitude")

        // Training fields
        event.setValue(record.string(forKey: "CD_exercise"), forKey: "exercise")
        event.setValue(record.string(forKey: "CD_result"), forKey: "result")
        event.setValue(record.int(forKey: "CD_successReps"), forKey: "successReps")
        event.setValue(record.int(forKey: "CD_failedReps"), forKey: "failedReps")
        event.setValue(record.string(forKey: "CD_trainingContext"), forKey: "trainingContext")
        event.setValue(record.string(forKey: "CD_skillPhase"), forKey: "skillPhase")

        // Social
        event.setValue(record.string(forKey: "CD_who"), forKey: "who")

        // Weight
        event.setValue(record.double(forKey: "CD_weightKg") ?? 0, forKey: "weightKg")

        // Sleep/nap
        event.setValue(record.string(forKey: "CD_napLocation"), forKey: "napLocation")
        if let sleepSessionIdStr = record.string(forKey: "CD_sleepSessionId") {
            event.setValue(UUID(uuidString: sleepSessionIdStr), forKey: "sleepSessionId")
        }

        // Walk/spot
        if let spotIdStr = record.string(forKey: "CD_spotId") {
            event.setValue(UUID(uuidString: spotIdStr), forKey: "spotId")
        }
        event.setValue(record.string(forKey: "CD_spotName"), forKey: "spotName")
        if let parentWalkIdStr = record.string(forKey: "CD_parentWalkId") {
            event.setValue(UUID(uuidString: parentWalkIdStr), forKey: "parentWalkId")
        }

        // Gap tracking
        event.setValue(record.string(forKey: "CD_gapType"), forKey: "gapType")
        event.setValue(record.string(forKey: "CD_gapLocation"), forKey: "gapLocation")

        // Media paths
        event.setValue(record.string(forKey: "CD_photo"), forKey: "photo")
        event.setValue(record.string(forKey: "CD_thumbnailPath"), forKey: "thumbnailPath")
        event.setValue(record.string(forKey: "CD_video"), forKey: "video")
        event.setValue(record.bool(forKey: "CD_cloudPhotoSynced") ?? false, forKey: "cloudPhotoSynced")
        event.setValue(record.string(forKey: "CD_cloudPhotoOwner"), forKey: "cloudPhotoOwner")

        // Download photo from CKAsset if present (NSPersistentCloudKitContainer stored photoData as CKAsset)
        if let photoAsset = record["CD_photoData"] as? CKAsset,
           let assetURL = photoAsset.fileURL,
           let eventId = event.value(forKey: "id") as? UUID {
            savePhotoFromAsset(assetURL: assetURL, eventId: eventId, event: event)
        }

        // User tracking
        event.setValue(record.string(forKey: "CD_loggedBy"), forKey: "loggedBy")

        // Likes (small JSON array, raw bytes)
        event.setValue(record.data(forKey: "CD_likesData"), forKey: "likesData")

        // Contact link
        if let linkedContactIDStr = record.string(forKey: "CD_linkedContactID") {
            event.setValue(UUID(uuidString: linkedContactIDStr), forKey: "linkedContactID")
        }

        // Profile relationship - NSPersistentCloudKitContainer stores as STRING (record name)
        // Support both string format and reference format for backwards compatibility
        var profileUUID: UUID?
        let profileString = record.string(forKey: "CD_profile")
        let profileRef = record["CD_profile"] as? CKRecord.Reference

        if let profileString = profileString {
            // String format: "CD_CDPuppyProfile:UUID" or just "UUID"
            profileUUID = extractUUID(from: profileString)
            logger.debug("Event \(record.recordID.recordName): CD_profile string = '\(profileString)', extracted UUID = \(profileUUID?.uuidString ?? "nil")")
        } else if let profileRef = profileRef {
            // Reference format (legacy)
            profileUUID = extractUUID(from: profileRef.recordID.recordName)
            logger.debug("Event \(record.recordID.recordName): CD_profile reference = '\(profileRef.recordID.recordName)', extracted UUID = \(profileUUID?.uuidString ?? "nil")")
        } else {
            logger.warning("Event \(record.recordID.recordName): CD_profile is nil (no string or reference)")
        }

        if let profileUUID = profileUUID {
            let storeDesc = targetStore?.url?.lastPathComponent ?? "all stores"
            if let profile = fetchEntity(entityName: "CDPuppyProfile", id: profileUUID, in: context, targetStore: targetStore) {
                event.setValue(profile, forKey: "profile")
                logger.debug("Event \(record.recordID.recordName): Linked to profile \(profileUUID) in \(storeDesc)")
            } else {
                logger.error("Event \(record.recordID.recordName): Profile \(profileUUID) NOT FOUND in \(storeDesc)")
            }
        }
    }

    /// Save photo from CloudKit CKAsset to local file system
    private func savePhotoFromAsset(assetURL: URL, eventId: UUID, event: NSManagedObject) {
        guard let documentsURL = getDocumentsDirectory() else {
            logger.error("Could not get documents directory")
            return
        }

        let mediaDir = documentsURL.appendingPathComponent(Constants.mediaDirectoryName, isDirectory: true)
        let filename = "\(eventId.uuidString).jpg"
        let destinationURL = mediaDir.appendingPathComponent(filename)
        let relativePath = "\(Constants.mediaDirectoryName)/\(filename)"

        // Skip if file already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            logger.debug("Photo already exists locally for event \(eventId)")
            // Still set the path in case it's not set
            if event.value(forKey: "photo") as? String != relativePath {
                event.setValue(relativePath, forKey: "photo")
            }
            return
        }

        // Copy from CloudKit cache to local storage
        do {
            try ensureDirectoryExists(at: mediaDir)
            try FileManager.default.copyItem(at: assetURL, to: destinationURL)
            event.setValue(relativePath, forKey: "photo")
            logger.info("Saved photo from CloudKit for event \(eventId)")
        } catch {
            logger.error("Failed to save photo for event \(eventId): \(error.localizedDescription)")
        }
    }
}
