//
//  ExportService.swift
//  Ollie-app
//
//  Handles exporting all puppy data to a shareable folder
//

import Combine
import CoreData
import Foundation
import OllieShared
import os
import UIKit

/// Service for exporting all puppy data to a shareable folder
@MainActor
class ExportService: ObservableObject {

    // MARK: - Published State

    @Published var isExporting = false
    @Published var progress: Double = 0.0
    @Published var currentStep: ExportStep = .preparing
    @Published var exportError: ExportError?

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "ExportService")
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController

        // Configure encoder with consistent date formatting
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
    }

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Export

    /// Export data with the given options
    /// - Parameter options: Export configuration options
    /// - Returns: ExportResult with the export folder URL and statistics
    func exportData(options: ExportOptions, profile: PuppyProfile) async throws -> ExportResult {
        isExporting = true
        progress = 0.0
        currentStep = .preparing
        exportError = nil

        defer {
            isExporting = false
        }

        do {
            // Create export folder
            let exportFolder = try createExportFolder(puppyName: profile.name)

            var itemCounts: [String: Int] = [:]

            // Export profile (always included)
            currentStep = .exportingProfile
            progress = 0.05
            try await exportProfile(profile, to: exportFolder)
            itemCounts["profile"] = 1

            // Export events
            if options.includeEvents {
                currentStep = .exportingEvents
                progress = 0.10
                let count = try await exportEvents(to: exportFolder)
                itemCounts["events"] = count
            }

            // Export documents
            if options.includeDocuments {
                currentStep = .exportingDocuments
                progress = 0.25
                let count = try await exportDocuments(to: exportFolder, includeAttachments: true)
                itemCounts["documents"] = count
            }

            // Export contacts
            if options.includeContacts {
                currentStep = .exportingContacts
                progress = 0.35
                let count = try await exportContacts(to: exportFolder)
                itemCounts["contacts"] = count
            }

            // Export appointments
            if options.includeAppointments {
                currentStep = .exportingAppointments
                progress = 0.40
                let count = try await exportAppointments(to: exportFolder, profile: profile)
                itemCounts["appointments"] = count
            }

            // Export milestones
            if options.includeMilestones {
                currentStep = .exportingMilestones
                progress = 0.45
                let count = try await exportMilestones(to: exportFolder)
                itemCounts["milestones"] = count
            }

            // Export socialization exposures
            if options.includeSocialization {
                currentStep = .exportingExposures
                progress = 0.50
                let count = try await exportExposures(to: exportFolder)
                itemCounts["exposures"] = count
            }

            // Export walk spots
            if options.includeWalkSpots {
                currentStep = .exportingWalkSpots
                progress = 0.55
                let count = try await exportWalkSpots(to: exportFolder)
                itemCounts["walkSpots"] = count
            }

            // Export profile photo
            if options.includeProfilePhoto {
                currentStep = .exportingProfilePhoto
                progress = 0.60
                if try await exportProfilePhoto(profile: profile, to: exportFolder) {
                    itemCounts["profilePhoto"] = 1
                }
            }

            // Export media (photos from events)
            if options.includeMedia {
                currentStep = .exportingMedia
                progress = 0.65
                let count = try await exportMedia(to: exportFolder)
                itemCounts["media"] = count
            }

            // Finalize - write manifest
            currentStep = .finalizing
            progress = 0.95

            let manifest = ExportManifest(
                puppyName: profile.name,
                components: options.enabledComponents,
                itemCounts: itemCounts
            )
            try await writeManifest(manifest, to: exportFolder)

            progress = 1.0

            // Calculate total size
            let sizeBytes = try calculateFolderSize(at: exportFolder)
            let totalItems = itemCounts.values.reduce(0, +)

            logger.info("Export completed: \(totalItems) items, \(sizeBytes) bytes")

            return ExportResult(
                exportURL: exportFolder,
                itemCount: totalItems,
                sizeBytes: sizeBytes,
                manifest: manifest
            )
        } catch let error as ExportError {
            exportError = error
            throw error
        } catch {
            let exportErr = ExportError.exportFailed(error.localizedDescription)
            exportError = exportErr
            throw exportErr
        }
    }

    // MARK: - Export Helpers

    private func createExportFolder(puppyName: String) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let sanitizedName = puppyName.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let folderName = "Ollie_Export_\(sanitizedName)_\(dateString)"

        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(folderName, isDirectory: true)

        // Clean up existing folder if any
        if fileManager.fileExists(atPath: tempURL.path) {
            try? fileManager.removeItem(at: tempURL)
        }

        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)

        return tempURL
    }

    private func exportProfile(_ profile: PuppyProfile, to folder: URL) async throws {
        let data = try encoder.encode(profile)
        let fileURL = folder.appendingPathComponent("profile.json")
        try data.write(to: fileURL)
        logger.debug("Exported profile")
    }

    private func exportEvents(to folder: URL) async throws -> Int {
        let cdEvents = CDPuppyEvent.fetchAllEvents(in: viewContext)
        let events = cdEvents.compactMap { $0.toPuppyEvent() }

        guard !events.isEmpty else { return 0 }

        let data = try encoder.encode(events)
        let fileURL = folder.appendingPathComponent("events.json")
        try data.write(to: fileURL)
        logger.debug("Exported \(events.count) events")
        return events.count
    }

    private func exportDocuments(to folder: URL, includeAttachments: Bool) async throws -> Int {
        guard let profileId = CDPuppyProfile.fetchProfile(in: viewContext)?.id else { return 0 }
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: viewContext) else { return 0 }

        let cdDocuments = CDDocument.fetchDocuments(for: cdProfile, in: viewContext)
        let documents = cdDocuments.compactMap { $0.toDocument() }

        guard !documents.isEmpty else { return 0 }

        // Write document metadata
        let data = try encoder.encode(documents)
        let fileURL = folder.appendingPathComponent("documents.json")
        try data.write(to: fileURL)

        // Export document attachments if requested
        if includeAttachments {
            let documentsFolder = folder.appendingPathComponent("Documents", isDirectory: true)
            try fileManager.createDirectory(at: documentsFolder, withIntermediateDirectories: true)

            for cdDocument in cdDocuments {
                guard let document = cdDocument.toDocument() else { continue }

                // Export image attachment
                if document.attachmentType == .image, let imageData = cdDocument.imageData {
                    let imageURL = documentsFolder.appendingPathComponent("\(document.id.uuidString).jpg")
                    try imageData.write(to: imageURL)
                }

                // Export PDF attachment
                if document.attachmentType == .pdf, let pdfData = cdDocument.pdfData {
                    let pdfURL = documentsFolder.appendingPathComponent("\(document.id.uuidString).pdf")
                    try pdfData.write(to: pdfURL)
                }
            }
        }

        logger.debug("Exported \(documents.count) documents")
        return documents.count
    }

    private func exportContacts(to folder: URL) async throws -> Int {
        let cdContacts = CDDogContact.fetchAllContacts(in: viewContext)
        let contacts = cdContacts.compactMap { $0.toContact() }

        guard !contacts.isEmpty else { return 0 }

        let data = try encoder.encode(contacts)
        let fileURL = folder.appendingPathComponent("contacts.json")
        try data.write(to: fileURL)
        logger.debug("Exported \(contacts.count) contacts")
        return contacts.count
    }

    private func exportAppointments(to folder: URL, profile: PuppyProfile) async throws -> Int {
        guard let cdProfile = CDPuppyProfile.fetch(byId: profile.id, in: viewContext) else { return 0 }

        let cdAppointments = CDDogAppointment.fetchAppointments(for: cdProfile, in: viewContext)
        let appointments = cdAppointments.compactMap { $0.toAppointment() }

        guard !appointments.isEmpty else { return 0 }

        let data = try encoder.encode(appointments)
        let fileURL = folder.appendingPathComponent("appointments.json")
        try data.write(to: fileURL)
        logger.debug("Exported \(appointments.count) appointments")
        return appointments.count
    }

    private func exportMilestones(to folder: URL) async throws -> Int {
        let cdMilestones = CDMilestone.fetchAllMilestones(in: viewContext)
        let milestones = cdMilestones.compactMap { $0.toMilestone() }

        guard !milestones.isEmpty else { return 0 }

        let data = try encoder.encode(milestones)
        let fileURL = folder.appendingPathComponent("milestones.json")
        try data.write(to: fileURL)
        logger.debug("Exported \(milestones.count) milestones")
        return milestones.count
    }

    private func exportExposures(to folder: URL) async throws -> Int {
        let cdExposures = CDExposure.fetchAllExposures(in: viewContext)
        let exposures = cdExposures.compactMap { $0.toExposure() }

        guard !exposures.isEmpty else { return 0 }

        let data = try encoder.encode(exposures)
        let fileURL = folder.appendingPathComponent("exposures.json")
        try data.write(to: fileURL)
        logger.debug("Exported \(exposures.count) exposures")
        return exposures.count
    }

    private func exportWalkSpots(to folder: URL) async throws -> Int {
        let cdSpots = CDWalkSpot.fetchAllSpots(in: viewContext)
        let spots = cdSpots.compactMap { $0.toWalkSpot() }

        guard !spots.isEmpty else { return 0 }

        let data = try encoder.encode(spots)
        let fileURL = folder.appendingPathComponent("walkSpots.json")
        try data.write(to: fileURL)
        logger.debug("Exported \(spots.count) walk spots")
        return spots.count
    }

    private func exportProfilePhoto(profile: PuppyProfile, to folder: URL) async throws -> Bool {
        guard let filename = profile.profilePhotoFilename else { return false }

        let photoStore = ProfilePhotoStore.shared
        guard let image = photoStore.load(filename: filename),
              let imageData = image.jpegData(compressionQuality: 0.9) else {
            return false
        }

        let profilePhotoFolder = folder.appendingPathComponent("ProfilePhoto", isDirectory: true)
        try fileManager.createDirectory(at: profilePhotoFolder, withIntermediateDirectories: true)

        let imageURL = profilePhotoFolder.appendingPathComponent("profile.jpg")
        try imageData.write(to: imageURL)
        logger.debug("Exported profile photo")
        return true
    }

    private func exportMedia(to folder: URL) async throws -> Int {
        let cdEvents = CDPuppyEvent.fetchAllEvents(in: viewContext)
        let eventsWithMedia = cdEvents.compactMap { $0.toPuppyEvent() }.filter { $0.photo != nil }

        guard !eventsWithMedia.isEmpty else { return 0 }

        let mediaFolder = folder.appendingPathComponent("Media", isDirectory: true)
        try fileManager.createDirectory(at: mediaFolder, withIntermediateDirectories: true)

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var exportedCount = 0

        for event in eventsWithMedia {
            guard let photoPath = event.photo else { continue }

            let sourceURL = documentsURL.appendingPathComponent(photoPath)
            guard fileManager.fileExists(atPath: sourceURL.path) else { continue }

            let destURL = mediaFolder.appendingPathComponent("\(event.id.uuidString).jpg")
            try? fileManager.copyItem(at: sourceURL, to: destURL)
            exportedCount += 1

            // Update progress incrementally during media export
            let mediaProgress = Double(exportedCount) / Double(eventsWithMedia.count)
            progress = 0.65 + (mediaProgress * 0.30) // 65% to 95%
        }

        logger.debug("Exported \(exportedCount) media files")
        return exportedCount
    }

    private func writeManifest(_ manifest: ExportManifest, to folder: URL) async throws {
        let data = try encoder.encode(manifest)
        let fileURL = folder.appendingPathComponent("manifest.json")
        try data.write(to: fileURL)
        logger.debug("Wrote export manifest")
    }

    private func calculateFolderSize(at url: URL) throws -> Int64 {
        var totalSize: Int64 = 0

        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey]
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys)
            if resourceValues?.isDirectory == false {
                totalSize += Int64(resourceValues?.fileSize ?? 0)
            }
        }

        return totalSize
    }

    // MARK: - Cleanup

    /// Clean up export folder after sharing
    func cleanupExportFolder(_ url: URL) {
        try? fileManager.removeItem(at: url)
        logger.debug("Cleaned up export folder")
    }
}
