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

    private let logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "SyncCoordinator")

    /// CloudKit container
    private let container: CKContainer

    /// Sync engine for private database
    private var privateEngine: SyncEngine?

    /// Sync engine for shared database
    private var sharedEngine: SyncEngine?

    /// Zone name for the app's data
    /// Uses NSPersistentCloudKitContainer's default zone for backward compatibility
    public let zoneName = "com.apple.coredata.cloudkit.zone"

    /// Whether sync is enabled (false if no iCloud account)
    public private(set) var isSyncEnabled: Bool = false

    /// Whether we're currently syncing
    public var isSyncing: Bool {
        (privateEngine?.isSyncing ?? false) || (sharedEngine?.isSyncing ?? false)
    }

    /// Last sync error
    public var lastError: Error? {
        privateEngine?.lastError ?? sharedEngine?.lastError
    }

    /// Pending changes to sync (for UI indicators)
    public private(set) var pendingChangesCount: Int = 0

    // MARK: - Entity Handlers

    /// Registered handlers for different record types
    private var entityHandlers: [String: any EntitySyncHandler] = [:]

    /// Core Data context for fetching/saving entities
    private var viewContext: NSManagedObjectContext?

    // MARK: - Callbacks

    /// Called when remote changes are fetched
    public var onRemoteChanges: (() -> Void)?

    /// Called when account status changes
    public var onAccountChange: ((CKSyncEngine.Event.AccountChange) -> Void)?

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
        logger.info("SyncCoordinator configured with Core Data context")
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
        logger.debug("Marked pending save: \(entity.syncIdentifier)")
    }

    /// Mark an entity as needing deletion
    public func markPendingDelete<T: CKRecordConvertible>(_ entity: T, isShared: Bool = false) {
        let engine = isShared ? sharedEngine : privateEngine
        engine?.addPendingDeletes([entity.recordID])
        pendingChangesCount += 1
        logger.debug("Marked pending delete: \(entity.syncIdentifier)")
    }

    /// Mark a record ID as needing sync (save)
    public func markPendingSave(recordID: CKRecord.ID, isShared: Bool = false) {
        let engine = isShared ? sharedEngine : privateEngine
        engine?.addPendingSaves([recordID])
        pendingChangesCount += 1
    }

    /// Mark a record ID as needing deletion
    public func markPendingDelete(recordID: CKRecord.ID, isShared: Bool = false) {
        let engine = isShared ? sharedEngine : privateEngine
        engine?.addPendingDeletes([recordID])
        pendingChangesCount += 1
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
        logger.debug("Manually sending changes to both databases")
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
}

// MARK: - SyncEngineDelegate

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
extension SyncCoordinator: SyncEngineDelegate {

