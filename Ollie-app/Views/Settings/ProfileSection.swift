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
    @Binding var showingPhotoPicker: Bool

    @State private var showingNameEditor = false
    @State private var editedName = ""

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

            Button {
                editedName = profile.name
                showingNameEditor = true
            } label: {
                HStack {
                    Text(Strings.Settings.name)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(profile.name)
                        .foregroundColor(.secondary)
                }
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
        .alert(Strings.Settings.changeName, isPresented: $showingNameEditor) {
            TextField(Strings.Settings.name, text: $editedName)
            Button(Strings.Common.cancel, role: .cancel) { }
            Button(Strings.Common.save) {
                let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    profileStore.updateName(trimmed)
                }
            }
        }
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
