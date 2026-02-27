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
