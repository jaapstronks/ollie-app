//
//  PhotoSyncService.swift
//  Otis-app
//
//  Coordinates photo sync between local storage and CloudKit
//  - Upload: Automatically uploads photos when events are saved
//  - Download: On-demand download when viewing photos not available locally
//

import Foundation
import OtisShared
import os

/// Coordinates bidirectional photo sync with CloudKit
@Observable
@MainActor
final class PhotoSyncService {
    static let shared = PhotoSyncService()

    // MARK: - State

    private(set) var pendingUploads: Set<UUID> = []
    private(set) var pendingDownloads: Set<UUID> = []
    private(set) var failedUploads: Set<UUID> = []
    private(set) var activeDownloads: Set<UUID> = []

    // MARK: - Configuration

    @ObservationIgnored private let maxConcurrentUploads = 5
    @ObservationIgnored private let retryDelay: TimeInterval = 30
    @ObservationIgnored private let maxRetryAttempts = 3

    // MARK: - Private State

    @ObservationIgnored private let logger = Logger.otis(category: "PhotoSyncService")
    @ObservationIgnored private let mediaStore = MediaStore()
    @ObservationIgnored private var retryAttempts: [UUID: Int] = [:]
    @ObservationIgnored private var uploadTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var downloadTasks: [UUID: Task<Bool, Never>] = [:]

    private init() {}

    // MARK: - Upload Operations

