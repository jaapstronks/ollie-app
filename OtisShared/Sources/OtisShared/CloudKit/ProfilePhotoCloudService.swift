//
//  ProfilePhotoCloudService.swift
//  OtisShared
//
//  Handles CloudKit operations for profile photos using CKAsset
//

import Foundation
import CloudKit
import os

/// Handles CloudKit operations for profile photos using CKAsset
@MainActor
public final class ProfilePhotoCloudService {
    private let profilePhotoRecordType = "ProfilePhoto"
    private let deviceID: String
    private let logger = Logger.otis(category: "ProfilePhotoCloudService")

    /// Closure to get the current database (private or shared based on participant status)
    private let getDatabase: () -> CKDatabase

    /// Closure to get the current zone ID
    private let getZoneID: () -> CKRecordZone.ID

    /// Closure to check if CloudKit is available
    private let isCloudAvailable: () -> Bool

    public init(
        deviceID: String,
        getDatabase: @escaping () -> CKDatabase,
        getZoneID: @escaping () -> CKRecordZone.ID,
        isCloudAvailable: @escaping () -> Bool
    ) {
        self.deviceID = deviceID
        self.getDatabase = getDatabase
        self.getZoneID = getZoneID
        self.isCloudAvailable = isCloudAvailable
    }

    // MARK: - Upload

    /// Upload a profile photo to CloudKit
    /// - Parameters:
    ///   - localURL: Local file URL of the photo
    ///   - profileId: UUID of the associated PuppyProfile
    /// - Returns: The CloudKit record ID of the uploaded photo
    public func uploadPhoto(localURL: URL, profileId: UUID) async throws -> CKRecord.ID {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        guard FileManager.default.fileExists(atPath: localURL.path) else {
            throw ProfilePhotoCloudError.fileNotFound(localURL.path)
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "profile-photo-\(profileId.uuidString)", zoneID: zoneID)

        // Try to fetch existing record first to update it
        let record: CKRecord
        do {
            record = try await getDatabase().record(for: recordID)
            logger.info("Updating existing profile photo record for profile \(profileId)")
        } catch let error as CKError where error.code == .unknownItem {
            // Create new record
            record = CKRecord(recordType: profilePhotoRecordType, recordID: recordID)
            logger.info("Creating new profile photo record for profile \(profileId)")
        }

        let asset = CKAsset(fileURL: localURL)
        record["photoAsset"] = asset
        record["profileId"] = profileId.uuidString as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue
        record["uploadedAt"] = Date() as CKRecordValue

        let database = getDatabase()

        do {
            let savedRecord = try await database.save(record)
            logger.info("Uploaded profile photo for profile \(profileId)")
            return savedRecord.recordID
        } catch let error as CKError {
            logger.error("Failed to upload profile photo: \(error.localizedDescription)")
            throw ProfilePhotoCloudError.uploadFailed(error.localizedDescription)
        }
    }

    // MARK: - Download

    /// Download a profile photo from CloudKit
    /// - Parameters:
    ///   - profileId: UUID of the associated PuppyProfile
    ///   - destinationURL: Local URL where the photo should be saved
    /// - Returns: True if download was successful
    public func downloadPhoto(profileId: UUID, to destinationURL: URL) async throws -> Bool {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "profile-photo-\(profileId.uuidString)", zoneID: zoneID)
        let database = getDatabase()

        do {
            let record = try await database.record(for: recordID)

            guard let asset = record["photoAsset"] as? CKAsset,
                  let assetURL = asset.fileURL else {
                logger.warning("No photo asset found for profile \(profileId)")
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

            logger.info("Downloaded profile photo for profile \(profileId)")
            return true

        } catch let error as CKError {
            if error.code == .unknownItem {
                logger.info("No cloud profile photo found for profile \(profileId)")
                return false
            }
            logger.error("Failed to download profile photo: \(error.localizedDescription)")
            throw ProfilePhotoCloudError.downloadFailed(error.localizedDescription)
        }
    }

    // MARK: - Check Existence

    /// Check if a profile photo exists in CloudKit
    public func photoExists(profileId: UUID) async throws -> Bool {
        guard isCloudAvailable() else {
            return false
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "profile-photo-\(profileId.uuidString)", zoneID: zoneID)
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

    /// Delete a profile photo from CloudKit
    public func deletePhoto(profileId: UUID) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "profile-photo-\(profileId.uuidString)", zoneID: zoneID)
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted profile photo for profile \(profileId)")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw ProfilePhotoCloudError.deleteFailed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Error Types

public enum ProfilePhotoCloudError: LocalizedError {
    case fileNotFound(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Profile photo file not found: \(path)"
        case .uploadFailed(let message):
            return "Failed to upload profile photo: \(message)"
        case .downloadFailed(let message):
            return "Failed to download profile photo: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete profile photo: \(message)"
        }
    }
}
