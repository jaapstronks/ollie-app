//
//  ProfileStore+Sync.swift
//  Ollie-app
//
//  ProfileStore extension for sync-related operations:
//  - CloudKit sync handling
//  - App Group sync (widgets, intents)
//  - Data migrations
//

import Foundation
import Combine
import CoreData
import OtisShared
import os

// MARK: - CloudKit Sync

extension ProfileStore {

    func setupRemoteChangeObserver() {
        // PERF: Register with centralized coordinator instead of individual listener
        // This reduces 12+ simultaneous reactions to 1 coordinated, debounced response
        CloudKitSyncCoordinator.shared.registerCallback(identifier: "ProfileStore") { [weak self] in
            self?.handleRemoteChange()
        }

        // Listen for share acceptance to reload profiles
        NotificationCenter.default.publisher(for: .cloudKitShareAccepted)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleShareAccepted()
            }
            .store(in: &cancellables)

        // Listen for seed data profile creation (UI testing mode)
        NotificationCenter.default.publisher(for: NSNotification.Name("ProfileStoreReload"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.logger.info("Received ProfileStoreReload notification - reloading profiles")
                self?.loadAllProfiles()
            }
            .store(in: &cancellables)
    }

    func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change for profiles")

        // Capture current state for comparison
        let previousProfileIds = Set(profiles.map { $0.id })
        let previousModifiedDates = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.modifiedAt) })

        // Load fresh profiles
        loadAllProfiles()

        // Check if anything actually changed
        let currentProfileIds = Set(profiles.map { $0.id })
        let hasNewOrRemovedProfiles = currentProfileIds != previousProfileIds
        let hasModifiedProfiles = profiles.contains { profile in
            previousModifiedDates[profile.id] != profile.modifiedAt
        }

        if !hasNewOrRemovedProfiles && !hasModifiedProfiles {
            logger.debug("No actual profile changes detected, skipping cascade")
            return
        }

        // Actual changes - log what changed
        let newProfiles = currentProfileIds.subtracting(previousProfileIds)
        let removedProfiles = previousProfileIds.subtracting(currentProfileIds)
        logger.info("Profile changes: \(newProfiles.count) new, \(removedProfiles.count) removed, modifications detected: \(hasModifiedProfiles)")
    }

    func handleShareAccepted() {
        logger.info("Share accepted - reloading all profiles")
        let previousSharedProfileIDs = knownSharedProfileIDs

        Task { @MainActor in
            _ = await awaitNewlySharedProfile(
                previousSharedProfileIDs: previousSharedProfileIDs,
                timeoutSeconds: 30
            )
        }
    }

    /// Snapshot shared profile IDs before accepting an invitation.
    /// Used to detect which shared profile is newly imported afterwards.
    func currentSharedProfileIDs() -> Set<UUID> {
        Set(profiles.filter { $0.ownership == .shared }.map(\.id))
    }

    /// Waits for a newly shared profile to arrive after invitation acceptance.
    /// Returns the imported profile once visible, or nil on timeout.
    func awaitNewlySharedProfile(
        previousSharedProfileIDs: Set<UUID>,
        timeoutSeconds: TimeInterval = 30
    ) async -> PuppyProfile? {
        let deadline = Date().addingTimeInterval(timeoutSeconds)

        // Shared records can take a while to appear in the shared store after acceptance.
        while Date() <= deadline {
            loadAllProfiles()

            let sharedProfiles = profiles.filter { $0.ownership == .shared }
            let newlyAddedSharedProfiles = sharedProfiles.filter { !previousSharedProfileIDs.contains($0.id) }

            if let profileToActivate = newlyAddedSharedProfiles.max(by: { $0.modifiedAt < $1.modifiedAt }) {
                switchToProfile(profileToActivate.id)
                NotificationCenter.default.post(
                    name: .sharedProfileAutoActivated,
                    object: nil,
                    userInfo: ["profileName": profileToActivate.name]
                )
                logger.info("Auto-activated newly shared profile: \(profileToActivate.name)")
                return profileToActivate
            }

            try? await Task.sleep(for: .seconds(1))
        }

        logger.info("Timed out waiting for newly shared profile import")
        return nil
    }

    /// Sync profile photos from CloudKit for shared profiles that have a photo filename but no local file
    func syncSharedProfilePhotos() {
        let sharedProfiles = profiles.filter { $0.ownership == .shared }

        for profile in sharedProfiles {
            guard let filename = profile.profilePhotoFilename else { continue }

            // Check if photo exists locally, if not, download from CloudKit
            // Pass isSharedProfile: true so it downloads from the owner's zone
            Task {
                await ProfilePhotoStore.shared.syncFromCloudKitIfNeeded(
                    filename: filename,
                    profileId: profile.id,
                    isSharedProfile: true
                )
            }
        }
    }

    /// Upload profile photo to CloudKit for a profile (used when enabling sharing or for migration)
    /// Call this when a user shares their profile to ensure the photo is available to participants
    func uploadProfilePhotoToCloud(for profileId: UUID) async {
        guard let profile = profiles.first(where: { $0.id == profileId }),
              let filename = profile.profilePhotoFilename,
              ProfilePhotoStore.shared.exists(filename: filename) else {
            return
        }

        let localURL = ProfilePhotoStore.shared.fullPath(for: filename)

        do {
            _ = try await CloudKitService.shared.uploadProfilePhoto(
                localURL: localURL,
                profileId: profileId
            )
            logger.info("Uploaded profile photo to CloudKit for profile \(profileId)")
        } catch {
            logger.warning("Failed to upload profile photo to CloudKit: \(error.localizedDescription)")
        }
    }

    // MARK: - Share Acceptance Support

    /// Check if user has an existing profile in their private store
    /// Used to inform user when accepting a share invitation (no longer destructive)
    func hasExistingPrivateProfile() -> Bool {
        guard let privateStore = persistenceController.getPrivateStore() else { return false }
        return CDPuppyProfile.hasProfile(in: viewContext, store: privateStore)
    }

    /// Delete existing profile from private store
    /// Only called for specific user action, not automatically on share acceptance
    @available(*, deprecated, message: "Multi-puppy support means we no longer need to delete profiles on share acceptance")
    func deletePrivateProfile() {
        guard let privateStore = persistenceController.getPrivateStore() else { return }

        CDPuppyProfile.deleteAllProfiles(in: viewContext, from: privateStore)

        do {
            try persistenceController.save()
            loadAllProfiles()
            logger.info("Deleted all profiles from private store")
        } catch {
            logger.error("Failed to delete private profile: \(error.localizedDescription)")
        }
    }
}

