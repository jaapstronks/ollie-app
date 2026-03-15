//
//  SyncCoordinator+Delegate.swift
//  OtisShared
//
//  CKSyncEngine delegate implementation for SyncCoordinator.
//  Handles record fetching, sending, and event processing.
//

import CloudKit
import CoreData
import Foundation
import os

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
        var recordsCache: [CKRecord.ID: CKRecord] = [:]
        var stalePendingChanges: [CKSyncEngine.PendingRecordZoneChange] = []

        for change in pendingChanges {
            switch change {
            case .saveRecord(let recordID):
                let recordType = extractRecordType(from: recordID)
                guard let handler = entityHandlers[recordType] else {
                    logger.warning("No handler for record type: \(recordType)")
                    // No handler - mark as stale to remove from queue
                    stalePendingChanges.append(change)
                    continue
                }

                if let record = await handler.fetchRecord(
                    for: recordID.recordName,
                    zoneID: syncEngine.zoneID,
                    in: viewContext
                ) {
                    recordsCache[recordID] = record
                } else {
                    // Entity no longer exists locally - mark as stale to remove from queue
                    logger.info("Entity not found for \(recordID.recordName) - removing stale pending save")
                    stalePendingChanges.append(change)
                }

            case .deleteRecord:
                break

            @unknown default:
                break
            }
        }

        // Remove stale pending changes from the engine's state
        if !stalePendingChanges.isEmpty {
            logger.info("Removing \(stalePendingChanges.count) stale pending changes from sync queue")
            syncEngine.removePendingChanges(stalePendingChanges)
        }

        pendingChangesCount = max(0, pendingChangesCount - pendingChanges.count)

        let cache = recordsCache
        logger.info("Prepared \(cache.count) records for batch (requested \(pendingChanges.count))")

        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pendingChanges) { recordID in
            let record = cache[recordID]
            if record == nil {
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

        onRemoteChanges?()
    }

    public func handleFetchedDatabaseChanges(
        _ changes: CKSyncEngine.Event.FetchedDatabaseChanges,
        for syncEngine: SyncEngine
    ) async {
        for deletion in changes.deletions {
            logger.info("Zone deleted: \(deletion.zoneID.zoneName), reason: \(String(describing: deletion.reason))")

            switch deletion.reason {
            case .purged:
                await deleteLocalDataForZone(deletion.zoneID, isShared: syncEngine === sharedEngine)
                syncEngine.clearStateSerialization()

            case .deleted:
                await deleteLocalDataForZone(deletion.zoneID, isShared: syncEngine === sharedEngine)

            case .encryptedDataReset:
                logger.warning("Encrypted data reset - clearing state and re-uploading all local data")
                syncEngine.clearStateSerialization()
                await reuploadAllDataForZone(deletion.zoneID, isShared: syncEngine === sharedEngine)

            @unknown default:
                logger.warning("Unknown zone deletion reason: \(String(describing: deletion.reason))")
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

            switch error.code {
            case .serverRecordChanged:
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
                syncEngine.addPendingSaves([recordID])
                logger.warning("Quota exceeded - re-queued record \(recordID.recordName) for retry")

            case .assetFileNotFound:
                logger.error("Asset file not found for record \(recordID.recordName) - cannot retry")

            case .assetFileModified:
                syncEngine.addPendingSaves([recordID])
                logger.warning("Asset file modified during upload - re-queued \(recordID.recordName)")

            case .zoneNotFound:
                syncEngine.ensureZoneExists()
                syncEngine.addPendingSaves([recordID])
                logger.warning("Zone not found - creating zone and re-queuing \(recordID.recordName)")

            case .unknownItem:
                logger.warning("Unknown item error for \(recordID.recordName) - record may have been deleted")

            case .batchRequestFailed:
                syncEngine.addPendingSaves([recordID])
                logger.warning("Batch request failed - re-queued \(recordID.recordName)")

            default:
                logger.error("Unhandled error \(error.code.rawValue) for \(recordID.recordName): \(error.localizedDescription)")
            }
        }

        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }

    public func handleSentDatabaseChanges(
        _ changes: CKSyncEngine.Event.SentDatabaseChanges,
        for syncEngine: SyncEngine
    ) async {
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
            scheduleAsyncWork { [weak self] in
                await self?.fetchChanges()
            }

        case .signOut:
            isSyncEnabled = false
            scheduleAsyncWork { [weak self] in
                await self?.deleteAllSyncedData()
                await self?.reinitializeEngines(restart: false)
            }

        case .switchAccounts:
            isSyncEnabled = true
            scheduleAsyncWork { [weak self] in
                await self?.deleteAllSyncedData()
                await self?.reinitializeEngines(restart: true)
            }

        @unknown default:
            break
        }

        onAccountChange?(change)
    }
}
