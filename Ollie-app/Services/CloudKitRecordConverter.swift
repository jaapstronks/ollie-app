//
//  CloudKitRecordConverter.swift
//  Ollie-app
//
//  Converts between PuppyEvent and CKRecord

import Foundation
import CloudKit

/// Handles conversion between PuppyEvent models and CloudKit records
struct CloudKitRecordConverter {
    let recordType: String
    let deviceID: String

    // MARK: - Event to Record

    /// Create a CKRecord from a PuppyEvent
    func createRecord(from event: PuppyEvent, in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: event.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["eventTime"] = event.time as CKRecordValue
        record["eventType"] = event.type.rawValue as CKRecordValue
        record["localId"] = event.id.uuidString as CKRecordValue
        record["deviceId"] = deviceID as CKRecordValue

        if let location = event.location {
            record["location"] = location.rawValue as CKRecordValue
        }
        if let note = event.note {
            record["note"] = note as CKRecordValue
        }
        if let who = event.who {
            record["who"] = who as CKRecordValue
        }
        if let exercise = event.exercise {
            record["exercise"] = exercise as CKRecordValue
        }
        if let result = event.result {
            record["result"] = result as CKRecordValue
        }
        if let duration = event.durationMin {
            record["durationMin"] = duration as CKRecordValue
        }
        if let photo = event.photo {
            record["photo"] = photo as CKRecordValue
        }
        if let video = event.video {
            record["video"] = video as CKRecordValue
        }
        if let latitude = event.latitude {
            record["latitude"] = latitude as CKRecordValue
        }
        if let longitude = event.longitude {
            record["longitude"] = longitude as CKRecordValue
        }
        if let thumbnailPath = event.thumbnailPath {
            record["thumbnailPath"] = thumbnailPath as CKRecordValue
        }

        return record
    }

    // MARK: - Record to Event

    /// Create a PuppyEvent from a CKRecord
    func createEvent(from record: CKRecord) -> PuppyEvent? {
        guard let eventTime = record["eventTime"] as? Date,
              let eventTypeRaw = record["eventType"] as? String,
              let eventType = EventType(rawValue: eventTypeRaw) else {
            return nil
        }

        // Use localId if available, otherwise derive from record name
        let id: UUID
        if let localIdString = record["localId"] as? String,
           let localId = UUID(uuidString: localIdString) {
            id = localId
        } else {
            id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        }

        var location: EventLocation?
        if let locationRaw = record["location"] as? String {
            location = EventLocation(rawValue: locationRaw)
        }

        return PuppyEvent(
            id: id,
            time: eventTime,
            type: eventType,
            location: location,
            note: record["note"] as? String,
            who: record["who"] as? String,
            exercise: record["exercise"] as? String,
            result: record["result"] as? String,
            durationMin: record["durationMin"] as? Int,
            photo: record["photo"] as? String,
            video: record["video"] as? String,
            latitude: record["latitude"] as? Double,
            longitude: record["longitude"] as? Double,
            thumbnailPath: record["thumbnailPath"] as? String
        )
    }

    // MARK: - Batch Conversion

    /// Convert multiple records to events
    func createEvents(from records: [CKRecord]) -> [PuppyEvent] {
        records.compactMap { createEvent(from: $0) }
    }

    /// Convert multiple events to records
    func createRecords(from events: [PuppyEvent], in zoneID: CKRecordZone.ID) -> [CKRecord] {
        events.map { createRecord(from: $0, in: zoneID) }
    }
}
