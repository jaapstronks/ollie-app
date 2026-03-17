//
//  CKRecordConvertible.swift
//  OtisShared
//
//  Protocol for converting between Core Data entities and CKRecords.
//  This enables CKSyncEngine to sync data without tight coupling to Core Data.
//
//  Key principles:
//  - Store CKRecord system fields (for conflict detection)
//  - Use record name = entity UUID for consistent mapping
//  - Handle relationships via CKRecord.Reference
//

import CloudKit
import CoreData
import Foundation

// MARK: - CKRecord Convertible Protocol

/// Protocol for entities that can be synced via CKSyncEngine
public protocol CKRecordConvertible {
    /// The CloudKit record type name (typically matches entity name)
    static var recordType: String { get }

    /// The entity's unique identifier (used as CKRecord.ID.recordName)
    var syncIdentifier: String { get }

    /// The zone this record belongs to
    var syncZoneID: CKRecordZone.ID { get }

    /// Stored CKRecord system fields (for conflict resolution)
    /// This should be persisted in Core Data as Data
    var ckRecordSystemFields: Data? { get set }

    /// Convert this entity to a CKRecord for upload
    func toCKRecord() -> CKRecord

    /// Update this entity from a fetched CKRecord
    mutating func update(from record: CKRecord)
}

// MARK: - CKRecord Convertible Extensions

public extension CKRecordConvertible {
    /// Generate the CKRecord.ID for this entity
    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: syncIdentifier, zoneID: syncZoneID)
    }

    /// Create or restore a CKRecord with proper system fields
    /// - If we have stored system fields, restore the record from them
    /// - Otherwise, create a new record
    func createOrRestoreCKRecord() -> CKRecord {
        if let systemFields = ckRecordSystemFields,
           let coder = try? NSKeyedUnarchiver(forReadingFrom: systemFields) {
            coder.requiresSecureCoding = true
            if let record = CKRecord(coder: coder) {
                coder.finishDecoding()
                return record
            }
        }

        // No stored system fields - create new record
        return CKRecord(recordType: Self.recordType, recordID: recordID)
    }

    /// Encode CKRecord system fields for storage
    static func encodeSystemFields(from record: CKRecord) -> Data? {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        return coder.encodedData
    }
}

// MARK: - CKRecord Extensions

public extension CKRecord {
    /// Convenience for setting optional string values
    func setString(_ value: String?, forKey key: String) {
        self[key] = value as CKRecordValue?
    }

    /// Convenience for setting optional Date values
    func setDate(_ value: Date?, forKey key: String) {
        self[key] = value as CKRecordValue?
    }

    /// Convenience for setting optional Int values
    func setInt(_ value: Int?, forKey key: String) {
        if let value = value {
            self[key] = value as CKRecordValue
        } else {
            self[key] = nil
        }
    }

    /// Convenience for setting optional Double values
    func setDouble(_ value: Double?, forKey key: String) {
        if let value = value {
            self[key] = value as CKRecordValue
        } else {
            self[key] = nil
        }
    }

    /// Convenience for setting optional Bool values
    func setBool(_ value: Bool?, forKey key: String) {
        if let value = value {
            self[key] = (value ? 1 : 0) as CKRecordValue
        } else {
            self[key] = nil
        }
    }

    /// Convenience for setting Data as raw bytes (for small binary data < 1MB)
    /// Use this for config/settings data. Use setAsset() for large files like images.
    func setData(_ value: Data?, forKey key: String) {
        self[key] = value as CKRecordValue?
    }

    /// Convenience for setting Data as CKAsset (for large binary data like images)
    func setAsset(_ data: Data?, forKey key: String) {
        guard let data = data else {
            self[key] = nil
            return
        }

        // Write to temp file for CKAsset
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            self[key] = CKAsset(fileURL: fileURL)
        } catch {
            // Failed to write - skip this asset
            self[key] = nil
        }
    }

    /// Convenience for getting optional string
    func string(forKey key: String) -> String? {
        self[key] as? String
    }

    /// Convenience for getting optional Date
    func date(forKey key: String) -> Date? {
        self[key] as? Date
    }

    /// Convenience for getting optional Int
    func int(forKey key: String) -> Int? {
        self[key] as? Int
    }

    /// Convenience for getting optional Double
    func double(forKey key: String) -> Double? {
        self[key] as? Double
    }

    /// Convenience for getting optional Bool
    func bool(forKey key: String) -> Bool? {
        guard let value = self[key] as? Int else { return nil }
        return value != 0
    }

    /// Convenience for getting raw bytes Data (for small binary data stored as BYTES)
    /// Use this for config/settings data. Use assetData() for large files like images.
    func data(forKey key: String) -> Data? {
        self[key] as? Data
    }

    /// Convenience for getting Data from CKAsset (for large binary data like images)
    func assetData(forKey key: String) -> Data? {
        guard let asset = self[key] as? CKAsset,
              let fileURL = asset.fileURL else {
            return nil
        }
        return try? Data(contentsOf: fileURL)
    }

    /// Convenience for getting a reference's record name
    func referenceRecordName(forKey key: String) -> String? {
        guard let reference = self[key] as? CKRecord.Reference else { return nil }
        return reference.recordID.recordName
    }
}

// MARK: - Sync Change Tracking

/// Tracks pending changes for sync
public struct PendingSyncChange: Equatable, Hashable {
    public enum ChangeType: Equatable, Hashable {
        case save
        case delete
    }

    public let recordID: CKRecord.ID
    public let changeType: ChangeType

    public init(recordID: CKRecord.ID, changeType: ChangeType) {
        self.recordID = recordID
        self.changeType = changeType
    }
}

// MARK: - Sync Result

/// Result of a sync operation
public enum SyncResult {
    case success
    case partialSuccess(saved: Int, failed: Int)
    case failure(Error)
}
