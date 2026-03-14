//
//  SharingSection.swift
//  Otis-app
//
//  CloudKit sharing section for app settings
//  Extracted from AppSettingsView.swift
//

import CloudKit
import OtisShared
import SwiftUI

/// CloudKit sharing section for settings
struct SharingSection: View {
    var cloudKit: CloudKitService
    @Environment(SubscriptionManager.self) var subscriptionManager

    /// Whether to show section header (false when used standalone with nav title)
    let showHeader: Bool

    /// Binding for navigation destination - must be handled by parent view outside Form/List
    @Binding var activeShareSheet: ShareSheetItem?

    @State private var isPreparingShare = false
    @State private var shareError: String?
    @State private var showStopSharingConfirm = false
    @State private var showOtisPlusSheet = false

    /// Access share manager directly from cloudKit
    private var shareManager: CloudKitShareManager {
        cloudKit.shareManager
    }

    init(cloudKit: CloudKitService, showHeader: Bool = true, activeShareSheet: Binding<ShareSheetItem?>) {
        self.cloudKit = cloudKit
        self.showHeader = showHeader
        self._activeShareSheet = activeShareSheet
    }

    var body: some View {
        Section {
            content
        } header: {
            if showHeader {
                Text(Strings.CloudSharing.sharing)
            }
        }
        .alert(Strings.CloudSharing.stopSharing, isPresented: $showStopSharingConfirm) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.CloudSharing.stopSharing, role: .destructive) {
                Task { await stopSharing() }
            }
        } message: {
            Text(Strings.CloudSharing.stopSharingConfirm)
        }
        .sheet(isPresented: $showOtisPlusSheet) {
            OtisPlusSheet(
                onDismiss: { showOtisPlusSheet = false },
                onSubscribed: { showOtisPlusSheet = false }
            )
        }
        .task {
            let context = PersistenceController.shared.viewContext
            if let cdProfile = CDPuppyProfile.fetchProfile(in: context) {
                await cloudKit.refreshShareState(
                    for: cdProfile,
                    using: PersistenceController.shared.container
                )
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !cloudKit.isCloudAvailable {
            iCloudUnavailableRow
        } else if cloudKit.isParticipant {
            participantRow
        } else if shareManager.isShared {
            sharedStatusRow
            participantsRows
            manageShareButton

            // Show invite button or upsell based on partner limit
            if subscriptionManager.canAddMorePartners(currentPartnerCount: currentPartnerCount) {
                inviteAnotherButton
            } else {
                partnerLimitUpsell
            }

            stopSharingButton
        } else {
            // Gate sharing for free users - Otis+ required to share
            if subscriptionManager.hasAccess(to: .unlimitedPartnerSharing) {
                shareButton
            } else {
                sharingLockedUpsell
            }
        }

        if let error = shareError {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Row Views

    private var iCloudUnavailableRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.icloud")
                .font(.title3)
                .foregroundStyle(Color.otisWarning)
                .frame(width: 28)

            Text(Strings.CloudSharing.iCloudUnavailable)

            Spacer()
        }
    }

    private var participantRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.title3)
                .foregroundStyle(Color.otisInfo)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.CloudSharing.sharedData)
                Text(Strings.CloudSharing.viewingOthersData)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var sharedStatusRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.otisSuccess)
                .frame(width: 28)

            Text(Strings.CloudSharing.shared)

            Spacer()
        }
    }

    @ViewBuilder
    private var participantsRows: some View {
        if shareManager.shareParticipants.isEmpty {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                Text(Strings.CloudSharing.noParticipants)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        } else {
            ForEach(shareManager.shareParticipants) { participant in
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 28)

                    Text(participant.name.isEmpty ? Strings.CloudSharing.partner : participant.name)

                    Spacer()

                    Text(participant.status.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Count of current non-owner participants (accepted + pending)
    private var currentPartnerCount: Int {
        shareManager.shareParticipants.count
    }

    /// Upsell row shown when free user tries to share (sharing is Otis+ only)
    private var sharingLockedUpsell: some View {
        Button {
            Analytics.trackFeatureGated(feature: "partner_sharing", action: "upsell_tapped")
            showOtisPlusSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                    .foregroundStyle(Color.otisAccent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.OtisPlus.featureUnlimitedSharing)
                    Text(Strings.OtisPlus.sharingRequiresPlus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text(Strings.OtisPlus.plusBadge)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.otisAccent))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Upsell row shown when free user wants to add more partners
    private var partnerLimitUpsell: some View {
        Button {
            Analytics.trackFeatureGated(feature: "unlimited_partners", action: "upsell_tapped")
            showOtisPlusSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                    .foregroundStyle(Color.otisAccent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.OtisPlus.featureUnlimitedSharing)
                    Text(Strings.OtisPlus.sharingRequiresPlus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.bold))
                    Text(Strings.OtisPlus.plusBadge)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.otisAccent))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var shareButton: some View {
        Button {
            Task { await prepareAndShowShare() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundStyle(Color.otisAccent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.CloudSharing.shareWithPartner)
                    Text(Strings.CloudSharing.sharingDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isPreparingShare {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isPreparingShare)
    }

    private var manageShareButton: some View {
        Button {
            Task { await manageExistingShare() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.title3)
                    .foregroundStyle(Color.otisAccent)
                    .frame(width: 28)

                Text(Strings.CloudSharing.manageSharing)

                Spacer()

                if isPreparingShare {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isPreparingShare)
    }

    private var inviteAnotherButton: some View {
        Button {
            Task { await prepareAndShowShare() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                    .foregroundStyle(Color.otisAccent)
                    .frame(width: 28)

                Text(Strings.CloudSharing.inviteAnother)

                Spacer()

                if isPreparingShare {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isPreparingShare)
    }

    private var stopSharingButton: some View {
        Button(role: .destructive) {
            HapticFeedback.warning()
            showStopSharingConfirm = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle")
                    .font(.title3)
                    .frame(width: 28)

                Text(Strings.CloudSharing.stopSharing)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
    }

    // MARK: - Actions

    private func prepareAndShowShare() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        shareError = nil

        do {
            let context = PersistenceController.shared.viewContext
            guard let cdProfile = CDPuppyProfile.fetchProfile(in: context) else {
                shareError = "No profile found. Please set up your puppy first."
                isPreparingShare = false
                return
            }

            // Upload profile photo to CloudKit before sharing
            // This ensures the photo is available to participants
            if let profileId = cdProfile.id {
                await ProfileStore.shared.uploadProfilePhotoToCloud(for: profileId)
            }

            let share = try await cloudKit.getOrCreateShare(
                for: cdProfile,
                using: PersistenceController.shared.container
            )

            activeShareSheet = ShareSheetItem(share: share)
        } catch {
            shareError = error.localizedDescription
        }

        isPreparingShare = false
    }

    private func manageExistingShare() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        shareError = nil

        let context = PersistenceController.shared.viewContext
        if let cdProfile = CDPuppyProfile.fetchProfile(in: context) {
            await cloudKit.refreshShareState(
                for: cdProfile,
                using: PersistenceController.shared.container
            )
        }

        if let share = shareManager.currentShare {
            activeShareSheet = ShareSheetItem(share: share)
        } else {
            shareError = Strings.CloudSharing.couldNotLoadShare
        }

        isPreparingShare = false
    }

    private func stopSharing() async {
        shareError = nil

        do {
            if shareManager.currentShare == nil {
                let context = PersistenceController.shared.viewContext
                if let cdProfile = CDPuppyProfile.fetchProfile(in: context) {
                    await cloudKit.refreshShareState(
                        for: cdProfile,
                        using: PersistenceController.shared.container
                    )
                }
            }
            try await cloudKit.stopSharing()
            await cloudKit.updateShareState()
        } catch {
            shareError = error.localizedDescription
        }
    }
}

struct ShareSheetItem: Identifiable, Hashable {
    let id = UUID()
    let share: CKShare

    static func == (lhs: ShareSheetItem, rhs: ShareSheetItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
