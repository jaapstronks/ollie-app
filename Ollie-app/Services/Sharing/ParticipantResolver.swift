//
//  ParticipantResolver.swift
//  Ollie-app
//
//  Resolves CloudKit share participants to display information.
//  Used for showing partner names and info in handover cards.
//

import Foundation
import CloudKit
import os
import OtisShared

/// Resolved participant information from CloudKit
public struct ResolvedParticipant: Identifiable, Equatable, Sendable {
    public var id: String { cloudKitRecordID }

    /// CloudKit user record ID (stable identifier)
    public let cloudKitRecordID: String

    /// Display name (from CloudKit or user-provided)
    public let displayName: String

    /// Whether this is the current user
    public let isCurrentUser: Bool

    /// Participant acceptance status
    public let status: Status

    public enum Status: Sendable {
        case owner
        case accepted
        case pending
        case unknown
    }

    public init(
        cloudKitRecordID: String,
        displayName: String,
        isCurrentUser: Bool,
        status: Status = .unknown
    ) {
        self.cloudKitRecordID = cloudKitRecordID
        self.displayName = displayName
        self.isCurrentUser = isCurrentUser
        self.status = status
    }
}

/// Service to resolve CloudKit participant identities
@Observable
@MainActor
public final class ParticipantResolver {
    public static let shared = ParticipantResolver()

    @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Ollie", category: "ParticipantResolver")

    /// Cache of resolved participants
    public private(set) var resolvedParticipants: [String: ResolvedParticipant] = [:]

    /// Whether we're currently resolving
    public private(set) var isResolving: Bool = false

    /// Last resolution time
    public private(set) var lastResolutionTime: Date?

    private init() {}

    // MARK: - Public Methods

    /// Get display name for a CloudKit record ID
    /// Convenience method that returns just the name string
    /// - Parameter cloudKitRecordID: The CloudKit record ID
    /// - Returns: Display name for the participant
    public func displayName(for cloudKitRecordID: String) -> String {
        resolve(cloudKitRecordID: cloudKitRecordID).displayName
    }

    /// Resolve a CloudKit user record ID to display info
    /// - Parameter cloudKitRecordID: The CloudKit record ID to resolve
    /// - Returns: Resolved participant info, or a placeholder if not found
    public func resolve(cloudKitRecordID: String) -> ResolvedParticipant {
        // Check if it's the current user
        if UserIdentityStore.shared.isCurrentUser(cloudKitRecordID) {
            let name = UserIdentityStore.shared.currentIdentity?.name ?? Strings.UserProfile.me
            return ResolvedParticipant(
                cloudKitRecordID: cloudKitRecordID,
                displayName: name,
                isCurrentUser: true,
                status: .owner
            )
        }

        // Check local cache first
        if let cached = resolvedParticipants[cloudKitRecordID] {
            return cached
        }

        // Check Core Data for synced family member identity
        // This is the key lookup - identities synced via CloudKit from other family members
        if let syncedIdentity = UserIdentityStore.shared.fetchIdentity(byCloudKitRecordID: cloudKitRecordID) {
            let name = syncedIdentity.name.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty && name != Strings.UserProfile.me {
                // Cache it for future lookups
                let resolved = ResolvedParticipant(
                    cloudKitRecordID: cloudKitRecordID,
                    displayName: name,
                    isCurrentUser: false,
                    status: .accepted
                )
                resolvedParticipants[cloudKitRecordID] = resolved
                return resolved
            }
        }

        // Return placeholder - will be resolved when share participants are fetched
        // or when the family member syncs their identity
        return ResolvedParticipant(
            cloudKitRecordID: cloudKitRecordID,
            displayName: Strings.Handoff.partner,
            isCurrentUser: false,
            status: .unknown
        )
    }

