//
//  CloudKitService.swift
//  OllieShared
//
//  CloudKit sync service for multi-device and multi-user data sharing
//  Coordinates zone management, record conversion, sharing, and sync operations

import Foundation
import CloudKit
import Combine
import os

/// Manages CloudKit sync for puppy events
/// Supports sharing between users (e.g., partners sharing a dog)
@MainActor
public final class CloudKitService: ObservableObject {
    public static let shared = CloudKitService()

    // MARK: - Configuration

    private let containerIdentifier = "iCloud.nl.jaapstronks.Ollie"
    private let zoneName = "OllieEvents"
    private let recordType = "PuppyEvent"

    // MARK: - CloudKit Objects

    private lazy var container: CKContainer = {
        CKContainer(identifier: containerIdentifier)
    }()

    private lazy var privateDatabase: CKDatabase = {
        container.privateCloudDatabase
    }()

    private lazy var sharedDatabase: CKDatabase = {
        container.sharedCloudDatabase
    }()

    private lazy var zoneID: CKRecordZone.ID = {
        CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }()

    // MARK: - Extracted Components

    private lazy var recordConverter: CloudKitRecordConverter = {
        CloudKitRecordConverter(recordType: recordType, deviceID: deviceID)
    }()

    private lazy var zoneManager: CloudKitZoneManager = {
        CloudKitZoneManager(
            privateDatabase: privateDatabase,
            sharedDatabase: sharedDatabase,
            zoneID: zoneID,
            zoneName: zoneName
        )
    }()

    public private(set) lazy var shareManager: CloudKitShareManager = {
        CloudKitShareManager(
            privateDatabase: privateDatabase,
            zoneID: zoneID,
            zoneManager: zoneManager
        )
    }()

    private lazy var exposureService: ExposureCloudService = {
        ExposureCloudService(
            deviceID: deviceID,
            getDatabase: { [weak self] in
                guard let self = self else { return CKContainer.default().privateCloudDatabase }
                return self.isParticipant ? self.sharedDatabase : self.privateDatabase
            },
            getZoneID: { [weak self] in
                guard let self = self else { return CKRecordZone.ID(zoneName: "OllieEvents", ownerName: CKCurrentUserDefaultName) }
                return self.isParticipant ? (self.participantZoneID ?? self.zoneID) : self.zoneID
            },
            isCloudAvailable: { [weak self] in
                self?.isCloudAvailable ?? false
            }
        )
    }()

    // MARK: - Published State

    @Published public private(set) var isSyncing = false
    @Published public private(set) var isCloudAvailable = false
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var syncError: String?
    @Published public private(set) var isParticipant = false // True if user is viewing someone else's shared data

    // MARK: - Private State

