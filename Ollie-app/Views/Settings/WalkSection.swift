//
//  WalkSection.swift
//  Ollie-app
//
//  Walk schedule settings section for SettingsView

import SwiftUI
import OllieShared

/// Walk schedule settings section
struct WalkSection: View {
    let profile: PuppyProfile
    let profileStore: ProfileStore
    @Binding var showingWalkScheduleEdit: Bool

    var body: some View {
        Section(header: sectionHeader) {
            // Summary row showing current settings
            VStack(alignment: .leading, spacing: 8) {
                // Mode indicator
                HStack {
                    Image(systemName: profile.walkSchedule.mode == .flexible ? "clock.arrow.2.circlepath" : "clock")
                        .foregroundColor(.ollieAccent)
                    Text(profile.walkSchedule.mode.label)
                        .font(.subheadline)
                    Spacer()
                }

                // Walks per day
                HStack {
                    Text(Strings.WalkScheduleEditor.walksPerDay(profile.walkSchedule.walksPerDay))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Strings.WalkScheduleEditor.intervalSummary(profile.walkSchedule.intervalMinutes))
                        .foregroundColor(.secondary)
                }
                .font(.caption)

                // Max exercise
                HStack {
                    Text(Strings.WalkScheduleEditor.maxExerciseSummary(profile.maxExerciseMinutes))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .font(.caption)
            }
            .padding(.vertical, 4)

            // Show scheduled walks
            ForEach(profile.walkSchedule.walks.prefix(4)) { walk in
                HStack {
                    Text(walk.label)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(walk.targetTime)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }

            if profile.walkSchedule.walks.count > 4 {
                Text("+ \(profile.walkSchedule.walks.count - 4) more walks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Edit button
            Button {
                showingWalkScheduleEdit = true
            } label: {
                Label(Strings.WalkScheduleEditor.editWalks, systemImage: "pencil")
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text(Strings.WalkScheduleEditor.title)
            Spacer()
            Image(systemName: "figure.walk")
                .foregroundColor(.ollieAccent)
        }
    }
}

#Preview {
    Form {
        WalkSection(
            profile: PuppyProfile.defaultProfile(
                name: "Ollie",
                birthDate: Date().addingTimeInterval(-86400 * 90),
                homeDate: Date().addingTimeInterval(-86400 * 30),
                size: .medium
            ),
            profileStore: ProfileStore(),
            showingWalkScheduleEdit: .constant(false)
        )
    }
}
