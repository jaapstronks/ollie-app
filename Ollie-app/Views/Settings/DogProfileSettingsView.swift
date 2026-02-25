//
//  DogProfileSettingsView.swift
//  Ollie-app
//
//  Dog profile settings: walks, meals, meds, spots, health

import SwiftUI
import OllieShared

/// Settings screen for all dog-related configuration
struct DogProfileSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var viewModel: TimelineViewModel

    @State private var showingMealEdit = false
    @State private var showingWalkScheduleEdit = false

    var body: some View {
        Form {
            if let profile = profileStore.profile {
                // Profile basics
                ProfileSection(profile: profile)
                StatsSection(profile: profile)

                // Schedules
                WalkSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingWalkScheduleEdit: $showingWalkScheduleEdit
                )

                MealSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingMealEdit: $showingMealEdit
                )

                // Medications
                medicationsSection

                // Walk spots
                walkSpotsSection

                // Health milestones
                healthSection
            }
        }
        .navigationTitle(profileStore.profile?.name ?? Strings.Settings.profile)
        .sheet(isPresented: $showingMealEdit) {
            if let profile = profileStore.profile {
                MealScheduleEditorWrapper(
                    initialSchedule: profile.mealSchedule,
                    onSave: { updatedSchedule in
                        profileStore.updateMealSchedule(updatedSchedule)
                    }
                )
            }
        }
        .sheet(isPresented: $showingWalkScheduleEdit) {
            if let profile = profileStore.profile {
                WalkScheduleEditorWrapper(
                    initialSchedule: profile.walkSchedule,
                    ageInMonths: profile.ageInMonths,
                    onSave: { updatedSchedule in
                        profileStore.updateWalkSchedule(updatedSchedule)
                    }
                )
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var medicationsSection: some View {
        Section(Strings.Medications.title) {
            NavigationLink {
                MedicationSettingsView(profileStore: profileStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Medications.title)
                    } icon: {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    let count = profileStore.profile?.medicationSchedule.medications.count ?? 0
                    if count > 0 {
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var walkSpotsSection: some View {
        Section(Strings.WalkLocations.walkLocation) {
            NavigationLink {
                FavoriteSpotsView(spotStore: spotStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.WalkLocations.favoriteSpots)
                    } icon: {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    Text("\(spotStore.spots.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var healthSection: some View {
        Section(Strings.Health.title) {
            NavigationLink {
                HealthView(viewModel: viewModel)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Health.milestones)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.ollieDanger)
                    }
                    Spacer()
                    Text(Strings.Insights.healthDescription)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    let profileStore = ProfileStore()
    let eventStore = EventStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return NavigationStack {
        DogProfileSettingsView(
            profileStore: profileStore,
            spotStore: SpotStore(),
            viewModel: viewModel
        )
    }
}