// MARK: - App Group Sync

extension ProfileStore {

    /// App Group suite name for sharing with Intents/Widgets
    static let appGroupSuiteName = Constants.appGroupIdentifier

    /// Syncs the active profile to App Group for use by App Intents and Widgets
    /// Called automatically after any profile save or switch
    func syncToAppGroup() {
        guard let profile = activeProfile else { return }

        let sharedProfile = SharedProfile(from: profile)
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupSuiteName) else {
            logger.warning("App Group UserDefaults unavailable - widget sync skipped")
            return
        }

        do {
            let data = try JSONEncoder().encode(sharedProfile)
            sharedDefaults.set(data, forKey: IntentDataStore.profileKey)

            // Also sync the active profile ID for widgets
            sharedDefaults.set(profile.id.uuidString, forKey: "activeProfileId")
        } catch {
            logger.error("Failed to encode profile for App Group sync: \(error.localizedDescription)")
        }
    }

    /// Force sync the current profile to App Group
    /// Call this if profile was loaded from elsewhere and needs to be shared
    func forceAppGroupSync() {
        syncToAppGroup()
    }
}

// MARK: - Migration Methods

extension ProfileStore {

    /// Link orphaned events (without profile relationship) to the first OWNED profile
    /// Note: We only link to owned profiles to avoid cross-store relationship errors
    /// (orphaned events are in the private store, shared profiles are in the shared store)
    func migrateOrphanedEventsIfNeeded() {
        // Only migrate orphans to owned profiles (from private store)
        // Shared profiles are in a different store, causing cross-store relationship errors
        let ownedProfiles = profiles.filter { $0.ownership == .owned }
        guard let firstOwnedProfile = ownedProfiles.first,
              let cdProfile = CDPuppyProfile.fetch(byId: firstOwnedProfile.id, in: viewContext) else {
            // No owned profiles - skip migration (orphaned events will stay orphaned until user creates a profile)
            return
        }

        let linkedCount = CDPuppyEvent.linkOrphanedEvents(to: cdProfile, in: viewContext)
        if linkedCount > 0 {
            do {
                try persistenceController.save()
                logger.info("Linked \(linkedCount) orphaned events to owned profile '\(firstOwnedProfile.name)'")
            } catch {
                logger.error("Failed to save after linking orphaned events: \(error.localizedDescription)")
            }
        }
    }

    /// Migrate breed name to breedId if profile has breed but no breedId
    func migrateBreedNameToId() async {
        guard let profile = activeProfile,
              let breedName = profile.breed,
              !breedName.isEmpty,
              profile.breedId == nil else {
            return
        }

        logger.info("Migrating breed name '\(breedName)' to breedId")

        // Fetch breeds and find matching breed
        await BreedService.shared.fetchBreeds()

        if let matchedBreed = BreedService.shared.findBreed(named: breedName) {
            updateBreedId(matchedBreed.id)
            logger.info("Migrated breed '\(breedName)' to breedId \(matchedBreed.id)")
        } else {
            logger.warning("Could not find breed match for '\(breedName)'")
        }
    }

    /// Create a test profile for UI testing if none exists
    func createTestProfileIfNeeded() {
        // Check if profile already exists
        if CDPuppyProfile.fetchProfile(in: viewContext) != nil {
            return
        }

        logger.info("Creating test profile for UI testing")

        // Create test profile: "Oliver", 16 weeks old, Golden Retriever
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .weekOfYear, value: -16, to: Date()) ?? Date()
        let homeDate = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) ?? Date()

        var testProfile = PuppyProfile.defaultProfile(
            name: "Oliver",
            birthDate: birthDate,
            homeDate: homeDate,
            size: .medium
        )
        testProfile.breed = "Golden Retriever"

        _ = CDPuppyProfile.create(from: testProfile, in: viewContext)
        try? persistenceController.save()
    }
}