    /// Upload a photo for an event to CloudKit
    /// Called automatically after saving an event with a photo
    func uploadPhoto(for event: PuppyEvent) {
        guard let photoPath = event.photo,
              !(event.cloudPhotoSynced ?? false) else {
            return
        }

        // Only upload if the file exists locally
        // If file doesn't exist, this is likely a synced event from another user
        // that needs download, not upload
        guard mediaStore.photoExists(for: photoPath) else {
            logger.debug("Skipping upload for event \(event.id) - photo file not found locally (likely needs download)")
            return
        }

        // Don't start duplicate uploads
        guard !pendingUploads.contains(event.id),
              uploadTasks[event.id] == nil else {
            return
        }

        pendingUploads.insert(event.id)
        failedUploads.remove(event.id)

        let eventId = event.id
        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.performUpload(eventId: eventId, photoPath: photoPath)
        }
        uploadTasks[event.id] = task
    }

    /// Upload all pending photos from events
    /// Call this on app launch to sync any missed uploads
    func uploadPendingPhotos(events: [PuppyEvent]) {
        let eventsNeedingUpload = events.filter { $0.needsPhotoUpload }

        guard !eventsNeedingUpload.isEmpty else {
            logger.debug("No pending photo uploads")
            return
        }

        logger.info("Starting upload of \(eventsNeedingUpload.count) pending photos")

        // Limit concurrent uploads
        let eventsToUpload = Array(eventsNeedingUpload.prefix(maxConcurrentUploads))
        for event in eventsToUpload {
            uploadPhoto(for: event)
        }
    }

    /// Retry failed uploads
    /// Call this when app returns to foreground
    func retryFailedUploads() {
        let failedIds = Array(failedUploads)
        guard !failedIds.isEmpty else { return }

        logger.info("Retrying \(failedIds.count) failed photo uploads")

        for eventId in failedIds {
            if let attempts = retryAttempts[eventId], attempts >= maxRetryAttempts {
                logger.warning("Max retry attempts reached for event \(eventId)")
                continue
            }
            // Post notification to request event refetch and retry
            NotificationCenter.default.post(
                name: .photoUploadRetryRequested,
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
    }

    /// Retry upload for a specific event (called after event is refetched)
    func retryUpload(for event: PuppyEvent) {
        guard failedUploads.contains(event.id) else { return }
        failedUploads.remove(event.id)
        uploadPhoto(for: event)
    }

    /// Perform the initial sync on app launch
    /// Uploads any photos that haven't been synced yet
    /// Also logs diagnostics about photos that may have sync issues
    func performInitialSync(events: [PuppyEvent]) {
        uploadPendingPhotos(events: events)

        // Diagnostic: Log events that are marked as synced but missing local files
        // These will fail to display and need to be downloaded from CloudKit
        let syncedButMissingLocal = events.filter {
            $0.photo != nil &&
            ($0.cloudPhotoSynced ?? false) &&
            !mediaStore.photoExists(for: $0.photo!)
        }

        if !syncedButMissingLocal.isEmpty {
            logger.info("Found \(syncedButMissingLocal.count) events marked as synced but missing local photo files")
            for event in syncedButMissingLocal.prefix(5) {
                logger.debug("  - Event \(event.id): cloudPhotoSynced=\(event.cloudPhotoSynced ?? false), owner=\(event.cloudPhotoOwner ?? "nil")")
            }
            if syncedButMissingLocal.count > 5 {
                logger.debug("  ... and \(syncedButMissingLocal.count - 5) more")
            }
        }
    }

    // MARK: - Migration

    /// Backfill cloudPhotoOwner for existing synced photos
    /// This is needed for photos uploaded before the owner tracking was added
    /// Only the profile owner should run this (not participants)
    func migrateExistingPhotos(events: [PuppyEvent], ownerName: String) {
        let eventsNeedingMigration = events.filter {
            $0.cloudPhotoSynced == true && $0.cloudPhotoOwner == nil && $0.photo != nil
        }

        guard !eventsNeedingMigration.isEmpty else {
            logger.debug("No photos need owner migration")
            return
        }

        logger.info("Migrating \(eventsNeedingMigration.count) photos to add owner info")

        for event in eventsNeedingMigration {
            // Post notification to update the event with owner info
            NotificationCenter.default.post(
                name: .photoOwnerMigrationNeeded,
                object: nil,
                userInfo: [
                    "eventId": event.id,
                    "ownerName": ownerName
                ]
            )
        }
    }

    // MARK: - Download Operations

    /// Download a photo from CloudKit for an event
    /// Returns true if download succeeded, false otherwise
    @discardableResult
    func downloadPhoto(for event: PuppyEvent) async -> Bool {
        guard let photoPath = event.photo,
              (event.cloudPhotoSynced ?? false) else {
            return false
        }

        // Check if already downloading
        if activeDownloads.contains(event.id) {
            // Wait for existing download
            if let existingTask = downloadTasks[event.id] {
                return await existingTask.value
            }
            return false
        }

        // Check if file already exists locally
        if mediaStore.photoExists(for: photoPath) {
            return true
        }

        activeDownloads.insert(event.id)
        pendingDownloads.insert(event.id)

        let ownerName = event.cloudPhotoOwner
        let task = Task<Bool, Never> { [weak self] in
            guard let self = self else { return false }
            let result = await self.performDownload(eventId: event.id, photoPath: photoPath, ownerName: ownerName)
            return result
        }
        downloadTasks[event.id] = task

        let result = await task.value

        activeDownloads.remove(event.id)
        pendingDownloads.remove(event.id)
        downloadTasks.removeValue(forKey: event.id)

        return result
    }

    /// Check if a photo is currently being downloaded
    func isDownloading(eventId: UUID) -> Bool {
        activeDownloads.contains(eventId)
    }

    // MARK: - Delete Operations

    /// Delete a photo from CloudKit when an event is deleted
    func deletePhoto(for event: PuppyEvent) async {
        guard event.cloudPhotoSynced == true else {
            return
        }

        do {
            try await CloudKitService.shared.deletePhoto(eventId: event.id)
            logger.info("Deleted cloud photo for event \(event.id)")
        } catch {
            logger.error("Failed to delete cloud photo for event \(event.id): \(error.localizedDescription)")
            // Non-critical error - the event is already deleted locally
        }
    }

    // MARK: - Private Upload Implementation

    private func performUpload(eventId: UUID, photoPath: String) async {
        guard let localURL = mediaStore.fullURL(for: photoPath) else {
            logger.error("Could not resolve photo path: \(photoPath)")
            handleUploadFailure(eventId: eventId)
            return
        }

        guard CloudKitService.shared.isCloudAvailable else {
            logger.debug("CloudKit not available, deferring upload for event \(eventId)")
            handleUploadFailure(eventId: eventId, shouldRetry: true)
            return
        }

        do {
            let result = try await CloudKitService.shared.uploadPhoto(localURL: localURL, eventId: eventId)

            // Mark as synced
            pendingUploads.remove(eventId)
            uploadTasks.removeValue(forKey: eventId)
            retryAttempts.removeValue(forKey: eventId)

            // Update the event's cloudPhotoSynced flag AND store the owner name
            // The owner name is critical for partners to download the photo later
            NotificationCenter.default.post(
                name: .photoUploadCompleted,
                object: nil,
                userInfo: [
                    "eventId": eventId,
                    "ownerName": result.ownerName
                ]
            )

            logger.info("Successfully uploaded photo for event \(eventId), owner: \(result.ownerName)")

        } catch {
            logger.error("Upload failed for event \(eventId): \(error.localizedDescription)")
            handleUploadFailure(eventId: eventId, shouldRetry: true)
        }
    }

    private func handleUploadFailure(eventId: UUID, shouldRetry: Bool = false) {
        pendingUploads.remove(eventId)
        uploadTasks.removeValue(forKey: eventId)

        let currentAttempts = (retryAttempts[eventId] ?? 0) + 1
        retryAttempts[eventId] = currentAttempts

        if shouldRetry && currentAttempts < maxRetryAttempts {
            failedUploads.insert(eventId)
            // Schedule retry
            Task {
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                // The retry will be triggered by retryFailedUploads on foreground
            }
        } else {
            failedUploads.insert(eventId)
        }
    }

    // MARK: - Private Download Implementation

    private func performDownload(eventId: UUID, photoPath: String, ownerName: String?) async -> Bool {
        let destinationURL = mediaStore.cloudDownloadURL(for: eventId, originalPath: photoPath)

        guard CloudKitService.shared.isCloudAvailable else {
            logger.debug("CloudKit not available for download of event \(eventId)")
            return false
        }

        do {
            // Pass the owner name so we can fetch from the correct CloudKit zone
            // This is essential for partner photo sharing
            let success = try await CloudKitService.shared.downloadPhoto(
                eventId: eventId,
                to: destinationURL,
                ownerName: ownerName
            )

            if success {
                // Regenerate thumbnail after download
                await mediaStore.regenerateThumbnail(for: eventId, photoURL: destinationURL)

                // Clear image cache for this path to force reload
                await ImageCache.shared.removeImage(relativePath: photoPath)

                logger.info("Successfully downloaded photo for event \(eventId)")
                return true
            } else {
                // Photo record doesn't exist in CloudKit - mark as not synced
                // This happens when event was synced with cloudPhotoSynced=true but the
                // EventMedia record was never uploaded or was deleted
                logger.warning("Download returned false for event \(eventId) - marking as not cloud synced")
                notifyPhotoNotFoundInCloud(eventId: eventId)
                return false
            }

        } catch {
            logger.error("Download failed for event \(eventId): \(error.localizedDescription)")
            return false
        }
    }

    /// Notify that a photo was not found in CloudKit and the event should be updated
    private func notifyPhotoNotFoundInCloud(eventId: UUID) {
        NotificationCenter.default.post(
            name: .photoNotFoundInCloud,
            object: nil,
            userInfo: ["eventId": eventId]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let photoUploadCompleted = Notification.Name("photoUploadCompleted")
    static let photoUploadRetryRequested = Notification.Name("photoUploadRetryRequested")
    static let photoOwnerMigrationNeeded = Notification.Name("photoOwnerMigrationNeeded")
    static let photoNotFoundInCloud = Notification.Name("photoNotFoundInCloud")
}
