//
//  MediaCloudService.swift
//  OllieShared
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
    private let logger = Logger.ollie(category: "MediaCloudService")

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

    /// Upload a photo for an event to CloudKit
    /// - Parameters:
    ///   - localURL: Local file URL of the photo
    ///   - eventId: UUID of the associated PuppyEvent
    /// - Returns: The CloudKit record ID of the uploaded media
    public func uploadPhoto(localURL: URL, eventId: UUID) async throws -> CKRecord.ID {
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

        do {
            let savedRecord = try await database.save(record)
            logger.info("Uploaded photo for event \(eventId)")
            return savedRecord.recordID
        } catch let error as CKError {
            logger.error("Failed to upload photo: \(error.localizedDescription)")
            throw MediaCloudError.uploadFailed(error.localizedDescription)
        }
    }

    // MARK: - Download

    /// Download a photo from CloudKit
    /// - Parameters:
    ///   - eventId: UUID of the associated PuppyEvent
    ///   - destinationURL: Local URL where the photo should be saved
    /// - Returns: True if download was successful
    public func downloadPhoto(eventId: UUID, to destinationURL: URL) async throws -> Bool {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let zoneID = getZoneID()
        let recordID = CKRecord.ID(recordName: "media-\(eventId.uuidString)", zoneID: zoneID)
        let database = getDatabase()

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
