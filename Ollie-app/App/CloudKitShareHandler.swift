//
//  CloudKitShareHandler.swift
//  Otis-app
//
//  Handles CloudKit share URL acceptance and invitation processing
//

import CloudKit
import OtisShared
import os
import SwiftUI

// MARK: - Share Acceptance Registry

/// Prevents duplicate share acceptance attempts
@MainActor
final class ShareAcceptanceRegistry {
    static let shared = ShareAcceptanceRegistry()
    private var inFlightKeys = Set<String>()

    func beginIfNeeded(for metadata: CKShare.Metadata) -> Bool {
        let key = keyForMetadata(metadata)
        guard !inFlightKeys.contains(key) else { return false }
        inFlightKeys.insert(key)
        return true
    }

    func end(for metadata: CKShare.Metadata) {
        inFlightKeys.remove(keyForMetadata(metadata))
    }

    private func keyForMetadata(_ metadata: CKShare.Metadata) -> String {
        let recordID = metadata.share.recordID
        return "\(recordID.zoneID.ownerName)|\(recordID.zoneID.zoneName)|\(recordID.recordName)"
    }
}

// MARK: - Pending Share Storage

/// Stores pending CloudKit share metadata for processing after SwiftUI scene is ready
@MainActor
final class PendingShareMetadata {
    static let shared = PendingShareMetadata()
    var metadata: CKShare.Metadata?
    var pendingURL: URL?
    private init() {}
}

// MARK: - Profile Store Provider

/// Provides access to the ProfileStore for scene delegates
/// This is necessary because scene delegates can't access SwiftUI's environment
@MainActor
final class ProfileStoreProvider {
    static let shared = ProfileStoreProvider()
    var store: ProfileStore = ProfileStore()
    private init() {}
}

// MARK: - CloudKit Share Handler

@MainActor
enum CloudKitShareHandler {

    private static let logger = Logger.otis(category: "ShareHandler")

    // MARK: - Process Pending Shares

    /// Process any pending CloudKit share that came through scene connection
    static func processPendingShare(profileStore: ProfileStore) async {
        logger.info("🔗 processPendingShare called")

        // Check for pre-fetched metadata first (most reliable)
        if let metadata = PendingShareMetadata.shared.metadata {
            logger.info("🔗 Processing pending CloudKit share metadata")
            logger.info("🔗   Share URL: \(metadata.share.url?.absoluteString ?? "nil")")
            logger.info("🔗   Container: \(metadata.containerIdentifier)")
            PendingShareMetadata.shared.metadata = nil

            let ownerName = metadata.ownerIdentity.nameComponents?.formatted() ?? "someone"
            logger.info("🔗   Owner: \(ownerName)")

            if profileStore.hasExistingPrivateProfile() {
                let existingName = profileStore.profile?.name ?? ""
                logger.info("🔗   User has existing profile '\(existingName)', showing warning")
                showExistingProfileWarning(
                    existingName: existingName,
                    ownerName: ownerName,
                    metadata: metadata,
                    profileStore: profileStore
                )
            } else {
                logger.info("🔗   No existing profile, accepting share directly")
                await acceptShareInvitation(
                    metadata: metadata,
                    profileStore: profileStore
                )
            }
            return
        } else {
            logger.info("🔗   No pending metadata found")
        }

        // Fall back to pending URL if no metadata
        if let url = PendingShareMetadata.shared.pendingURL {
            logger.info("🔗 Processing pending CloudKit share URL: \(url.absoluteString)")
            PendingShareMetadata.shared.pendingURL = nil
            await handleShareURL(url, profileStore: profileStore)
        } else {
            logger.info("🔗   No pending URL found either")
        }
    }

    // MARK: - Handle Share URL

    /// Handle CloudKit share URL by fetching metadata and accepting
    static func handleShareURL(_ url: URL, profileStore: ProfileStore) async {
        logger.info("🔗 handleShareURL called with: \(url.absoluteString)")

        let container = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis")

        let operation = CKFetchShareMetadataOperation(shareURLs: [url])
        operation.perShareMetadataResultBlock = { _, result in
            switch result {
            case .success(let metadata):
                logger.info("✅ Got share metadata for URL")
                let ownerName = metadata.ownerIdentity.nameComponents?.formatted() ?? "someone"
                logger.info("🔗 Owner: \(ownerName)")
                logger.info("🔗 Container: \(metadata.containerIdentifier)")

                Task { @MainActor in
                    if profileStore.hasExistingPrivateProfile() {
                        let existingName = profileStore.profile?.name ?? ""
                        showExistingProfileWarning(
                            existingName: existingName,
                            ownerName: ownerName,
                            metadata: metadata,
                            profileStore: profileStore
                        )
                    } else {
                        await acceptShareInvitation(metadata: metadata, profileStore: profileStore)
                    }
                }

            case .failure(let error):
                logger.error("❌ Failed to fetch share metadata: \(error.localizedDescription)")

                Task { @MainActor in
                    showErrorAlert(
                        title: Strings.CloudSharing.shareError,
                        message: "\(Strings.CloudSharing.couldNotFetchShareInfo): \(error.localizedDescription)"
                    )
                }
            }
        }

        operation.qualityOfService = .userInitiated
        container.add(operation)
    }

    // MARK: - Accept Share Invitation

