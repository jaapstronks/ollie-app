//
//  MediaCloudService.swift
//  OtisShared
//
//  Handles CloudKit operations for photo assets using CKAsset
//

import Foundation
import CloudKit
import os

/// Handles CloudKit operations for photo media using CKAsset
@MainActor
public final class MediaCloudService {
    private let mediaRecordType = "EventMedia"
    private let deviceID: String
    private let logger = Logger.otis(category: "MediaCloudService")

    /// Closure to get the current database (private or shared based on participant status)
    private let getDatabase: () -> CKDatabase

    /// Closure to get the current zone ID
    private let getZoneID: () -> CKRecordZone.ID

    /// Closure to check if CloudKit is available
    private let isCloudAvailable: () -> Bool

    /// Closure to get the current user's actual CloudKit record name
    private let getCurrentUserRecordName: () -> String?

    public init(
        deviceID: String,
        getDatabase: @escaping () -> CKDatabase,
        getZoneID: @escaping () -> CKRecordZone.ID,
        isCloudAvailable: @escaping () -> Bool,
        getCurrentUserRecordName: @escaping () -> String? = { nil }
    ) {
        self.deviceID = deviceID
        self.getDatabase = getDatabase
        self.getZoneID = getZoneID
        self.isCloudAvailable = isCloudAvailable
        self.getCurrentUserRecordName = getCurrentUserRecordName
    }

    // MARK: - Upload

    /// Result of a successful photo upload
    public struct UploadResult {
        public let recordID: CKRecord.ID
        public let ownerName: String
    }

    /// Upload a photo for an event to CloudKit
    /// - Parameters:
    ///   - localURL: Local file URL of the photo
    ///   - eventId: UUID of the associated PuppyEvent
    /// - Returns: Upload result containing the record ID and zone owner name
    public func uploadPhoto(localURL: URL, eventId: UUID) async throws -> UploadResult {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        guard FileManager.default.fileExists(atPath: localURL.path) else {
            throw MediaCloudError.fileNotFound(localURL.path)
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "media-\(eventId.uuidString)", zoneID: zoneID)
        let record = CKRecord(recordType: mediaRecordType, recordID: recordID)

        let asset = CKAsset(fileURL: localURL)
        record["photoAsset"] = asset
        record["eventId"] = eventId.uuidString as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue
        record["uploadedAt"] = Date() as CKRecordValue

        let database = getDatabase()

        // Since we bypass CKSyncEngine for media uploads, we need to handle
        // transient errors manually with retry logic
        return try await saveRecordWithRetry(record, to: database, zoneID: zoneID, eventId: eventId)
    }

    /// Save a record with automatic retry for transient errors
    /// CKSyncEngine handles these automatically, but since we use direct database saves
    /// for media, we need to handle retries ourselves
    private func saveRecordWithRetry(
        _ record: CKRecord,
        to database: CKDatabase,
        zoneID: CKRecordZone.ID,
        eventId: UUID,
        maxRetries: Int = 3,
        currentRetry: Int = 0
    ) async throws -> UploadResult {
        do {
            let savedRecord = try await database.save(record)
            // Use actual user record name, not __defaultOwner__ which is device-relative
            let actualOwnerName = getCurrentUserRecordName() ?? zoneID.ownerName
            logger.info("Uploaded photo for event \(eventId), owner: \(actualOwnerName)")
            return UploadResult(recordID: savedRecord.recordID, ownerName: actualOwnerName)
        } catch let error as CKError {
            // Check if this is a retryable transient error
            if isRetryableError(error) && currentRetry < maxRetries {
                // Get retry delay from error or use exponential backoff
                let delay = error.retryAfterSeconds ?? Double(pow(2.0, Double(currentRetry)))
                logger.warning("Retryable error uploading photo (attempt \(currentRetry + 1)/\(maxRetries)): \(error.localizedDescription). Retrying in \(delay)s")

                try await Task.sleep(for: .seconds(delay))

                return try await saveRecordWithRetry(
                    record,
                    to: database,
                    zoneID: zoneID,
                    eventId: eventId,
                    maxRetries: maxRetries,
                    currentRetry: currentRetry + 1
                )
            }

            logger.error("Failed to upload photo after \(currentRetry) retries: \(error.localizedDescription)")
            throw MediaCloudError.uploadFailed(error.localizedDescription)
        }
    }

