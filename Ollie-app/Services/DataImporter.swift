//
//  DataImporter.swift
//  Otis-app
//
//  Service for importing data from exported JSON files

import Foundation
import OtisShared
import Combine
import CoreData
import UIKit
import os

/// Preview of what will be imported from a file
struct ImportPreview {
    let manifest: ExportManifest?
    let components: [String]
    let itemCounts: [String: Int]
    let puppyName: String?
    let exportDate: Date?
    let folderURL: URL
}

/// Progress update during import
struct ImportProgress {
    let currentComponent: String
    let currentIndex: Int
    let totalComponents: Int
    let itemsImportedSoFar: Int
}

/// Result of a data import operation
struct ImportResult {
    var componentsImported: Int
    var itemsImported: Int
    var skipped: Int
    var errors: [String]
}

/// Service for importing data from exported JSON files
@MainActor
class DataImporter: ObservableObject {
    @Published private(set) var isImporting: Bool = false
    @Published private(set) var progress: String = ""
    @Published private(set) var importProgress: ImportProgress?
    @Published private(set) var lastResult: ImportResult?
    @Published private(set) var lastPreview: ImportPreview?
    @Published private(set) var lastError: String?

    private let fileManager = FileManager.default
    private let persistenceController: PersistenceController
    private let logger = Logger.otis(category: "DataImporter")
    private let decoder: JSONDecoder

    // MARK: - Security

    /// Maximum allowed file size for imports (50MB for folders with media)
    private static let maxFileSize = 50 * 1024 * 1024

    /// Maximum allowed line length in files (prevents memory attacks)
    private static let maxLineLength = 100_000

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Public Methods

    /// Preview what will be imported from a file or folder
    func previewImport(from url: URL) async throws -> ImportPreview {
        lastError = nil

        // Check if this is a file or folder
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ImportError.invalidFile
        }

