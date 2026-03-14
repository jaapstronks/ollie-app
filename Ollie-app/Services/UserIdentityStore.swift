//
//  UserIdentityStore.swift
//  Ollie-app
//
//  Manages the local user's identity for event attribution.
//  Each iCloud account = one user identity. The CloudKit user record ID
//  is the source of truth for identity across devices.
//
//  User identities are stored in both:
//  - UserDefaults (for offline/local access)
//  - Core Data shared zone (syncs to all family members via CloudKit)
//

import Foundation
import CloudKit
import CoreData
import os
import OtisShared

/// Manages the current user's identity for event attribution
/// Uses CloudKit user record ID as the stable identifier across devices
@Observable
@MainActor
public final class UserIdentityStore {

    // MARK: - Singleton

    public static let shared = UserIdentityStore()

    /// Cached current user record ID for nonisolated access
    /// Updated whenever cloudKitRecordID changes on main actor
    nonisolated(unsafe) public static var cachedCurrentUserRecordID: String?

    // MARK: - Published State

    public private(set) var currentIdentity: UserIdentity?
    public private(set) var isSetupComplete = false
    public private(set) var cloudKitRecordID: String?

    // MARK: - Private

    @ObservationIgnored private let logger = Logger.otis(category: "UserIdentityStore")
    @ObservationIgnored private let container: CKContainer
    @ObservationIgnored private let userDefaultsKey = "otis.user.identity"

    /// Profile store reference for CloudKit sharing (set during app setup)
    @ObservationIgnored private weak var profileStore: ProfileStore?

    // MARK: - Init

    private init(containerIdentifier: String = "iCloud.nl.jaapstronks.Otis") {
        self.container = CKContainer(identifier: containerIdentifier)
        loadCachedIdentity()
    }

    // MARK: - Configuration

    /// Configure the profile store for CloudKit sharing
    /// Call this after profile store is initialized
    func configureProfileStore(_ store: ProfileStore) {
        self.profileStore = store
        // Migrate orphaned identities to profile
        migrateOrphanedIdentities()
    }

