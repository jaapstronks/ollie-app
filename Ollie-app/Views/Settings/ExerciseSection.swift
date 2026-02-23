//
//  ExerciseSection.swift
//  Ollie-app
//
//  Exercise settings section for SettingsView

import SwiftUI
import OllieShared

/// Exercise limits and settings section
struct ExerciseSection: View {
    let profile: PuppyProfile
    let profileStore: ProfileStore
    @Binding var showingExerciseEdit: Bool

    var body: some View {
        Section(Strings.Settings.exercise) {
            HStack {
                Text(Strings.Settings.maxExercise)
                Spacer()
                Text("\(profile.maxExerciseMinutes) \(Strings.Settings.minPerWalk)")
                    .foregroundColor(.secondary)
            }

            Button {
                showingExerciseEdit = true
            } label: {
                Label(Strings.Settings.editExerciseLimit, systemImage: "pencil")
            }
        }
    }
}
