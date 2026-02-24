//
//  CloudKitShareManager.swift
//  OllieShared
//
//  Manages CloudKit sharing functionality

import Foundation
import CloudKit
import Combine
import os

/// Handles CloudKit share creation, management, and participant tracking
@MainActor
public final class CloudKitShareManager: ObservableObject {
    private let privateDatabase: CKDatabase
    private let zoneID: CKRecordZone.ID
    private let zoneManager: CloudKitZoneManager

    private let logger = Logger.ollie(category: "CloudKitShare")

    // MARK: - Published State

    @Published public private(set) var isShared = false
    @Published public private(set) var shareParticipants: [ShareParticipant] = []

    // MARK: - Init

    public init(
        privateDatabase: CKDatabase,
        zoneID: CKRecordZone.ID,
        zoneManager: CloudKitZoneManager
    ) {
        self.privateDatabase = privateDatabase
        self.zoneID = zoneID
        self.zoneManager = zoneManager
    }

    // MARK: - Share Creation

    /// Create a share for the events zone (does NOT update UI state - caller should call updateShareState after sheet is dismissed)
    public func createShare() async throws -> CKShare {
        // Ensure zone exists
        try await zoneManager.createZoneIfNeeded()

        // Check if share already exists (pure fetch, no side effects)
        if let existingShare = try await fetchShareRecord() {
            return existingShare
        }

        // Create new share for the zone
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = "Ollie - Puppy Events"
        share.publicPermission = .none // Invite-only

        _ = try await privateDatabase.save(share)

        logger.info("Created new share for zone")
        return share
    }

    // MARK: - Share Fetching

    /// Pure fetch - gets share record without updating any UI state
    private func fetchShareRecord() async throws -> CKShare? {
        do {
            let zone = try await privateDatabase.recordZone(for: zoneID)

            if let shareRef = zone.share {
                return try await privateDatabase.record(for: shareRef.recordID) as? CKShare
            }
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return nil
            }
            throw error
        }

        return nil
    }

    /// Fetch existing share for the zone (updates UI state)
    public func fetchExistingShare() async throws -> CKShare? {
        let share = try await fetchShareRecord()
        // Don't update state here - let caller decide when to update
        return share
    }

    /// Update the shared state based on current CloudKit status
    public func updateShareState() async {
        do {
            if let share = try await fetchShareRecord() {
                isShared = true
                updateParticipants(from: share)
            } else {
                isShared = false
                shareParticipants = []
            }
        } catch {
            logger.error("Failed to update share state: \(error.localizedDescription)")
        }
    }

    // MARK: - Participants

    /// Update participants from a share object (no async fetch)
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

    /// Stop sharing (remove all participants)
    public func stopSharing() async throws {
        // Fetch without side effects
        guard let share = try await fetchShareRecord() else {
            // No share exists, reset state
            isShared = false
            shareParticipants = []
            logger.info("No share to stop, reset state")
            return
        }

        try await privateDatabase.deleteRecord(withID: share.recordID)
        isShared = false
        shareParticipants = []

        logger.info("Stopped sharing")
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
