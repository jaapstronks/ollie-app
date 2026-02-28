//
//  DogProfileSettingsView.swift
//  Ollie-app
//
//  Dog profile settings: name, breed, size, photo

import SwiftUI
import OllieShared

/// Settings screen for dog profile identity information
struct DogProfileSettingsView: View {
    @ObservedObject var profileStore: ProfileStore

    @State private var showingPhotoPicker = false

    var body: some View {
        Form {
            if let profile = profileStore.profile {
                // Profile basics only
                ProfileSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingPhotoPicker: $showingPhotoPicker
                )
            }
        }
        .navigationTitle(profileStore.profile?.name ?? Strings.Settings.profile)
        .sheet(isPresented: $showingPhotoPicker) {
            if let profile = profileStore.profile {
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
        guard let profile = profileStore.profile else { return }
        do {
            // Delete old photo if exists
            if let oldFilename = profile.profilePhotoFilename {
                ProfilePhotoStore.shared.delete(filename: oldFilename)
            }

            let filename = try ProfilePhotoStore.shared.save(image: image)
            profileStore.updateProfilePhoto(filename)
        } catch {
            print("Failed to save profile photo: \(error)")
        }
    }

    private func removeProfilePhoto() {
        if let filename = profileStore.profile?.profilePhotoFilename {
            ProfilePhotoStore.shared.delete(filename: filename)
        }
        profileStore.updateProfilePhoto(nil)
    }
}

#Preview {
    NavigationStack {
        DogProfileSettingsView(profileStore: ProfileStore())
    }
}