    /// Check if a CKError is a transient error that should be retried
    /// These are the same errors that CKSyncEngine handles automatically
    private func isRetryableError(_ error: CKError) -> Bool {
        switch error.code {
        case .networkFailure,
             .networkUnavailable,
             .zoneBusy,
             .serviceUnavailable,
             .requestRateLimited,
             .operationCancelled:
            return true
        default:
            return false
        }
    }

    // MARK: - Download

    /// Download a photo from CloudKit
    /// - Parameters:
    ///   - eventId: UUID of the associated PuppyEvent
    ///   - destinationURL: Local URL where the photo should be saved
    ///   - ownerName: Optional CloudKit zone owner name. If provided, uses this to construct the zone ID.
    ///                This is required when downloading photos uploaded by a different user (partner sharing).
    /// - Returns: True if download was successful
    public func downloadPhoto(eventId: UUID, to destinationURL: URL, ownerName: String? = nil) async throws -> Bool {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        // Determine if this is the user's own data or shared data
        // This affects both database and zone selection
        let currentUserRecordName = getCurrentUserRecordName()
        let isOwnData = ownerName == nil ||
                        ownerName == CKCurrentUserDefaultName ||
                        ownerName == currentUserRecordName

        let database: CKDatabase
        let zoneID: CKRecordZone.ID

        if isOwnData {
            // Own data - use private database with default zone
            // IMPORTANT: Private database uses CKCurrentUserDefaultName, not actual user record name
            database = getDatabase()
            zoneID = getZoneID()
            logger.debug("Downloading photo for event \(eventId) from own private zone")
        } else {
            // Photo is from another user - use shared database with their zone
            database = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis").sharedCloudDatabase
            zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: ownerName!)
            logger.debug("Downloading photo for event \(eventId) from shared zone owned by \(ownerName!)")
        }

        let recordID = CKRecord.ID(recordName: "media-\(eventId.uuidString)", zoneID: zoneID)

        do {
            let record = try await database.record(for: recordID)

            guard let asset = record["photoAsset"] as? CKAsset,
                  let assetURL = asset.fileURL else {
                logger.warning("No photo asset found for event \(eventId)")
                return false
            }

            // Copy the downloaded file to destination
            let fileManager = FileManager.default

            // Ensure destination directory exists
            let destinationDir = destinationURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: destinationDir.path) {
                try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            }

            // Remove existing file if any
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            // Copy from CloudKit cache to destination
            try fileManager.copyItem(at: assetURL, to: destinationURL)

            logger.info("Downloaded photo for event \(eventId)")
            return true

        } catch let error as CKError {
            if error.code == .unknownItem {
                logger.info("No cloud photo found for event \(eventId)")
                return false
            }
            logger.error("Failed to download photo: \(error.localizedDescription)")
            throw MediaCloudError.downloadFailed(error.localizedDescription)
        }
    }

    // MARK: - Check Existence

    /// Check if a photo exists in CloudKit for an event
    public func photoExists(eventId: UUID) async throws -> Bool {
        guard isCloudAvailable() else {
            return false
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "media-\(eventId.uuidString)", zoneID: zoneID)
        let database = getDatabase()

        do {
            _ = try await database.record(for: recordID)
            return true
        } catch let error as CKError {
            if error.code == .unknownItem {
                return false
            }
            throw error
        }
    }

    // MARK: - Delete

    /// Delete a photo from CloudKit
    public func deletePhoto(eventId: UUID) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "media-\(eventId.uuidString)", zoneID: zoneID)
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted photo for event \(eventId)")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw MediaCloudError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Batch Operations

    /// Fetch all event IDs that have photos in CloudKit
    public func fetchAllPhotoEventIds() async throws -> [UUID] {
        guard isCloudAvailable() else {
            return []
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: mediaRecordType, predicate: predicate)

        let database = getDatabase()
        let zoneID = getZoneID()

        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

            var eventIds: [UUID] = []
            for (_, result) in results {
                if case .success(let record) = result,
                   let eventIdString = record["eventId"] as? String,
                   let eventId = UUID(uuidString: eventIdString) {
                    eventIds.append(eventId)
                }
            }

            return eventIds
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return []
            }
            throw error
        }
    }
}

// MARK: - Error Types

public enum MediaCloudError: LocalizedError {
    case fileNotFound(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Photo file not found: \(path)"
        case .uploadFailed(let message):
            return "Failed to upload photo: \(message)"
        case .downloadFailed(let message):
            return "Failed to download photo: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete photo: \(message)"
        }
    }
}
