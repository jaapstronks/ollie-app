//
//  CloudKitShareManager.swift
//  OllieShared
//
//  Manages CloudKit sharing functionality using NSPersistentCloudKitContainer
//

import Foundation
import CloudKit
import CoreData
import Combine
import os

/// Handles CloudKit share management for Core Data
/// Uses NSPersistentCloudKitContainer's sharing APIs
@MainActor
public final class CloudKitShareManager: ObservableObject {
    private let container: CKContainer
    private let logger = Logger.ollie(category: "CloudKitShare")

    // MARK: - Published State

    @Published public private(set) var isShared = false
    @Published public private(set) var shareParticipants: [ShareParticipant] = []
    @Published public private(set) var currentShare: CKShare?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: String?

    // MARK: - Init

    public init(containerIdentifier: String = "iCloud.nl.jaapstronks.Ollie") {
        self.container = CKContainer(identifier: containerIdentifier)
    }

    // MARK: - Share Creation with Core Data

    /// Create or get existing share for a profile using NSPersistentCloudKitContainer
    /// Returns existing share if one exists, otherwise creates a new one
    public func getOrCreateShare(
        for profile: NSManagedObject,
        using persistentContainer: NSPersistentCloudKitContainer
    ) async throws -> CKShare {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // First check if a share already exists
        if let existingShare = try await fetchExistingShare(for: profile, using: persistentContainer) {
            logger.info("Found existing share")
            return existingShare
        }

        // Create new share using Core Data's sharing API
        let (_, share, _) = try await persistentContainer.share([profile], to: nil)

        // Configure the share
        share[CKShare.SystemFieldKey.title] = "Ollie - Puppy Data"
        share.publicPermission = .none // Invite-only

        currentShare = share
        await updateShareState()

        logger.info("Created new share using Core Data")
        return share
    }

    /// Get existing share for a profile
    public func fetchExistingShare(
        for profile: NSManagedObject,
        using persistentContainer: NSPersistentCloudKitContainer
    ) async throws -> CKShare? {
        let shares = try persistentContainer.fetchShares(matching: [profile.objectID])
        let share = shares[profile.objectID]
        if share != nil {
            currentShare = share
            await updateShareState()
        }
        return share
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
    public func refreshShareState(
        for profile: NSManagedObject,
        using persistentContainer: NSPersistentCloudKitContainer
    ) async {
        do {
            if let share = try await fetchExistingShare(for: profile, using: persistentContainer) {
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

    // MARK: - Share Acceptance

    /// Accept a share invitation using NSPersistentCloudKitContainer
    public func acceptShare(
        _ metadata: CKShare.Metadata,
        into store: NSPersistentStore,
        using persistentContainer: NSPersistentCloudKitContainer
    ) async throws {
        try await persistentContainer.acceptShareInvitations(from: [metadata], into: store)
        logger.info("Share invitation accepted via Core Data")
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
