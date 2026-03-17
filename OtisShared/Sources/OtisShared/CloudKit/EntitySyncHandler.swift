//
//  EntitySyncHandler.swift
//  OtisShared
//
//  Protocol and constants for entity sync handlers.
//  Handlers convert between Core Data entities and CKRecords for CKSyncEngine.
//
//  Record naming convention: "RecordType:UUID"
//  This allows extracting the record type from the record ID.
//

import CloudKit
import CoreData
import Foundation

// MARK: - Record Type Constants

/// CloudKit record type names
/// Note: Uses CD_ prefix to match NSPersistentCloudKitContainer legacy format
public enum RecordType {
    public static let puppyProfile = "CD_CDPuppyProfile"
    public static let puppyEvent = "CD_CDPuppyEvent"
    public static let walkSpot = "CD_CDWalkSpot"
    public static let masteredSkill = "CD_CDMasteredSkill"
    public static let medicationCompletion = "CD_CDMedicationCompletion"
    public static let exposure = "CD_CDExposure"
    public static let milestone = "CD_CDMilestone"
    public static let document = "CD_CDDocument"
    public static let dogContact = "CD_CDDogContact"
    public static let dogAppointment = "CD_CDDogAppointment"
    public static let weightMeasurement = "CD_CDWeightMeasurement"
    public static let comfortableItem = "CD_CDComfortableItem"
    public static let earlyMilestone = "CD_CDEarlyMilestone"
    public static let skillProgress = "CD_CDSkillProgress"
    public static let regressionLog = "CD_CDRegressionLog"
    public static let routineItem = "CD_CDRoutineItem"
    public static let weightGoal = "CD_CDWeightGoal"
    public static let bodyConditionScore = "CD_CDBodyConditionScore"
    public static let groomingActivity = "CD_CDGroomingActivity"
    public static let enrichmentActivity = "CD_CDEnrichmentActivity"
    public static let userIdentity = "CD_CDUserIdentity"
    public static let userSentimentCheckIn = "CD_CDUserSentimentCheckIn"
    public static let aiCache = "CD_CDAICache"
    public static let exploredTile = "CD_CDExploredTile"
}

// MARK: - Entity Sync Handler Protocol

/// Protocol for handling sync of a specific entity type
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public protocol EntitySyncHandler: Sendable {
    /// The CKRecord type this handler manages
    static var recordType: String { get }

    /// Fetch a CKRecord for the given identifier
    @MainActor
    func fetchRecord(
        for identifier: String,
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async -> CKRecord?

    /// Handle a fetched record from CloudKit
    /// - Parameters:
    ///   - record: The fetched CKRecord
    ///   - context: The Core Data context
    ///   - isShared: Whether this record came from the shared database
    ///   - targetStore: The Core Data store to assign new entities to (nil = default store)
    @MainActor
    func handleFetchedRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext,
        isShared: Bool,
        targetStore: NSPersistentStore?
    ) async

    /// Handle a deleted record from CloudKit
    @MainActor
    func handleDeletedRecord(
        recordID: String,
        in context: NSManagedObjectContext
    ) async

    /// Handle a successfully sent record (update system fields)
    @MainActor
    func handleSentRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext
    ) async

    /// Handle zone purge - delete all local records for the given zone
    /// Called when a zone is purged (e.g., user left a share)
    @MainActor
    func handleZonePurge(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async

    /// Handle account sign out - delete all synced records
    /// Called when user signs out of iCloud or switches accounts
    @MainActor
    func handleAccountSignOut(
        in context: NSManagedObjectContext
    ) async

    /// Handle encrypted data reset - re-upload all records
    /// Called when user resets encrypted CloudKit data in Settings
    @MainActor
    func handleEncryptedDataReset(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async
}

// MARK: - Default Implementations

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public extension EntitySyncHandler {
    /// Default no-op implementation for zone purge
    /// Handlers can override to provide entity-specific cleanup
    func handleZonePurge(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async {
        // Default: no-op - handlers can override for entity-specific cleanup
    }

    /// Default no-op implementation for account sign out
    /// Handlers can override to provide entity-specific cleanup
    func handleAccountSignOut(
        in context: NSManagedObjectContext
    ) async {
        // Default: no-op - handlers can override for entity-specific cleanup
    }

    /// Default no-op implementation for encrypted data reset
    /// Handlers can override to queue records for re-upload
    func handleEncryptedDataReset(
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async {
        // Default: no-op - handlers can override to queue records for re-upload
    }
}