    /// Accept the share invitation and reload profile
    static func acceptShareInvitation(
        metadata: CKShare.Metadata,
        profileStore: ProfileStore?
    ) async {
        guard ShareAcceptanceRegistry.shared.beginIfNeeded(for: metadata) else {
            logger.info("Share acceptance already in progress for this invitation")
            return
        }
        defer { ShareAcceptanceRegistry.shared.end(for: metadata) }

        // Show accepting alert
        let acceptingAlert = UIAlertController(
            title: Strings.CloudSharing.acceptingShare,
            message: Strings.CloudSharing.connectingToSharedData,
            preferredStyle: .alert
        )
        presentAlert(acceptingAlert)

        do {
            let previousSharedProfileIDs = profileStore?.currentSharedProfileIDs() ?? sharedProfileIDSnapshot()
            logger.info("Previous shared profile IDs: \(previousSharedProfileIDs)")

            logger.info("Calling acceptShareInvitation...")
            try await PersistenceController.shared.acceptShareInvitation(from: metadata)
            logger.info("acceptShareInvitation completed successfully")

            CloudKitService.shared.markAsParticipant()
            logger.info("Marked as participant")

            // Re-check participant status from CloudKit to confirm
            await CloudKitService.shared.checkShareAccessStatus()
            logger.info("Participant status after check: \(CloudKitService.shared.isParticipant)")

            // Force a sync refresh to pull shared data
            logger.info("Forcing CloudKit sync refresh...")
            await CloudKitSyncCoordinator.shared.forceRefresh()

            let dateFormatter = ISO8601DateFormatter()
            UserDefaults.standard.set(dateFormatter.string(from: Date()), forKey: "shareAcceptedDate")

            NotificationCenter.default.post(name: .cloudKitShareAccepted, object: nil)

            // Wait for the shared profile to appear
            let importedProfile: PuppyProfile?
            if let profileStore {
                importedProfile = await profileStore.awaitNewlySharedProfile(
                    previousSharedProfileIDs: previousSharedProfileIDs,
                    timeoutSeconds: 30
                )
            } else {
                // Fallback: just wait for name (legacy path)
                let name = await waitForSharedProfileName(
                    previousSharedProfileIDs: previousSharedProfileIDs,
                    timeoutSeconds: 30
                )
                importedProfile = name != nil ? profileStore?.profiles.first { $0.name == name && $0.ownership == .shared } : nil
            }

            // Set default role to helper for the shared profile
            if let profile = importedProfile {
                UserIdentityStore.shared.setDefaultRoleForSharedProfile(profile.id)
                logger.info("Set default role (helper) for shared profile: \(profile.name)")
            }

            acceptingAlert.dismiss(animated: true) {
                if let profile = importedProfile {
                    // Post notification for role selection UI
                    NotificationCenter.default.post(
                        name: .showRoleSelectionForSharedProfile,
                        object: nil,
                        userInfo: ["profileId": profile.id, "dogName": profile.name]
                    )
                } else {
                    // Fallback: show simple success alert if profile not found
                    let successAlert = UIAlertController(
                        title: Strings.CloudSharing.shareAccepted,
                        message: Strings.CloudSharing.shareAcceptedSyncingMessage,
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: Strings.Common.ok, style: .default))
                    presentAlert(successAlert)
                }
            }

            logger.info("✅ Share accepted successfully")
        } catch {
            logger.error("❌ Failed to accept share: \(error.localizedDescription)")

            acceptingAlert.dismiss(animated: true) {
                showErrorAlert(
                    title: Strings.CloudSharing.shareFailed,
                    message: error.localizedDescription
                )
            }
        }
    }

    // MARK: - Existing Profile Warning

    /// Show warning when user has existing profile and is accepting a share
    private static func showExistingProfileWarning(
        existingName: String,
        ownerName: String,
        metadata: CKShare.Metadata,
        profileStore: ProfileStore
    ) {
        let message = existingName.isEmpty
            ? Strings.CloudSharing.addSharedProfileMessageGeneric(ownerName: ownerName)
            : Strings.CloudSharing.addSharedProfileMessage(existingName: existingName, sharedOwner: ownerName)

        let alert = UIAlertController(
            title: Strings.CloudSharing.addSharedProfileTitle,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Strings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Strings.CloudSharing.acceptShare, style: .default) { _ in
            Task { @MainActor in
                await acceptShareInvitation(metadata: metadata, profileStore: profileStore)
            }
        })

        presentAlert(alert)
    }

    // MARK: - Helpers

    private static func sharedProfileIDSnapshot() -> Set<UUID> {
        guard let sharedStore = PersistenceController.shared.getSharedStore() else { return [] }
        let profiles = CDPuppyProfile.fetchAllProfiles(in: PersistenceController.shared.viewContext, from: sharedStore)
        return Set(profiles.compactMap(\.id))
    }

    private static func waitForSharedProfileName(
        previousSharedProfileIDs: Set<UUID>,
        timeoutSeconds: TimeInterval = 30
    ) async -> String? {
        guard let sharedStore = PersistenceController.shared.getSharedStore() else { return nil }
        let deadline = Date().addingTimeInterval(timeoutSeconds)

        while Date() <= deadline {
            let profiles = CDPuppyProfile.fetchAllProfiles(in: PersistenceController.shared.viewContext, from: sharedStore)
            let newlyAdded = profiles.filter { profile in
                guard let id = profile.id else { return false }
                return !previousSharedProfileIDs.contains(id)
            }

            if let newest = newlyAdded.max(by: { ($0.modifiedAt ?? .distantPast) < ($1.modifiedAt ?? .distantPast) }),
               let name = newest.name,
               !name.isEmpty {
                return name
            }

            try? await Task.sleep(for: .seconds(1))
        }

        return nil
    }

    private static func presentAlert(_ alert: UIAlertController) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(alert, animated: true)
    }

    private static func showErrorAlert(title: String, message: String) {
        let errorAlert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        errorAlert.addAction(UIAlertAction(title: Strings.Common.ok, style: .default))
        presentAlert(errorAlert)
    }
}
