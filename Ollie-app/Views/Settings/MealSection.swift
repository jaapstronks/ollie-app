//
//  MealSection.swift
//  Ollie-app
//
//  Meal schedule section for SettingsView

import SwiftUI
import OllieShared

/// Meal schedule settings section
struct MealSection: View {
    let profile: PuppyProfile
    let profileStore: ProfileStore
    @Binding var showingMealEdit: Bool

    var body: some View {
        Section(Strings.Settings.mealsPerDay(profile.mealSchedule.mealsPerDay)) {
            ForEach(profile.mealSchedule.portions) { portion in
                HStack {
                    Text(portion.label)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(portion.amount)
                            .foregroundColor(.secondary)
                        if let time = portion.targetTime {
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Button {
                showingMealEdit = true
            } label: {
                Label(Strings.Settings.editMeals, systemImage: "pencil")
            }
        }
    }
}
