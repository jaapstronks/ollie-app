//
//  ProfileSyncHandler.swift
//  OtisShared
//
//  Sync handler for PuppyProfile entities.
//  Handles conversion between CDPuppyProfile Core Data entities and CKRecords.
//

import CloudKit
import CoreData
import Foundation
import os

// MARK: - Profile Sync Handler

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class ProfileSyncHandler: EntitySyncHandler, @unchecked Sendable {
    public static let recordType = RecordType.puppyProfile

    private let logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "ProfileSyncHandler")

    public init() {}

    @MainActor
    public func fetchRecord(
        for identifier: String,
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async -> CKRecord? {
        let uuid = extractUUID(from: identifier)

        guard let profile = fetchEntity(entityName: "CDPuppyProfile", id: uuid, in: context) else {
            logger.warning("Profile not found for identifier: \(identifier)")
            return nil
        }

        return createRecord(from: profile, zoneID: zoneID)
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

        guard let profile = fetchOrCreateEntity(
            entityName: "CDPuppyProfile",
            id: uuid,
            in: context,
            targetStore: targetStore
        ) else {
            logger.error("Could not find or create CDPuppyProfile entity")
            return
        }

        if targetStore != nil {
            logger.debug("Assigned new profile to shared store")
        }

        // Update from record
        updateEntity(profile, from: record)

        // Store system fields for conflict resolution
        if let systemFields = encodeSystemFields(from: record) {
            profile.setValue(systemFields, forKey: "ckRecordSystemFields")
        }
    }

    @MainActor
    public func handleDeletedRecord(
        recordID: String,
        in context: NSManagedObjectContext
    ) async {
        let uuid = extractUUID(from: recordID)

        if let profile = fetchEntity(entityName: "CDPuppyProfile", id: uuid, in: context) {
            context.delete(profile)
            logger.info("Deleted profile: \(recordID)")
        }
    }

    @MainActor
    public func handleSentRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext
    ) async {
        let recordName = record.recordID.recordName
        let uuid = extractUUID(from: recordName)

        if let profile = fetchEntity(entityName: "CDPuppyProfile", id: uuid, in: context) {
            if let systemFields = encodeSystemFields(from: record) {
                profile.setValue(systemFields, forKey: "ckRecordSystemFields")
            }
        }
    }

    @MainActor
    public func handleZonePurge(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")

        do {
            let profiles = try context.fetch(request)
            for profile in profiles {
                context.delete(profile)
            }
            logger.info("Purged \(profiles.count) profiles")
        } catch {
            logger.error("Failed to purge profiles: \(error.localizedDescription)")
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
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDPuppyProfile")

        do {
            let profiles = try context.fetch(request)
            for profile in profiles {
                profile.setValue(nil, forKey: "ckRecordSystemFields")

                if let id = profile.value(forKey: "id") as? UUID {
                    let recordID = CKRecord.ID(
                        recordName: "\(Self.recordType):\(id.uuidString)",
                        zoneID: zoneID
                    )
                    SyncCoordinator.shared.markPendingSave(recordID: recordID)
                }
            }
            logger.info("Queued \(profiles.count) profiles for re-upload")
        } catch {
            logger.error("Failed to queue profiles for re-upload: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func createRecord(from profile: NSManagedObject, zoneID: CKRecordZone.ID) -> CKRecord {
        guard let id = profile.value(forKey: "id") as? UUID else {
            fatalError("Profile must have an id")
        }

        let expectedRecordName = "\(Self.recordType):\(id.uuidString)"
        let systemFields = profile.value(forKey: "ckRecordSystemFields") as? Data

        let record = restoreOrCreateRecord(
            systemFields: systemFields,
            expectedRecordName: expectedRecordName,
            recordType: Self.recordType,
            zoneID: zoneID
        ) {
            // On mismatch, clear old system fields
            profile.setValue(nil, forKey: "ckRecordSystemFields")
            self.logger.info("Creating new record for profile \(id) - old record had different name")
        }

        // Set fields - use CD_ prefix for NSPersistentCloudKitContainer compatibility
        record.setString(profile.value(forKey: "name") as? String, forKey: "CD_name")
        record.setDate(profile.value(forKey: "birthDate") as? Date, forKey: "CD_birthDate")
        record.setDate(profile.value(forKey: "homeDate") as? Date, forKey: "CD_homeDate")
        record.setString(profile.value(forKey: "sizeCategory") as? String, forKey: "CD_sizeCategory")
        record.setString(profile.value(forKey: "breed") as? String, forKey: "CD_breed")
        record.setInt(profile.value(forKey: "breedId") as? Int, forKey: "CD_breedId")
        record.setString(profile.value(forKey: "gender") as? String, forKey: "CD_gender")
        record.setString(profile.value(forKey: "coatType") as? String, forKey: "CD_coatType")
        record.setString(profile.value(forKey: "profilePhotoFilename") as? String, forKey: "CD_profilePhotoFilename")
        record.setDate(profile.value(forKey: "passedDate") as? Date, forKey: "CD_passedDate")
        record.setDate(profile.value(forKey: "modifiedAt") as? Date, forKey: "CD_modifiedAt")
        record.setString(profile.value(forKey: "preferredLocale") as? String, forKey: "CD_preferredLocale")
        record.setString(profile.value(forKey: "lastAcknowledgedPhase") as? String, forKey: "CD_lastAcknowledgedPhase")
        record.setBool(profile.value(forKey: "legacyPremiumUnlocked") as? Bool, forKey: "CD_legacyPremiumUnlocked")

        // Binary config data fields (as raw bytes, not CKAsset) - use CD_ prefix
        // These are small serialized JSON blobs, stored as BYTES in CloudKit schema
        record.setData(profile.value(forKey: "mealScheduleData") as? Data, forKey: "CD_mealScheduleData")
        record.setData(profile.value(forKey: "walkScheduleData") as? Data, forKey: "CD_walkScheduleData")
        record.setData(profile.value(forKey: "medicationScheduleData") as? Data, forKey: "CD_medicationScheduleData")
        record.setData(profile.value(forKey: "notificationSettingsData") as? Data, forKey: "CD_notificationSettingsData")
        record.setData(profile.value(forKey: "predictionConfigData") as? Data, forKey: "CD_predictionConfigData")
        record.setData(profile.value(forKey: "exerciseConfigData") as? Data, forKey: "CD_exerciseConfigData")
        record.setData(profile.value(forKey: "householdMembersData") as? Data, forKey: "CD_householdMembersData")
        record.setData(profile.value(forKey: "trainingPreparationData") as? Data, forKey: "CD_trainingPreparationData")

        return record
    }

    private func updateEntity(_ profile: NSManagedObject, from record: CKRecord) {
        // NSPersistentCloudKitContainer uses CD_ prefix for field names
        profile.setValue(record.string(forKey: "CD_name"), forKey: "name")
        profile.setValue(record.date(forKey: "CD_birthDate"), forKey: "birthDate")
        profile.setValue(record.date(forKey: "CD_homeDate"), forKey: "homeDate")
        profile.setValue(record.string(forKey: "CD_sizeCategory"), forKey: "sizeCategory")
        profile.setValue(record.string(forKey: "CD_breed"), forKey: "breed")
        profile.setValue(record.int(forKey: "CD_breedId"), forKey: "breedId")
        profile.setValue(record.string(forKey: "CD_gender"), forKey: "gender")
        profile.setValue(record.string(forKey: "CD_coatType"), forKey: "coatType")
        profile.setValue(record.string(forKey: "CD_profilePhotoFilename"), forKey: "profilePhotoFilename")
        profile.setValue(record.date(forKey: "CD_passedDate"), forKey: "passedDate")
        profile.setValue(record.date(forKey: "CD_modifiedAt"), forKey: "modifiedAt")
        profile.setValue(record.string(forKey: "CD_preferredLocale"), forKey: "preferredLocale")
        profile.setValue(record.string(forKey: "CD_lastAcknowledgedPhase"), forKey: "lastAcknowledgedPhase")
        profile.setValue(record.bool(forKey: "CD_legacyPremiumUnlocked"), forKey: "legacyPremiumUnlocked")

        // Binary config data (raw bytes, not CKAsset)
        profile.setValue(record.data(forKey: "CD_mealScheduleData"), forKey: "mealScheduleData")
        profile.setValue(record.data(forKey: "CD_walkScheduleData"), forKey: "walkScheduleData")
        profile.setValue(record.data(forKey: "CD_medicationScheduleData"), forKey: "medicationScheduleData")
        profile.setValue(record.data(forKey: "CD_notificationSettingsData"), forKey: "notificationSettingsData")
        profile.setValue(record.data(forKey: "CD_predictionConfigData"), forKey: "predictionConfigData")
        profile.setValue(record.data(forKey: "CD_exerciseConfigData"), forKey: "exerciseConfigData")
        profile.setValue(record.data(forKey: "CD_householdMembersData"), forKey: "householdMembersData")
        profile.setValue(record.data(forKey: "CD_trainingPreparationData"), forKey: "trainingPreparationData")
    }
}
