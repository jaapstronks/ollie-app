//
//  ProfilePickerSheet.swift
//  Otis-app
//
//  Sheet for switching between puppy profiles (multi-puppy feature)
//

import SwiftUI
import OtisShared

/// Sheet for switching between puppy profiles
struct ProfilePickerSheet: View {
    var profileStore: ProfileStore
    @Binding var isPresented: Bool

    var onAddDog: (() -> Void)?
    var onManageProfiles: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProfileId: UUID?
    @State private var profileToDelete: PuppyProfile?
    @State private var showDeleteConfirmation = false
    @State private var showLeaveConfirmation = false

    /// Profiles sorted with the active profile at the top
    private var sortedProfiles: [PuppyProfile] {
        profileStore.profiles.sorted { lhs, rhs in
            // Active profile comes first
            let lhsIsActive = lhs.id == profileStore.activeProfileId
            let rhsIsActive = rhs.id == profileStore.activeProfileId
            if lhsIsActive != rhsIsActive {
                return lhsIsActive
            }
            // Otherwise maintain original order (by name as fallback)
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Profile list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sortedProfiles, id: \.id) { profile in
                            ProfilePickerRow(
                                profile: profile,
                                isActive: profile.id == profileStore.activeProfileId,
                                canDelete: canDeleteProfile(profile),
                                onSelect: {
                                    selectProfile(profile)
                                },
                                onDelete: {
                                    profileToDelete = profile
                                    if profile.ownership == .shared {
                                        showLeaveConfirmation = true
                                    } else {
                                        showDeleteConfirmation = true
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }

                Divider()

                // Bottom actions
                VStack(spacing: 12) {
                    // Add dog button
                    if profileStore.canAddOwnedProfile() {
                        Button {
                            isPresented = false
                            onAddDog?()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text(Strings.Profile.addDog)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.otisAccent.opacity(0.1))
                            .foregroundStyle(Color.otisAccent)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel(Strings.Profile.addDog)
                    } else {
                        // At limit - show upgrade prompt
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.otisAccent)

                            Text(Strings.Profile.upgradeForMoreDogs)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("Otis+")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.otisAccent)
                                .foregroundStyle(.white)
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Profile count
                    if profileStore.profiles.count > 1 {
                        Text(Strings.Profile.profileLimit(
                            profileStore.ownedProfileCount,
                            max: SubscriptionManager.shared.effectiveStatus.hasOtisPlus ? maxOtisProfiles : maxFreeProfiles
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Profile.yourDogs)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // Delete confirmation for owned profiles
        .confirmationDialog(
            Strings.Profile.deleteConfirmTitle,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Profile.deleteProfile, role: .destructive) {
                if let profile = profileToDelete {
                    deleteProfile(profile)
                }
            }
            Button(Strings.Common.cancel, role: .cancel) {
                profileToDelete = nil
            }
        } message: {
            if let profile = profileToDelete {
                Text(Strings.Profile.deleteConfirmMessage(profile.name))
            }
        }
        // Leave confirmation for shared profiles
        .confirmationDialog(
            Strings.Profile.leaveConfirmTitle,
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Profile.leaveProfile, role: .destructive) {
                if let profile = profileToDelete {
                    leaveProfile(profile)
                }
            }
            Button(Strings.Common.cancel, role: .cancel) {
                profileToDelete = nil
            }
        } message: {
            if let profile = profileToDelete {
                Text(Strings.Profile.leaveConfirmMessage(profile.name))
            }
        }
    }

    /// Check if a profile can be deleted (can't delete the only remaining profile)
    private func canDeleteProfile(_ profile: PuppyProfile) -> Bool {
        profileStore.profiles.count > 1
    }

    private func deleteProfile(_ profile: PuppyProfile) {
        HapticFeedback.warning()
        profileStore.deleteProfile(profile.id)
        profileToDelete = nil
    }

    private func leaveProfile(_ profile: PuppyProfile) {
        HapticFeedback.warning()
        profileStore.leaveSharedProfile(profile.id)
        profileToDelete = nil
    }

    private func selectProfile(_ profile: PuppyProfile) {
        guard profile.id != profileStore.activeProfileId else { return }

        HapticFeedback.selection()
        profileStore.switchToProfile(profile.id)

        // Brief delay before dismissing to show the selection
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            isPresented = false
        }
    }
}

// MARK: - Profile Row

private struct ProfilePickerRow: View {
    let profile: PuppyProfile
    let isActive: Bool
    let canDelete: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var loadedImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Profile photo
                profilePhoto

                // Name and ownership
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ownershipBadge
                }

                Spacer()

                // Active indicator
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.otisAccent)
                        .accessibilityLabel(Strings.Profile.activeProfile)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive
                        ? Color.otisAccent.opacity(colorScheme == .dark ? 0.15 : 0.08)
                        : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.otisAccent.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            // Delete/Leave action (only if not the last profile)
            if canDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(
                        profile.ownership == .shared ? Strings.Profile.leaveProfile : Strings.Profile.deleteProfile,
                        systemImage: profile.ownership == .shared ? "rectangle.portrait.and.arrow.right" : "trash"
                    )
                }
            }
        }
        .accessibilityLabel(isActive
            ? Strings.Profile.profileSelected(profile.name)
            : profile.name)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityActions {
            if canDelete {
                Button(profile.ownership == .shared ? Strings.Profile.leaveProfile : Strings.Profile.deleteProfile) {
                    onDelete()
                }
            }
        }
        .task(id: profile.profilePhotoFilename) {
            await loadImageAsync()
        }
    }

    @ViewBuilder
    private var profilePhoto: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.otisAccent, Color.otisAccent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                // First letter of name
                Text(String(profile.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .overlay {
            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.15)
                        : Color.black.opacity(0.05),
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var ownershipBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: profile.ownership == .owned ? "person.fill" : "person.2.fill")
                .font(.caption)
            Text(profile.ownership == .owned ? Strings.Profile.owner : Strings.Profile.shared)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    private func loadImageAsync() async {
        guard let filename = profile.profilePhotoFilename else {
            loadedImage = nil
            return
        }
        // Use the version that can download from CloudKit if photo is missing locally
        // For shared profiles, this will download from the owner's zone
        loadedImage = await ProfilePhotoStore.shared.loadAsync(
            filename: filename,
            profileId: profile.id,
            isSharedProfile: profile.ownership == .shared
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var profileStore = ProfileStore()
        @State private var isPresented = true

        var body: some View {
            Color.clear
                .sheet(isPresented: $isPresented) {
                    ProfilePickerSheet(
                        profileStore: profileStore,
                        isPresented: $isPresented,
                        onAddDog: { print("Add dog") },
                        onManageProfiles: { print("Manage profiles") }
                    )
                }
        }
    }

    return PreviewWrapper()
}
