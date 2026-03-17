//
//  AssetCloudService.swift
//  OtisShared
//
//  Unified CloudKit service for asset (photo) operations.
//  Replaces MediaCloudService and ProfilePhotoCloudService with a single
//  configuration-based implementation.
//

import CloudKit
import Foundation
import os

// Import sync logging for structured photo logs
// Uses [PHOTO] prefix for easy filtering

// MARK: - Asset Configuration

/// Configuration for different asset types
public struct AssetCloudConfig: Sendable {
    /// CloudKit record type (e.g., "EventMedia", "ProfilePhoto")
    public let recordType: String

    /// Prefix for record names (e.g., "media", "profile-photo")
    public let recordNamePrefix: String

    /// Field name for the entity ID in the record (e.g., "eventId", "profileId")
    public let entityIdFieldName: String

    /// Maximum retry attempts for transient errors
    public let maxRetries: Int

    /// Field name for the photo asset
    public let assetFieldName: String

    public init(
        recordType: String,
        recordNamePrefix: String,
        entityIdFieldName: String,
        maxRetries: Int = 3,
        assetFieldName: String = "photoAsset"
    ) {
        self.recordType = recordType
        self.recordNamePrefix = recordNamePrefix
        self.entityIdFieldName = entityIdFieldName
        self.maxRetries = maxRetries
        self.assetFieldName = assetFieldName
    }

    // MARK: - Preset Configurations

    /// Configuration for event media (photos attached to events)
    public static let eventMedia = AssetCloudConfig(
        recordType: "EventMedia",
        recordNamePrefix: "media",
        entityIdFieldName: "eventId",
        maxRetries: 3
    )

    /// Configuration for profile photos
    public static let profilePhoto = AssetCloudConfig(
        recordType: "ProfilePhoto",
        recordNamePrefix: "profile-photo",
        entityIdFieldName: "profileId",
        maxRetries: 3
    )
}

// MARK: - Upload Result

/// Result of a successful asset upload
public struct AssetUploadResult {
    public let recordID: CKRecord.ID
    public let ownerName: String

    public init(recordID: CKRecord.ID, ownerName: String) {
        self.recordID = recordID
        self.ownerName = ownerName
    }
}

// MARK: - Asset Cloud Service

/// Unified service for CloudKit asset operations
@MainActor
public final class AssetCloudService {
    private let config: AssetCloudConfig
    private let deviceID: String
    private let logger: Logger

    /// Closure to get the current database (private or shared based on participant status)
    private let getDatabase: () -> CKDatabase

    /// Closure to get the current zone ID
    private let getZoneID: () -> CKRecordZone.ID

    /// Closure to check if CloudKit is available
    private let isCloudAvailable: () -> Bool

    /// Closure to get the current user's actual CloudKit record name
    private let getCurrentUserRecordName: () -> String?

    public init(
        config: AssetCloudConfig,
        deviceID: String,
        getDatabase: @escaping () -> CKDatabase,
        getZoneID: @escaping () -> CKRecordZone.ID,
        isCloudAvailable: @escaping () -> Bool,
        getCurrentUserRecordName: @escaping () -> String? = { nil }
    ) {
        self.config = config
        self.deviceID = deviceID
        self.getDatabase = getDatabase
        self.getZoneID = getZoneID
        self.isCloudAvailable = isCloudAvailable
        self.getCurrentUserRecordName = getCurrentUserRecordName
        self.logger = Logger.otis(category: "\(config.recordType)Service")
    }

    // MARK: - Record Name

    /// Generate record name from entity ID
    private func recordName(for entityId: UUID) -> String {
        "\(config.recordNamePrefix)-\(entityId.uuidString)"
    }

    // MARK: - Upload

    /// Upload an asset for an entity to CloudKit
    /// - Parameters:
    ///   - localURL: Local file URL of the asset
    ///   - entityId: UUID of the associated entity
    /// - Returns: Upload result containing the record ID and zone owner name
    public func upload(localURL: URL, entityId: UUID) async throws -> AssetUploadResult {
        let shortID = String(entityId.uuidString.prefix(8))

        guard isCloudAvailable() else {
            logger.info("[PHOTO] [ERROR] [\(shortID)] CloudKit not available for upload")
            throw AssetCloudError.notAvailable
        }

        guard FileManager.default.fileExists(atPath: localURL.path) else {
            logger.info("[PHOTO] [ERROR] [\(shortID)] File not found: \(localURL.lastPathComponent)")
            throw AssetCloudError.fileNotFound(localURL.path)
        }

        logger.info("[PHOTO] [QUEUED] [\(shortID)] Queued \(self.config.recordType) for upload")

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: recordName(for: entityId), zoneID: zoneID)

        // Try to fetch existing record first (for updates)
        let record: CKRecord
        do {
            record = try await getDatabase().record(for: recordID)
            logger.info("[PHOTO] [UPLOADING] [\(shortID)] Updating existing \(self.config.recordType)")
        } catch let error as CKError where error.code == .unknownItem {
            // Create new record
            record = CKRecord(recordType: config.recordType, recordID: recordID)
            logger.info("[PHOTO] [UPLOADING] [\(shortID)] Creating new \(self.config.recordType)")
        }

        // Set record fields
        let asset = CKAsset(fileURL: localURL)
        record[config.assetFieldName] = asset
        record[config.entityIdFieldName] = entityId.uuidString as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue
        record["uploadedAt"] = Date() as CKRecordValue

        let database = getDatabase()

