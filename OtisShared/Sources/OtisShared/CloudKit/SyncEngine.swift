//
//  SyncEngine.swift
//  OtisShared
//
//  CKSyncEngine wrapper providing fast, controlled CloudKit sync.
//  Replaces NSPersistentCloudKitContainer for better sync performance
//  and more control over sync timing.
//
//  Key benefits over NSPersistentCloudKitContainer:
//  - Sub-second sync when conditions allow (vs 1-5 min delays)
//  - Manual sync triggers for pull-to-refresh, widget updates
//  - Explicit conflict resolution
//  - Better error visibility
//
//  References:
//  - WWDC23: "Sync to iCloud with CKSyncEngine"
//  - https://developer.apple.com/documentation/cloudkit/cksyncengine
//
//  Availability: iOS 17.0+, macOS 14.0+, watchOS 10.0+
//

import CloudKit
import Foundation
import os

// MARK: - Sync Engine Configuration

/// Configuration for a SyncEngine instance
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public struct SyncEngineConfiguration: Sendable {
    /// The CloudKit database to sync with
    public let database: CKDatabase

    /// Identifier for this sync engine (for logging/debugging)
    public let identifier: String

    /// Zone name for storing records
    public let zoneName: String

    /// Whether to automatically sync (recommended: true)
    public let automaticallySync: Bool

    public init(
        database: CKDatabase,
        identifier: String,
        zoneName: String = "com.apple.coredata.cloudkit.zone",
        automaticallySync: Bool = true
    ) {
        self.database = database
        self.identifier = identifier
        self.zoneName = zoneName
        self.automaticallySync = automaticallySync
    }
}

// MARK: - Sync Engine Delegate Protocol

/// Protocol for handling sync events from CKSyncEngine
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@MainActor
public protocol SyncEngineDelegate: AnyObject {
    /// Provide the next batch of records to upload
    func nextRecordZoneChangeBatch(
        for syncEngine: SyncEngine,
        context: CKSyncEngine.SendChangesContext
    ) async -> CKSyncEngine.RecordZoneChangeBatch?

    /// Handle records fetched from the server
    func handleFetchedRecordZoneChanges(
        _ changes: CKSyncEngine.Event.FetchedRecordZoneChanges,
        for syncEngine: SyncEngine
    ) async

    /// Handle database changes (zone creation/deletion)
    func handleFetchedDatabaseChanges(
        _ changes: CKSyncEngine.Event.FetchedDatabaseChanges,
        for syncEngine: SyncEngine
    ) async

    /// Handle sent record results (success/failure)
    func handleSentRecordZoneChanges(
        _ changes: CKSyncEngine.Event.SentRecordZoneChanges,
        for syncEngine: SyncEngine
    ) async

    /// Handle sent database changes results
    func handleSentDatabaseChanges(
        _ changes: CKSyncEngine.Event.SentDatabaseChanges,
        for syncEngine: SyncEngine
    ) async

    /// Handle account change (sign in/out/switch)
    func handleAccountChange(
        _ change: CKSyncEngine.Event.AccountChange,
        for syncEngine: SyncEngine
    ) async
}

// MARK: - Sync Engine

/// Wrapper around CKSyncEngine that manages CloudKit sync for the app
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@MainActor
public final class SyncEngine: @unchecked Sendable {

    // MARK: - Properties

    private let configuration: SyncEngineConfiguration
    private let logger: Logger

    /// The underlying CKSyncEngine instance
    private var engine: CKSyncEngine?

    /// Delegate for handling sync events
    public weak var delegate: SyncEngineDelegate?

