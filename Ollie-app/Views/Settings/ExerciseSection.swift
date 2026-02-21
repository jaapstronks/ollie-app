//
//  ExerciseSection.swift
//  Ollie-app
//
//  Exercise settings section for SettingsView

import SwiftUI

/// Exercise limits and settings section
struct ExerciseSection: View {
    let profile: PuppyProfile
    @ObservedObject var profileStore: ProfileStore
    @State private var showingExerciseEdit = false

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
        .sheet(isPresented: $showingExerciseEdit) {
            ExerciseEditView(profileStore: profileStore)
        }
    }
}
