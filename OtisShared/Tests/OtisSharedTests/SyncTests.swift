//
//  SyncTests.swift
//  OtisSharedTests
//
//  Unit tests for CloudKit sync utilities and helpers.
//  Tests that can run without a real Core Data stack or CloudKit connection.
//

import CloudKit
import XCTest

@testable import OtisShared

final class SyncTests: XCTestCase {

    // MARK: - UUID Extraction Tests

    func testExtractUUID_FromRecordName() {
        let uuid = UUID()
        let recordName = "CD_CDPuppyProfile:\(uuid.uuidString)"

        let extracted = extractUUID(from: recordName)

        XCTAssertEqual(extracted, uuid)
    }

    func testExtractUUID_FromBareUUID() {
        let uuid = UUID()

        let extracted = extractUUID(from: uuid.uuidString)

        XCTAssertEqual(extracted, uuid)
    }

    func testExtractUUID_FromEventRecordName() {
        let uuid = UUID()
        let recordName = "CD_CDPuppyEvent:\(uuid.uuidString)"

        let extracted = extractUUID(from: recordName)

        XCTAssertEqual(extracted, uuid)
    }

    func testExtractUUID_InvalidString_ReturnsNewUUID() {
        let extracted = extractUUID(from: "not-a-valid-uuid")

        // Should return a new UUID (not crash)
        XCTAssertNotNil(extracted)
    }

    func testExtractUUID_EmptyAfterColon_ReturnsNewUUID() {
        let extracted = extractUUID(from: "CD_CDPuppyProfile:")

        // Should return a new UUID (not crash)
        XCTAssertNotNil(extracted)
    }

    // MARK: - System Fields Encoding Tests

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testEncodeSystemFields_ProducesData() {
        let zoneID = CKRecordZone.ID(zoneName: "test-zone", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: "Test:123", zoneID: zoneID)
        let record = CKRecord(recordType: "TestType", recordID: recordID)

        let encoded = encodeSystemFields(from: record)

        XCTAssertNotNil(encoded)
        XCTAssertGreaterThan(encoded?.count ?? 0, 0)
    }

    // MARK: - Record Restoration Tests

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testRestoreOrCreateRecord_NoSystemFields_CreatesNew() {
        let zoneID = CKRecordZone.ID(zoneName: "test-zone", ownerName: CKCurrentUserDefaultName)
        let expectedName = "CD_CDPuppyProfile:12345678-1234-1234-1234-123456789012"

        let record = restoreOrCreateRecord(
            systemFields: nil,
            expectedRecordName: expectedName,
            recordType: "CD_CDPuppyProfile",
            zoneID: zoneID
        )

        XCTAssertEqual(record.recordID.recordName, expectedName)
        XCTAssertEqual(record.recordType, "CD_CDPuppyProfile")
        XCTAssertEqual(record.recordID.zoneID, zoneID)
    }

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testRestoreOrCreateRecord_WithSystemFields_Restores() {
        let zoneID = CKRecordZone.ID(zoneName: "test-zone", ownerName: CKCurrentUserDefaultName)
        let uuid = UUID()
        let expectedName = "CD_CDPuppyProfile:\(uuid.uuidString)"

        // Create original record and encode its system fields
        let recordID = CKRecord.ID(recordName: expectedName, zoneID: zoneID)
        let original = CKRecord(recordType: "CD_CDPuppyProfile", recordID: recordID)
        let systemFields = encodeSystemFields(from: original)

        // Restore from system fields
        let restored = restoreOrCreateRecord(
            systemFields: systemFields,
            expectedRecordName: expectedName,
            recordType: "CD_CDPuppyProfile",
            zoneID: zoneID
        )

        XCTAssertEqual(restored.recordID.recordName, expectedName)
        XCTAssertEqual(restored.recordType, "CD_CDPuppyProfile")
    }

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testRestoreOrCreateRecord_MismatchedName_CallsOnMismatch() {
        let zoneID = CKRecordZone.ID(zoneName: "test-zone", ownerName: CKCurrentUserDefaultName)
        let originalUUID = UUID()
        let newUUID = UUID()

        // Create record with one UUID
        let originalName = "CD_CDPuppyProfile:\(originalUUID.uuidString)"
        let recordID = CKRecord.ID(recordName: originalName, zoneID: zoneID)
        let original = CKRecord(recordType: "CD_CDPuppyProfile", recordID: recordID)
        let systemFields = encodeSystemFields(from: original)

        // Try to restore with different expected name
        var onMismatchCalled = false
        let expectedName = "CD_CDPuppyProfile:\(newUUID.uuidString)"

        let record = restoreOrCreateRecord(
            systemFields: systemFields,
            expectedRecordName: expectedName,
            recordType: "CD_CDPuppyProfile",
            zoneID: zoneID,
            onMismatch: {
                onMismatchCalled = true
            }
        )

        XCTAssertTrue(onMismatchCalled)
        XCTAssertEqual(record.recordID.recordName, expectedName)  // Should create new with expected name
    }

    // MARK: - Test Fixture ID Tests

    func testTestProfileID_IsValidUUID() {
        XCTAssertNotNil(testProfileID)
        XCTAssertTrue(testProfileID.uuidString.hasPrefix("TEST0000"))
    }

    func testTestEventIDs_AreUnique() {
        let ids = TestEventID.allCases.map { $0.uuid }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All test event IDs should be unique")
    }

    func testTestEventIDs_HaveTestPrefix() {
        for testEvent in TestEventID.allCases {
            XCTAssertTrue(
                testEvent.rawValue.hasPrefix("TEST0000"),
                "\(testEvent) should have TEST0000 prefix"
            )
        }
    }