    /// Zone ID for this sync engine
    public var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: configuration.zoneName, ownerName: CKCurrentUserDefaultName)
    }

    /// Whether the engine is currently syncing
    public private(set) var isSyncing: Bool = false

    /// Last sync error (if any)
    public private(set) var lastError: Error?

    // MARK: - State Persistence Keys

    private var stateKey: String {
        "SyncEngineState_\(configuration.identifier)"
    }

    private var zoneNameKey: String {
        "SyncEngineZoneName_\(configuration.identifier)"
    }

    // MARK: - Initialization

    public init(configuration: SyncEngineConfiguration) {
        self.configuration = configuration
        self.logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "SyncEngine-\(configuration.identifier)")
    }

    // MARK: - Engine Lifecycle

    /// Start the sync engine - call this early in app launch
    public func start() {
        guard engine == nil else {
            logger.debug("Sync engine already started")
            return
        }

        logger.info("Starting sync engine: \(self.configuration.identifier)")

        // Check if zone name changed - if so, clear old state
        migrateStateIfZoneChanged()

        // Load persisted state
        let stateSerialization = loadStateSerialization()

        // Create the CKSyncEngine configuration
        var engineConfig = CKSyncEngine.Configuration(
            database: configuration.database,
            stateSerialization: stateSerialization,
            delegate: self
        )

        // Set automatic sync preference
        engineConfig.automaticallySync = configuration.automaticallySync

        // Create the engine
        engine = CKSyncEngine(engineConfig)

        logger.info("Sync engine started successfully")
    }

    /// Stop the sync engine
    public func stop() {
        logger.info("Stopping sync engine: \(self.configuration.identifier)")
        engine = nil
    }

    // MARK: - Manual Sync Control

    /// Manually trigger a fetch of changes from the server
    /// Use for pull-to-refresh or when you need immediate updates
    public func fetchChanges() async {
        guard let engine = engine else {
            logger.warning("Cannot fetch changes - engine not started")
            return
        }

        logger.debug("Manually fetching changes")
        isSyncing = true

        do {
            try await engine.fetchChanges()
            lastError = nil
        } catch {
            logger.error("Fetch changes failed: \(error.localizedDescription)")
            lastError = error
        }

        isSyncing = false
    }

    /// Manually trigger sending pending changes to the server
    /// Use for "sync now" buttons or critical updates
    public func sendChanges() async {
        guard let engine = engine else {
            logger.warning("Cannot send changes - engine not started")
            return
        }

        logger.debug("Manually sending changes")
        isSyncing = true

        do {
            try await engine.sendChanges()
            lastError = nil
        } catch {
            logger.error("Send changes failed: \(error.localizedDescription)")
            lastError = error
        }

        isSyncing = false
    }

    // MARK: - Pending Changes

    /// Add records to be saved to CloudKit
    public func addPendingSaves(_ recordIDs: [CKRecord.ID]) {
        guard let engine = engine else {
            logger.warning("Cannot add pending saves - engine not started")
            return
        }

        let changes = recordIDs.map { CKSyncEngine.PendingRecordZoneChange.saveRecord($0) }
        engine.state.add(pendingRecordZoneChanges: changes)

        logger.debug("Added \(recordIDs.count) pending saves")
    }

    /// Add records to be deleted from CloudKit
    public func addPendingDeletes(_ recordIDs: [CKRecord.ID]) {
        guard let engine = engine else {
            logger.warning("Cannot add pending deletes - engine not started")
            return
        }

        let changes = recordIDs.map { CKSyncEngine.PendingRecordZoneChange.deleteRecord($0) }
        engine.state.add(pendingRecordZoneChanges: changes)

        logger.debug("Added \(recordIDs.count) pending deletes")
    }

    /// Add a zone to be created
    public func addPendingZoneSave(_ zone: CKRecordZone) {
        guard let engine = engine else {
            logger.warning("Cannot add pending zone save - engine not started")
            return
        }

        engine.state.add(pendingDatabaseChanges: [.saveZone(zone)])
        logger.debug("Added pending zone save: \(zone.zoneID.zoneName)")
    }

    /// Add a zone to be deleted
    public func addPendingZoneDelete(_ zoneID: CKRecordZone.ID) {
        guard let engine = engine else {
            logger.warning("Cannot add pending zone delete - engine not started")
            return
        }

        engine.state.add(pendingDatabaseChanges: [.deleteZone(zoneID)])
        logger.debug("Added pending zone delete: \(zoneID.zoneName)")
    }

    /// Get pending record zone changes filtered by the send context scope
    public func pendingRecordZoneChanges(
        for context: CKSyncEngine.SendChangesContext
    ) -> [CKSyncEngine.PendingRecordZoneChange] {
        guard let engine = engine else { return [] }
        return engine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
    }

    /// Remove stale pending changes from the sync queue
    /// Call this when an entity no longer exists locally
    public func removePendingChanges(_ changes: [CKSyncEngine.PendingRecordZoneChange]) {
        guard let engine = engine, !changes.isEmpty else { return }
        engine.state.remove(pendingRecordZoneChanges: changes)
    }

    // MARK: - Zone Check

    /// Check if our zone exists, create if needed
    public func ensureZoneExists() {
        let zone = CKRecordZone(zoneID: zoneID)
        addPendingZoneSave(zone)
    }

    /// Clear persisted state serialization
    /// Call this when re-initializing after sign out or account switch
    /// Per CKSyncEngine best practices, state should be cleared when:
    /// - User signs out of iCloud
    /// - User switches accounts
    /// - Zone is purged
    public func clearStateSerialization() {
        UserDefaults.standard.removeObject(forKey: stateKey)
        UserDefaults.standard.removeObject(forKey: zoneNameKey)
        logger.info("Cleared sync state for \(self.configuration.identifier)")
    }

    // MARK: - State Persistence

    private func loadStateSerialization() -> CKSyncEngine.State.Serialization? {
        guard let data = UserDefaults.standard.data(forKey: stateKey) else {
            logger.debug("No persisted sync state found")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(CKSyncEngine.State.Serialization.self, from: data)
            logger.debug("Loaded persisted sync state")
            return state
        } catch {
            logger.error("Failed to decode sync state: \(error.localizedDescription)")
            return nil
        }
    }

    private func saveStateSerialization(_ serialization: CKSyncEngine.State.Serialization) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(serialization)
            UserDefaults.standard.set(data, forKey: stateKey)
            logger.debug("Saved sync state")
        } catch {
            logger.error("Failed to encode sync state: \(error.localizedDescription)")
        }
    }

    /// Check if zone name changed and clear old state if needed
    /// This handles migration from OllieZone to com.apple.coredata.cloudkit.zone
    private func migrateStateIfZoneChanged() {
        let savedZoneName = UserDefaults.standard.string(forKey: zoneNameKey)
        let currentZoneName = configuration.zoneName

        if let savedZoneName = savedZoneName, savedZoneName != currentZoneName {
            // Zone name changed - clear old sync state
            logger.warning("Zone name changed from '\(savedZoneName)' to '\(currentZoneName)' - clearing sync state")
            UserDefaults.standard.removeObject(forKey: stateKey)
        }

        // Save current zone name
        UserDefaults.standard.set(currentZoneName, forKey: zoneNameKey)
    }
}

