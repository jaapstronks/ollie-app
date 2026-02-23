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

    private let logger = Logger(subsystem: "nl.jaapstronks.Ollie", category: "CloudKitShare")

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

    /// Create a share for the events zone
    public func createShare() async throws -> CKShare {
        // Ensure zone exists
        try await zoneManager.createZoneIfNeeded()

        // Check if share already exists
        if let existingShare = try await fetchExistingShare() {
            return existingShare
        }

        // Create new share for the zone
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = "Ollie - Puppy Events"
        share.publicPermission = .none // Invite-only

        _ = try await privateDatabase.save(share)

        isShared = true
        await refreshShareParticipants()

        logger.info("Created new share for zone")
        return share
    }

    // MARK: - Share Fetching

    /// Fetch existing share for the zone
    public func fetchExistingShare() async throws -> CKShare? {
        do {
            let zone = try await privateDatabase.recordZone(for: zoneID)

            if let shareRef = zone.share {
                let share = try await privateDatabase.record(for: shareRef.recordID) as? CKShare

                if share != nil {
                    isShared = true
                    await refreshShareParticipants()
                }

                return share
            }
        } catch let error as CKError {
            if error.code == .zoneNotFound {
                return nil
            }
            throw error
        }

        return nil
    }

    // MARK: - Participants

    /// Refresh the list of share participants
    public func refreshShareParticipants() async {
        guard let share = try? await fetchExistingShare() else {
            shareParticipants = []
            return
        }

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

    // MARK: - Stop Sharing

    /// Stop sharing (remove all participants)
    public func stopSharing() async throws {
        guard let share = try await fetchExistingShare() else {
            // No share exists, reset state anyway
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
