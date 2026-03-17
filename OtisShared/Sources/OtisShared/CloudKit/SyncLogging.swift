//
//  SyncLogging.swift
//  OtisShared
//
//  Structured logging utilities for CloudKit sync debugging.
//  Provides traceability for specific records through the sync pipeline.
//
//  Usage:
//  - Filter logs by record ID: `message CONTAINS "abc123"`
//  - Filter by phase: `message CONTAINS "[QUEUE]"`
//  - Filter by category: `category=="SyncCoordinator"`
//
//  Log stream command:
//  xcrun simctl spawn booted log stream --predicate 'subsystem=="nl.jaapstronks.Otis"' --level debug
//

import Foundation
import os

// MARK: - Sync Phase

/// Phases in the sync pipeline for traceability
public enum SyncPhase: String {
    case queue = "QUEUE"      // Local change queued for sync
    case send = "SEND"        // Sending to CloudKit
    case sent = "SENT"        // Successfully sent
    case receive = "RECV"     // Received from CloudKit
    case apply = "APPLY"      // Applied to Core Data
    case conflict = "CONFLICT" // Conflict detected
    case error = "ERROR"      // Error occurred
    case delete = "DELETE"    // Deletion processed
    case photo = "PHOTO"      // Photo/asset operation
}

/// Database type for logging
public enum SyncDatabase: String {
    case privateDB = "PRIV"
    case sharedDB = "SHARED"
}

// MARK: - Sync Logger Extension

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public extension Logger {

    /// Log a sync event with record traceability
    /// - Parameters:
    ///   - message: The log message
    ///   - recordID: Short identifier for the record (first 8 chars of UUID)
    ///   - phase: The sync phase
    ///   - database: Private or shared database
    func syncEvent(
        _ message: String,
        recordID: String,
        phase: SyncPhase,
        database: SyncDatabase = .privateDB
    ) {
        let shortID = String(recordID.prefix(8))
        self.info("[\(phase.rawValue)] [\(database.rawValue)] [\(shortID)] \(message)")
    }

    /// Log a sync event with full record name
    func syncEventFull(
        _ message: String,
        recordName: String,
        phase: SyncPhase,
        database: SyncDatabase = .privateDB
    ) {
        // Extract just the UUID part from record names like "CD_CDPuppyEvent:UUID"
        let shortID: String
        if let colonIndex = recordName.lastIndex(of: ":") {
            let uuid = String(recordName[recordName.index(after: colonIndex)...])
            shortID = String(uuid.prefix(8))
        } else {
            shortID = String(recordName.prefix(8))
        }
        self.info("[\(phase.rawValue)] [\(database.rawValue)] [\(shortID)] \(message)")
    }

    /// Log a batch operation
    func syncBatch(
        _ message: String,
        count: Int,
        phase: SyncPhase,
        database: SyncDatabase = .privateDB
    ) {
        self.info("[\(phase.rawValue)] [\(database.rawValue)] [BATCH:\(count)] \(message)")
    }

    /// Log a photo/asset sync event
    func photoSync(
        _ message: String,
        photoID: String,
        status: PhotoSyncStatus
    ) {
        let shortID = String(photoID.prefix(8))
        self.info("[PHOTO] [\(status.rawValue)] [\(shortID)] \(message)")
    }
}

/// Photo sync status for logging
public enum PhotoSyncStatus: String {
    case queued = "QUEUED"
    case uploading = "UPLOADING"
    case uploaded = "UPLOADED"
    case downloading = "DOWNLOADING"
    case downloaded = "DOWNLOADED"
    case error = "ERROR"
    case cached = "CACHED"
}

// MARK: - Test Identifiers

/// Prefix for test data to make filtering easy
public let testRecordPrefix = "AA000000"

/// Check if a record ID is a test record
public func isTestRecord(_ recordID: String) -> Bool {
    recordID.hasPrefix(testRecordPrefix) || recordID.contains(testRecordPrefix)
}

// MARK: - Log Filter Helpers

/// Generate a log predicate for filtering by record ID
public func logPredicate(forRecordID recordID: String) -> String {
    let shortID = String(recordID.prefix(8))
    return "subsystem==\"nl.jaapstronks.Otis\" AND message CONTAINS \"[\(shortID)]\""
}

/// Generate a log predicate for filtering by phase
public func logPredicate(forPhase phase: SyncPhase) -> String {
    "subsystem==\"nl.jaapstronks.Otis\" AND message CONTAINS \"[\(phase.rawValue)]\""
}

/// Generate a log predicate for filtering test records only
public func logPredicateForTestRecords() -> String {
    "subsystem==\"nl.jaapstronks.Otis\" AND message CONTAINS \"[\(testRecordPrefix.prefix(8))]\""
}