// MARK: - CKSyncEngineDelegate

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
extension SyncEngine: CKSyncEngineDelegate {

    nonisolated public func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        await handleEventOnMain(event, syncEngine: syncEngine)
    }

    @MainActor
    private func handleEventOnMain(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let stateUpdate):
            // Always persist state updates
            saveStateSerialization(stateUpdate.stateSerialization)

        case .accountChange(let accountChange):
            logger.info("Account change: \(String(describing: accountChange.changeType))")
            await delegate?.handleAccountChange(accountChange, for: self)

        case .fetchedDatabaseChanges(let databaseChanges):
            logger.debug("Fetched database changes")
            await delegate?.handleFetchedDatabaseChanges(databaseChanges, for: self)

        case .fetchedRecordZoneChanges(let recordZoneChanges):
            logger.debug("Fetched \(recordZoneChanges.modifications.count) modifications, \(recordZoneChanges.deletions.count) deletions")
            await delegate?.handleFetchedRecordZoneChanges(recordZoneChanges, for: self)

        case .sentDatabaseChanges(let sentDatabaseChanges):
            logger.debug("Sent database changes")
            await delegate?.handleSentDatabaseChanges(sentDatabaseChanges, for: self)

        case .sentRecordZoneChanges(let sentRecordZoneChanges):
            logger.debug("Sent \(sentRecordZoneChanges.savedRecords.count) records, \(sentRecordZoneChanges.failedRecordSaves.count) failures")
            await delegate?.handleSentRecordZoneChanges(sentRecordZoneChanges, for: self)

        case .willFetchChanges:
            logger.debug("Will fetch changes")
            isSyncing = true

        case .didFetchChanges:
            logger.debug("Did fetch changes")
            isSyncing = false

        case .willSendChanges:
            logger.debug("Will send changes")
            isSyncing = true

        case .didSendChanges:
            logger.debug("Did send changes")
            isSyncing = false

        case .willFetchRecordZoneChanges:
            break

        case .didFetchRecordZoneChanges:
            break

        @unknown default:
            logger.warning("Unknown sync engine event")
        }
    }

    nonisolated public func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        await nextRecordZoneChangeBatchOnMain(context)
    }

    @MainActor
    private func nextRecordZoneChangeBatchOnMain(
        _ context: CKSyncEngine.SendChangesContext
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        await delegate?.nextRecordZoneChangeBatch(for: self, context: context)
    }
}
