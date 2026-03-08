//
//  RoutineView.swift
//  Otis-app
//
//  Main dashboard for adult dog routines and wellness
//

import SwiftUI
import OtisShared

/// Main routine dashboard showing daily routine, grooming, enrichment, and weight management
struct RoutineView: View {
    @EnvironmentObject private var routineStore: RoutineStore
    @EnvironmentObject private var weightStore: WeightStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var showRoutineEdit = false
    @State private var showWeightGoalSheet = false
    @State private var showBCSSheet = false
    @State private var showGroomingSchedule = false
    @State private var showEnrichmentView = false
    @State private var showEnrichmentLogSheet = false

    @Environment(\.colorScheme) private var colorScheme

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily routine status
                routineSection

                // Weight management
                weightSection

                // Grooming schedule
                groomingSection

                // Enrichment
                enrichmentSection
            }
            .padding()
        }
        .navigationTitle(Strings.AdultWellness.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Seed defaults if needed
            routineStore.seedDefaultRoutineItemsIfNeeded()
            routineStore.seedDefaultGroomingActivitiesIfNeeded()
        }
        .sheet(isPresented: $showRoutineEdit) {
            RoutineEditSheet()
        }
        .sheet(isPresented: $showWeightGoalSheet) {
            WeightGoalView()
        }
        .sheet(isPresented: $showBCSSheet) {
            BodyConditionSheet()
        }
        .sheet(isPresented: $showGroomingSchedule) {
            GroomingScheduleView()
        }
        .sheet(isPresented: $showEnrichmentView) {
            EnrichmentView()
        }
        .sheet(isPresented: $showEnrichmentLogSheet) {
            EnrichmentLogSheet()
        }
    }

    // MARK: - Routine Section

    @ViewBuilder
    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: Strings.Routine.title,
                icon: "clock.fill",
                iconColor: .blue,
                action: { showRoutineEdit = true }
            )

            RoutineStatusCard(
                items: routineStore.routineItems,
                onTap: { showRoutineEdit = true }
            )
        }
    }

    // MARK: - Weight Section

    @ViewBuilder
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: Strings.AdultWellness.weightCard,
                icon: "scalemass.fill",
                iconColor: .orange,
                action: { showWeightGoalSheet = true }
            )

            WeightGoalCard(
                goal: routineStore.weightGoal,
                currentWeight: weightStore.latestWeight?.weight,
                latestBCS: routineStore.latestBodyConditionScore,
                onGoalTap: { showWeightGoalSheet = true },
                onBCSTap: { showBCSSheet = true }
            )
        }
    }

    // MARK: - Grooming Section

    @ViewBuilder
    private var groomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: Strings.Grooming.title,
                icon: "comb.fill",
                iconColor: .purple,
                action: { showGroomingSchedule = true }
            )

            GroomingCard(
                activities: routineStore.groomingActivities,
                onMarkComplete: { activity in
                    routineStore.markGroomingCompleted(activity)
                },
                onTap: { showGroomingSchedule = true }
            )
        }
    }

    // MARK: - Enrichment Section

    @ViewBuilder
    private var enrichmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: Strings.Enrichment.title,
                icon: "puzzlepiece.fill",
                iconColor: .green,
                action: { showEnrichmentView = true }
            )

            EnrichmentCard(
                activities: routineStore.enrichmentActivities,
                suggestion: routineStore.enrichmentSuggestion(),
                onLogActivity: { showEnrichmentLogSheet = true },
                onTap: { showEnrichmentView = true }
            )
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: action) {
                HStack(spacing: 4) {
                    Text(Strings.Common.seeAll)
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Enrichment Log Sheet

private struct EnrichmentLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var routineStore: RoutineStore

    @State private var selectedType: EnrichmentType = .puzzleToy
    @State private var duration: Int = 15
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(Strings.Enrichment.category) {
                    Picker(Strings.Enrichment.category, selection: $selectedType) {
                        ForEach(EnrichmentType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(Strings.Enrichment.duration) {
                    Stepper("\(duration) min", value: $duration, in: 5...120, step: 5)
                }

                Section {
                    TextField(Strings.Common.note, text: $note)
                }
            }
            .navigationTitle(Strings.Enrichment.logActivity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        routineStore.addEnrichment(
                            type: selectedType,
                            durationMinutes: duration,
                            note: note.isEmpty ? nil : note
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoutineView()
    }
    .environmentObject(RoutineStore())
    .environmentObject(WeightStore())
    .environmentObject(ProfileStore())
}
