//
//  ExportOptions.swift
//  Ollie-app
//
//  Options and result types for data export functionality
//

import Foundation

// MARK: - Export Options

/// Options for what data to include in the export
struct ExportOptions {
    var includeEvents: Bool = true
    var includeDocuments: Bool = true
    var includeContacts: Bool = true
    var includeAppointments: Bool = true
    var includeMilestones: Bool = true
    var includeSocialization: Bool = true
    var includeWalkSpots: Bool = true
    var includeMedia: Bool = false  // Large files, off by default
    var includeProfilePhoto: Bool = true

    /// Returns a list of component names that are enabled
    var enabledComponents: [String] {
        var components: [String] = ["profile"]
        if includeEvents { components.append("events") }
        if includeDocuments { components.append("documents") }
        if includeContacts { components.append("contacts") }
        if includeAppointments { components.append("appointments") }
        if includeMilestones { components.append("milestones") }
        if includeSocialization { components.append("exposures") }
        if includeWalkSpots { components.append("walkSpots") }
        if includeMedia { components.append("media") }
        if includeProfilePhoto { components.append("profilePhoto") }
        return components
    }
}

// MARK: - Export Manifest

/// Manifest file included in exports for versioning and metadata
struct ExportManifest: Codable {
    let version: String
    let exportDate: Date
    let puppyName: String
    let components: [String]
    let itemCounts: [String: Int]

    init(
        version: String = "1.0",
        exportDate: Date = Date(),
        puppyName: String,
        components: [String],
        itemCounts: [String: Int] = [:]
    ) {
        self.version = version
        self.exportDate = exportDate
        self.puppyName = puppyName
        self.components = components
        self.itemCounts = itemCounts
    }
}

// MARK: - Export Result

/// Result of a successful export operation
struct ExportResult {
    let exportURL: URL
    let itemCount: Int
    let sizeBytes: Int64
    let manifest: ExportManifest

    /// Human-readable size string
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

// MARK: - Export Error

/// Errors that can occur during export
enum ExportError: LocalizedError {
    case noProfile
    case exportFailed(String)
    case fileCreationFailed
    case encodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noProfile:
            return Strings.Export.errorNoProfile
        case .exportFailed(let message):
            return Strings.Export.errorExportFailed(message)
        case .fileCreationFailed:
            return Strings.Export.errorFileCreation
        case .encodingFailed(let type):
            return Strings.Export.errorEncoding(type)
        }
    }
}

// MARK: - Export Step

/// Steps in the export process for progress tracking
enum ExportStep: String {
    case preparing = "preparing"
    case exportingProfile = "profile"
    case exportingEvents = "events"
    case exportingDocuments = "documents"
    case exportingContacts = "contacts"
    case exportingAppointments = "appointments"
    case exportingMilestones = "milestones"
    case exportingExposures = "exposures"
    case exportingWalkSpots = "walkSpots"
    case exportingMedia = "media"
    case exportingProfilePhoto = "profilePhoto"
    case finalizing = "finalizing"

    var localizedDescription: String {
        switch self {
        case .preparing:
            return Strings.Export.stepPreparing
        case .exportingProfile:
            return Strings.Export.stepProfile
        case .exportingEvents:
            return Strings.Export.stepEvents
        case .exportingDocuments:
            return Strings.Export.stepDocuments
        case .exportingContacts:
            return Strings.Export.stepContacts
        case .exportingAppointments:
            return Strings.Export.stepAppointments
        case .exportingMilestones:
            return Strings.Export.stepMilestones
        case .exportingExposures:
            return Strings.Export.stepExposures
        case .exportingWalkSpots:
            return Strings.Export.stepWalkSpots
        case .exportingMedia:
            return Strings.Export.stepMedia
        case .exportingProfilePhoto:
            return Strings.Export.stepProfilePhoto
        case .finalizing:
            return Strings.Export.stepFinalizing
        }
    }
}
