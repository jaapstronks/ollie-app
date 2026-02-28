//
//  CloudKitService.swift
//  OllieShared
//
//  Simplified CloudKit service for sharing functionality with Core Data
//  Sync is handled automatically by NSPersistentCloudKitContainer
//

import Foundation
import CloudKit
import CoreData
import Combine
import os

/// Manages CloudKit sharing with Core Data
/// Note: Data sync is automatic via NSPersistentCloudKitContainer
/// This service handles: sharing, share acceptance, and media (photos)
@MainActor
public final class CloudKitService: ObservableObject {
    public static let shared = CloudKitService()

    // MARK: - Configuration

    public static let containerIdentifier = "iCloud.nl.jaapstronks.Ollie"
    private let zoneName = "com.apple.coredata.cloudkit.zone"

    // MARK: - CloudKit Objects

    private lazy var container: CKContainer = {
        CKContainer(identifier: Self.containerIdentifier)
    }()

    private lazy var privateDatabase: CKDatabase = {
        container.privateCloudDatabase
    }()

    private lazy var sharedDatabase: CKDatabase = {
        container.sharedCloudDatabase
    }()

    // MARK: - State

    @Published public private(set) var isCloudAvailable = false
    @Published public private(set) var isParticipant = false
    @Published public private(set) var isSyncing = false

    // MARK: - Share Manager

    /// Share manager for managing CloudKit shares
    public let shareManager = CloudKitShareManager()

    /// Whether data is currently shared (delegates to shareManager)
    public var isShared: Bool {
        shareManager.isShared
    }

    /// Share participants (delegates to shareManager)
    public var shareParticipants: [ShareParticipant] {
        shareManager.shareParticipants
    }

    /// Current share (delegates to shareManager)
    public var currentShare: CKShare? {
        shareManager.currentShare
    }

    private let logger = Logger.ollie(category: "CloudKitService")

    /// Device identifier for tracking which device created records
    private let deviceID: String = {
        let key = "ollie.device.id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }()

    // MARK: - Init

    private init() {}

    // MARK: - Setup

    /// Setup CloudKit and check availability
    public func setup() async {
        do {
            let status = try await container.accountStatus()
            isCloudAvailable = (status == .available)

            if isCloudAvailable {
                logger.info("CloudKit available")
                await checkParticipantStatus()
            } else {
                logger.info("CloudKit not available: \(String(describing: status))")
            }
        } catch {
            logger.error("CloudKit setup failed: \(error.localizedDescription)")
            isCloudAvailable = false
        }
    }

    // MARK: - Participant Detection

    /// Track if user was previously a participant (for removal detection)
    private var wasParticipant = false

    /// Check if user is a participant in a shared zone
    private func checkParticipantStatus() async {
        do {
            // Check shared database for any zones
            let zones = try await sharedDatabase.allRecordZones()
            let nowParticipant = !zones.isEmpty

            // Detect if access was revoked
            if wasParticipant && !nowParticipant {
                logger.info("Participant access was revoked")
                shareManager.clearShareState()
                NotificationCenter.default.post(name: .shareAccessRevoked, object: nil)
            }

            wasParticipant = isParticipant
            isParticipant = nowParticipant
            logger.info("Participant status: \(self.isParticipant)")
        } catch {
            logger.debug("Failed to check participant status: \(error.localizedDescription)")
            isParticipant = false
        }
    }

    /// Check for share access changes (call on app foreground)
    /// Detects if participant was removed from share by owner
    public func checkShareAccessStatus() async {
        guard isCloudAvailable else { return }

        let previousStatus = isParticipant
        await checkParticipantStatus()

        // If status changed from participant to non-participant, access was revoked
        if previousStatus && !isParticipant {
            logger.info("Share access revoked - user was removed by owner")
        }
    }

    // MARK: - Share State

    /// Update share state (refreshes from shareManager)
    public func updateShareState() async {
        await shareManager.updateShareState()
    }

    /// Refresh share state from CloudKit using the profile managed object
    public func refreshShareState(
        for profile: NSManagedObject,
        using persistentContainer: NSPersistentCloudKitContainer
    ) async {
        await shareManager.refreshShareState(for: profile, using: persistentContainer)
    }

    /// Get or create a share for the profile
    public func getOrCreateShare(
        for profile: NSManagedObject,
        using persistentContainer: NSPersistentCloudKitContainer
    ) async throws -> CKShare {
        try await shareManager.getOrCreateShare(for: profile, using: persistentContainer)
    }

    /// Stop sharing (owner only)
    public func stopSharing() async throws {
        try await shareManager.stopSharing()
    }

    // MARK: - Share Acceptance

    /// Mark the user as a participant after share acceptance
    /// Call this after accepting a share via PersistenceController.acceptShareInvitation
    public func markAsParticipant() {
        isParticipant = true
        logger.info("Marked as participant after share acceptance")
    }

    // MARK: - Container Access

    /// Get the CloudKit container for share operations
    public var cloudKitContainer: CKContainer {
        container
    }

    // MARK: - Media Service

    /// Media service for photo operations (CKAsset handling)
    public lazy var mediaService: MediaCloudService = {
        MediaCloudService(
            deviceID: deviceID,
            getDatabase: { [weak self] in
                guard let self = self else { return CKContainer.default().privateCloudDatabase }
                return self.isParticipant ? self.sharedDatabase : self.privateDatabase
            },
            getZoneID: { [weak self] in
                CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
            },
            isCloudAvailable: { [weak self] in
                self?.isCloudAvailable ?? false
            }
        )
    }()

    // MARK: - Photo Operations

    /// Upload a photo to CloudKit
    public func uploadPhoto(
        localURL: URL,
        eventId: UUID
    ) async throws -> CKRecord.ID {
        try await mediaService.uploadPhoto(localURL: localURL, eventId: eventId)
    }

    /// Download a photo from CloudKit
    public func downloadPhoto(
        eventId: UUID,
        to destinationURL: URL
    ) async throws -> Bool {
        try await mediaService.downloadPhoto(eventId: eventId, to: destinationURL)
    }

    /// Delete a photo from CloudKit
    public func deletePhoto(eventId: UUID) async throws {
        try await mediaService.deletePhoto(eventId: eventId)
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let cloudKitShareAccepted = Notification.Name("cloudKitShareAccepted")
    static let shareAccessRevoked = Notification.Name("shareAccessRevoked")
}

// MARK: - Error Types

/// CloudKit-related errors
public enum CloudKitError: LocalizedError {
    case notAvailable
    case syncFailed(String)
    case recordNotFound
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "iCloud is not available"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .recordNotFound:
            return "Record not found"
        case .invalidData:
            return "Invalid data"
        }
    }
}
