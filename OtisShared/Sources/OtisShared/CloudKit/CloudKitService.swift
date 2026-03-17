//
//  CloudKitService.swift
//  OtisShared
//
//  CloudKit service for sharing functionality.
//  Data sync is handled by CKSyncEngine via SyncCoordinator (iOS 17+).
//  This service handles: sharing, share acceptance, and media (photos)
//

import Foundation
import CloudKit
import CoreData
import os

/// Manages CloudKit sharing
/// Data sync is handled by CKSyncEngine via SyncCoordinator (not NSPersistentCloudKitContainer)
/// This service handles: sharing, share acceptance, and media (photos)
@Observable
@MainActor
public final class CloudKitService {
    public static let shared = CloudKitService()

    // MARK: - Configuration

    public static let containerIdentifier = "iCloud.nl.jaapstronks.Otis"
    @ObservationIgnored private let zoneName = "com.apple.coredata.cloudkit.zone"

    // MARK: - CloudKit Objects

    @ObservationIgnored private lazy var container: CKContainer = {
        CKContainer(identifier: Self.containerIdentifier)
    }()

    @ObservationIgnored private lazy var privateDatabase: CKDatabase = {
        container.privateCloudDatabase
    }()

    @ObservationIgnored private lazy var sharedDatabase: CKDatabase = {
        container.sharedCloudDatabase
    }()

    // MARK: - State

    public private(set) var isCloudAvailable = false
    public private(set) var isParticipant = false
    public private(set) var isSyncing = false

    /// The owner's zone ID when user is a participant (used for media fetches)
    /// This is the owner's actual CloudKit user record name (e.g., "_abc123...")
    @ObservationIgnored public private(set) var sharedZoneOwnerName: String?

    /// The current user's actual CloudKit record ID (not __defaultOwner__)
    /// This is needed for storing photo ownership so other users can download
    public private(set) var currentUserRecordName: String?

    // MARK: - Share Manager

    /// Share manager for managing CloudKit shares
    @ObservationIgnored public let shareManager = CloudKitShareManager()

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

    @ObservationIgnored private let logger = Logger.otis(category: "CloudKitService")

