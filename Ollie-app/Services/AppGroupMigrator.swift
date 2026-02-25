//
//  AppGroupMigrator.swift
//  Ollie-app
//
//  Handles one-time migration of event data from Documents to App Group container
//

import Foundation
import OllieShared
import os

/// Migrates event data from the legacy Documents directory to the App Group container
/// This enables sharing data with App Intents and Widgets
struct AppGroupMigrator {
    /// App Group identifier
    static let appGroupSuiteName = Constants.appGroupIdentifier

    /// UserDefaults key to track migration completion
    private static let migrationCompletedKey = "eventDataMigratedToAppGroup"

    private let fileManager = FileManager.default
    private let logger = Logger.ollie(category: "AppGroupMigrator")
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(decoder: JSONDecoder, encoder: JSONEncoder) {
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: - URLs

    /// App Group container URL
    var appGroupContainerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupSuiteName)
    }

    /// Primary data directory in App Group container
    var dataDirectoryURL: URL? {
        guard let container = appGroupContainerURL else { return nil }
        return container.appendingPathComponent(Constants.dataDirectoryName, isDirectory: true)
    }

    /// Legacy data directory in Documents (source for migration)
    var legacyDataDirectoryURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(Constants.dataDirectoryName, isDirectory: true)
    }

    // MARK: - Migration

    /// Check if migration has been completed
    var isMigrationCompleted: Bool {
        UserDefaults.standard.bool(forKey: Self.migrationCompletedKey)
    }

    /// Migrate data from Documents to App Group container if needed
    /// - Returns: True if migration was performed or already complete
    @discardableResult
    func migrateIfNeeded() -> Bool {
        let defaults = UserDefaults.standard

        // Check if already migrated
        guard !defaults.bool(forKey: Self.migrationCompletedKey) else {
            return true
        }

        guard let destDir = dataDirectoryURL else {
            logger.warning("App Group container not available, skipping migration")
            return false
        }

        // Check if legacy data exists
        guard fileManager.fileExists(atPath: legacyDataDirectoryURL.path) else {
            // No legacy data, mark as migrated
            defaults.set(true, forKey: Self.migrationCompletedKey)
            return true
        }

        logger.info("Migrating event data to App Group container...")

        // Ensure destination exists
        if !fileManager.fileExists(atPath: destDir.path) {
            try? fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
        }

        // Copy all JSONL files from legacy to App Group
        do {
            let legacyFiles = try fileManager.contentsOfDirectory(
                at: legacyDataDirectoryURL,
                includingPropertiesForKeys: nil
            )

            var migratedCount = 0
            for file in legacyFiles where file.pathExtension == "jsonl" {
                let destURL = destDir.appendingPathComponent(file.lastPathComponent)

                // If destination exists, merge events; otherwise just copy
                if fileManager.fileExists(atPath: destURL.path) {
                    try mergeEventFiles(source: file, destination: destURL)
                } else {
                    try fileManager.copyItem(at: file, to: destURL)
                }
                migratedCount += 1
            }

            logger.info("Migration complete: \(migratedCount) files migrated")
            defaults.set(true, forKey: Self.migrationCompletedKey)
            return true

        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Private Methods

    /// Merge two event files (used during migration to preserve any App Group events)
    private func mergeEventFiles(source: URL, destination: URL) throws {
        // Read source events
        guard let sourceContent = try? String(contentsOf: source, encoding: .utf8) else { return }
        let sourceLines = sourceContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let sourceEvents: [PuppyEvent] = sourceLines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(PuppyEvent.self, from: data)
        }

        // Read destination events
        let destContent = (try? String(contentsOf: destination, encoding: .utf8)) ?? ""
        let destLines = destContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let destEvents: [PuppyEvent] = destLines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(PuppyEvent.self, from: data)
        }

        // Merge by ID (destination wins for conflicts)
        var merged: [UUID: PuppyEvent] = [:]
        for event in sourceEvents { merged[event.id] = event }
        for event in destEvents { merged[event.id] = event }

        // Sort and write
        let sortedEvents = Array(merged.values).sorted { $0.time > $1.time }
        let lines = sortedEvents.compactMap { event -> String? in
            guard let data = try? encoder.encode(event) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        let content = lines.joined(separator: "\n")
        try content.write(to: destination, atomically: true, encoding: .utf8)
    }
}
