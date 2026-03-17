//
//  MediaSyncHandlers.swift
//  OtisShared
//
//  Sync handlers for media records (photos stored separately from entities).
//  ProfilePhoto and EventMedia are download-only via CKSyncEngine.
//  Uploads are handled directly via AssetCloudService.
//

import CloudKit
import CoreData
import Foundation
import os

// MARK: - Profile Photo Sync Handler

/// Handles syncing of ProfilePhoto records (profile photos stored separately from profiles)
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class ProfilePhotoSyncHandler: EntitySyncHandler, @unchecked Sendable {
    public static let recordType = "ProfilePhoto"

    private let logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "ProfilePhotoSyncHandler")

    public init() {}

    @MainActor
    public func fetchRecord(
        for identifier: String,
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async -> CKRecord? {
        // ProfilePhoto records are download-only via CKSyncEngine
        // Uploads are handled directly via ProfilePhotoCloudService
        return nil
    }

    @MainActor
    public func handleFetchedRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext,
        isShared: Bool,
        targetStore: NSPersistentStore? = nil
    ) async {
        // Extract profileId from the record
        guard let profileIdString = record["profileId"] as? String,
              let profileId = UUID(uuidString: profileIdString) else {
            logger.warning("ProfilePhoto record missing profileId")
            return
        }

        // Get the photo asset
        guard let photoAsset = record["photoAsset"] as? CKAsset,
              let assetURL = photoAsset.fileURL else {
            logger.warning("ProfilePhoto record missing photoAsset for profile \(profileIdString)")
            return
        }

        // Save photo to local storage
        guard let documentsURL = getDocumentsDirectory() else {
            logger.error("Could not get documents directory")
            return
        }

        let profilePhotosDir = documentsURL.appendingPathComponent(Constants.profilePhotosDirectoryName, isDirectory: true)

        do {
            try ensureDirectoryExists(at: profilePhotosDir)
        } catch {
            logger.error("Failed to create profile photos directory: \(error.localizedDescription)")
            return
        }

        // Use a consistent filename format: {profileId}.jpg
        let filename = "\(profileId.uuidString).jpg"
        let destinationURL = profilePhotosDir.appendingPathComponent(filename)

        // Copy from CloudKit cache to local storage (overwriting any existing file)
        do {
            try saveFile(from: assetURL, to: destinationURL)
            logger.info("Saved profile photo from ProfilePhoto record for profile \(profileIdString)")

            // Update the corresponding profile's photo filename
            if let profile = fetchEntity(entityName: "CDPuppyProfile", id: profileId, in: context) {
                let currentFilename = profile.value(forKey: "profilePhotoFilename") as? String
                if currentFilename != filename {
                    profile.setValue(filename, forKey: "profilePhotoFilename")
                    logger.info("Updated profile \(profileIdString) with profile photo filename: \(filename)")
                }
            }
        } catch {
            logger.error("Failed to save profile photo for profile \(profileIdString): \(error.localizedDescription)")
        }
    }

    @MainActor
    public func handleDeletedRecord(
        recordID: String,
        in context: NSManagedObjectContext
    ) async {
        // Extract profileId from record name (format: "profile-photo-{profileId}")
        guard recordID.hasPrefix("profile-photo-") else {
            logger.warning("Invalid ProfilePhoto record name format: \(recordID)")
            return
        }

        let uuidString = String(recordID.dropFirst("profile-photo-".count))
        guard let profileId = UUID(uuidString: uuidString) else {
            logger.warning("Could not parse profile ID from record name: \(recordID)")
            return
        }

        // Delete local photo file
        deleteLocalProfilePhoto(for: profileId)
    }

    private func deleteLocalProfilePhoto(for profileId: UUID) {
        guard let documentsURL = getDocumentsDirectory() else { return }

        let profilePhotosDir = documentsURL.appendingPathComponent(Constants.profilePhotosDirectoryName, isDirectory: true)
        let filename = "\(profileId.uuidString).jpg"
        let photoURL = profilePhotosDir.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: photoURL.path) {
            try? FileManager.default.removeItem(at: photoURL)
            logger.info("Deleted local profile photo for profile \(profileId.uuidString)")
        }
    }

    @MainActor
    public func handleSentRecord(_ record: CKRecord, in context: NSManagedObjectContext) async {
        // No-op for ProfilePhoto - uploads handled directly
    }

    @MainActor
    public func handleZonePurge(zoneID: CKRecordZone.ID, in context: NSManagedObjectContext) async {
        // When a zone is purged, we could delete photos associated with profiles in that zone
        // For now, no-op as this is complex to track
    }

    @MainActor
    public func handleAccountSignOut(in context: NSManagedObjectContext) async {
        // Profile photos retained locally - they might be re-synced
        logger.info("Account sign out - profile photos retained locally")
    }

    @MainActor
    public func handleEncryptedDataReset(zoneID: CKRecordZone.ID, in context: NSManagedObjectContext) async {
        // No-op - profile photos will be re-fetched automatically
    }
}

// MARK: - Event Media Sync Handler

