//
//  DogProfileSettingsView.swift
//  Otis-app
//
//  Dog profile settings: name, breed, size, photo

import SwiftUI
import OtisShared

/// Settings screen for dog profile identity information
struct DogProfileSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    let profileId: UUID

    @State private var showingPhotoPicker = false
    @State private var showDeleteConfirmation = false
    @State private var showLeaveConfirmation = false
    @Environment(\.dismiss) private var dismiss

    /// The profile being edited (looked up by ID)
    private var targetProfile: PuppyProfile? {
        profileStore.profile(for: profileId)
    }

    /// Whether this profile can be deleted (must have at least one profile remaining)
    private var canDeleteProfile: Bool {
        profileStore.profiles.count > 1
    }

    var body: some View {
        Form {
            if let profile = targetProfile {
                // Profile basics only
                ProfileSection(
                    profile: profile,
                    profileStore: profileStore,
                    profileId: profileId,
                    showingPhotoPicker: $showingPhotoPicker
                )

                // Memorial section (subtle, at the bottom)
                MemorialSection(
                    profile: profile,
                    profileStore: profileStore,
                    profileId: profileId
                )

                // Delete/Leave section
                DeleteProfileSection(
                    profile: profile,
                    canDelete: canDeleteProfile,
                    onDeleteTapped: {
                        if profile.ownership == .shared {
                            showLeaveConfirmation = true
                        } else {
                            showDeleteConfirmation = true
                        }
                    }
                )
            }
        }
        .navigationTitle(targetProfile?.name ?? Strings.Settings.profile)
        .sheet(isPresented: $showingPhotoPicker) {
            if let profile = targetProfile {
                ProfilePhotoPicker(
                    currentImage: loadCurrentProfileImage(for: profile),
                    onSave: { image in
                        saveProfilePhoto(image)
                    },
                    onRemove: profile.profilePhotoFilename != nil ? {
                        removeProfilePhoto()
                    } : nil
                )
            }
        }
        // Delete confirmation for owned profiles
        .confirmationDialog(
            Strings.DeleteProfile.deleteTitle,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.DeleteProfile.deleteConfirm, role: .destructive) {
                performDelete()
            }
            Button(Strings.Common.cancel, role: .cancel) { }
        } message: {
            Text(Strings.DeleteProfile.deleteMessage)
        }
        // Leave confirmation for shared profiles
        .confirmationDialog(
            Strings.DeleteProfile.leaveTitle,
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.DeleteProfile.leaveConfirm, role: .destructive) {
                performLeave()
            }
            Button(Strings.Common.cancel, role: .cancel) { }
        } message: {
            Text(Strings.DeleteProfile.leaveMessage)
        }
    }

    // MARK: - Delete/Leave Actions

    private func performDelete() {
        Task {
            HapticFeedback.warning()
            await profileStore.deleteProfileWithMediaCleanup(profileId, mediaStore: MediaStore())
            HapticFeedback.success()
            dismiss()
        }
    }

    private func performLeave() {
        HapticFeedback.warning()
        profileStore.leaveSharedProfile(profileId)
        HapticFeedback.success()
        dismiss()
    }

    // MARK: - Profile Photo Helpers

    private func loadCurrentProfileImage(for profile: PuppyProfile) -> UIImage? {
        guard let filename = profile.profilePhotoFilename else { return nil }
        return ProfilePhotoStore.shared.load(filename: filename)
    }

    private func saveProfilePhoto(_ image: UIImage) {
        guard let profile = targetProfile else { return }

        Task {
            // Delete old photo if exists (including from CloudKit)
            if let oldFilename = profile.profilePhotoFilename {
                ProfilePhotoStore.shared.delete(filename: oldFilename, profileId: profile.id)
            }

            do {
                // Save new photo with CloudKit sync
                let filename = try await ProfilePhotoStore.shared.save(image: image, for: profile.id)
                await MainActor.run {
                    profileStore.updateProfilePhoto(filename, for: profileId)
                }
            } catch {
                print("Failed to save profile photo: \(error)")
            }
        }
    }

    private func removeProfilePhoto() {
        guard let profile = targetProfile else { return }

        if let filename = profile.profilePhotoFilename {
            ProfilePhotoStore.shared.delete(filename: filename, profileId: profile.id)
        }
        profileStore.updateProfilePhoto(nil, for: profileId)
    }
}

// MARK: - Delete Profile Section

/// Section for deleting or leaving a dog profile
private struct DeleteProfileSection: View {
    let profile: PuppyProfile
    let canDelete: Bool
    let onDeleteTapped: () -> Void

    var body: some View {
        Section {
            Button(role: .destructive) {
                onDeleteTapped()
            } label: {
                Label {
                    if profile.ownership == .shared {
                        Text(Strings.DeleteProfile.leaveButton(profile.name))
                    } else {
                        Text(Strings.DeleteProfile.deleteButton(profile.name))
                    }
                } icon: {
                    Image(systemName: profile.ownership == .shared
                        ? "rectangle.portrait.and.arrow.right"
                        : "trash")
                }
            }
            .disabled(!canDelete)
        } footer: {
            if !canDelete {
                Text(Strings.DeleteProfile.cannotDeleteOnly)
            } else {
                Text(Strings.DeleteProfile.deleteWarningFooter)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DogProfileSettingsView(profileStore: ProfileStore(), profileId: UUID())
    }
}
