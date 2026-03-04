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

    /// The profile being edited (looked up by ID)
    private var targetProfile: PuppyProfile? {
        profileStore.profile(for: profileId)
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
    }

    // MARK: - Profile Photo Helpers

    private func loadCurrentProfileImage(for profile: PuppyProfile) -> UIImage? {
        guard let filename = profile.profilePhotoFilename else { return nil }
        return ProfilePhotoStore.shared.load(filename: filename)
    }

    private func saveProfilePhoto(_ image: UIImage) {
        guard let profile = targetProfile else { return }
        do {
            // Delete old photo if exists
            if let oldFilename = profile.profilePhotoFilename {
                ProfilePhotoStore.shared.delete(filename: oldFilename)
            }

            let filename = try ProfilePhotoStore.shared.save(image: image)
            profileStore.updateProfilePhoto(filename, for: profileId)
        } catch {
            print("Failed to save profile photo: \(error)")
        }
    }

    private func removeProfilePhoto() {
        if let filename = targetProfile?.profilePhotoFilename {
            ProfilePhotoStore.shared.delete(filename: filename)
        }
        profileStore.updateProfilePhoto(nil, for: profileId)
    }
}

#Preview {
    NavigationStack {
        DogProfileSettingsView(profileStore: ProfileStore(), profileId: UUID())
    }
}
