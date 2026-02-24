//
//  MasteredSkillsCloudService.swift
//  OllieShared
//
//  Handles CloudKit operations for mastered skills
//

import Foundation
import CloudKit
import os

/// Handles CloudKit operations for mastered skills
@MainActor
public final class MasteredSkillsCloudService {
    private let recordType = "MasteredSkill"
    private let deviceID: String
    private let logger = Logger.ollie(category: "MasteredSkillsCloudService")

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

    /// Save a mastered skill to CloudKit
    public func saveMasteredSkill(_ skill: MasteredSkill) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let record = createRecord(from: skill, in: getZoneID())
        let database = getDatabase()

        do {
            _ = try await database.save(record)
            logger.info("Saved mastered skill to CloudKit: \(skill.skillId)")
        } catch let error as CKError {
            logger.error("Failed to save mastered skill: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    /// Save multiple mastered skills (batch)
    public func saveMasteredSkills(_ skills: [MasteredSkill]) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        guard !skills.isEmpty else { return }

        let records = skills.map { createRecord(from: $0, in: getZoneID()) }
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

        logger.info("Batch saved \(successCount)/\(skills.count) mastered skills to CloudKit")
    }

    // MARK: - Delete

    /// Delete a mastered skill from CloudKit
    public func deleteMasteredSkill(_ skill: MasteredSkill) async throws {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let recordID = CKRecord.ID(recordName: skill.id.uuidString, zoneID: getZoneID())
        let database = getDatabase()

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("Deleted mastered skill from CloudKit: \(skill.skillId)")
        } catch let error as CKError {
            if error.code != .unknownItem {
                throw CloudKitError.deleteFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Fetch

    /// Fetch all mastered skills from CloudKit
    public func fetchAllMasteredSkills() async throws -> [MasteredSkill] {
        guard isCloudAvailable() else {
            throw CloudKitError.notAvailable
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "masteredAt", ascending: false)]

        let database = getDatabase()
        let zoneID = getZoneID()

        do {
            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)

            var skills: [MasteredSkill] = []
            for (_, result) in results {
                if case .success(let record) = result,
                   let skill = createSkill(from: record) {
                    skills.append(skill)
                }
            }

            return skills.uniqued(on: \.skillId)
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return []
            }
            throw error
        }
    }

    // MARK: - Record Conversion

    private func createRecord(from skill: MasteredSkill, in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: skill.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["localId"] = skill.id.uuidString as CKRecordValue
        record["skillId"] = skill.skillId as CKRecordValue
        record["masteredAt"] = skill.masteredAt as CKRecordValue
        record["modifiedAt"] = skill.modifiedAt as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue

        return record
    }

    private func createSkill(from record: CKRecord) -> MasteredSkill? {
        guard let skillId = record["skillId"] as? String,
              let masteredAt = record["masteredAt"] as? Date else {
            return nil
        }

        let id: UUID
        if let localIdString = record["localId"] as? String,
           let localId = UUID(uuidString: localIdString) {
            id = localId
        } else {
            id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        }

        let modifiedAt = record["modifiedAt"] as? Date ?? masteredAt

        return MasteredSkill(
            id: id,
            skillId: skillId,
            masteredAt: masteredAt,
            modifiedAt: modifiedAt
        )
    }
}
