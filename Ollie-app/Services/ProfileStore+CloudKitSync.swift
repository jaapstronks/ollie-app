//
//  ProfileStore+CloudKitSync.swift
//  Otis-app
//
//  CloudKit sync handling for ProfileStore.
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
        loadAllProfiles()
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
            Task {
                await ProfilePhotoStore.shared.syncFromCloudKitIfNeeded(
                    filename: filename,
                    profileId: profile.id
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
