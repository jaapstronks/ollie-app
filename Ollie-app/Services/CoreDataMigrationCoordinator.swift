//
//  CoreDataMigrationCoordinator.swift
//  Ollie-app
//
//  Migrates existing JSONL/JSON data to Core Data
//

import Foundation
import CoreData
import OllieShared
import os

/// Handles one-time migration from JSONL/JSON files to Core Data
final class CoreDataMigrationCoordinator {

    // MARK: - Singleton

    static let shared = CoreDataMigrationCoordinator()

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let migrationCompleted = "coreDataMigration.completed.v1"
        static let migrationVersion = "coreDataMigration.version"
    }

    // MARK: - Current Migration Version

    private static let currentMigrationVersion = 1

    // MARK: - Properties

    private let logger = Logger.ollie(category: "CoreDataMigration")
    private let fileManager = FileManager.default

    /// App Group identifier for data access
    private static let appGroupIdentifier = "group.jaapstronks.Ollie"

    // MARK: - File Names

    private enum FileName {
        static let profile = "profile.json"
        static let spots = "spots.json"
        static let socialization = "socialization.json"
        static let masteredSkills = "mastered-skills-v2.json"
        static let medicationCompletions = "medication-completions.jsonl"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Migration Check

    /// Check if migration has been completed
    var isMigrationCompleted: Bool {
        let completed = UserDefaults.standard.bool(forKey: UserDefaultsKey.migrationCompleted)
        let version = UserDefaults.standard.integer(forKey: UserDefaultsKey.migrationVersion)
        return completed && version >= Self.currentMigrationVersion
    }

    // MARK: - Migration

    /// Perform migration if needed
    func migrateIfNeeded(using persistenceController: PersistenceController) async throws {
        guard !isMigrationCompleted else {
            logger.info("Core Data migration already completed")
            return
        }

        // Ensure stores are ready before migrating
        guard persistenceController.isReady else {
            logger.error("Core Data stores not ready - cannot migrate")
            throw MigrationError.storesNotReady
        }

        logger.info("Starting Core Data migration...")

        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            // Migration order is important: entities with no dependencies first
            try self.migrateProfile(in: context)
            try self.migrateWalkSpots(in: context)
            try self.migrateMasteredSkills(in: context)
            try self.migrateMedicationCompletions(in: context)
            try self.migrateExposures(in: context)
            try self.migrateEvents(in: context)

            // Save all changes
            if context.hasChanges {
                try context.save()
                self.logger.info("Core Data migration saved successfully")
            }
        }

        // Mark migration as completed
        markMigrationCompleted()

        // Archive old files (don't delete immediately for safety)
        archiveOldFiles()

        logger.info("Core Data migration completed")
    }

    // MARK: - Profile Migration

    private func migrateProfile(in context: NSManagedObjectContext) throws {
        guard let profileData = readFile(named: FileName.profile),
              let profile = decodeProfile(from: profileData) else {
            logger.info("No profile found to migrate")
            return
        }

        // Check if profile already exists in Core Data
        if CDPuppyProfile.fetch(byId: profile.id, in: context) != nil {
            logger.info("Profile already exists in Core Data, skipping")
            return
        }

        _ = CDPuppyProfile.create(from: profile, in: context)
        logger.info("Migrated profile: \(profile.name)")
    }

    // MARK: - Walk Spots Migration

    private func migrateWalkSpots(in context: NSManagedObjectContext) throws {
        guard let spotsData = readFile(named: FileName.spots),
              let spots = decodeSpots(from: spotsData) else {
            logger.info("No walk spots found to migrate")
            return
        }

        var migratedCount = 0
        for spot in spots {
            // Check if spot already exists
            if CDWalkSpot.fetch(byId: spot.id, in: context) == nil {
                _ = CDWalkSpot.create(from: spot, in: context)
                migratedCount += 1
            }
        }
        logger.info("Migrated \(migratedCount) walk spots")
    }

    // MARK: - Mastered Skills Migration

    private func migrateMasteredSkills(in context: NSManagedObjectContext) throws {
        guard let skillsData = readFile(named: FileName.masteredSkills),
              let skills = decodeMasteredSkills(from: skillsData) else {
            logger.info("No mastered skills found to migrate")
            return
        }

        var migratedCount = 0
        for skill in skills {
            // Check if skill already exists
            if CDMasteredSkill.fetch(byId: skill.id, in: context) == nil {
                _ = CDMasteredSkill.create(from: skill, in: context)
                migratedCount += 1
            }
        }
        logger.info("Migrated \(migratedCount) mastered skills")
    }

    // MARK: - Medication Completions Migration

    private func migrateMedicationCompletions(in context: NSManagedObjectContext) throws {
        guard let completionsData = readFile(named: FileName.medicationCompletions) else {
            logger.info("No medication completions found to migrate")
            return
        }

        let completions = decodeMedicationCompletions(from: completionsData)
        var migratedCount = 0
        for completion in completions {
            // Check if completion already exists
            if CDMedicationCompletion.fetch(byId: completion.id, in: context) == nil {
                _ = CDMedicationCompletion.create(from: completion, in: context)
                migratedCount += 1
            }
        }
        logger.info("Migrated \(migratedCount) medication completions")
    }

    // MARK: - Exposures Migration

    private func migrateExposures(in context: NSManagedObjectContext) throws {
        guard let socializationData = readFile(named: FileName.socialization),
              let exposures = decodeExposures(from: socializationData) else {
            logger.info("No exposures found to migrate")
            return
        }

        var migratedCount = 0
        for exposure in exposures {
            // Check if exposure already exists
            if CDExposure.fetch(byId: exposure.id, in: context) == nil {
                _ = CDExposure.create(from: exposure, in: context)
                migratedCount += 1
            }
        }
        logger.info("Migrated \(migratedCount) exposures")
    }

    // MARK: - Events Migration

    private func migrateEvents(in context: NSManagedObjectContext) throws {
        guard let dataDirectoryURL = dataDirectoryURL else {
            logger.info("No data directory found for events migration")
            return
        }

        guard let files = try? fileManager.contentsOfDirectory(at: dataDirectoryURL, includingPropertiesForKeys: nil) else {
            logger.info("No JSONL files found to migrate")
            return
        }

        var totalMigratedCount = 0
        let jsonlFiles = files.filter { $0.pathExtension == "jsonl" }

        for file in jsonlFiles {
            let events = readEvents(from: file)
            for event in events {
                // Check if event already exists
                if CDPuppyEvent.fetch(byId: event.id, in: context) == nil {
                    _ = CDPuppyEvent.create(from: event, in: context)
                    totalMigratedCount += 1
                }
            }
        }
        logger.info("Migrated \(totalMigratedCount) events from \(jsonlFiles.count) files")
    }

    // MARK: - File Reading Helpers

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var dataDirectoryURL: URL? {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) else {
            // Fall back to documents directory if App Group not available
            let fallback = documentsURL.appendingPathComponent("data")
            return fileManager.fileExists(atPath: fallback.path) ? fallback : nil
        }
        let dataURL = containerURL.appendingPathComponent("data")
        return fileManager.fileExists(atPath: dataURL.path) ? dataURL : nil
    }

    private func readFile(named fileName: String) -> Data? {
        // Try documents directory first
        let documentsPath = documentsURL.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: documentsPath.path),
           let data = try? Data(contentsOf: documentsPath) {
            return data
        }

        // Try App Group container
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) {
            let containerPath = containerURL.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: containerPath.path),
               let data = try? Data(contentsOf: containerPath) {
                return data
            }
        }

        return nil
    }

    // MARK: - Decoding Helpers

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = Date.fromISO8601(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        return decoder
    }

    private func createISODecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func decodeProfile(from data: Data) -> PuppyProfile? {
        let decoder = createISODecoder()
        return try? decoder.decode(PuppyProfile.self, from: data)
    }

    private func decodeSpots(from data: Data) -> [WalkSpot]? {
        let decoder = createISODecoder()
        return try? decoder.decode([WalkSpot].self, from: data)
    }

    private func decodeMasteredSkills(from data: Data) -> [MasteredSkill]? {
        let decoder = createISODecoder()
        return try? decoder.decode([MasteredSkill].self, from: data)
    }

    private func decodeMedicationCompletions(from data: Data) -> [MedicationCompletion] {
        let decoder = createDecoder()
        guard let content = String(data: data, encoding: .utf8) else { return [] }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.compactMap { line in
            guard let lineData = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(MedicationCompletion.self, from: lineData)
        }
    }

    private func decodeExposures(from data: Data) -> [Exposure]? {
        let decoder = createISODecoder()

        // Socialization data is stored in a container with exposuresByItem
        struct ExposureDataContainer: Codable {
            let exposuresByItem: [String: [Exposure]]
            let startedDate: Date?
        }

        guard let container = try? decoder.decode(ExposureDataContainer.self, from: data) else {
            return nil
        }

        // Flatten all exposures from all items
        return container.exposuresByItem.values.flatMap { $0 }
    }

    private func readEvents(from fileURL: URL) -> [PuppyEvent] {
        let decoder = createDecoder()

        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.compactMap { line in
            guard let lineData = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(PuppyEvent.self, from: lineData)
        }
    }

    // MARK: - Migration State

    private func markMigrationCompleted() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.migrationCompleted)
        UserDefaults.standard.set(Self.currentMigrationVersion, forKey: UserDefaultsKey.migrationVersion)
    }

    // MARK: - Archiving

    private func archiveOldFiles() {
        let archiveDirectoryName = "data-archive"

        // Create archive directory in documents
        let archiveURL = documentsURL.appendingPathComponent(archiveDirectoryName)
        try? fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)

        let timestamp = DateFormatter.fileTimestamp.string(from: Date())
        let timestampedArchive = archiveURL.appendingPathComponent(timestamp)
        try? fileManager.createDirectory(at: timestampedArchive, withIntermediateDirectories: true)

        // Archive profile.json
        archiveFile(named: FileName.profile, to: timestampedArchive)

        // Archive spots.json
        archiveFile(named: FileName.spots, to: timestampedArchive)

        // Archive socialization.json
        archiveFile(named: FileName.socialization, to: timestampedArchive)

        // Archive mastered-skills-v2.json
        archiveFile(named: FileName.masteredSkills, to: timestampedArchive)

        // Archive medication-completions.jsonl
        archiveFile(named: FileName.medicationCompletions, to: timestampedArchive)

        // Archive JSONL data directory
        if let dataDir = dataDirectoryURL {
            let archivedDataDir = timestampedArchive.appendingPathComponent("data")
            try? fileManager.copyItem(at: dataDir, to: archivedDataDir)
            logger.info("Archived data directory to \(archivedDataDir.path)")
        }

        logger.info("Archived old files to \(timestampedArchive.path)")
    }

    private func archiveFile(named fileName: String, to directory: URL) {
        let sourceURL = documentsURL.appendingPathComponent(fileName)
        let destURL = directory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: sourceURL.path) {
            try? fileManager.copyItem(at: sourceURL, to: destURL)
            logger.debug("Archived \(fileName)")
        }
    }

    // MARK: - Rollback Support

    /// Reset migration flag to allow re-migration (for testing/debugging)
    func resetMigration() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.migrationCompleted)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.migrationVersion)
        logger.info("Migration state reset")
    }
}

// MARK: - Migration Errors

enum MigrationError: LocalizedError {
    case storesNotReady

    var errorDescription: String? {
        switch self {
        case .storesNotReady:
            return "Core Data stores are not ready. Please restart the app."
        }
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let fileTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }()
}
