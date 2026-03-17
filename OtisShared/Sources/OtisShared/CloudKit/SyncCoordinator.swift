//
//  SyncCoordinator.swift
//  OtisShared
//
//  Central coordinator for CloudKit sync using CKSyncEngine.
//  Manages both private and shared database sync engines.
//
//  Architecture:
//  - One SyncEngine for private database (user's own data)
//  - One SyncEngine for shared database (data shared with user)
//  - Handles CKRecord ↔ Core Data entity conversion
//  - Notifies stores when data changes
//
//  Usage:
//  1. Initialize early in app launch
//  2. Register entity handlers for each Core Data entity type
//  3. Call markPendingSave/Delete when local data changes
//  4. CKSyncEngine handles the rest automatically
//
//  Note: Delegate methods are in SyncCoordinator+Delegate.swift
//

import CloudKit
import CoreData
import Foundation
import os

// MARK: - Sync Coordinator

/// Central coordinator for CloudKit sync
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@MainActor
@Observable
public final class SyncCoordinator {

    // MARK: - Singleton

    public static let shared = SyncCoordinator()

    // MARK: - Properties

    internal let logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "SyncCoordinator")

    /// CloudKit container
    private let container: CKContainer

    /// Sync engine for private database
    internal var privateEngine: SyncEngine?

    /// Sync engine for shared database
    internal var sharedEngine: SyncEngine?

    /// Zone name for the app's data
    /// Uses NSPersistentCloudKitContainer's default zone for backward compatibility
    public let zoneName = "com.apple.coredata.cloudkit.zone"

    /// Whether sync is enabled (false if no iCloud account)
    public internal(set) var isSyncEnabled: Bool = false

    /// Whether we're currently syncing
    public var isSyncing: Bool {
        (privateEngine?.isSyncing ?? false) || (sharedEngine?.isSyncing ?? false)
    }

    /// Last sync error
    public var lastError: Error? {
        privateEngine?.lastError ?? sharedEngine?.lastError
    }

    /// Pending changes to sync (for UI indicators)
    public internal(set) var pendingChangesCount: Int = 0

    // MARK: - Entity Handlers

    /// Registered handlers for different record types
    internal var entityHandlers: [String: any EntitySyncHandler] = [:]

    /// Core Data context for fetching/saving entities
    internal var viewContext: NSManagedObjectContext?

    // MARK: - Callbacks

    /// Called when remote changes are fetched
    public var onRemoteChanges: (() -> Void)?

    /// Called when account status changes
    public var onAccountChange: ((CKSyncEngine.Event.AccountChange) -> Void)?

    // MARK: - Tombstone Tracking

    /// Recently deleted record IDs to prevent resurrection from stale CloudKit records
    /// Key: record name (e.g., "CD_CDPuppyEvent:UUID"), Value: deletion timestamp
    /// Records are kept for 7 days to handle sync delays
    private var deletionTombstones: [String: Date] = [:]
    private let tombstoneRetentionDays: Int = 7
    private let tombstonesKey = "SyncCoordinator_DeletionTombstones"

    // MARK: - Store Assignment

    /// Callback to get the shared Core Data store for assigning shared entities
    /// Set this from PersistenceController to enable proper store routing
    public var getSharedStore: (() -> NSPersistentStore?)?

    // MARK: - Initialization

    private init() {
        self.container = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis")
    }

    // MARK: - Setup

    /// Configure the sync coordinator with Core Data context
    public func configure(with context: NSManagedObjectContext) {
        self.viewContext = context
        loadTombstones()
        logger.info("SyncCoordinator configured with Core Data context")
    }

    // MARK: - Tombstone Management

    /// Load tombstones from persistent storage
    private func loadTombstones() {
        guard let data = UserDefaults.standard.data(forKey: tombstonesKey),
              let stored = try? JSONDecoder().decode([String: Date].self, from: data) else {
            deletionTombstones = [:]
            return
        }

        // Filter out expired tombstones
        let cutoff = Date().addingTimeInterval(-TimeInterval(tombstoneRetentionDays * 24 * 60 * 60))
        deletionTombstones = stored.filter { $0.value > cutoff }

        logger.debug("Loaded \(self.deletionTombstones.count) active tombstones")
    }

    /// Save tombstones to persistent storage
    private func saveTombstones() {
        guard let data = try? JSONEncoder().encode(deletionTombstones) else {
            logger.error("Failed to encode tombstones")
            return
        }
        UserDefaults.standard.set(data, forKey: tombstonesKey)
    }

    /// Add a tombstone for a deleted record
    private func addTombstone(recordName: String) {
        deletionTombstones[recordName] = Date()
        saveTombstones()
        logger.info("Added tombstone for deleted record: \(recordName)")
    }

    /// Check if a record is tombstoned (was recently deleted locally)
    public func isTombstoned(recordName: String) -> Bool {
        guard let deletionDate = deletionTombstones[recordName] else {
            return false
        }

        // Check if tombstone is still valid
        let cutoff = Date().addingTimeInterval(-TimeInterval(tombstoneRetentionDays * 24 * 60 * 60))
        if deletionDate > cutoff {
            logger.warning("Rejecting tombstoned record: \(recordName) (deleted on \(deletionDate))")
            return true
        }

        // Tombstone expired, remove it
        deletionTombstones.removeValue(forKey: recordName)
        saveTombstones()
        return false
    }

    /// Remove a tombstone (when deletion is confirmed synced)
    public func removeTombstone(recordName: String) {
        if deletionTombstones.removeValue(forKey: recordName) != nil {
            saveTombstones()
            logger.debug("Removed tombstone for synced deletion: \(recordName)")
        }
    }

    /// Clear all tombstones (use when account changes)
    private func clearTombstones() {
        deletionTombstones.removeAll()
        saveTombstones()
        logger.info("Cleared all tombstones")
    }

    /// Start sync engines - call early in app launch
    public func start() async {
        logger.info("Starting SyncCoordinator")

        // Check iCloud availability
        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                logger.warning("iCloud not available: \(String(describing: status))")
                isSyncEnabled = false
                return
            }
        } catch {
            logger.error("Failed to check iCloud status: \(error.localizedDescription)")
            isSyncEnabled = false
            return
        }

        isSyncEnabled = true

        // Create and start private engine
        let privateConfig = SyncEngineConfiguration(
            database: container.privateCloudDatabase,
            identifier: "private",
            zoneName: zoneName
        )
        privateEngine = SyncEngine(configuration: privateConfig)
        privateEngine?.delegate = self
        privateEngine?.start()
        privateEngine?.ensureZoneExists()

        // Create and start shared engine
        // Note: We don't call ensureZoneExists() for shared engine because:
        // 1. Participants don't create zones - they access zones shared by the owner
        // 2. CKSyncEngine automatically discovers zones in the shared database
        // 3. Records from shared database are routed to the shared Core Data store via getSharedStore
        let sharedConfig = SyncEngineConfiguration(
            database: container.sharedCloudDatabase,
            identifier: "shared",
            zoneName: zoneName
        )
        sharedEngine = SyncEngine(configuration: sharedConfig)
        sharedEngine?.delegate = self
        sharedEngine?.start()

        logger.info("SyncCoordinator started successfully (private + shared engines)")
    }

    /// Stop sync engines
    public func stop() {
        logger.info("Stopping SyncCoordinator")
        privateEngine?.stop()
        sharedEngine?.stop()
        privateEngine = nil
        sharedEngine = nil
    }

    // MARK: - Entity Handler Registration

    /// Register a handler for a specific record type
    public func registerHandler<T: EntitySyncHandler>(_ handler: T) {
        entityHandlers[T.recordType] = handler
        logger.debug("Registered handler for \(T.recordType)")
    }

    /// Register a handler for a specific record type with an alias
    /// Use this to handle records that may have different type names (e.g., legacy records)
    public func registerHandler<T: EntitySyncHandler>(_ handler: T, forRecordType recordType: String) {
        entityHandlers[recordType] = handler
        logger.debug("Registered handler for \(recordType) (alias)")
    }

    // MARK: - Pending Changes

    /// Mark an entity as needing sync (save)
    public func markPendingSave<T: CKRecordConvertible>(_ entity: T, isShared: Bool = false) {
        let engine = isShared ? sharedEngine : privateEngine
        engine?.addPendingSaves([entity.recordID])
        pendingChangesCount += 1
        let db: SyncDatabase = isShared ? .sharedDB : .privateDB
        logger.syncEvent("Queued for save", recordID: entity.syncIdentifier, phase: .queue, database: db)
    }

    /// Mark an entity as needing deletion
    public func markPendingDelete<T: CKRecordConvertible>(_ entity: T, isShared: Bool = false) {
        let engine = isShared ? sharedEngine : privateEngine
        engine?.addPendingDeletes([entity.recordID])
        pendingChangesCount += 1

        // Add tombstone to prevent resurrection from stale CloudKit records
        addTombstone(recordName: entity.recordID.recordName)
        let db: SyncDatabase = isShared ? .sharedDB : .privateDB
        logger.syncEvent("Queued for delete + tombstone added", recordID: entity.syncIdentifier, phase: .delete, database: db)
    }

    /// Mark a record ID as needing sync (save)
    public func markPendingSave(recordID: CKRecord.ID, isShared: Bool = false) {
        let engine = isShared ? sharedEngine : privateEngine
        guard let engine = engine else {
            logger.warning("[QUEUE] Engine is nil! Cannot add pending save for \(recordID.recordName)")
            pendingChangesCount += 1  // Still increment for UI, but it won't sync
            return
        }
        engine.addPendingSaves([recordID])
        pendingChangesCount += 1
        let db: SyncDatabase = isShared ? .sharedDB : .privateDB
        logger.syncEventFull("Queued for save", recordName: recordID.recordName, phase: .queue, database: db)
    }

    /// Mark a record ID as needing deletion
    public func markPendingDelete(recordID: CKRecord.ID, isShared: Bool = false) {
        let engine = isShared ? sharedEngine : privateEngine

        // Add tombstone regardless of engine state
        addTombstone(recordName: recordID.recordName)

        guard let engine = engine else {
            logger.warning("[DELETE] Engine is nil! Cannot add pending delete for \(recordID.recordName)")
            pendingChangesCount += 1
            return
        }
        engine.addPendingDeletes([recordID])
        pendingChangesCount += 1
        let db: SyncDatabase = isShared ? .sharedDB : .privateDB
        logger.syncEventFull("Queued for delete + tombstone added", recordName: recordID.recordName, phase: .delete, database: db)
    }

    // MARK: - Manual Sync

    /// Force fetch changes from server (pull-to-refresh)
    public func fetchChanges() async {
        logger.debug("Manually fetching changes from both databases")
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.privateEngine?.fetchChanges() }
            group.addTask { await self.sharedEngine?.fetchChanges() }
        }
    }

    /// Force send pending changes to server
    public func sendChanges() async {
        let privateStarted = privateEngine != nil
        let sharedStarted = sharedEngine != nil
        logger.debug("Manually sending changes to both databases (private: \(privateStarted), shared: \(sharedStarted))")
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.privateEngine?.sendChanges() }
            group.addTask { await self.sharedEngine?.sendChanges() }
        }
    }

    /// Full sync (fetch + send)
    public func sync() async {
        await sendChanges()
        await fetchChanges()
    }

    /// Clear sync state and force full re-fetch from shared database
    /// Use this when shared data isn't appearing (stale state issue)
    public func resetSharedSyncState() async {
        logger.info("Resetting shared sync engine state for full re-fetch")
        sharedEngine?.clearStateSerialization()

        // Restart the shared engine
        sharedEngine?.stop()

        let container = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis")
        let sharedConfig = SyncEngineConfiguration(
            database: container.sharedCloudDatabase,
            identifier: "shared",
            zoneName: zoneName
        )
        sharedEngine = SyncEngine(configuration: sharedConfig)
        sharedEngine?.delegate = self
        sharedEngine?.start()

        // Fetch fresh data
        await sharedEngine?.fetchChanges()
        logger.info("Shared sync engine reset complete")
    }

    /// Clear all tombstones (for debugging resurrection issues)
    public func clearAllTombstones() {
        deletionTombstones.removeAll()
        saveTombstones()
        logger.info("Cleared all deletion tombstones")
    }

    // MARK: - Zone IDs

    /// Get zone ID for private database
    public var privateZoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    /// Get zone ID for shared database (with specific owner)
    public func sharedZoneID(ownerName: String) -> CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
    }

    // MARK: - Record ID Helpers

    /// Build a CKRecord.ID from entity name or record type and UUID
    /// Convention: recordName format is "CD_EntityName:UUID" to match NSPersistentCloudKitContainer
    ///
    /// Examples:
    /// - recordID(for: "CDPuppyEvent", id: uuid) → "CD_CDPuppyEvent:UUID"
    /// - recordID(for: "CD_CDPuppyEvent", id: uuid) → "CD_CDPuppyEvent:UUID" (already prefixed)
    public func recordID(for entityNameOrRecordType: String, id: UUID) -> CKRecord.ID {
        // If already has CD_ prefix, use as-is; otherwise add the prefix
        let recordType = entityNameOrRecordType.hasPrefix("CD_")
            ? entityNameOrRecordType
            : "CD_\(entityNameOrRecordType)"
        return CKRecord.ID(
            recordName: "\(recordType):\(id.uuidString)",
            zoneID: privateZoneID
        )
    }

    // MARK: - Internal Helpers (used by delegate extension)

    /// Delete all local data associated with a specific zone
    internal func deleteLocalDataForZone(_ zoneID: CKRecordZone.ID, isShared: Bool) async {
        guard let viewContext = viewContext else {
            logger.error("No view context - cannot delete zone data")
            return
        }

        logger.info("Deleting local data for zone: \(zoneID.zoneName), isShared: \(isShared)")

        for (recordType, handler) in entityHandlers {
            await handler.handleZonePurge(zoneID: zoneID, in: viewContext)
            logger.debug("Purged \(recordType) records for zone \(zoneID.zoneName)")
        }

        if viewContext.hasChanges {
            do {
                try viewContext.save()
                logger.info("Saved context after zone purge")
            } catch {
                logger.error("Failed to save after zone purge: \(error.localizedDescription)")
            }
        }

        onRemoteChanges?()
    }

    /// Re-upload all local data for a zone after encrypted data reset
    internal func reuploadAllDataForZone(_ zoneID: CKRecordZone.ID, isShared: Bool) async {
        guard let viewContext = viewContext else {
            logger.error("No view context - cannot re-upload zone data")
            return
        }

        logger.info("Re-uploading all data for zone: \(zoneID.zoneName), isShared: \(isShared)")

        for (recordType, handler) in entityHandlers {
            await handler.handleEncryptedDataReset(zoneID: zoneID, in: viewContext)
            logger.debug("Queued \(recordType) records for re-upload")
        }

        let engine = isShared ? sharedEngine : privateEngine
        await engine?.sendChanges()
    }

    /// Re-initialize sync engines with cleared state
    internal func reinitializeEngines(restart: Bool) async {
        logger.info("Re-initializing sync engines (restart: \(restart))")

        privateEngine?.clearStateSerialization()
        sharedEngine?.clearStateSerialization()

        privateEngine?.stop()
        sharedEngine?.stop()
        privateEngine = nil
        sharedEngine = nil

        if restart {
            await start()
        }
    }

    /// Delete all locally synced data
    internal func deleteAllSyncedData() async {
        guard let viewContext = viewContext else {
            logger.error("No view context - cannot delete synced data")
            return
        }

        logger.info("Deleting all synced data due to account change")

        // Clear tombstones since they're no longer relevant after account change
        clearTombstones()

        for (recordType, handler) in entityHandlers {
            await handler.handleAccountSignOut(in: viewContext)
            logger.debug("Cleared synced data for \(recordType)")
        }

        if viewContext.hasChanges {
            do {
                try viewContext.save()
                logger.info("Saved context after clearing synced data")
            } catch {
                logger.error("Failed to save after clearing synced data: \(error.localizedDescription)")
            }
        }

        pendingChangesCount = 0
        onRemoteChanges?()
    }

    /// Schedule async work in a truly detached context
    internal nonisolated func scheduleAsyncWork(_ work: @escaping @MainActor @Sendable () async -> Void) {
        Task.detached {
            await Task { @MainActor in
                await work()
            }.value
        }
    }

    /// Extract record type from record ID
    internal func extractRecordType(from recordID: CKRecord.ID) -> String {
        let recordName = recordID.recordName
        if let colonIndex = recordName.firstIndex(of: ":") {
            return String(recordName[..<colonIndex])
        }
        return "Unknown"
    }
}