    func testTestEventIDs_MapToCorrectEventTypes() {
        XCTAssertEqual(TestEventID.pee.eventType, "plassen")
        XCTAssertEqual(TestEventID.poop.eventType, "poepen")
        XCTAssertEqual(TestEventID.meal.eventType, "eten")
        XCTAssertEqual(TestEventID.nap.eventType, "slapen")
        XCTAssertEqual(TestEventID.walk.eventType, "uitlaten")
        XCTAssertEqual(TestEventID.training.eventType, "training")
        XCTAssertEqual(TestEventID.moment.eventType, "moment")
        XCTAssertEqual(TestEventID.weight.eventType, "gewicht")
    }

    // MARK: - Sync Logging Tests

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testIsTestRecord_DetectsTestPrefix() {
        let testRecord = "TEST0000-1234-5678-9012-345678901234"
        let regularRecord = "ABCD1234-1234-5678-9012-345678901234"

        XCTAssertTrue(isTestRecord(testRecord))
        XCTAssertFalse(isTestRecord(regularRecord))
    }

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testIsTestRecord_DetectsEmbeddedTestPrefix() {
        let recordName = "CD_CDPuppyProfile:TEST0000-0000-0000-0000-PROFILE00001"

        XCTAssertTrue(isTestRecord(recordName))
    }

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testLogPredicate_ForRecordID() {
        let predicate = logPredicate(forRecordID: "12345678-1234-5678-9012-345678901234")

        XCTAssertTrue(predicate.contains("[12345678]"))
        XCTAssertTrue(predicate.contains("nl.jaapstronks.Otis"))
    }

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testLogPredicate_ForPhase() {
        let predicate = logPredicate(forPhase: .send)

        XCTAssertTrue(predicate.contains("[SEND]"))
        XCTAssertTrue(predicate.contains("nl.jaapstronks.Otis"))
    }

    // MARK: - SyncPhase Tests

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testSyncPhase_RawValues() {
        XCTAssertEqual(SyncPhase.queue.rawValue, "QUEUE")
        XCTAssertEqual(SyncPhase.send.rawValue, "SEND")
        XCTAssertEqual(SyncPhase.sent.rawValue, "SENT")
        XCTAssertEqual(SyncPhase.receive.rawValue, "RECV")
        XCTAssertEqual(SyncPhase.apply.rawValue, "APPLY")
        XCTAssertEqual(SyncPhase.conflict.rawValue, "CONFLICT")
        XCTAssertEqual(SyncPhase.error.rawValue, "ERROR")
        XCTAssertEqual(SyncPhase.delete.rawValue, "DELETE")
        XCTAssertEqual(SyncPhase.photo.rawValue, "PHOTO")
    }

    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testSyncDatabase_RawValues() {
        XCTAssertEqual(SyncDatabase.privateDB.rawValue, "PRIV")
        XCTAssertEqual(SyncDatabase.sharedDB.rawValue, "SHARED")
    }

    // MARK: - File System Helpers Tests

    func testGetDocumentsDirectory_ReturnsValidURL() {
        let url = getDocumentsDirectory()

        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.contains("Documents") ?? false)
    }
}

// MARK: - CKRecord Extension Tests

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
final class CKRecordExtensionTests: XCTestCase {

    private var record: CKRecord!
    private let zoneID = CKRecordZone.ID(zoneName: "test-zone", ownerName: CKCurrentUserDefaultName)

    override func setUp() {
        super.setUp()
        let recordID = CKRecord.ID(recordName: "test-record", zoneID: zoneID)
        record = CKRecord(recordType: "TestRecord", recordID: recordID)
    }

    func testSetString_NilValue_DoesNotCrash() {
        record.setString(nil, forKey: "test")
        // Should not crash
        XCTAssertNil(record["test"])
    }

    func testSetDate_NilValue_DoesNotCrash() {
        record.setDate(nil, forKey: "test")
        XCTAssertNil(record["test"])
    }

    func testSetInt_NilValue_DoesNotCrash() {
        record.setInt(nil, forKey: "test")
        XCTAssertNil(record["test"])
    }

    func testSetDouble_NilValue_DoesNotCrash() {
        record.setDouble(nil, forKey: "test")
        XCTAssertNil(record["test"])
    }

    func testSetBool_NilValue_DoesNotCrash() {
        record.setBool(nil, forKey: "test")
        XCTAssertNil(record["test"])
    }

    func testSetData_NilValue_DoesNotCrash() {
        record.setData(nil, forKey: "test")
        XCTAssertNil(record["test"])
    }

    func testSetString_ValidValue_Stores() {
        record.setString("hello", forKey: "test")
        XCTAssertEqual(record.string(forKey: "test"), "hello")
    }

    func testSetDate_ValidValue_Stores() {
        let date = Date()
        record.setDate(date, forKey: "test")
        XCTAssertEqual(record.date(forKey: "test"), date)
    }

    func testSetInt_ValidValue_Stores() {
        record.setInt(42, forKey: "test")
        XCTAssertEqual(record.int(forKey: "test"), 42)
    }

    func testSetDouble_ValidValue_Stores() {
        record.setDouble(3.14, forKey: "test")
        XCTAssertEqual(record.double(forKey: "test"), 3.14)
    }

    func testSetBool_ValidValue_Stores() {
        record.setBool(true, forKey: "test")
        XCTAssertEqual(record.bool(forKey: "test"), true)
    }
}
