//
//  WalkSpotCloudService.swift
//  OllieShared
//
//  Handles CloudKit operations for walk spots
//  Extracted from CloudKitService to separate spot logic
//

import Foundation
import CloudKit
import os

/// Handles CloudKit operations for walk spots
@MainActor
public final class WalkSpotCloudService {
    private let spotRecordType = "WalkSpot"
    private let deviceID: String
    private let logger = Logger.ollie(category: "WalkSpotCloudService")

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

    /// Save a spot to CloudKit
    public func saveSpot(_ spot: WalkSpot) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let record = createSpotRecord(from: spot, in: getZoneID())
        let database = getDatabase()

        do {
            _ = try await database.save(record)
            logger.info("Saved spot to CloudKit: \(spot.name)")
        } catch let error as CKError {
            logger.error("Failed to save spot: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    /// Save multiple spots (batch)
    public func saveSpots(_ spots: [WalkSpot]) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        guard !spots.isEmpty else { return }

        let records = spots.map { createSpotRecord(from: $0, in: getZoneID()) }
        let database = getDatabase()

        let (saveResults, _) = try await database.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .changedKeys
        )

        let successCount = saveResults.values.filter { result in
            if case .success = result { return true }
            return false
        }.count

        logger.info("Batch saved \(successCount)/\(spots.count) spots to CloudKit")
    }

    // MARK: - Delete

    /// Delete a spot from CloudKit
    public func deleteSpot(_ spot: WalkSpot) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let recordID = CKRecord.ID(recordName: spot.id.uuidString, zoneID: getZoneID())
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted spot from CloudKit: \(spot.id)")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw CloudKitError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Fetch

    /// Fetch all spots from CloudKit
    public func fetchAllSpots() async throws -> [WalkSpot] {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: spotRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let spots = try await fetchSpotsFromDatabase(getDatabase(), query: query, zoneID: getZoneID())
        return spots.uniqued(on: \.id)
    }

    private func fetchSpotsFromDatabase(_ database: CKDatabase, query: CKQuery, zoneID: CKRecordZone.ID) async throws -> [WalkSpot] {
        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

            var spots: [WalkSpot] = []
            for (_, result) in results {
                if case .success(let record) = result,
                   let spot = createSpot(from: record) {
                    spots.append(spot)
                }
            }

            return spots
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return []
            }
            throw error
        }
    }

    // MARK: - Record Conversion

    private func createSpotRecord(from spot: WalkSpot, in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: spot.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: spotRecordType, recordID: recordID)

        record["localId"] = spot.id.uuidString as CKRecordValue
        record["name"] = spot.name as CKRecordValue
        record["latitude"] = spot.latitude as CKRecordValue
        record["longitude"] = spot.longitude as CKRecordValue
        record["createdAt"] = spot.createdAt as CKRecordValue
        record["modifiedAt"] = spot.modifiedAt as CKRecordValue
        record["isFavorite"] = (spot.isFavorite ? 1 : 0) as CKRecordValue
        record["visitCount"] = spot.visitCount as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue

        if let notes = spot.notes {
            record["notes"] = notes as CKRecordValue
        }

        return record
    }

    private func createSpot(from record: CKRecord) -> WalkSpot? {
        guard let name = record["name"] as? String,
              let latitude = record["latitude"] as? Double,
              let longitude = record["longitude"] as? Double else {
            return nil
        }

        let id: UUID
        if let localIdString = record["localId"] as? String,
           let localId = UUID(uuidString: localIdString) {
            id = localId
        } else {
            id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        }

        let createdAt = record["createdAt"] as? Date ?? Date()
        let modifiedAt = record["modifiedAt"] as? Date ?? createdAt
        let isFavorite = (record["isFavorite"] as? Int ?? 0) != 0
        let visitCount = record["visitCount"] as? Int ?? 1

        return WalkSpot(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            isFavorite: isFavorite,
            notes: record["notes"] as? String,
            visitCount: visitCount
        )
    }
}
