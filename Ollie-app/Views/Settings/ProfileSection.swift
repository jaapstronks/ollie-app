//
//  ProfileSection.swift
//  Ollie-app
//
//  Profile information section for SettingsView

import SwiftUI

/// Profile information section showing puppy details
struct ProfileSection: View {
    let profile: PuppyProfile

    var body: some View {
        Section(Strings.Settings.profile) {
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
