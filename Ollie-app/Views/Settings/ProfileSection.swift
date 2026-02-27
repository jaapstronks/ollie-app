//
//  ProfileSection.swift
//  Ollie-app
//
//  Profile information section for SettingsView

import SwiftUI
import OllieShared

/// Profile information section showing puppy details
struct ProfileSection: View {
    let profile: PuppyProfile
    @ObservedObject var profileStore: ProfileStore

    @State private var showingPhotoPicker = false

    var body: some View {
        Section(Strings.Settings.profile) {
            // Profile photo row
            HStack {
                ProfilePhotoView(profile: profile, size: 60)

                Spacer()

                Button(profile.profilePhotoFilename == nil ? Strings.Profile.addPhoto : Strings.Profile.changePhoto) {
                    showingPhotoPicker = true
                }
            }
            .padding(.vertical, 8)

            HStack {
                Text(Strings.Settings.name)
                Spacer()
                Text(profile.name)
                    .foregroundColor(.secondary)
            }

            if let breed = profile.breed {
                HStack {
                    Text(Strings.Settings.breed)
                    Spacer()
                    Text(breed)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(Strings.Settings.size)
                Spacer()
                Text(profile.sizeCategory.label)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            ProfilePhotoPicker(
                currentImage: loadCurrentImage(),
                onSave: { image in
                    saveProfilePhoto(image)
                },
                onRemove: profile.profilePhotoFilename != nil ? {
                    removeProfilePhoto()
                } : nil
            )
        }
    }

    private func loadCurrentImage() -> UIImage? {
        guard let filename = profile.profilePhotoFilename else { return nil }
        return ProfilePhotoStore.shared.load(filename: filename)
    }

    private func saveProfilePhoto(_ image: UIImage) {
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
        if let filename = profile.profilePhotoFilename {
            ProfilePhotoStore.shared.delete(filename: filename)
        }
        profileStore.updateProfilePhoto(nil)
    }
}

/// Stats section showing age and days home
struct StatsSection: View {
    let profile: PuppyProfile

    var body: some View {
        Section(Strings.Settings.stats) {
            HStack {
                Text(Strings.Settings.age)
                Spacer()
                Text("\(profile.ageInWeeks) \(Strings.Common.weeks)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(Strings.Settings.daysHome)
                Spacer()
                Text("\(profile.daysHome) \(Strings.Common.days)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Previews require a PuppyProfile instance - handled by parent SettingsView preview
