//
//  CloudKitShareManager.swift
//  OtisShared
//
//  Manages CloudKit sharing functionality using direct CloudKit APIs.
//  Works with CKSyncEngine-based sync (not NSPersistentCloudKitContainer).
//

import Foundation
import CloudKit
import CoreData
import os

/// Handles CloudKit share management
/// Uses direct CloudKit APIs instead of NSPersistentCloudKitContainer
@Observable
@MainActor
public final class CloudKitShareManager {
    @ObservationIgnored private let container: CKContainer
    @ObservationIgnored private let logger = Logger.otis(category: "CloudKitShare")
    @ObservationIgnored private let zoneName = "com.apple.coredata.cloudkit.zone"

    // MARK: - Published State

    public private(set) var isShared = false
    public private(set) var shareParticipants: [ShareParticipant] = []
    public private(set) var currentShare: CKShare?
    public private(set) var isLoading = false
    public private(set) var error: String?

    // MARK: - Init

    public init(containerIdentifier: String = "iCloud.nl.jaapstronks.Otis") {
        self.container = CKContainer(identifier: containerIdentifier)
    }

    // MARK: - Zone ID

    private var privateZoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    // MARK: - Share Creation

    /// Create or get existing share for a profile using direct CloudKit APIs
    /// Returns existing share if one exists, otherwise creates a new one
    public func getOrCreateShare(for profileId: UUID) async throws -> CKShare {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // First check if a share already exists
        if let existingShare = try await fetchExistingShare(for: profileId) {
            logger.info("Found existing share")
            return existingShare
        }

        // CKSyncEngine uses CD_ prefix for record types (NSPersistentCloudKitContainer compatibility)
        let rootRecordID = CKRecord.ID(
            recordName: "\(RecordType.puppyProfile):\(profileId.uuidString)",
            zoneID: privateZoneID
        )

        // Try to fetch the root record from CloudKit
        // If it doesn't exist (CKSyncEngine hasn't synced it yet), build it locally
        let rootRecord: CKRecord
        do {
            rootRecord = try await container.privateCloudDatabase.record(for: rootRecordID)
            logger.info("Found existing profile record in CloudKit")
        } catch let ckError as CKError where ckError.code == .unknownItem {
            // Record doesn't exist in CloudKit yet - build it from Core Data
            logger.info("Profile not in CloudKit yet, building record from Core Data")

            guard let record = await buildProfileRecord(for: profileId, recordID: rootRecordID) else {
                logger.error("Failed to build profile record from Core Data")
                throw CloudKitError.recordNotFound
            }
            rootRecord = record
        } catch {
            logger.error("Failed to fetch profile record: \(error.localizedDescription)")
            throw error
        }

        // Create a new share for this record
        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = "Ollie - Puppy Data"
        share.publicPermission = .none // Invite-only

        // Save the share to CloudKit
        let modifyOperation = CKModifyRecordsOperation(
            recordsToSave: [share, rootRecord],
            recordIDsToDelete: nil
        )
        modifyOperation.savePolicy = .changedKeys
        modifyOperation.qualityOfService = .userInitiated

        return try await withCheckedThrowingContinuation { continuation in
            modifyOperation.modifyRecordsResultBlock = { [weak self] result in
                guard let self else { return }

                switch result {
                case .success:
                    logger.info("Created new share using direct CloudKit API")
                    currentShare = share
                    Task { @MainActor in
                        await self.updateShareState()
                    }
                    continuation.resume(returning: share)
                case .failure(let error):
                    logger.error("Failed to create share: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }

            container.privateCloudDatabase.add(modifyOperation)
        }
    }

    /// Legacy method that accepts NSManagedObject - extracts profile ID and delegates
    public func getOrCreateShare(
        for profile: NSManagedObject,
        using persistentContainer: Any  // Accepts any container type for compatibility
    ) async throws -> CKShare {
        guard let profileId = profile.value(forKey: "id") as? UUID else {
            throw CloudKitError.invalidData
        }
        return try await getOrCreateShare(for: profileId)
    }

    /// Get existing share for a profile
    /// Fetches the share directly using the record ID convention
    public func fetchExistingShare(for profileId: UUID) async throws -> CKShare? {
        // Try to fetch the profile record and check if it has a share
        // Uses CD_ prefix to match CKSyncEngine/NSPersistentCloudKitContainer format
        let profileRecordID = CKRecord.ID(
            recordName: "\(RecordType.puppyProfile):\(profileId.uuidString)",
            zoneID: privateZoneID
        )

        do {
            // Fetch the profile record
            let profileRecord = try await container.privateCloudDatabase.record(for: profileRecordID)

            // Check if this record has a share by looking at the share reference
            if let shareReference = profileRecord.share {
                // Fetch the share record
                let shareRecord = try await container.privateCloudDatabase.record(for: shareReference.recordID)
                if let share = shareRecord as? CKShare {
                    currentShare = share
                    await updateShareState()
                    return share
                }
            }

            return nil
        } catch let ckError as CKError where ckError.code == .unknownItem {
            // Profile or share not found in CloudKit
            return nil
        }
    }

    /// Legacy method that accepts NSManagedObject - extracts profile ID and delegates
    public func fetchExistingShare(
        for profile: NSManagedObject,
        using persistentContainer: Any  // Accepts any container type for compatibility
    ) async throws -> CKShare? {
        guard let profileId = profile.value(forKey: "id") as? UUID else {
            throw CloudKitError.invalidData
        }
        return try await fetchExistingShare(for: profileId)
    }

    // MARK: - State Updates

    /// Update the shared state based on current share
    public func updateShareState() async {
        guard let share = currentShare else {
            isShared = false
            shareParticipants = []
            return
        }

        isShared = true
        updateParticipants(from: share)
    }

    /// Refresh share state from CloudKit by re-fetching
    public func refreshShareState(for profileId: UUID) async {
        do {
            if let share = try await fetchExistingShare(for: profileId) {
                currentShare = share
                await updateShareState()
            } else {
                currentShare = nil
                isShared = false
                shareParticipants = []
            }
        } catch {
            logger.error("Failed to refresh share state: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    /// Legacy method that accepts NSManagedObject - extracts profile ID and delegates
    public func refreshShareState(
        for profile: NSManagedObject,
        using persistentContainer: Any  // Accepts any container type for compatibility
    ) async {
        guard let profileId = profile.value(forKey: "id") as? UUID else {
            logger.error("Cannot refresh share state: profile has no ID")
            return
        }
        await refreshShareState(for: profileId)
    }

    // MARK: - Participants

    private func updateParticipants(from share: CKShare) {
        shareParticipants = share.participants.compactMap { participant in
            guard participant.role != .owner else { return nil }

            let name = participant.userIdentity.nameComponents?.formatted() ?? "Partner"
            let status: ShareParticipant.Status

            switch participant.acceptanceStatus {
            case .accepted:
                status = .accepted
            case .pending:
                status = .pending
            case .removed:
                status = .removed
            case .unknown:
                status = .pending
            @unknown default:
                status = .pending
            }

            return ShareParticipant(name: name, status: status)
        }
    }

    /// Refresh the list of share participants
    public func refreshShareParticipants() async {
        await updateShareState()
    }

    // MARK: - Profile Record Builder

    /// Build a profile CKRecord from Core Data when it doesn't exist in CloudKit yet
    /// Uses SyncCoordinator's ProfileSyncHandler to ensure correct field mapping
    @available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
    private func buildProfileRecord(for profileId: UUID, recordID: CKRecord.ID) async -> CKRecord? {
        guard let viewContext = SyncCoordinator.shared.viewContext else {
            logger.error("No view context available for building profile record")
            return nil
        }

        // Use ProfileSyncHandler to build the record with correct field mapping
        let handler = ProfileSyncHandler()
        let identifier = "\(RecordType.puppyProfile):\(profileId.uuidString)"

        return await handler.fetchRecord(
            for: identifier,
            zoneID: privateZoneID,
            in: viewContext
        )
    }

    // MARK: - Stop Sharing

    /// Stop sharing by deleting the CKShare record
    /// This removes participant access but owner keeps all data
    public func stopSharing() async throws {
        guard let share = currentShare else {
            isShared = false
            shareParticipants = []
            logger.info("No share to stop")
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // Delete the share record from CloudKit
        // This stops sharing but preserves owner's data
        let database = container.privateCloudDatabase
        try await database.deleteRecord(withID: share.recordID)

        currentShare = nil
        isShared = false
        shareParticipants = []

        logger.info("Stopped sharing - participants removed, owner data preserved")
    }

    /// Clear local share state (used when share was removed externally)
    public func clearShareState() {
        currentShare = nil
        isShared = false
        shareParticipants = []
        error = nil
    }
}

// MARK: - Supporting Types

public struct ShareParticipant: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let status: Status

    public init(name: String, status: Status) {
        self.name = name
        self.status = status
    }

    public enum Status: Sendable {
        case pending
        case accepted
        case removed

        public var label: String {
            switch self {
            case .pending: return Strings.CloudSharing.statusPending
            case .accepted: return Strings.CloudSharing.statusAccepted
            case .removed: return Strings.CloudSharing.statusRemoved
            }
        }
    }
}