    /// Migrate orphaned user identity records to the current profile
    /// This ensures existing local-only records get synced to CloudKit shared zone
    private func migrateOrphanedIdentities() {
        guard let profileId = profileStore?.profile?.id else { return }

        let context = PersistenceController.shared.container.viewContext
        context.perform {
            guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else { return }

            let orphaned = CDUserIdentity.fetchOrphaned(in: context)
            guard !orphaned.isEmpty else { return }

            let orphanedCount = orphaned.count
            Task { @MainActor in
                self.logger.info("Migrating \(orphanedCount) orphaned user identities to profile")
            }

            for cdIdentity in orphaned {
                cdIdentity.profile = cdProfile
            }

            if context.hasChanges {
                do {
                    try context.save()
                    Task { @MainActor in
                        self.logger.info("Migrated orphaned user identities to profile")
                    }
                } catch {
                    Task { @MainActor in
                        self.logger.error("Failed to migrate orphaned identities: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Setup

    /// Setup the user identity store
    /// Call this on app launch to fetch/refresh the CloudKit user record ID
    public func setup() async {
        do {
            // Fetch CloudKit user record ID using continuation for Swift 6 compatibility
            let recordID = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord.ID, Error>) in
                container.fetchUserRecordID { recordID, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let recordID = recordID {
                        continuation.resume(returning: recordID)
                    } else {
                        continuation.resume(throwing: CKError(.internalError))
                    }
                }
            }
            cloudKitRecordID = recordID.recordName
            Self.cachedCurrentUserRecordID = recordID.recordName
            logger.info("CloudKit user record ID: \(recordID.recordName)")

            // Check if we have an existing identity with this CloudKit ID
            if var identity = currentIdentity {
                // Update CloudKit ID if it changed (shouldn't normally happen)
                if identity.cloudKitUserRecordID != recordID.recordName {
                    identity = UserIdentity(
                        id: identity.id,
                        name: identity.name,
                        avatarData: identity.avatarData,
                        colorHex: identity.colorHex,
                        cloudKitUserRecordID: recordID.recordName,
                        responsibilityLevel: identity.responsibilityLevel,
                        enabledNudges: identity.enabledNudges,
                        createdAt: identity.createdAt,
                        modifiedAt: Date()
                    )
                    currentIdentity = identity
                    saveIdentity(identity)
                }
            } else {
                // Create default identity with just the CloudKit ID
                // User can set their name later
                let defaultName = Strings.UserProfile.me
                let identity = UserIdentity(
                    name: defaultName,
                    cloudKitUserRecordID: recordID.recordName
                )
                currentIdentity = identity
                saveIdentity(identity)
                logger.info("Created default user identity")
            }

            isSetupComplete = true
            notifySetupComplete()
        } catch {
            logger.warning("Could not fetch CloudKit user record ID: \(error.localizedDescription)")
            // Still mark as complete - we'll use local-only identity
            // This happens when iCloud is unavailable
            if currentIdentity == nil {
                // Create a local-only identity with a placeholder CloudKit ID
                let localID = "local-\(UUID().uuidString)"
                let identity = UserIdentity(
                    name: Strings.UserProfile.me,
                    cloudKitUserRecordID: localID
                )
                currentIdentity = identity
                saveIdentity(identity)
                logger.info("Created local-only user identity")
            }
            isSetupComplete = true
            notifySetupComplete()
        }
    }

    /// Notify that user identity setup is complete.
    /// This allows other stores to reload user-specific data.
    private func notifySetupComplete() {
        // Reload sentiment data for the current user
        Task {
            await SentimentStore.shared.loadCheckInsFromCoreData()
        }
    }

    // MARK: - Current User ID for Attribution

    /// Get the current user's CloudKit record ID for event attribution
    /// Returns nil if setup hasn't completed
    public var currentUserRecordID: String? {
        cloudKitRecordID ?? currentIdentity?.cloudKitUserRecordID
    }

    /// Check if a CloudKit record ID is the current user
    public func isCurrentUser(_ recordID: String) -> Bool {
        currentUserRecordID == recordID
    }

    // MARK: - Update Identity

    /// Update the user's display name
    public func updateName(_ name: String) {
        guard var identity = currentIdentity else { return }
        identity = UserIdentity(
            id: identity.id,
            name: name,
            avatarData: identity.avatarData,
            colorHex: identity.colorHex,
            cloudKitUserRecordID: identity.cloudKitUserRecordID,
            responsibilityLevel: identity.responsibilityLevel,
            enabledNudges: identity.enabledNudges,
            createdAt: identity.createdAt,
            modifiedAt: Date()
        )
        currentIdentity = identity
        saveIdentity(identity)
        logger.info("Updated user name to: \(name)")
    }

    /// Update the user's avatar
    public func updateAvatar(_ avatarData: Data?) {
        guard var identity = currentIdentity else { return }
        identity = UserIdentity(
            id: identity.id,
            name: identity.name,
            avatarData: avatarData,
            colorHex: identity.colorHex,
            cloudKitUserRecordID: identity.cloudKitUserRecordID,
            responsibilityLevel: identity.responsibilityLevel,
            enabledNudges: identity.enabledNudges,
            createdAt: identity.createdAt,
            modifiedAt: Date()
        )
        currentIdentity = identity
        saveIdentity(identity)
        logger.info("Updated user avatar")
    }

    /// Update the user's color
    public func updateColor(_ colorHex: String) {
        guard var identity = currentIdentity else { return }
        identity = UserIdentity(
            id: identity.id,
            name: identity.name,
            avatarData: identity.avatarData,
            colorHex: colorHex,
            cloudKitUserRecordID: identity.cloudKitUserRecordID,
            responsibilityLevel: identity.responsibilityLevel,
            enabledNudges: identity.enabledNudges,
            createdAt: identity.createdAt,
            modifiedAt: Date()
        )
        currentIdentity = identity
        saveIdentity(identity)
        logger.info("Updated user color to: \(colorHex)")
    }

    /// Update the user's responsibility level
    /// This also resets enabled nudges to the new level's defaults
    public func updateResponsibilityLevel(_ level: ResponsibilityLevel) {
        guard var identity = currentIdentity else { return }
        identity = UserIdentity(
            id: identity.id,
            name: identity.name,
            avatarData: identity.avatarData,
            colorHex: identity.colorHex,
            cloudKitUserRecordID: identity.cloudKitUserRecordID,
            responsibilityLevel: level,
            enabledNudges: level.defaultEnabledNudges,
            createdAt: identity.createdAt,
            modifiedAt: Date()
        )
        currentIdentity = identity
        saveIdentity(identity)
        logger.info("Updated responsibility level to: \(level.rawValue)")
    }

    /// Update which nudge categories are enabled for this user
    public func updateEnabledNudges(_ nudges: Set<NudgeCategory>) {
        guard var identity = currentIdentity else { return }
        identity = UserIdentity(
            id: identity.id,
            name: identity.name,
            avatarData: identity.avatarData,
            colorHex: identity.colorHex,
            cloudKitUserRecordID: identity.cloudKitUserRecordID,
            responsibilityLevel: identity.responsibilityLevel,
            enabledNudges: nudges,
            createdAt: identity.createdAt,
            modifiedAt: Date()
        )
        currentIdentity = identity
        saveIdentity(identity)
        logger.info("Updated enabled nudges")
    }

    /// Toggle a single nudge category on or off
    public func toggleNudge(_ category: NudgeCategory, enabled: Bool) {
        guard let identity = currentIdentity else { return }
        var nudges = identity.enabledNudges
        if enabled {
            nudges.insert(category)
        } else {
            nudges.remove(category)
        }
        updateEnabledNudges(nudges)
    }

    /// Check if a nudge category should be shown for the current user
    public func shouldShowNudge(_ category: NudgeCategory) -> Bool {
        currentIdentity?.shouldShowNudge(category) ?? true
    }

    // MARK: - Persistence

    private func loadCachedIdentity() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            let identity = try JSONDecoder().decode(UserIdentity.self, from: data)
            currentIdentity = identity
            cloudKitRecordID = identity.cloudKitUserRecordID
            Self.cachedCurrentUserRecordID = identity.cloudKitUserRecordID
            logger.debug("Loaded cached user identity")
        } catch {
            logger.error("Failed to decode cached identity: \(error.localizedDescription)")
        }
    }

    private func saveIdentity(_ identity: UserIdentity) {
        // Save to UserDefaults (local cache for offline access)
        do {
            let data = try JSONEncoder().encode(identity)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            logger.error("Failed to save identity to UserDefaults: \(error.localizedDescription)")
        }

        // Save to Core Data (syncs via CloudKit to other family members)
        saveToCoreData(identity)
    }

    /// Save identity to Core Data shared zone for CloudKit sync
    private func saveToCoreData(_ identity: UserIdentity) {
        let profileId = profileStore?.profile?.id
        let context = PersistenceController.shared.container.viewContext

        context.perform {
            // Link to profile for CloudKit sharing
            if let profileId = profileId,
               let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) {
                CDUserIdentity.upsert(identity, profile: cdProfile, in: context)
            } else {
                // Fallback: save without profile (will be migrated later)
                CDUserIdentity.upsert(identity, in: context)
                Task { @MainActor in
                    self.logger.warning("Saved user identity without profile link - will need migration")
                }
            }

            if context.hasChanges {
                do {
                    try context.save()
                    Task { @MainActor in
                        self.logger.info("Saved user identity to Core Data for CloudKit sync")
                    }
                } catch {
                    Task { @MainActor in
                        self.logger.error("Failed to save identity to Core Data: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Sync from CloudKit

    /// Fetch all family member identities from Core Data (synced via CloudKit)
    /// Returns identities for all users except the current user
    public func fetchFamilyMemberIdentities() -> [UserIdentity] {
        let context = PersistenceController.shared.container.viewContext
        let allIdentities = CDUserIdentity.fetchAllAsModels(in: context)

        // Exclude current user
        guard let currentID = currentUserRecordID else {
            return allIdentities
        }

        return allIdentities.filter { $0.cloudKitUserRecordID != currentID }
    }

    /// Fetch a specific user's identity by CloudKit record ID
    /// Returns nil if not found (user hasn't synced their identity yet)
    public func fetchIdentity(byCloudKitRecordID recordID: String) -> UserIdentity? {
        let context = PersistenceController.shared.container.viewContext
        return CDUserIdentity.fetch(byCloudKitRecordID: recordID, in: context)?.toUserIdentity()
    }

    // MARK: - Profile Setup Check

    /// Check if user profile needs setup (default name "Me" and no avatar)
    /// Used to prompt user to complete their profile after share acceptance or during onboarding
    public var needsProfileSetup: Bool {
        guard let identity = currentIdentity else { return true }
        return identity.name == Strings.UserProfile.me && identity.avatarData == nil
    }

    // MARK: - Migration from HouseholdMember

    /// Migrate from legacy HouseholdMember to UserIdentity
    /// Call this once during app upgrade if user had household members set up
    public func migrateFromHouseholdMember(_ member: HouseholdMember) {
        guard let cloudKitID = cloudKitRecordID ?? member.cloudKitUserRecordID else {
            logger.warning("Cannot migrate HouseholdMember without CloudKit ID")
            return
        }

        let identity = UserIdentity.fromHouseholdMember(member, cloudKitUserRecordID: cloudKitID)
        currentIdentity = identity
        saveIdentity(identity)
        logger.info("Migrated from HouseholdMember: \(member.name)")
    }
}