        if isDirectory.boolValue {
            return try await previewFolder(url)
        } else {
            return try await previewSingleFile(url)
        }
    }

    /// Preview import from a folder (export folder structure)
    private func previewFolder(_ folderURL: URL) async throws -> ImportPreview {
        // Check if this is a valid export folder by looking for manifest.json
        let manifestURL = folderURL.appendingPathComponent("manifest.json")

        var manifest: ExportManifest?
        var components: [String] = []
        var itemCounts: [String: Int] = [:]
        var puppyName: String?
        var exportDate: Date?

        if fileManager.fileExists(atPath: manifestURL.path) {
            // Has manifest - read it
            let data = try Data(contentsOf: manifestURL)
            manifest = try decoder.decode(ExportManifest.self, from: data)
            components = manifest?.components ?? []
            itemCounts = manifest?.itemCounts ?? [:]
            puppyName = manifest?.puppyName
            exportDate = manifest?.exportDate
        } else {
            // No manifest - scan for available files
            let knownFiles: [(String, String)] = [
                ("profile.json", "profile"),
                ("events.json", "events"),
                ("documents.json", "documents"),
                ("contacts.json", "contacts"),
                ("appointments.json", "appointments"),
                ("milestones.json", "milestones"),
                ("exposures.json", "exposures"),
                ("walkSpots.json", "walkSpots")
            ]

            for (filename, component) in knownFiles {
                let fileURL = folderURL.appendingPathComponent(filename)
                if fileManager.fileExists(atPath: fileURL.path) {
                    components.append(component)

                    // Count items if it's an array file
                    if component != "profile" {
                        if let data = try? Data(contentsOf: fileURL),
                           let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            itemCounts[component] = array.count
                        }
                    }
                }
            }

            // Try to get puppy name from profile.json
            let profileURL = folderURL.appendingPathComponent("profile.json")
            if fileManager.fileExists(atPath: profileURL.path),
               let data = try? Data(contentsOf: profileURL),
               let profile = try? decoder.decode(PuppyProfile.self, from: data) {
                puppyName = profile.name
            }
        }

        let preview = ImportPreview(
            manifest: manifest,
            components: components,
            itemCounts: itemCounts,
            puppyName: puppyName,
            exportDate: exportDate,
            folderURL: folderURL
        )

        lastPreview = preview
        return preview
    }

    /// Preview import from a single JSON file (events.json)
    private func previewSingleFile(_ fileURL: URL) async throws -> ImportPreview {
        let data = try Data(contentsOf: fileURL)

        // Try to detect what kind of JSON file this is
        var components: [String] = []
        var itemCounts: [String: Int] = [:]

        // Try parsing as array of events
        if let events = try? decoder.decode([PuppyEvent].self, from: data) {
            components.append("events")
            itemCounts["events"] = events.count
        }
        // Could add more detection for other types if needed

        if components.isEmpty {
            throw ImportError.invalidContent
        }

        let preview = ImportPreview(
            manifest: nil,
            components: components,
            itemCounts: itemCounts,
            puppyName: nil,
            exportDate: nil,
            folderURL: fileURL  // Store the file URL, we'll handle it specially during import
        )

        lastPreview = preview
        return preview
    }

    /// Import data from a file or folder
    func importFrom(_ url: URL, overwriteExisting: Bool = false) async throws -> ImportResult {
        isImporting = true
        lastError = nil
        progress = Strings.DataImport.importing
        importProgress = nil

        defer {
            isImporting = false
        }

        var result = ImportResult(componentsImported: 0, itemsImported: 0, skipped: 0, errors: [])

        // Check if this is a file or folder
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ImportError.invalidFile
        }

        // Get preview to know what's available
        let preview = try await previewImport(from: url)
        let components = preview.components

        for (index, component) in components.enumerated() {
            progress = Strings.DataImport.importingComponent(component)
            importProgress = ImportProgress(
                currentComponent: component,
                currentIndex: index + 1,
                totalComponents: components.count,
                itemsImportedSoFar: result.itemsImported
            )

            do {
                let count: Int
                if isDirectory.boolValue {
                    count = try await importComponent(component, from: url, overwrite: overwriteExisting)
                } else {
                    // Single file - import directly as events
                    count = try await importEventsFromFile(url, overwrite: overwriteExisting)
                }
                result.componentsImported += 1
                result.itemsImported += count
                logger.info("Imported \(count) items for component: \(component)")
            } catch {
                result.errors.append("\(component): \(error.localizedDescription)")
                logger.error("Failed to import \(component): \(error.localizedDescription)")
            }
        }

        progress = Strings.DataImport.done
        importProgress = nil
        lastResult = result

        // Save context
        try viewContext.save()

        return result
    }

    /// Legacy method name for compatibility
    func importFromFolder(_ folderURL: URL, overwriteExisting: Bool = false) async throws -> ImportResult {
        try await importFrom(folderURL, overwriteExisting: overwriteExisting)
    }

    // MARK: - Component Importers

    /// Import events directly from a single JSON file
    private func importEventsFromFile(_ fileURL: URL, overwrite: Bool) async throws -> Int {
        let data = try Data(contentsOf: fileURL)
        let events = try decoder.decode([PuppyEvent].self, from: data)

        var importedCount = 0
        for event in events {
            // Check if event already exists
            let existingEvent = CDPuppyEvent.fetch(byId: event.id, in: viewContext)
            if existingEvent != nil && !overwrite {
                continue
            }

            // Delete existing if overwriting
            if let existing = existingEvent {
                viewContext.delete(existing)
            }

            // Create new event using the helper method
            _ = CDPuppyEvent.create(from: event, in: viewContext)
            importedCount += 1
        }

        return importedCount
    }

    private func importComponent(_ component: String, from folderURL: URL, overwrite: Bool) async throws -> Int {
        switch component {
        case "events":
            return try await importEvents(from: folderURL, overwrite: overwrite)
        case "documents":
            return try await importDocuments(from: folderURL, overwrite: overwrite)
        case "contacts":
            return try await importContacts(from: folderURL, overwrite: overwrite)
        case "appointments":
            return try await importAppointments(from: folderURL, overwrite: overwrite)
        case "milestones":
            return try await importMilestones(from: folderURL, overwrite: overwrite)
        case "exposures":
            return try await importExposures(from: folderURL, overwrite: overwrite)
        case "walkSpots":
            return try await importWalkSpots(from: folderURL, overwrite: overwrite)
        case "profile":
            // Profile import is handled separately as it affects the app's active profile
            return 0
        default:
            return 0
        }
    }

    private func importEvents(from folderURL: URL, overwrite: Bool) async throws -> Int {
        let fileURL = folderURL.appendingPathComponent("events.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }

        return try await importEventsFromFile(fileURL, overwrite: overwrite)
    }

    private func importDocuments(from folderURL: URL, overwrite: Bool) async throws -> Int {
        let fileURL = folderURL.appendingPathComponent("documents.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }

        guard let profileId = CDPuppyProfile.fetchProfile(in: viewContext)?.id,
              let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: viewContext) else {
            throw ImportError.noProfileFound
        }

        let data = try Data(contentsOf: fileURL)
        let documents = try decoder.decode([Document].self, from: data)

        var importedCount = 0
        for document in documents {
            let existingDoc = CDDocument.fetch(byId: document.id, in: viewContext)
            if existingDoc != nil && !overwrite {
                continue
            }

            if let existing = existingDoc {
                viewContext.delete(existing)
            }

            // Use the helper method to create document
            let cdDoc = CDDocument.create(from: document, profile: cdProfile, in: viewContext)

            // Try to import attachment files
            let documentsFolder = folderURL.appendingPathComponent("Documents", isDirectory: true)
            if document.attachmentType == .pdf {
                let attachmentURL = documentsFolder.appendingPathComponent("\(document.id.uuidString).pdf")
                if fileManager.fileExists(atPath: attachmentURL.path) {
                    let attachmentData = try Data(contentsOf: attachmentURL)
                    cdDoc.setPDF(attachmentData)
                }
            } else if document.attachmentType == .image {
                let attachmentURL = documentsFolder.appendingPathComponent("\(document.id.uuidString).jpg")
                if fileManager.fileExists(atPath: attachmentURL.path),
                   let attachmentData = try? Data(contentsOf: attachmentURL),
                   let image = UIImage(data: attachmentData) {
                    cdDoc.setImage(image)
                }
            }

            importedCount += 1
        }

        return importedCount
    }

    private func importContacts(from folderURL: URL, overwrite: Bool) async throws -> Int {
        let fileURL = folderURL.appendingPathComponent("contacts.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }

        let data = try Data(contentsOf: fileURL)
        let contacts = try decoder.decode([DogContact].self, from: data)

        var importedCount = 0
        for contact in contacts {
            let existingContact = CDDogContact.fetch(byId: contact.id, in: viewContext) as? CDDogContact
            if existingContact != nil && !overwrite {
                continue
            }

            if let existing = existingContact {
                viewContext.delete(existing)
            }

            // Use the helper method to create contact
            _ = CDDogContact.create(from: contact, in: viewContext)
            importedCount += 1
        }

        return importedCount
    }

    private func importAppointments(from folderURL: URL, overwrite: Bool) async throws -> Int {
        let fileURL = folderURL.appendingPathComponent("appointments.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }

        guard let profileId = CDPuppyProfile.fetchProfile(in: viewContext)?.id,
              let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: viewContext) else {
            throw ImportError.noProfileFound
        }

        let data = try Data(contentsOf: fileURL)
        let appointments = try decoder.decode([DogAppointment].self, from: data)

        var importedCount = 0
        for appointment in appointments {
            let existingAppt = CDDogAppointment.fetch(byId: appointment.id, in: viewContext)
            if existingAppt != nil && !overwrite {
                continue
            }

            if let existing = existingAppt {
                viewContext.delete(existing)
            }

            // Use the helper method to create appointment
            _ = CDDogAppointment.create(from: appointment, profile: cdProfile, in: viewContext)
            importedCount += 1
        }

        return importedCount
    }

    private func importMilestones(from folderURL: URL, overwrite: Bool) async throws -> Int {
        let fileURL = folderURL.appendingPathComponent("milestones.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }

        let data = try Data(contentsOf: fileURL)
        let milestones = try decoder.decode([Milestone].self, from: data)

        var importedCount = 0
        for milestone in milestones {
            let existingMilestone = CDMilestone.fetch(byId: milestone.id, in: viewContext) as? CDMilestone
            if existingMilestone != nil && !overwrite {
                continue
            }

            if let existing = existingMilestone {
                viewContext.delete(existing)
            }

            // Use the helper method to create milestone
            _ = CDMilestone.create(from: milestone, in: viewContext)
            importedCount += 1
        }

        return importedCount
    }

    private func importExposures(from folderURL: URL, overwrite: Bool) async throws -> Int {
        let fileURL = folderURL.appendingPathComponent("exposures.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }

        let data = try Data(contentsOf: fileURL)
        let exposures = try decoder.decode([Exposure].self, from: data)

        var importedCount = 0
        for exposure in exposures {
            let existingExposure = CDExposure.fetch(byId: exposure.id, in: viewContext)
            if existingExposure != nil && !overwrite {
                continue
            }

            if let existing = existingExposure {
                viewContext.delete(existing)
            }

            // Use the helper method to create exposure
            _ = CDExposure.create(from: exposure, in: viewContext)
            importedCount += 1
        }

        return importedCount
    }

    private func importWalkSpots(from folderURL: URL, overwrite: Bool) async throws -> Int {
        let fileURL = folderURL.appendingPathComponent("walkSpots.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }

        let data = try Data(contentsOf: fileURL)
        let spots = try decoder.decode([WalkSpot].self, from: data)

        var importedCount = 0
        for spot in spots {
            let existingSpot = CDWalkSpot.fetch(byId: spot.id, in: viewContext)
            if existingSpot != nil && !overwrite {
                continue
            }

            if let existing = existingSpot {
                viewContext.delete(existing)
            }

            // Use the helper method to create walk spot
            _ = CDWalkSpot.create(from: spot, in: viewContext)
            importedCount += 1
        }

        return importedCount
    }

    /// Reset state for new import attempt
    func reset() {
        lastError = nil
        lastPreview = nil
        lastResult = nil
        importProgress = nil
    }
}

enum ImportError: LocalizedError {
    case invalidFile
    case invalidContent
    case contentTooLarge
    case maliciousContent
    case noProfileFound

    var errorDescription: String? {
        switch self {
        case .invalidFile: return Strings.Errors.invalidFile
        case .invalidContent: return Strings.Errors.invalidContent
        case .contentTooLarge: return Strings.Errors.contentTooLarge
        case .maliciousContent: return Strings.Errors.maliciousContent
        case .noProfileFound: return Strings.Errors.noProfileFound
        }
    }
}
