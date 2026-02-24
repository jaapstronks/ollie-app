//
//  ExposureCloudService.swift
//  OllieShared
//
//  Handles CloudKit operations for socialization exposures
//  Extracted from CloudKitService to separate exposure logic
//

import Foundation
import CloudKit
import os

/// Handles CloudKit operations for socialization exposures
@MainActor
public final class ExposureCloudService {
    private let exposureRecordType = "SocializationExposure"
    private let deviceID: String
    private let logger = Logger.ollie(category: "ExposureCloudService")

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

    /// Save an exposure to CloudKit
    public func saveExposure(_ exposure: Exposure) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let record = createExposureRecord(from: exposure, in: getZoneID())
        let database = getDatabase()

        do {
            _ = try await database.save(record)
            logger.info("Saved exposure to CloudKit: \(exposure.itemId)")
        } catch let error as CKError {
            logger.error("Failed to save exposure: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete

    /// Delete an exposure from CloudKit
    public func deleteExposure(_ exposure: Exposure) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let recordID = CKRecord.ID(recordName: exposure.id.uuidString, zoneID: getZoneID())
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted exposure from CloudKit: \(exposure.id)")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw CloudKitError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Fetch

    /// Fetch all exposures from CloudKit
    public func fetchAllExposures() async throws -> [Exposure] {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: exposureRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "exposureDate", ascending: false)]

        let exposures = try await fetchExposuresFromDatabase(getDatabase(), query: query, zoneID: getZoneID())
        return exposures.uniqued(on: \.id)
    }

    private func fetchExposuresFromDatabase(_ database: CKDatabase, query: CKQuery, zoneID: CKRecordZone.ID) async throws -> [Exposure] {
        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

            var exposures: [Exposure] = []
            for (_, result) in results {
                if case .success(let record) = result,
                   let exposure = createExposure(from: record) {
                    exposures.append(exposure)
                }
            }

            return exposures
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return []
            }
            throw error
        }
    }

    // MARK: - Record Conversion

    private func createExposureRecord(from exposure: Exposure, in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: exposure.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: exposureRecordType, recordID: recordID)

        record["localId"] = exposure.id.uuidString as CKRecordValue
        record["itemId"] = exposure.itemId as CKRecordValue
        record["exposureDate"] = exposure.date as CKRecordValue
        record["distance"] = exposure.distance.rawValue as CKRecordValue
        record["reaction"] = exposure.reaction.rawValue as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue
        record["createdAt"] = exposure.createdAt as CKRecordValue
        record["modifiedAt"] = exposure.modifiedAt as CKRecordValue

        if let note = exposure.note {
            record["note"] = note as CKRecordValue
        }

        return record
    }

    private func createExposure(from record: CKRecord) -> Exposure? {
        guard let itemId = record["itemId"] as? String,
              let exposureDate = record["exposureDate"] as? Date,
              let distanceRaw = record["distance"] as? String,
              let distance = ExposureDistance(rawValue: distanceRaw),
              let reactionRaw = record["reaction"] as? String,
              let reaction = SocializationReaction(rawValue: reactionRaw) else {
            return nil
        }

        let id: UUID
        if let localIdString = record["localId"] as? String,
           let localId = UUID(uuidString: localIdString) {
            id = localId
        } else {
            id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        }

        let createdAt = record["createdAt"] as? Date ?? exposureDate
        let modifiedAt = record["modifiedAt"] as? Date ?? exposureDate

        return Exposure(
            id: id,
            itemId: itemId,
            date: exposureDate,
            distance: distance,
            reaction: reaction,
            note: record["note"] as? String,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