    public func nextRecordZoneChangeBatch(
        for syncEngine: SyncEngine,
        context: CKSyncEngine.SendChangesContext
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        guard let viewContext = viewContext else {
            logger.error("No view context configured")
            return nil
        }

        let _ = syncEngine === sharedEngine  // Reserved for future shared database handling
        let pendingChanges = syncEngine.pendingRecordZoneChanges(for: context)

        guard !pendingChanges.isEmpty else {
            return nil
        }

        // Debug: log what records are being requested
        logger.info("Processing \(pendingChanges.count) pending changes:")
        for change in pendingChanges {
            switch change {
            case .saveRecord(let recordID):
                logger.info("  SAVE: \(recordID.recordName)")
            case .deleteRecord(let recordID):
                logger.info("  DELETE: \(recordID.recordName)")
            @unknown default:
                logger.info("  UNKNOWN change type")
            }
        }

        // Pre-fetch all records for save operations
        // Build a dictionary of recordID -> CKRecord for the provider closure
        var recordsCache: [CKRecord.ID: CKRecord] = [:]

        for change in pendingChanges {
            switch change {
            case .saveRecord(let recordID):
                let recordType = extractRecordType(from: recordID)
                guard let handler = entityHandlers[recordType] else {
                    logger.warning("No handler for record type: \(recordType)")
                    continue
                }

                if let record = await handler.fetchRecord(
                    for: recordID.recordName,
                    zoneID: syncEngine.zoneID,
                    in: viewContext
                ) {
                    recordsCache[recordID] = record
                }

            case .deleteRecord:
                // Deletions don't need records, just pass through
                break

            @unknown default:
                break
            }
        }

        pendingChangesCount = max(0, pendingChangesCount - pendingChanges.count)

        // Capture the cache as a let constant for use in the closure
        let cache = recordsCache

        // Debug: log how many records we actually have
        logger.info("Prepared \(cache.count) records for batch (requested \(pendingChanges.count))")

        // Use the pendingChanges-based initializer so CKSyncEngine knows
        // which pending changes are satisfied by this batch
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pendingChanges) { recordID in
            // Return the cached record, or nil if not found (entity was deleted locally)
            let record = cache[recordID]
            if record == nil {
                // This shouldn't happen often - means entity was deleted between queue and send
                self.logger.warning("No record found for \(recordID.recordName) - entity may have been deleted")
            }
            return record
        }
    }

    public func handleFetchedRecordZoneChanges(
        _ changes: CKSyncEngine.Event.FetchedRecordZoneChanges,
        for syncEngine: SyncEngine
    ) async {
        guard let viewContext = viewContext else {
            logger.error("No view context configured")
            return
        }

        let isShared = syncEngine === sharedEngine

        // Get the target store for shared records
        let targetStore: NSPersistentStore? = isShared ? getSharedStore?() : nil

        // Process modifications
        for modification in changes.modifications {
            let record = modification.record
            let recordType = record.recordType

            guard let handler = entityHandlers[recordType] else {
                logger.warning("No handler for record type: \(recordType)")
                continue
            }

            await handler.handleFetchedRecord(record, in: viewContext, isShared: isShared, targetStore: targetStore)
        }

        // Process deletions
        for deletion in changes.deletions {
            let recordType = extractRecordType(from: deletion.recordID)

            guard let handler = entityHandlers[recordType] else {
                logger.warning("No handler for deletion of type: \(recordType)")
                continue
            }

            await handler.handleDeletedRecord(
                recordID: deletion.recordID.recordName,
                in: viewContext
            )
        }

        // Save context
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                logger.debug("Saved fetched changes to Core Data")
            } catch let error as NSError {
                logger.error("Failed to save fetched changes: \(error.localizedDescription)")
                // Log detailed validation errors
                if let errors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                    for detailedError in errors {
                        logger.error("  Validation error: \(detailedError.localizedDescription)")
                        if let key = detailedError.userInfo[NSValidationKeyErrorKey] {
                            logger.error("    Key: \(String(describing: key))")
                        }
                        if let object = detailedError.userInfo[NSValidationObjectErrorKey] as? NSManagedObject {
                            logger.error("    Entity: \(object.entity.name ?? "unknown")")
                        }
                    }
                }
            }
        }

        // Notify observers
        onRemoteChanges?()
    }

    public func handleFetchedDatabaseChanges(
        _ changes: CKSyncEngine.Event.FetchedDatabaseChanges,
        for syncEngine: SyncEngine
    ) async {
        // Handle zone deletions (e.g., user left share)
        for deletion in changes.deletions {
            logger.info("Zone deleted: \(deletion.zoneID.zoneName), reason: \(String(describing: deletion.reason))")

            switch deletion.reason {
            case .purged:
                // Zone was purged - user went through Settings > iCloud > Manage Storage
                // Per CKSyncEngine best practices:
                // 1. Delete all local data (user explicitly asked for this)
                // 2. Clear state serialization (change tokens are no longer valid)
                await deleteLocalDataForZone(deletion.zoneID, isShared: syncEngine === sharedEngine)
                syncEngine.clearStateSerialization()

            case .deleted:
                // Zone was explicitly deleted programmatically
                // Delete local data but keep state (we initiated this)
                await deleteLocalDataForZone(deletion.zoneID, isShared: syncEngine === sharedEngine)

            case .encryptedDataReset:
                // User reset encrypted data during account recovery
                // Per CKSyncEngine best practices:
                // 1. Clear state serialization (change tokens are no longer valid)
                // 2. Re-upload all local data to minimize data loss
                logger.warning("Encrypted data reset - clearing state and re-uploading all local data")
                syncEngine.clearStateSerialization()
                await reuploadAllDataForZone(deletion.zoneID, isShared: syncEngine === sharedEngine)

            @unknown default:
                logger.warning("Unknown zone deletion reason: \(String(describing: deletion.reason))")
            }
        }
    }

    /// Delete all local data associated with a specific zone
    /// Called when a zone is purged (e.g., user left a share)
    private func deleteLocalDataForZone(_ zoneID: CKRecordZone.ID, isShared: Bool) async {
        guard let viewContext = viewContext else {
            logger.error("No view context - cannot delete zone data")
            return
        }

        logger.info("Deleting local data for zone: \(zoneID.zoneName), isShared: \(isShared)")

        // Notify all registered handlers to delete records for this zone
        for (recordType, handler) in entityHandlers {
            await handler.handleZonePurge(zoneID: zoneID, in: viewContext)
            logger.debug("Purged \(recordType) records for zone \(zoneID.zoneName)")
        }

        // Save context after deletions
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                logger.info("Saved context after zone purge")
            } catch {
                logger.error("Failed to save after zone purge: \(error.localizedDescription)")
            }
        }

        // Notify observers that data changed
        onRemoteChanges?()
    }

    /// Re-upload all local data for a zone after encrypted data reset
    /// Called when user resets encrypted CloudKit data in Settings
    private func reuploadAllDataForZone(_ zoneID: CKRecordZone.ID, isShared: Bool) async {
        guard let viewContext = viewContext else {
            logger.error("No view context - cannot re-upload zone data")
            return
        }

        logger.info("Re-uploading all data for zone: \(zoneID.zoneName), isShared: \(isShared)")

        // Notify all registered handlers to queue their records for re-upload
        for (recordType, handler) in entityHandlers {
            await handler.handleEncryptedDataReset(zoneID: zoneID, in: viewContext)
            logger.debug("Queued \(recordType) records for re-upload")
        }

        // Trigger send to upload the queued records
        let engine = isShared ? sharedEngine : privateEngine
        await engine?.sendChanges()
    }

    public func handleSentRecordZoneChanges(
        _ changes: CKSyncEngine.Event.SentRecordZoneChanges,
        for syncEngine: SyncEngine
    ) async {
        guard let viewContext = viewContext else { return }

        // Update system fields for saved records
        for savedRecord in changes.savedRecords {
            let recordType = savedRecord.recordType

            guard let handler = entityHandlers[recordType] else { continue }

            await handler.handleSentRecord(savedRecord, in: viewContext)
        }

        // Handle failures
        // Note: CKSyncEngine automatically handles transient errors like:
        // .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable,
        // .notAuthenticated, .operationCancelled, .requestRateLimited
        // We only need to handle non-transient errors here
        for failure in changes.failedRecordSaves {
            let recordID = failure.record.recordID
            let error = failure.error
            logger.error("Failed to save record \(recordID.recordName): \(error.localizedDescription)")

            switch error.code {
            case .serverRecordChanged:
                // Conflict: server has newer version - accept server version
                // This is the "server wins" strategy; adjust if you need different conflict resolution
                if let serverRecord = error.serverRecord {
                    let recordType = serverRecord.recordType
                    let isShared = syncEngine === sharedEngine
                    let targetStore: NSPersistentStore? = isShared ? getSharedStore?() : nil
                    if let handler = entityHandlers[recordType] {
                        await handler.handleFetchedRecord(serverRecord, in: viewContext, isShared: isShared, targetStore: targetStore)
                        logger.info("Resolved conflict for \(recordID.recordName) by accepting server version")
                    }
                }

            case .quotaExceeded:
                // User ran out of iCloud storage
                // CKSyncEngine pauses but does NOT re-add the item to the queue
                // Per CKSyncEngine best practices, we must re-add it manually
                // The item will retry after the user frees up space or the retry delay passes
                syncEngine.addPendingSaves([recordID])
                logger.warning("Quota exceeded - re-queued record \(recordID.recordName) for retry")

            case .assetFileNotFound:
                // The local file for a CKAsset was deleted before upload completed
                // Don't retry - the data is gone
                logger.error("Asset file not found for record \(recordID.recordName) - cannot retry")

            case .assetFileModified:
                // The local file was modified during upload - re-queue to try again
                syncEngine.addPendingSaves([recordID])
                logger.warning("Asset file modified during upload - re-queued \(recordID.recordName)")

            case .zoneNotFound:
                // Zone doesn't exist - ensure it's created then retry
                syncEngine.ensureZoneExists()
                syncEngine.addPendingSaves([recordID])
                logger.warning("Zone not found - creating zone and re-queuing \(recordID.recordName)")

            case .unknownItem:
                // Record doesn't exist on server (might have been deleted)
                // This shouldn't happen for saves, but if it does, just log it
                logger.warning("Unknown item error for \(recordID.recordName) - record may have been deleted")

            case .batchRequestFailed:
                // Part of a batch failed - CKSyncEngine should retry automatically
                // but if not, re-queue just in case
                syncEngine.addPendingSaves([recordID])
                logger.warning("Batch request failed - re-queued \(recordID.recordName)")

            default:
                // For other errors, log them but don't automatically retry
                // These might be permanent failures (invalid arguments, permission denied, etc.)
                logger.error("Unhandled error \(error.code.rawValue) for \(recordID.recordName): \(error.localizedDescription)")
            }
        }

        // Save updated system fields
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }

    public func handleSentDatabaseChanges(
        _ changes: CKSyncEngine.Event.SentDatabaseChanges,
        for syncEngine: SyncEngine
    ) async {
        // Log any zone save/delete failures
        if !changes.failedZoneSaves.isEmpty {
            logger.error("Failed to save \(changes.failedZoneSaves.count) zone(s)")
        }

        if !changes.failedZoneDeletes.isEmpty {
            logger.error("Failed to delete \(changes.failedZoneDeletes.count) zone(s)")
        }
    }

    public func handleAccountChange(
        _ change: CKSyncEngine.Event.AccountChange,
        for syncEngine: SyncEngine
    ) async {
        logger.info("Account change: \(String(describing: change.changeType))")

        switch change.changeType {
        case .signIn:
            isSyncEnabled = true
            // Fetch all data for the new account
            // Schedule on next run loop to avoid reentrancy into CKSyncEngine from delegate callback
            scheduleAsyncWork { [weak self] in
                await self?.fetchChanges()
            }

        case .signOut:
            isSyncEnabled = false
            // Per Apple/CKSyncEngine best practices:
            // 1. Delete local CloudKit-synced data to prevent sharing with wrong account
            // 2. Clear state serialization so engine starts fresh
            // 3. Stop engines (they're invalid without an account)
            // Schedule on next run loop to avoid reentrancy into CKSyncEngine from delegate callback
            scheduleAsyncWork { [weak self] in
                await self?.deleteAllSyncedData()
                await self?.reinitializeEngines(restart: false)
            }

        case .switchAccounts:
            // Account switched - this is a combined sign out + sign in
            // Per CKSyncEngine best practices, we must:
            // 1. Delete all local synced data
            // 2. Clear state serialization (tokens are no longer valid)
            // 3. Re-initialize engines with fresh state
            // 4. Fetch data for the new account
            isSyncEnabled = true
            // Schedule on next run loop to avoid reentrancy into CKSyncEngine from delegate callback
            scheduleAsyncWork { [weak self] in
                await self?.deleteAllSyncedData()
                await self?.reinitializeEngines(restart: true)
            }

        @unknown default:
            break
        }

        onAccountChange?(change)
    }

    /// Re-initialize sync engines with cleared state
    /// Called on sign out or account switch per CKSyncEngine best practices
    /// - Parameter restart: Whether to restart engines after clearing (true for account switch, false for sign out)
    private func reinitializeEngines(restart: Bool) async {
        logger.info("Re-initializing sync engines (restart: \(restart))")

        // Clear state serialization - tokens are no longer valid
        privateEngine?.clearStateSerialization()
        sharedEngine?.clearStateSerialization()

        // Stop current engines
        privateEngine?.stop()
        sharedEngine?.stop()
        privateEngine = nil
        sharedEngine = nil

        // Restart if needed (account switch case)
        if restart {
            await start()
        }
    }

    /// Delete all locally synced data (called on sign out or account switch)
    /// This clears CloudKit-synced entities but preserves local-only data
    private func deleteAllSyncedData() async {
        guard let viewContext = viewContext else {
            logger.error("No view context - cannot delete synced data")
            return
        }

        logger.info("Deleting all synced data due to account change")

        // Notify all registered handlers to clear their synced data
        for (recordType, handler) in entityHandlers {
            await handler.handleAccountSignOut(in: viewContext)
            logger.debug("Cleared synced data for \(recordType)")
        }

        // Save context after deletions
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                logger.info("Saved context after clearing synced data")
            } catch {
                logger.error("Failed to save after clearing synced data: \(error.localizedDescription)")
            }
        }

        // Reset pending changes count
        pendingChangesCount = 0

        // Notify observers that data changed
        onRemoteChanges?()
    }

    // MARK: - Helpers

    /// Schedule async work in a truly detached context
    /// Used to avoid reentrancy into CKSyncEngine from delegate callbacks
    /// IMPORTANT: Uses Task.detached to completely break out of the current CKSyncEngine context
    private nonisolated func scheduleAsyncWork(_ work: @escaping @MainActor @Sendable () async -> Void) {
        // Use Task.detached to create a completely new task hierarchy
        // that CKSyncEngine doesn't track as part of the delegate callback
        Task.detached {
            // Create a new Task on MainActor inside the detached context
            await Task { @MainActor in
                await work()
            }.value
        }
    }

    /// Extract record type from record ID
    /// Convention: recordName format is "RecordType:UUID" or just "UUID"
    private func extractRecordType(from recordID: CKRecord.ID) -> String {
        let recordName = recordID.recordName
        if let colonIndex = recordName.firstIndex(of: ":") {
            return String(recordName[..<colonIndex])
        }
        // Fallback: try to determine from registered handlers
        return "Unknown"
    }
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