        // Save with retry for transient errors
        return try await saveRecordWithRetry(record, to: database, zoneID: zoneID, entityId: entityId)
    }

    /// Save a record with automatic retry for transient errors
    private func saveRecordWithRetry(
        _ record: CKRecord,
        to database: CKDatabase,
        zoneID: CKRecordZone.ID,
        entityId: UUID,
        currentRetry: Int = 0
    ) async throws -> AssetUploadResult {
        let shortID = String(entityId.uuidString.prefix(8))

        do {
            let savedRecord = try await database.save(record)
            // Use actual user record name, not __defaultOwner__ which is device-relative
            let actualOwnerName = getCurrentUserRecordName() ?? zoneID.ownerName
            logger.info("[PHOTO] [UPLOADED] [\(shortID)] Confirmed \(self.config.recordType)")
            return AssetUploadResult(recordID: savedRecord.recordID, ownerName: actualOwnerName)
        } catch let error as CKError {
            // Check if this is a retryable transient error
            if isRetryableError(error) && currentRetry < config.maxRetries {
                // Get retry delay from error or use exponential backoff
                let delay = error.retryAfterSeconds ?? Double(pow(2.0, Double(currentRetry)))
                logger.warning("[PHOTO] [RETRY] [\(shortID)] Attempt \(currentRetry + 1)/\(self.config.maxRetries): \(error.localizedDescription)")

                try await Task.sleep(for: .seconds(delay))

                return try await saveRecordWithRetry(
                    record,
                    to: database,
                    zoneID: zoneID,
                    entityId: entityId,
                    currentRetry: currentRetry + 1
                )
            }

            logger.error("[PHOTO] [ERROR] [\(shortID)] Upload failed after \(currentRetry) retries: \(error.localizedDescription)")
            throw AssetCloudError.uploadFailed(error.localizedDescription)
        }
    }

    /// Check if a CKError is a transient error that should be retried
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

    /// Download an asset from CloudKit
    /// - Parameters:
    ///   - entityId: UUID of the associated entity
    ///   - destinationURL: Local URL where the asset should be saved
    ///   - ownerName: Optional CloudKit zone owner name. Required when downloading from a shared zone.
    /// - Returns: True if download was successful
    public func download(entityId: UUID, to destinationURL: URL, ownerName: String? = nil) async throws -> Bool {
        let shortID = String(entityId.uuidString.prefix(8))

        guard isCloudAvailable() else {
            logger.info("[PHOTO] [ERROR] [\(shortID)] CloudKit not available for download")
            throw AssetCloudError.notAvailable
        }

        // Determine if this is the user's own data or shared data
        let currentUserRecordName = getCurrentUserRecordName()
        let isOwnData = ownerName == nil ||
                        ownerName == CKCurrentUserDefaultName ||
                        ownerName == currentUserRecordName

        let database: CKDatabase
        let zoneID: CKRecordZone.ID

        if isOwnData {
            // Own data - use private database with default zone
            database = getDatabase()
            zoneID = getZoneID()
            logger.info("[PHOTO] [DOWNLOADING] [\(shortID)] Fetching \(self.config.recordType) from private zone")
        } else {
            // Asset is from another user - use shared database with their zone
            database = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis").sharedCloudDatabase
            zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: ownerName!)
            logger.info("[PHOTO] [DOWNLOADING] [\(shortID)] Fetching \(self.config.recordType) from shared zone")
        }

        let recordID = CKRecord.ID(recordName: recordName(for: entityId), zoneID: zoneID)

        do {
            let record = try await database.record(for: recordID)

            guard let asset = record[config.assetFieldName] as? CKAsset,
                  let assetURL = asset.fileURL else {
                logger.warning("[PHOTO] [ERROR] [\(shortID)] No asset found in record")
                return false
            }

            // Save to destination
            try saveFile(from: assetURL, to: destinationURL)

            logger.info("[PHOTO] [DOWNLOADED] [\(shortID)] Saved \(self.config.recordType)")
            return true

        } catch let error as CKError {
            if error.code == .unknownItem {
                logger.info("[PHOTO] [CACHED] [\(shortID)] No cloud \(self.config.recordType) found")
                return false
            }
            logger.error("[PHOTO] [ERROR] [\(shortID)] Download failed: \(error.localizedDescription)")
            throw AssetCloudError.downloadFailed(error.localizedDescription)
        }
    }

    // MARK: - Check Existence

    /// Check if an asset exists in CloudKit for an entity
    public func exists(entityId: UUID) async throws -> Bool {
        guard isCloudAvailable() else {
            return false
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: recordName(for: entityId), zoneID: zoneID)
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

    /// Delete an asset from CloudKit
    public func delete(entityId: UUID) async throws {
        guard isCloudAvailable() else {
            throw AssetCloudError.notAvailable
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: recordName(for: entityId), zoneID: zoneID)
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted \(self.config.recordType) for entity \(entityId)")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw AssetCloudError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Batch Operations

    /// Fetch all entity IDs that have assets in CloudKit
    public func fetchAllEntityIds() async throws -> [UUID] {
        guard isCloudAvailable() else {
            return []
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: config.recordType, predicate: predicate)

        let database = getDatabase()
        let zoneID = getZoneID()

        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

            var entityIds: [UUID] = []
            for (_, result) in results {
                if case .success(let record) = result,
                   let entityIdString = record[config.entityIdFieldName] as? String,
                   let entityId = UUID(uuidString: entityIdString) {
                    entityIds.append(entityId)
                }
            }

            return entityIds
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return []
            }
            throw error
        }
    }
}

// MARK: - Error Types

public enum AssetCloudError: LocalizedError {
    case notAvailable
    case fileNotFound(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "CloudKit is not available"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .uploadFailed(let message):
            return "Failed to upload: \(message)"
        case .downloadFailed(let message):
            return "Failed to download: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        }
    }
}