/// Handles syncing of EventMedia records (photos stored separately from events)
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class EventMediaSyncHandler: EntitySyncHandler, @unchecked Sendable {
    public static let recordType = "EventMedia"

    private let logger = Logger(subsystem: "nl.jaapstronks.Otis", category: "EventMediaSyncHandler")

    public init() {}

    @MainActor
    public func fetchRecord(
        for identifier: String,
        zoneID: CKRecordZone.ID,
        in context: NSManagedObjectContext
    ) async -> CKRecord? {
        // EventMedia records are download-only, we don't upload them via this handler
        return nil
    }

    @MainActor
    public func handleFetchedRecord(
        _ record: CKRecord,
        in context: NSManagedObjectContext,
        isShared: Bool,
        targetStore: NSPersistentStore? = nil
    ) async {
        // Extract eventId from the record
        guard let eventIdString = record["eventId"] as? String,
              let eventId = UUID(uuidString: eventIdString) else {
            logger.warning("EventMedia record missing eventId")
            return
        }

        // Get the photo asset
        guard let photoAsset = record["photoAsset"] as? CKAsset,
              let assetURL = photoAsset.fileURL else {
            logger.warning("EventMedia record missing photoAsset for event \(eventIdString)")
            return
        }

        // Save photo to local storage
        guard let documentsURL = getDocumentsDirectory() else {
            logger.error("Could not get documents directory")
            return
        }

        let mediaDir = documentsURL.appendingPathComponent(Constants.mediaDirectoryName, isDirectory: true)

        do {
            try ensureDirectoryExists(at: mediaDir)
        } catch {
            logger.error("Failed to create media directory: \(error.localizedDescription)")
            return
        }

        let filename = "\(eventId.uuidString).jpg"
        let destinationURL = mediaDir.appendingPathComponent(filename)
        let relativePath = "\(Constants.mediaDirectoryName)/\(filename)"

        // Skip if file already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            logger.debug("Photo already exists locally for event \(eventIdString)")
            return
        }

        // Copy from CloudKit cache to local storage
        do {
            try saveFile(from: assetURL, to: destinationURL)
            logger.info("Saved photo from EventMedia for event \(eventIdString)")

            // Update the corresponding event's photo path
            if let event = fetchEntity(entityName: "CDPuppyEvent", id: eventId, in: context) {
                event.setValue(relativePath, forKey: "photo")
                logger.info("Updated event \(eventIdString) with photo path")
            }
        } catch {
            logger.error("Failed to save photo for event \(eventIdString): \(error.localizedDescription)")
        }
    }

    @MainActor
    public func handleDeletedRecord(
        recordID: String,
        in context: NSManagedObjectContext
    ) async {
        // Extract eventId from record name (format: "media-{eventId}")
        guard recordID.hasPrefix("media-"),
              let eventIdString = recordID.split(separator: "-").last,
              let eventId = UUID(uuidString: String(eventIdString)) else {
            return
        }

        // Delete local photo file
        guard let documentsURL = getDocumentsDirectory() else { return }

        let mediaDir = documentsURL.appendingPathComponent(Constants.mediaDirectoryName, isDirectory: true)
        let filename = "\(eventId.uuidString).jpg"
        let photoURL = mediaDir.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: photoURL.path) {
            try? FileManager.default.removeItem(at: photoURL)
            logger.info("Deleted local photo for event \(eventIdString)")
        }
    }

    @MainActor
    public func handleSentRecord(_ record: CKRecord, in context: NSManagedObjectContext) async {
        // No-op for EventMedia
    }

    @MainActor
    public func handleZonePurge(zoneID: CKRecordZone.ID, in context: NSManagedObjectContext) async {
        // No-op - we don't delete all photos on zone purge
    }

    @MainActor
    public func handleAccountSignOut(in context: NSManagedObjectContext) async {
        // No-op
    }

    @MainActor
    public func handleEncryptedDataReset(zoneID: CKRecordZone.ID, in context: NSManagedObjectContext) async {
        // No-op
    }
}

// MARK: - Handler Registration Helper

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public extension SyncCoordinator {

    /// Register all entity sync handlers
    func registerAllHandlers() {
        // Core entities
        let profileHandler = ProfileSyncHandler()
        let eventHandler = EventSyncHandler()
        registerHandler(profileHandler)
        registerHandler(eventHandler)

        // Legacy record type aliases (for records created with different naming)
        registerHandler(profileHandler, forRecordType: "CDPuppyProfile")
        registerHandler(eventHandler, forRecordType: "CDPuppyEvent")

        // Media (separate from events - photos stored as EventMedia records)
        registerHandler(EventMediaSyncHandler())
        registerHandler(ProfilePhotoSyncHandler())

        // Profile-related
        registerHandler(WeightMeasurementSyncHandler())
        registerHandler(MilestoneSyncHandler())
        registerHandler(DocumentSyncHandler())
        registerHandler(DogAppointmentSyncHandler())
        registerHandler(UserIdentitySyncHandler())
        registerHandler(UserSentimentCheckInSyncHandler())

        // Training
        registerHandler(MasteredSkillSyncHandler())
        registerHandler(SkillProgressSyncHandler())
        registerHandler(RegressionLogSyncHandler())
        registerHandler(ExposureSyncHandler())
        registerHandler(ComfortableItemSyncHandler())
        registerHandler(EarlyMilestoneSyncHandler())

        // Care
        registerHandler(MedicationCompletionSyncHandler())
        registerHandler(RoutineItemSyncHandler())
        registerHandler(WeightGoalSyncHandler())
        registerHandler(BodyConditionScoreSyncHandler())
        registerHandler(GroomingActivitySyncHandler())
        registerHandler(EnrichmentActivitySyncHandler())

        // Locations/Contacts
        registerHandler(DogContactSyncHandler())
        registerHandler(WalkSpotSyncHandler())

        // Cache (optional - may not need to sync)
        registerHandler(AICacheSyncHandler())

        // Exploration
        registerHandler(ExploredTileSyncHandler())
    }
}