    private var serverChangeToken: CKServerChangeToken?
    private var participantZoneID: CKRecordZone.ID? // Zone ID when viewing shared data
    private let logger = Logger.ollie(category: "CloudKit")
    private let deviceID: String
    private var shareManagerCancellable: AnyCancellable?

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let serverChangeToken = "cloudkit.serverChangeToken"
        static let lastSyncDate = "cloudkit.lastSyncDate"
        static let migrationCompleted = "cloudkit.migrationCompleted"
        static let participantZoneOwner = "cloudkit.participantZoneOwner"
        static let participantZoneName = "cloudkit.participantZoneName"
    }

    // MARK: - Computed Properties (forwarded from ShareManager)

    public var isShared: Bool { shareManager.isShared }
    public var shareParticipants: [ShareParticipant] { shareManager.shareParticipants }

    // MARK: - Init

    private init() {
        // Use DeviceIdentifier for cross-platform device ID
        deviceID = DeviceIdentifier.current
        loadPersistedState()

        // Forward shareManager changes to this object so SwiftUI views update
        shareManagerCancellable = shareManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

        #if targetEnvironment(simulator)
        // CloudKit works on simulator but may have limitations without proper entitlements
        logger.info("Running on simulator - CloudKit may have limited functionality")
        Task {
            await checkCloudAvailability()
        }
        #else
        Task {
            await checkCloudAvailability()
        }
        #endif
    }

    // MARK: - Setup

    /// Initial setup - call on app launch
    public func setup() async {
        await checkCloudAvailability()

        guard isCloudAvailable else {
            logger.warning("CloudKit not available, skipping setup")
            return
        }

        do {
            // Check if we're a participant (viewing shared data) or owner
            await checkParticipantStatus()

            if !isParticipant {
                // Only create zone if we're the owner
                try await zoneManager.createZoneIfNeeded()
            }

            // Subscribe to changes for real-time sync
            let targetZoneID = isParticipant ? (participantZoneID ?? zoneID) : zoneID
            try await zoneManager.subscribeToChanges(targetZoneID: targetZoneID, isParticipant: isParticipant)

            logger.info("CloudKit setup completed successfully")
        } catch {
            logger.error("CloudKit setup failed: \(error.localizedDescription)")
            syncError = Strings.CloudKitSetup.setupFailed(error.localizedDescription)
        }
    }

    /// Check if CloudKit is available
    public func checkCloudAvailability() async {
        do {
            let status = try await container.accountStatus()
            isCloudAvailable = (status == .available)

            switch status {
            case .available:
                syncError = nil
            case .couldNotDetermine:
                syncError = Strings.CloudSharing.iCloudStatusUnknown
            case .noAccount:
                syncError = Strings.CloudSharing.noICloudAccount
            case .restricted:
                syncError = Strings.CloudSharing.iCloudRestricted
            case .temporarilyUnavailable:
                syncError = Strings.CloudSharing.iCloudTemporarilyUnavailable
            @unknown default:
                syncError = Strings.CloudSharing.iCloudNotAvailable
            }
        } catch {
            isCloudAvailable = false
            syncError = Strings.CloudSharing.couldNotCheckICloudStatus
            logger.error("Failed to check account status: \(error.localizedDescription)")
        }
    }

    // MARK: - Participant Status

    /// Check if we're viewing someone else's shared data
    private func checkParticipantStatus() async {
        // Check if we have stored participant zone info
        if let ownerName = UserDefaults.standard.string(forKey: UserDefaultsKey.participantZoneOwner),
           let zoneName = UserDefaults.standard.string(forKey: UserDefaultsKey.participantZoneName) {

            // Security: Verify the cached zone still exists in shared database
            // This prevents using stale/tampered zone IDs
            let cachedZoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
            if await verifyParticipantZone(cachedZoneID) {
                participantZoneID = cachedZoneID
                isParticipant = true
                logger.info("Verified participant zone: \(zoneName) owned by \(ownerName)")
                return
            } else {
                // Cached zone is invalid - clear it
                logger.warning("Cached participant zone no longer valid, clearing")
                clearParticipantZoneCache()
            }
        }

        // Check shared database for any shared zones
        if let sharedZoneID = await zoneManager.findParticipantZone() {
            participantZoneID = sharedZoneID
            isParticipant = true

            // Persist for future launches
            UserDefaults.standard.set(sharedZoneID.ownerName, forKey: UserDefaultsKey.participantZoneOwner)
            UserDefaults.standard.set(sharedZoneID.zoneName, forKey: UserDefaultsKey.participantZoneName)

            logger.info("Found shared zone, switching to participant mode")
        }
    }

    /// Verify that a participant zone ID is valid (exists in shared database)
    private func verifyParticipantZone(_ zoneID: CKRecordZone.ID) async -> Bool {
        do {
            let zones = try await zoneManager.allSharedZones()
            return zones.contains { $0.zoneID == zoneID }
        } catch {
            logger.error("Failed to verify participant zone: \(error.localizedDescription)")
            return false
        }
    }

    /// Clear cached participant zone info
    private func clearParticipantZoneCache() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.participantZoneOwner)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.participantZoneName)
    }

    // MARK: - Save Events

    /// Save an event to CloudKit
    public func saveEvent(_ event: PuppyEvent) async throws {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        let targetZoneID = isParticipant ? (participantZoneID ?? zoneID) : zoneID
        let record = recordConverter.createRecord(from: event, in: targetZoneID)
        let database = isParticipant ? sharedDatabase : privateDatabase

        do {
            _ = try await database.save(record)
            logger.info("Saved event to CloudKit: \(event.type.rawValue)")
        } catch let error as CKError {
            logger.error("Failed to save event: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    /// Save multiple events (batch)
    public func saveEvents(_ events: [PuppyEvent]) async throws {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        guard !events.isEmpty else { return }

        let targetZoneID = isParticipant ? (participantZoneID ?? zoneID) : zoneID
        let records = recordConverter.createRecords(from: events, in: targetZoneID)
        let database = isParticipant ? sharedDatabase : privateDatabase

        let (saveResults, _) = try await database.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .changedKeys
        )

        let successCount = saveResults.values.filter { result in
            if case .success = result { return true }
            return false
        }.count

        logger.info("Batch saved \(successCount)/\(events.count) events to CloudKit")
    }

    /// Delete an event from CloudKit
    public func deleteEvent(_ event: PuppyEvent) async throws {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        let targetZoneID = isParticipant ? (participantZoneID ?? zoneID) : zoneID
        let recordID = CKRecord.ID(recordName: event.id.uuidString, zoneID: targetZoneID)
        let database = isParticipant ? sharedDatabase : privateDatabase

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted event from CloudKit: \(event.id)")
        } catch let error as CKError {
            // Record might not exist in CloudKit yet (local-only)
            if error.code != .unknownItem {
                throw CloudKitError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Fetch Events

    /// Fetch events for a specific date from CloudKit
    public func fetchEvents(for date: Date) async throws -> [PuppyEvent] {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = NSPredicate(
            format: "eventTime >= %@ AND eventTime < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "eventTime", ascending: true)]

        var allEvents: [PuppyEvent] = []

        // Fetch from appropriate database based on participant status
        if isParticipant {
            let events = try await fetchFromDatabase(sharedDatabase, query: query, zoneID: participantZoneID ?? zoneID)
            allEvents.append(contentsOf: events)
        } else {
            let privateEvents = try await fetchFromDatabase(privateDatabase, query: query, zoneID: zoneID)
            allEvents.append(contentsOf: privateEvents)

            let sharedEvents = try await fetchFromSharedDatabase(query: query)
            allEvents.append(contentsOf: sharedEvents)
        }

        return allEvents.uniqued(on: \.id).sorted { $0.time > $1.time }
    }

    /// Fetch events for a date range
    public func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [PuppyEvent] {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        let predicate = NSPredicate(
            format: "eventTime >= %@ AND eventTime < %@",
            startDate as NSDate,
            endDate as NSDate
        )

        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "eventTime", ascending: true)]

        var allEvents: [PuppyEvent] = []

        if isParticipant {
            let events = try await fetchFromDatabase(sharedDatabase, query: query, zoneID: participantZoneID ?? zoneID)
            allEvents.append(contentsOf: events)
        } else {
            let privateEvents = try await fetchFromDatabase(privateDatabase, query: query, zoneID: zoneID)
            allEvents.append(contentsOf: privateEvents)

            let sharedEvents = try await fetchFromSharedDatabase(query: query)
            allEvents.append(contentsOf: sharedEvents)
        }

        return allEvents.uniqued(on: \.id).sorted { $0.time > $1.time }
    }

    private func fetchFromDatabase(_ database: CKDatabase, query: CKQuery, zoneID: CKRecordZone.ID) async throws -> [PuppyEvent] {
        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

            var records: [CKRecord] = []
            for (_, result) in results {
                if case .success(let record) = result {
                    records.append(record)
                }
            }

            return recordConverter.createEvents(from: records)
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return []
            }
            throw error
        }
    }

    private func fetchFromSharedDatabase(query: CKQuery) async throws -> [PuppyEvent] {
        var allEvents: [PuppyEvent] = []

        let zones = try await zoneManager.allSharedZones()

        for zone in zones {
            let events = try await fetchFromDatabase(sharedDatabase, query: query, zoneID: zone.zoneID)
            allEvents.append(contentsOf: events)
        }

        return allEvents
    }

    // MARK: - Sync

    /// Perform a full sync - fetch changes since last sync
    public func sync() async throws {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        guard !isSyncing else {
            logger.info("Sync already in progress, skipping")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        logger.info("Starting CloudKit sync")

        let targetZoneID = isParticipant ? (participantZoneID ?? zoneID) : zoneID
        let database = isParticipant ? sharedDatabase : privateDatabase

        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        configuration.previousServerChangeToken = serverChangeToken

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [targetZoneID],
            configurationsByRecordZoneID: [targetZoneID: configuration]
        )

        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []

        operation.recordWasChangedBlock = { _, result in
            if case .success(let record) = result {
                changedRecords.append(record)
            }
        }

        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            deletedRecordIDs.append(recordID)
        }

        operation.recordZoneChangeTokensUpdatedBlock = { [weak self] _, token, _ in
            self?.serverChangeToken = token
            self?.saveChangeToken(token)
        }

        operation.recordZoneFetchResultBlock = { [weak self] _, result in
            if case .success(let (token, _, _)) = result {
                self?.serverChangeToken = token
                self?.saveChangeToken(token)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            operation.fetchRecordZoneChangesResultBlock = { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        self?.lastSyncDate = Date()
                        self?.saveLastSyncDate()
                        self?.logger.info("Sync completed: \(changedRecords.count) changed, \(deletedRecordIDs.count) deleted")

                        NotificationCenter.default.post(
                            name: .cloudKitSyncCompleted,
                            object: nil,
                            userInfo: [
                                "changedRecords": changedRecords,
                                "deletedRecordIDs": deletedRecordIDs
                            ]
                        )

                        continuation.resume()

                    case .failure(let error):
                        self?.syncError = error.localizedDescription
                        self?.logger.error("Sync failed: \(error.localizedDescription)")
                        continuation.resume(throwing: CloudKitError.syncFailed(error.localizedDescription))
                    }
                }
            }

            database.add(operation)
        }
    }

    // MARK: - Sharing (forwarded to ShareManager)

    /// Create a share for the events zone
    public func createShare() async throws -> CKShare {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        guard !isParticipant else {
            throw CloudKitError.cannotShareAsParticipant
        }

        return try await shareManager.createShare()
    }

    /// Fetch existing share for the zone
    public func fetchExistingShare() async throws -> CKShare? {
        guard isCloudAvailable else { return nil }
        return try await shareManager.fetchExistingShare()
    }

    /// Refresh the list of share participants and share state
    public func refreshShareParticipants() async {
        guard isCloudAvailable else { return }
        await shareManager.refreshShareParticipants()
    }

    /// Update share state (call after share sheet is dismissed)
    public func updateShareState() async {
        guard isCloudAvailable else { return }
        await shareManager.updateShareState()
    }

    /// Stop sharing (remove all participants)
    public func stopSharing() async throws {
        guard isCloudAvailable else { return }
        try await shareManager.stopSharing()
    }

    // MARK: - Migration

    /// Migrate local events to CloudKit (one-time on first CloudKit setup)
    public func migrateLocalEvents(_ events: [PuppyEvent]) async throws {
        guard isCloudAvailable else {
            throw CloudKitError.notAvailable
        }

        let migrationKey = UserDefaultsKey.migrationCompleted
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            logger.info("Migration already completed, skipping")
            return
        }

        guard !events.isEmpty else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        logger.info("Starting migration of \(events.count) local events to CloudKit")

        // Upload in batches of 400 (CloudKit limit)
        let batchSize = 400
        var uploadedCount = 0

        for batchStart in stride(from: 0, to: events.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, events.count)
            let batch = Array(events[batchStart..<batchEnd])

            do {
                try await saveEvents(batch)
                uploadedCount += batch.count
                logger.info("Migrated batch: \(uploadedCount)/\(events.count)")
            } catch {
                logger.error("Migration batch failed: \(error.localizedDescription)")
                throw CloudKitError.migrationFailed(error.localizedDescription)
            }
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
        logger.info("Migration completed: \(uploadedCount) events uploaded")
    }

    /// Check if migration has been completed
    public var isMigrationCompleted: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKey.migrationCompleted)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        // Load change token
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKey.serverChangeToken),
           let token = try? NSKeyedUnarchiver.unarchivedObject(
               ofClass: CKServerChangeToken.self,
               from: data
           ) {
            serverChangeToken = token
        }

        // Load last sync date
        if let date = UserDefaults.standard.object(forKey: UserDefaultsKey.lastSyncDate) as? Date {
            lastSyncDate = date
        }
    }

    private func saveChangeToken(_ token: CKServerChangeToken?) {
        guard let token = token else {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.serverChangeToken)
            return
        }

        if let data = try? NSKeyedArchiver.archivedData(
            withRootObject: token,
            requiringSecureCoding: true
        ) {
            UserDefaults.standard.set(data, forKey: UserDefaultsKey.serverChangeToken)
        }
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: UserDefaultsKey.lastSyncDate)
    }

    // MARK: - Debug / Reset

    /// Reset all CloudKit state (for debugging)
    public func resetState() {
        serverChangeToken = nil
        lastSyncDate = nil
        isParticipant = false
        participantZoneID = nil

        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.serverChangeToken)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.lastSyncDate)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.migrationCompleted)
        clearParticipantZoneCache()

        logger.info("CloudKit state reset")
    }

    // MARK: - Socialization Exposures (delegated to ExposureCloudService)

    /// Save an exposure to CloudKit
    public func saveExposure(_ exposure: Exposure) async throws {
        try await exposureService.saveExposure(exposure)
    }

    /// Delete an exposure from CloudKit
    public func deleteExposure(_ exposure: Exposure) async throws {
        try await exposureService.deleteExposure(exposure)
    }

    /// Fetch all exposures from CloudKit
    public func fetchAllExposures() async throws -> [Exposure] {
        try await exposureService.fetchAllExposures()
    }
}

// MARK: - Error Types

public enum CloudKitError: LocalizedError {
    case notAvailable
    case saveFailed(String)
    case deleteFailed(String)
    case syncFailed(String)
    case migrationFailed(String)
    case cannotShareAsParticipant

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return Strings.CloudSharing.cloudKitNotAvailable
        case .saveFailed(let message):
            return Strings.CloudSharing.saveFailedMessage(message)
        case .deleteFailed(let message):
            return Strings.CloudSharing.deleteFailedMessage(message)
        case .syncFailed(let message):
            return Strings.CloudSharing.syncFailedMessage(message)
        case .migrationFailed(let message):
            return Strings.CloudSharing.migrationFailedMessage(message)
        case .cannotShareAsParticipant:
            return Strings.CloudSharing.cannotShareAsParticipant
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let cloudKitSyncCompleted = Notification.Name("cloudKitSyncCompleted")
}

// MARK: - Helpers

extension Sequence {
    func uniqued<T: Hashable>(on keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
