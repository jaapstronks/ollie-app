//
//  ExerciseEditView.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

/// View for editing exercise configuration
struct ExerciseEditView: View {
    let profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var minutesPerMonth: Int
    @State private var maxWalksPerDay: Int

    init(profileStore: ProfileStore) {
        self.profileStore = profileStore
        let config = profileStore.profile?.exerciseConfig ?? ExerciseConfig.defaultConfig()
        _minutesPerMonth = State(initialValue: config.minutesPerMonthOfAge)
        _maxWalksPerDay = State(initialValue: config.maxWalksPerDay ?? 2)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.Exercise.minutesPerMonth)
                            .font(.headline)

                        Text(Strings.Exercise.fiveMinuteRule)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Stepper(value: $minutesPerMonth, in: 1...10) {
                            HStack {
                                Text("\(minutesPerMonth)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(Strings.Exercise.minMonth)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(Strings.Exercise.exerciseLimit)
                } footer: {
                    if let profile = profileStore.profile {
                        Text(Strings.Exercise.maxAtAge(age: profile.ageInMonths, minutes: profile.ageInMonths * minutesPerMonth))
                    }
                }

                Section(Strings.Exercise.walksPerDay) {
                    Stepper(value: $maxWalksPerDay, in: 1...5) {
                        HStack {
                            Text("\(maxWalksPerDay)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(Strings.Exercise.walksPerDayUnit)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(Strings.Exercise.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        let config = ExerciseConfig(
            minutesPerMonthOfAge: minutesPerMonth,
            maxWalksPerDay: maxWalksPerDay
        )
        profileStore.updateExerciseConfig(config)
        dismiss()
    }
}

#Preview {
    ExerciseEditView(profileStore: ProfileStore())
}
