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
    public let zoneName = "OllieZone"

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
        let sharedConfig = SyncEngineConfiguration(
            database: container.sharedCloudDatabase,
            identifier: "shared",
            zoneName: zoneName
        )
        sharedEngine = SyncEngine(configuration: sharedConfig)
        sharedEngine?.delegate = self
        sharedEngine?.start()

        logger.info("SyncCoordinator started successfully")
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

        let isShared = syncEngine === sharedEngine
        let pendingChanges = context.pendingRecordZoneChanges

        // Group by record type for efficient fetching
        var recordsByType: [String: [CKRecord]] = [:]
        var deletions: [CKRecord.ID] = []

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
                    recordsByType[recordType, default: []].append(record)
                }

            case .deleteRecord(let recordID):
                deletions.append(recordID)

            @unknown default:
                break
            }
        }

        // Flatten records
        let recordsToSave = recordsByType.values.flatMap { $0 }

        guard !recordsToSave.isEmpty || !deletions.isEmpty else {
            return nil
        }

        pendingChangesCount = max(0, pendingChangesCount - recordsToSave.count - deletions.count)

        return CKSyncEngine.RecordZoneChangeBatch(
            recordsToSave: recordsToSave,
            recordIDsToDelete: deletions,
            atomicByZone: true
        )
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

        // Process modifications
        for modification in changes.modifications {
            let record = modification.record
            let recordType = record.recordType

            guard let handler = entityHandlers[recordType] else {
                logger.warning("No handler for record type: \(recordType)")
                continue
            }

            await handler.handleFetchedRecord(record, in: viewContext, isShared: isShared)
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
            } catch {
                logger.error("Failed to save fetched changes: \(error.localizedDescription)")
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

            // If the zone was purged, we should delete local data
            if deletion.reason == .purged {
                // TODO: Delete all local data for this zone
            }
        }
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
        for failure in changes.failedRecordSaves {
            let recordID = failure.record.recordID
            let error = failure.error
            logger.error("Failed to save record \(recordID.recordName): \(error.localizedDescription)")

            // Check for conflict
            if let ckError = error as? CKError, ckError.code == CKError.Code.serverRecordChanged {
                // Server has newer version - fetch it
                if let serverRecord = ckError.serverRecord {
                    let recordType = serverRecord.recordType
                    if let handler = entityHandlers[recordType] {
                        await handler.handleFetchedRecord(serverRecord, in: viewContext, isShared: syncEngine === sharedEngine)
                    }
                }
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
        for failure in changes.failedZoneSaves {
            logger.error("Failed to save zone \(failure.zoneID.zoneName): \(failure.error.localizedDescription)")
        }

        for failure in changes.failedZoneDeletes {
            logger.error("Failed to delete zone \(failure.zoneID.zoneName): \(failure.error.localizedDescription)")
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

        case .signOut:
            isSyncEnabled = false
            // Per Apple recommendation, delete local data on sign out
            // to prevent sharing data with wrong account
            // TODO: Implement data deletion
            break

        case .switchAccounts:
            // Account switched - need to re-sync everything
            // TODO: Clear and re-fetch data
            break

        @unknown default:
            break
        }

        onAccountChange?(change)
    }

    // MARK: - Helpers

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
    @MainActor
    func handleFetchedRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext,
        isShared: Bool
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
}
