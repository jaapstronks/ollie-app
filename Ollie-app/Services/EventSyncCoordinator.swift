//
//  EventSyncCoordinator.swift
//  Ollie-app
//
//  Coordinates CloudKit sync operations for puppy events
//  Extracted from EventStore to separate sync logic from file I/O
//

import Combine
import Foundation
import OllieShared
import os

/// Coordinates CloudKit sync operations for puppy events
/// Handles save, delete, refresh, migration, merge operations, and photo sync
@MainActor
final class EventSyncCoordinator: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var syncError: String?

    private let cloudKit = CloudKitService.shared
    private let logger = Logger.ollie(category: "EventSyncCoordinator")

    private var cancellables = Set<AnyCancellable>()
    private var pendingCloudSaves: [PuppyEvent] = []
    private var pendingCloudDeletes: [PuppyEvent] = []
    private var pendingPhotoUploads: [PuppyEvent] = []

    /// Reference to MediaStore for photo operations
    var mediaStore: MediaStore?

    /// Callback invoked when cloud sync completes and local data should refresh
    var onSyncCompleted: (() async -> Void)?

    /// Callback to update an event's cloudPhotoSynced flag after upload
    var onPhotoSynced: ((UUID) async -> Void)?

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let photoMigrationCompleted = "eventSyncCoordinator.photoMigrationCompleted"
    }

    init() {
        setupCloudKitObservers()
    }

    // MARK: - Setup

    private func setupCloudKitObservers() {
        // Observe CloudKit sync state
        cloudKit.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSyncing)

        cloudKit.$syncError
            .receive(on: DispatchQueue.main)
            .assign(to: &$syncError)

        // Listen for sync completion to refresh local data
        NotificationCenter.default.publisher(for: .cloudKitSyncCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.onSyncCompleted?()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Properties

    var isCloudAvailable: Bool {
        cloudKit.isCloudAvailable
    }

    var isMigrationCompleted: Bool {
        cloudKit.isMigrationCompleted
    }

    // MARK: - Initial Sync

    /// Perform initial sync on app launch
    func initialSync(localEvents: [PuppyEvent]) async {
        await cloudKit.setup()

        // Migrate local data to CloudKit if needed
        if cloudKit.isCloudAvailable && !cloudKit.isMigrationCompleted {
            await migrateLocalEvents(localEvents)
        }

        // Sync from cloud
        do {
            try await cloudKit.sync()
            await onSyncCompleted?()
        } catch {
            logger.warning("Initial sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Cloud Operations

    /// Save event to CloudKit (and upload photo if needed)
    func saveToCloud(_ event: PuppyEvent) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudSaves.append(event)
            if event.needsPhotoUpload {
                pendingPhotoUploads.append(event)
            }
            return
        }

        do {
            try await cloudKit.saveEvent(event)
            pendingCloudSaves.removeAll { $0.id == event.id }

            // Upload photo if event has one that hasn't been synced
            if event.needsPhotoUpload {
                await uploadPhotoForEvent(event)
            }
        } catch {
            logger.warning("Failed to save to cloud, will retry: \(error.localizedDescription)")
            if !pendingCloudSaves.contains(where: { $0.id == event.id }) {
                pendingCloudSaves.append(event)
            }
        }
    }

    /// Upload photo for an event to CloudKit
    private func uploadPhotoForEvent(_ event: PuppyEvent) async {
        guard let photoPath = event.photo,
              let mediaStore = mediaStore,
              let localURL = mediaStore.fullURL(for: photoPath) else {
            return
        }

        do {
            _ = try await cloudKit.uploadPhoto(localURL: localURL, eventId: event.id)
            pendingPhotoUploads.removeAll { $0.id == event.id }

            // Notify that photo was synced so local event can be updated
            await onPhotoSynced?(event.id)

            logger.info("Uploaded photo for event \(event.id)")
        } catch {
            logger.warning("Failed to upload photo: \(error.localizedDescription)")
            if !pendingPhotoUploads.contains(where: { $0.id == event.id }) {
                pendingPhotoUploads.append(event)
            }
        }
    }

    /// Delete event from CloudKit
    func deleteFromCloud(_ event: PuppyEvent) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudDeletes.append(event)
            return
        }

        do {
            try await cloudKit.deleteEvent(event)
            pendingCloudDeletes.removeAll { $0.id == event.id }
        } catch {
            logger.warning("Failed to delete from cloud: \(error.localizedDescription)")
            if !pendingCloudDeletes.contains(where: { $0.id == event.id }) {
                pendingCloudDeletes.append(event)
            }
        }
    }

    /// Fetch events for a date from CloudKit
    func fetchEvents(for date: Date) async throws -> [PuppyEvent] {
        try await cloudKit.fetchEvents(for: date)
    }

    /// Fetch events for a date range from CloudKit
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [PuppyEvent] {
        try await cloudKit.fetchEvents(from: startDate, to: endDate)
    }

    /// Force a full sync with CloudKit
    func forceSync() async {
        guard cloudKit.isCloudAvailable else {
            syncError = "CloudKit niet beschikbaar"
            return
        }

        do {
            try await cloudKit.sync()
            await onSyncCompleted?()
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Retry pending cloud operations
    func retryPendingOperations() async {
        for event in pendingCloudSaves {
            await saveToCloud(event)
        }
        for event in pendingCloudDeletes {
            await deleteFromCloud(event)
        }
        for event in pendingPhotoUploads {
            await uploadPhotoForEvent(event)
        }
    }

    // MARK: - Photo Sync

    /// Download missing photos from CloudKit after sync
    /// Call this with events that have cloudPhotoSynced=true but no local photo file
    func downloadMissingPhotos(for events: [PuppyEvent]) async {
        guard cloudKit.isCloudAvailable, let mediaStore = mediaStore else { return }

        let eventsNeedingDownload = events.filter { event in
            guard let photoPath = event.photo else { return false }
            // Has cloud photo but local file doesn't exist
            return event.cloudPhotoSynced == true && mediaStore.fullURL(for: photoPath) == nil
        }

        guard !eventsNeedingDownload.isEmpty else { return }

        logger.info("Downloading \(eventsNeedingDownload.count) missing photos from cloud")

        for event in eventsNeedingDownload {
            guard let photoPath = event.photo else { continue }
            let destinationURL = mediaStore.cloudDownloadURL(for: event.id, originalPath: photoPath)

            do {
                let downloaded = try await cloudKit.downloadPhoto(eventId: event.id, to: destinationURL)
                if downloaded {
                    // Regenerate thumbnail locally
                    await mediaStore.regenerateThumbnail(for: event.id, photoURL: destinationURL)
                    logger.info("Downloaded photo for event \(event.id)")
                }
            } catch {
                logger.warning("Failed to download photo for event \(event.id): \(error.localizedDescription)")
            }
        }
    }

    /// Migrate existing local photos to CloudKit (one-time operation)
    func migrateExistingPhotos(_ events: [PuppyEvent]) async {
        guard cloudKit.isCloudAvailable else { return }
        guard !UserDefaults.standard.bool(forKey: UserDefaultsKey.photoMigrationCompleted) else {
            return
        }

        let eventsWithUnuploadedPhotos = events.filter { $0.needsPhotoUpload }

        guard !eventsWithUnuploadedPhotos.isEmpty else {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.photoMigrationCompleted)
            return
        }

        logger.info("Migrating \(eventsWithUnuploadedPhotos.count) existing photos to CloudKit")

        for event in eventsWithUnuploadedPhotos {
            await uploadPhotoForEvent(event)
        }

        UserDefaults.standard.set(true, forKey: UserDefaultsKey.photoMigrationCompleted)
        logger.info("Photo migration completed")
    }

    // MARK: - Migration

    /// Migrate local events to CloudKit
    private func migrateLocalEvents(_ events: [PuppyEvent]) async {
        logger.info("Starting local data migration to CloudKit")

        guard !events.isEmpty else {
            logger.info("No local events to migrate")
            return
        }

        do {
            try await cloudKit.migrateLocalEvents(events)
            logger.info("Migration completed: \(events.count) events")
        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Merging

    /// Merge local and cloud events, preferring cloud versions for duplicates
    func mergeEvents(local: [PuppyEvent], cloud: [PuppyEvent]) -> [PuppyEvent] {
        var merged: [UUID: PuppyEvent] = [:]

        for event in local {
            merged[event.id] = event
        }
        for event in cloud {
            merged[event.id] = event
        }

        return Array(merged.values)
    }
}
