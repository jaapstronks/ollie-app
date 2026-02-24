//
//  MedicationCompletionCloudService.swift
//  OllieShared
//
//  Handles CloudKit operations for medication completions
//

import Foundation
import CloudKit
import os

/// Handles CloudKit operations for medication completions
@MainActor
public final class MedicationCompletionCloudService {
    private let recordType = "MedicationCompletion"
    private let deviceID: String
    private let logger = Logger.ollie(category: "MedicationCompletionCloudService")

    /// Closure to get the current database
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

    /// Save a completion to CloudKit
    public func saveCompletion(_ completion: MedicationCompletion) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let record = createRecord(from: completion, in: getZoneID())
        let database = getDatabase()

        do {
            _ = try await database.save(record)
            logger.info("Saved medication completion to CloudKit")
        } catch let error as CKError {
            logger.error("Failed to save completion: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    /// Save multiple completions (batch)
    public func saveCompletions(_ completions: [MedicationCompletion]) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        guard !completions.isEmpty else { return }

        let records = completions.map { createRecord(from: $0, in: getZoneID()) }
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

        logger.info("Batch saved \(successCount)/\(completions.count) completions to CloudKit")
    }

    // MARK: - Delete

    /// Delete a completion from CloudKit
    public func deleteCompletion(_ completion: MedicationCompletion) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let recordID = CKRecord.ID(recordName: completion.id.uuidString, zoneID: getZoneID())
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted completion from CloudKit")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw CloudKitError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Fetch

    /// Fetch all completions from CloudKit
    public func fetchAllCompletions() async throws -> [MedicationCompletion] {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        let database = getDatabase()
        let zoneID = getZoneID()

        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

            var completions: [MedicationCompletion] = []
            for (_, result) in results {
                if case .success(let record) = result,
                   let completion = createCompletion(from: record) {
                    completions.append(completion)
                }
            }

            return completions.uniqued(on: \.id)
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return []
            }
            throw error
        }
    }

    // MARK: - Record Conversion

    private func createRecord(from completion: MedicationCompletion, in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: completion.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["localId"] = completion.id.uuidString as CKRecordValue
        record["medicationId"] = completion.medicationId.uuidString as CKRecordValue
        record["timeId"] = completion.timeId.uuidString as CKRecordValue
        record["date"] = completion.date as CKRecordValue
        record["completedAt"] = completion.completedAt as CKRecordValue
        record["modifiedAt"] = completion.modifiedAt as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue

        return record
    }

    private func createCompletion(from record: CKRecord) -> MedicationCompletion? {
        guard let medicationIdString = record["medicationId"] as? String,
              let medicationId = UUID(uuidString: medicationIdString),
              let timeIdString = record["timeId"] as? String,
              let timeId = UUID(uuidString: timeIdString),
              let date = record["date"] as? Date,
              let completedAt = record["completedAt"] as? Date else {
            return nil
        }

        let id: UUID
        if let localIdString = record["localId"] as? String,
           let localId = UUID(uuidString: localIdString) {
            id = localId
        } else {
            id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        }

        let modifiedAt = record["modifiedAt"] as? Date ?? completedAt

        return MedicationCompletion(
            id: id,
            medicationId: medicationId,
            timeId: timeId,
            date: date,
            completedAt: completedAt,
            modifiedAt: modifiedAt
        )
    }
}
