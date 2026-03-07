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
    @ObservedObject var cloudKit: CloudKitService
    @ObservedObject private var shareManager: CloudKitShareManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var activeShareSheet: ShareSheetItem?
    @State private var isPreparingShare = false
    @State private var shareError: String?
    @State private var showStopSharingConfirm = false
    @State private var showOtisPlusSheet = false

    init(cloudKit: CloudKitService) {
        self.cloudKit = cloudKit
        _shareManager = ObservedObject(wrappedValue: cloudKit.shareManager)
    }

    var body: some View {
        Section {
            content
        } header: {
            Text(Strings.CloudSharing.sharing)
        } footer: {
            if cloudKit.isCloudAvailable && !cloudKit.isParticipant {
                Text(Strings.CloudSharing.sharingDescription)
            }
        }
        .navigationDestination(item: $activeShareSheet) { item in
            CloudSharingView(
                share: item.share,
                container: CKContainer(identifier: "iCloud.nl.jaapstronks.Otis"),
                onDismiss: {
                    activeShareSheet = nil
                    Task { await cloudKit.updateShareState() }
                }
            )
            .navigationTitle(Strings.CloudSharing.manageSharing)
            .navigationBarTitleDisplayMode(.inline)
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
            participantsRow
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
        HStack {
            Image(systemName: "exclamationmark.icloud")
                .foregroundStyle(Color.otisWarning)
            Text(Strings.CloudSharing.iCloudUnavailable)
                .font(.subheadline)
        }
    }

    private var participantRow: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .foregroundStyle(Color.otisInfo)
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.CloudSharing.sharedData)
                    .font(.subheadline)
                Text(Strings.CloudSharing.viewingOthersData)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sharedStatusRow: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.otisSuccess)
            Text(Strings.CloudSharing.shared)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private var participantsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            if shareManager.shareParticipants.isEmpty {
                Text(Strings.CloudSharing.noParticipants)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(shareManager.shareParticipants) { participant in
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(participant.name)
                            .font(.subheadline)
                        Spacer()
                        Text(participant.status.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
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
                    .foregroundStyle(Color.otisAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.OtisPlus.featureUnlimitedSharing)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(Strings.OtisPlus.sharingRequiresPlus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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
                    .foregroundStyle(Color.otisAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.OtisPlus.featureUnlimitedSharing)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(Strings.OtisPlus.sharingRequiresPlus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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
        }
        .buttonStyle(.plain)
    }

    private var shareButton: some View {
        Button {
            Task { await prepareAndShowShare() }
        } label: {
            HStack {
                Label(Strings.CloudSharing.shareWithPartner, systemImage: "person.badge.plus")
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
            HStack {
                Label(Strings.CloudSharing.manageSharing, systemImage: "person.2.fill")
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
            HStack {
                Label(Strings.CloudSharing.inviteAnother, systemImage: "person.badge.plus")
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
            HStack {
                Label(Strings.CloudSharing.stopSharing, systemImage: "xmark.circle")
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

private struct ShareSheetItem: Identifiable, Hashable {
    let id = UUID()
    let share: CKShare

    static func == (lhs: ShareSheetItem, rhs: ShareSheetItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
