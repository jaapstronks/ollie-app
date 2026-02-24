//
//  ProfileCloudService.swift
//  OllieShared
//
//  Handles CloudKit operations for PuppyProfile
//  Stores profile as JSON data for simplicity with complex nested structures
//

import Foundation
import CloudKit
import os

/// Handles CloudKit operations for the puppy profile
@MainActor
public final class ProfileCloudService {
    private let profileRecordType = "PuppyProfile"
    private let deviceID: String
    private let logger = Logger.ollie(category: "ProfileCloudService")

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

    // MARK: - Save

    /// Save a profile to CloudKit
    public func saveProfile(_ profile: PuppyProfile) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let record = try createProfileRecord(from: profile, in: getZoneID())
        let database = getDatabase()

        do {
            _ = try await database.save(record)
            logger.info("Saved profile to CloudKit: \(profile.name)")
        } catch let error as CKError {
            logger.error("Failed to save profile: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Fetch

    /// Fetch the profile from CloudKit
    /// Returns nil if no profile exists in the cloud
    public func fetchProfile() async throws -> PuppyProfile? {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: profileRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

        let database = getDatabase()
        let zoneID = getZoneID()

        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID, resultsLimit: 1)

            for (_, result) in results {
                if case .success(let record) = result,
                   let profile = try? createProfile(from: record) {
                    return profile
                }
            }

            return nil
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return nil
            }
            logger.error("Failed to fetch profile: \(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete

    /// Delete the profile from CloudKit
    public func deleteProfile(_ profile: PuppyProfile) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let recordID = CKRecord.ID(recordName: "profile-\(profile.id.uuidString)", zoneID: getZoneID())
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted profile from CloudKit")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw CloudKitError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Record Conversion

    private func createProfileRecord(from profile: PuppyProfile, in zoneID: CKRecordZone.ID) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "profile-\(profile.id.uuidString)", zoneID: zoneID)
        let record = CKRecord(recordType: profileRecordType, recordID: recordID)

        // Store basic fields for querying and conflict resolution
        record["profileId"] = profile.id.uuidString as CKRecordValue
        record["name"] = profile.name as CKRecordValue
        record["modifiedAt"] = profile.modifiedAt as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue

        // Store the entire profile as JSON data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(profile)
        record["profileData"] = jsonData as CKRecordValue

        return record
    }

    private func createProfile(from record: CKRecord) throws -> PuppyProfile {
        guard let jsonData = record["profileData"] as? Data else {
            throw ProfileCloudError.missingProfileData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PuppyProfile.self, from: jsonData)
    }
}

// MARK: - Error Types

public enum ProfileCloudError: LocalizedError {
    case missingProfileData
    case encodingFailed(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingProfileData:
            return "Profile data missing from CloudKit record"
        case .encodingFailed(let message):
            return "Failed to encode profile: \(message)"
        case .decodingFailed(let message):
            return "Failed to decode profile: \(message)"
        }
    }
}