    /// Get all participants from current CloudKit share
    /// - Returns: Array of resolved participants
    public func getAllParticipants() -> [ResolvedParticipant] {
        var participants = Array(resolvedParticipants.values)

        // Always include current user
        if let currentID = UserIdentityStore.shared.currentUserRecordID,
           !participants.contains(where: { $0.cloudKitRecordID == currentID }) {
            let currentUser = ResolvedParticipant(
                cloudKitRecordID: currentID,
                displayName: UserIdentityStore.shared.currentIdentity?.name ?? Strings.UserProfile.me,
                isCurrentUser: true,
                status: .owner
            )
            participants.insert(currentUser, at: 0)
        }

        return participants
    }

    /// Refresh participant info from CloudKit share
    public func refreshFromCloudKit() async {
        guard !isResolving else { return }

        isResolving = true
        defer { isResolving = false }

        do {
            // Get the shared database
            let container = CKContainer.default()
            let sharedDB = container.sharedCloudDatabase

            // Fetch all shared zones
            let zones = try await sharedDB.allRecordZones()

            for zone in zones {
                // Try to get share for this zone
                if let share = try? await sharedDB.record(for: CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone.zoneID)) as? CKShare {
                    await processShare(share)
                }
            }

            // Also check private database for shares we own
            let privateDB = container.privateCloudDatabase
            let privateZones = try await privateDB.allRecordZones()

            for zone in privateZones {
                if let share = try? await privateDB.record(for: CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone.zoneID)) as? CKShare {
                    await processShare(share)
                }
            }

            lastResolutionTime = Date()
            logger.info("Resolved \(self.resolvedParticipants.count) participants")

        } catch {
            logger.error("Failed to refresh participants: \(error.localizedDescription)")
        }
    }

    /// Register a participant manually (e.g., from event data)
    /// - Parameters:
    ///   - recordID: CloudKit record ID
    ///   - name: Display name (optional)
    public func registerParticipant(recordID: String, name: String? = nil) {
        guard !UserIdentityStore.shared.isCurrentUser(recordID) else { return }
        guard resolvedParticipants[recordID] == nil else { return }

        let participant = ResolvedParticipant(
            cloudKitRecordID: recordID,
            displayName: name ?? Strings.Handoff.partner,
            isCurrentUser: false,
            status: .unknown
        )

        resolvedParticipants[recordID] = participant
    }

    /// Refresh participant cache from Core Data synced identities
    /// Call this when Core Data receives CloudKit updates
    public func refreshFromSyncedIdentities() {
        let familyMembers = UserIdentityStore.shared.fetchFamilyMemberIdentities()

        for identity in familyMembers {
            let name = identity.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty && name != Strings.UserProfile.me else { continue }

            let resolved = ResolvedParticipant(
                cloudKitRecordID: identity.cloudKitUserRecordID,
                displayName: name,
                isCurrentUser: false,
                status: .accepted
            )
            resolvedParticipants[identity.cloudKitUserRecordID] = resolved
        }

        if !familyMembers.isEmpty {
            logger.info("Refreshed \(familyMembers.count) participants from synced identities")
        }
    }

    /// Clear the cache to force re-resolution
    /// Useful when identities may have been updated
    public func clearCache() {
        resolvedParticipants.removeAll()
        logger.debug("Cleared participant cache")
    }

    // MARK: - Private Methods

    private func processShare(_ share: CKShare) async {
        for participant in share.participants {
            guard let recordID = participant.userIdentity.userRecordID?.recordName else { continue }

            // Skip current user
            if UserIdentityStore.shared.isCurrentUser(recordID) { continue }

            // Get display name from CloudKit participant
            let displayName: String
            if let nameComponents = participant.userIdentity.nameComponents {
                displayName = PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
            } else {
                displayName = Strings.Handoff.partner
            }

            let status: ResolvedParticipant.Status
            switch participant.acceptanceStatus {
            case .accepted: status = .accepted
            case .pending: status = .pending
            case .removed: continue  // Skip removed participants
            case .unknown: status = .unknown
            @unknown default: status = .unknown
            }

            let isOwner = participant.role == .owner

            let resolved = ResolvedParticipant(
                cloudKitRecordID: recordID,
                displayName: displayName,
                isCurrentUser: false,
                status: isOwner ? .owner : status
            )

            resolvedParticipants[recordID] = resolved
        }
    }
}