    /// Device identifier for tracking which device created records
    @ObservationIgnored private let deviceID: String = {
        let key = "otis.device.id"
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

                // Fetch the current user's actual record ID (not __defaultOwner__)
                // This is needed for photo sharing between users
                do {
                    let userRecordID = try await container.userRecordID()
                    currentUserRecordName = userRecordID.recordName
                    logger.info("Current user record name: \(userRecordID.recordName)")
                } catch {
                    logger.error("Failed to get user record ID: \(error.localizedDescription)")
                }

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
    @ObservationIgnored private var wasParticipant = false

    /// Check if user is a participant in a shared zone
    private func checkParticipantStatus() async {
        do {
            // Check shared database for any zones
            logger.info("Checking shared database for zones...")
            let zones = try await sharedDatabase.allRecordZones()
            logger.info("Found \(zones.count) zone(s) in shared database")

            for zone in zones {
                logger.info("  Zone: \(zone.zoneID.zoneName) (owner: \(zone.zoneID.ownerName))")
            }

            let nowParticipant = !zones.isEmpty

            // Capture the owner's zone name for media fetches
            // Look for the Core Data zone specifically
            if let coreDataZone = zones.first(where: { $0.zoneID.zoneName == zoneName }) {
                sharedZoneOwnerName = coreDataZone.zoneID.ownerName
                logger.info("Found shared zone owner: \(coreDataZone.zoneID.ownerName)")
            } else if let firstZone = zones.first {
                // Fallback to first zone if no exact match
                sharedZoneOwnerName = firstZone.zoneID.ownerName
                logger.info("Using first shared zone owner: \(firstZone.zoneID.ownerName)")
            } else {
                sharedZoneOwnerName = nil
                logger.info("No shared zones found - user is not a participant")
            }

            // Detect if access was revoked
            if wasParticipant && !nowParticipant {
                logger.info("Participant access was revoked")
                shareManager.clearShareState()
                sharedZoneOwnerName = nil
                NotificationCenter.default.post(name: .shareAccessRevoked, object: nil)
            }

            wasParticipant = isParticipant
            isParticipant = nowParticipant
            logger.info("Participant status: \(self.isParticipant)")
        } catch {
            logger.error("Failed to check participant status: \(error.localizedDescription)")
            isParticipant = false
            sharedZoneOwnerName = nil
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
    /// The container parameter is kept for API compatibility but is no longer used
    /// (sharing now uses direct CloudKit APIs, not NSPersistentCloudKitContainer)
    public func refreshShareState(
        for profile: NSManagedObject,
        using persistentContainer: Any
    ) async {
        await shareManager.refreshShareState(for: profile, using: persistentContainer)
    }

    /// Get or create a share for the profile
    /// The container parameter is kept for API compatibility but is no longer used
    /// (sharing now uses direct CloudKit APIs, not NSPersistentCloudKitContainer)
    public func getOrCreateShare(
        for profile: NSManagedObject,
        using persistentContainer: Any
    ) async throws -> CKShare {
        try await shareManager.getOrCreateShare(for: profile, using: persistentContainer)
    }

    /// Stop sharing (owner only)
    public func stopSharing() async throws {
        try await shareManager.stopSharing()
    }

    // MARK: - Share Acceptance

    /// Accept a CloudKit share invitation
    /// Uses direct CloudKit API (CKAcceptSharesOperation) instead of NSPersistentCloudKitContainer
    public func acceptShareInvitation(from metadata: CKShare.Metadata) async throws {
        logger.info("Accepting share invitation...")
        logger.info("  Share record ID: \(metadata.share.recordID)")
        logger.info("  Zone: \(metadata.share.recordID.zoneID.zoneName)")
        logger.info("  Owner: \(metadata.share.recordID.zoneID.ownerName)")
        logger.info("  Container: \(metadata.containerIdentifier)")

        return try await withCheckedThrowingContinuation { continuation in
            let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])

            operation.perShareResultBlock = { [weak self] shareMetadata, result in
                guard let self else { return }

                switch result {
                case .success(let acceptedShare):
                    logger.info("Share accepted successfully")
                    logger.info("  Share URL: \(acceptedShare.url?.absoluteString ?? "none")")
                case .failure(let error):
                    logger.error("Failed to accept share: \(error.localizedDescription)")
                }
            }

            operation.acceptSharesResultBlock = { [weak self] result in
                guard let self else { return }

                switch result {
                case .success:
                    logger.info("Share invitation accepted successfully")
                    continuation.resume()
                case .failure(let error):
                    logger.error("Share acceptance failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }

            operation.qualityOfService = .userInitiated
            container.add(operation)
        }
    }

    /// Mark the user as a participant after share acceptance
    public func markAsParticipant() {
        isParticipant = true
        logger.info("Marked as participant after share acceptance")
    }

    // MARK: - Container Access

    /// Get the CloudKit container for share operations
    public var cloudKitContainer: CKContainer {
        container
    }

    // MARK: - Asset Services

    /// Lazily create an AssetCloudService with the given configuration
    private func createAssetService(config: AssetCloudConfig) -> AssetCloudService {
        AssetCloudService(
            config: config,
            deviceID: deviceID,
            getDatabase: { [weak self] in
                guard let self = self else { return CKContainer.default().privateCloudDatabase }
                return self.isParticipant ? self.sharedDatabase : self.privateDatabase
            },
            getZoneID: { [weak self] in
                guard let self = self else {
                    return CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
                }
                let ownerName = self.isParticipant ? (self.sharedZoneOwnerName ?? CKCurrentUserDefaultName) : CKCurrentUserDefaultName
                return CKRecordZone.ID(zoneName: self.zoneName, ownerName: ownerName)
            },
            isCloudAvailable: { [weak self] in
                self?.isCloudAvailable ?? false
            },
            getCurrentUserRecordName: { [weak self] in
                self?.currentUserRecordName
            }
        )
    }

    /// Media service for photo operations (event photos)
    @ObservationIgnored public lazy var mediaService: AssetCloudService = {
        createAssetService(config: .eventMedia)
    }()

    /// Profile photo service for syncing profile photos via CloudKit
    @ObservationIgnored public lazy var profilePhotoService: AssetCloudService = {
        createAssetService(config: .profilePhoto)
    }()

    // MARK: - Photo Operations

    /// Upload a photo to CloudKit
    /// - Returns: Upload result containing the record ID and zone owner name (needed for partner downloads)
    public func uploadPhoto(
        localURL: URL,
        eventId: UUID
    ) async throws -> AssetUploadResult {
        try await mediaService.upload(localURL: localURL, entityId: eventId)
    }

    /// Download a photo from CloudKit
    /// - Parameters:
    ///   - eventId: Event ID
    ///   - destinationURL: Where to save the photo
    ///   - ownerName: Optional zone owner name. Required when downloading photos from a partner.
    public func downloadPhoto(
        eventId: UUID,
        to destinationURL: URL,
        ownerName: String? = nil
    ) async throws -> Bool {
        try await mediaService.download(entityId: eventId, to: destinationURL, ownerName: ownerName)
    }

    /// Delete a photo from CloudKit
    public func deletePhoto(eventId: UUID) async throws {
        try await mediaService.delete(entityId: eventId)
    }

    // MARK: - Profile Photo Operations

    /// Upload a profile photo to CloudKit
    public func uploadProfilePhoto(
        localURL: URL,
        profileId: UUID
    ) async throws -> CKRecord.ID {
        let result = try await profilePhotoService.upload(localURL: localURL, entityId: profileId)
        return result.recordID
    }

    /// Download a profile photo from CloudKit
    /// - Parameters:
    ///   - profileId: Profile ID to download photo for
    ///   - destinationURL: Where to save the photo
    ///   - ownerName: Optional zone owner name. Required when downloading photos from a shared profile.
    public func downloadProfilePhoto(
        profileId: UUID,
        to destinationURL: URL,
        ownerName: String? = nil
    ) async throws -> Bool {
        try await profilePhotoService.download(entityId: profileId, to: destinationURL, ownerName: ownerName)
    }

    /// Delete a profile photo from CloudKit
    public func deleteProfilePhoto(profileId: UUID) async throws {
        try await profilePhotoService.delete(entityId: profileId)
    }

    /// Check if a profile photo exists in CloudKit
    public func profilePhotoExists(profileId: UUID) async throws -> Bool {
        try await profilePhotoService.exists(entityId: profileId)
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let cloudKitShareAccepted = Notification.Name("cloudKitShareAccepted")
    static let cloudKitShareReceived = Notification.Name("cloudKitShareReceived")
    static let shareAccessRevoked = Notification.Name("shareAccessRevoked")
    /// Posted after share acceptance to trigger role selection UI
    /// userInfo: ["profileId": UUID, "dogName": String]
    static let showRoleSelectionForSharedProfile = Notification.Name("showRoleSelectionForSharedProfile")
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
