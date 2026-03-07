//
//  ProfileSection.swift
//  Otis-app
//
//  Profile information section for SettingsView

import SwiftUI
import OtisShared

/// Profile information section showing puppy details
struct ProfileSection: View {
    let profile: PuppyProfile
    @ObservedObject var profileStore: ProfileStore
    var profileId: UUID? = nil
    @Binding var showingPhotoPicker: Bool

    @State private var showingNameEditor = false
    @State private var editedName = ""

    /// Binding for gender picker that updates the profile
    private var genderBinding: Binding<PuppyProfile.Gender> {
        Binding(
            get: { profile.gender },
            set: { newGender in
                profileStore.updateGender(newGender, for: profileId)
            }
        )
    }

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

            Picker(Strings.Settings.gender, selection: genderBinding) {
                ForEach(PuppyProfile.Gender.allCases) { gender in
                    Text(gender.label).tag(gender)
                }
            }
        }
        .alert(Strings.Settings.changeName, isPresented: $showingNameEditor) {
            TextField(Strings.Settings.name, text: $editedName)
            Button(Strings.Common.cancel, role: .cancel) { }
            Button(Strings.Common.save) {
                let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    profileStore.updateName(trimmed, for: profileId)
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
