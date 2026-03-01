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
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var activeShare: CKShare?
    @State private var isPreparingShare = false
    @State private var shareError: String?
    @State private var showStopSharingConfirm = false
    @State private var showOtisPlusSheet = false

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
        .sheet(isPresented: Binding(
            get: { activeShare != nil },
            set: { if !$0 { activeShare = nil } }
        )) {
            if let share = activeShare {
                CloudSharingView(
                    share: share,
                    container: CKContainer(identifier: "iCloud.nl.jaapstronks.Otis"),
                    onDismiss: {
                        activeShare = nil
                        Task { await cloudKit.updateShareState() }
                    }
                )
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
        } else if cloudKit.isShared {
            sharedContentRows
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

    @ViewBuilder
    private var sharedContentRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.otisSuccess)
                Text(Strings.CloudSharing.shared)
                    .font(.subheadline.weight(.medium))
            }

            if cloudKit.shareParticipants.isEmpty {
                Text(Strings.CloudSharing.noParticipants)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(cloudKit.shareParticipants) { participant in
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

        manageShareButton

        // Show invite button or upsell based on partner limit
        if subscriptionManager.canAddMorePartners(currentPartnerCount: currentPartnerCount) {
            inviteAnotherButton
        } else {
            partnerLimitUpsell
        }

        stopSharingButton
    }

    /// Count of current non-owner participants (accepted + pending)
    private var currentPartnerCount: Int {
        cloudKit.shareParticipants.count
    }

    /// Upsell row shown when free user tries to share (sharing is Otis+ only)
    private var sharingLockedUpsell: some View {
        Button {
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
                if isPreparingShare {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(isPreparingShare)
    }

    private var manageShareButton: some View {
        Button {
            Task { await manageExistingShare() }
        } label: {
            HStack {
                Label(Strings.CloudSharing.manageSharing, systemImage: "person.2.fill")
                if isPreparingShare {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(isPreparingShare)
    }

    private var inviteAnotherButton: some View {
        Button {
            Task { await prepareAndShowShare() }
        } label: {
            HStack {
                Label(Strings.CloudSharing.inviteAnother, systemImage: "person.badge.plus")
                if isPreparingShare {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(isPreparingShare)
    }

    private var stopSharingButton: some View {
        Button(role: .destructive) {
            HapticFeedback.warning()
            showStopSharingConfirm = true
        } label: {
            Label(Strings.CloudSharing.stopSharing, systemImage: "xmark.circle")
        }
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

            activeShare = share
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

        if let share = cloudKit.currentShare {
            activeShare = share
        } else {
            shareError = Strings.CloudSharing.couldNotLoadShare
        }

        isPreparingShare = false
    }

    private func stopSharing() async {
        shareError = nil

        do {
            try await cloudKit.stopSharing()
            await cloudKit.updateShareState()
        } catch {
            shareError = error.localizedDescription
        }
    }
}
