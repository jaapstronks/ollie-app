//
//  TrainTabView.swift
//  Otis-app
//
//  Combined training tab with Potty Progress, Socialization, and Skills sections

import OtisShared
import SwiftUI

/// Train tab - unified view with potty progress, socialization checklist, and skills tracker
struct TrainTabView: View {
    @ObservedObject var viewModel: TimelineViewModel
    let onSettingsTap: () -> Void

    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var skillProgressStore: SkillProgressStore

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Sheet state for training guides
    @State private var showPottyGuide = false
    @State private var showCrateGuide = false

    // First-visit tip tracking
    @AppStorage("hasSeenTrainTip") private var hasSeenTrainTip = false

    /// Calculate crate nap percentage for guide entry card
    private var crateNapPercentage: Int {
        let recentNaps = eventStore.events
            .sleeps()
            .lastDays(14)

        guard !recentNaps.isEmpty else { return 0 }

        let crateNaps = recentNaps.filter { $0.napLocation == .crate }
        return Int((Double(crateNaps.count) / Double(recentNaps.count)) * 100)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // First-visit tip
                    if !hasSeenTrainTip {
                        FeatureTipCard(
                            tip: .trainIntro,
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hasSeenTrainTip = true
                                }
                            }
                        )
                    }

                    // Section 1: Training Guides (Potty + Crate)
                    guidesSection
                        .animatedAppear(delay: 0)

                    // Section 2: Skills
                    skillsSection
                        .animatedAppear(delay: 0.05)

                    // Section 3: Socialization
                    socializationSection
                        .animatedAppear(delay: 0.10)
                }
                .padding()
                .adaptiveContainer()
            }
            .navigationTitle(Strings.Tabs.train)
            .navigationBarTitleDisplayMode(.inline)
            .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
            // Training guide sheets
            .sheet(isPresented: $showPottyGuide) {
                PottyTrainingGuideSheet(
                    streakInfo: viewModel.streakInfo,
                    patternAnalysis: viewModel.patternAnalysis,
                    outdoorPercentage: viewModel.outdoorPercentage,
                    ageInWeeks: profileStore.profile?.ageInWeeks ?? 12
                )
            }
            .sheet(isPresented: $showCrateGuide) {
                CrateTrainingGuideSheet(eventStore: eventStore)
            }
        }
    }

    // MARK: - Training Guides Section

    @ViewBuilder
    private var guidesSection: some View {
        VStack(spacing: 10) {
            // Potty Training Guide - hidden when at 100% for 4+ days
            if viewModel.shouldShowPottyTrainingGuide {
                TrainingGuideEntryCard(
                    icon: "target",
                    title: Strings.Training.Guides.pottyTitle,
                    subtitle: Strings.Training.Guides.pottySubtitle,
                    statValue: viewModel.outdoorPercentage > 0 ? "\(viewModel.outdoorPercentage)%" : nil,
                    tintColor: .otisSuccess
                ) {
                    showPottyGuide = true
                }
            }

            // Crate Training Guide
            TrainingGuideEntryCard(
                icon: "house.fill",
                title: Strings.Training.Guides.crateTitle,
                subtitle: Strings.Training.Guides.crateSubtitle,
                statValue: crateNapPercentage > 0 ? "\(crateNapPercentage)%" : nil,
                tintColor: .indigo
            ) {
                showCrateGuide = true
            }
        }
    }

    // MARK: - Socialization Section

    @ViewBuilder
    private var socializationSection: some View {
        SocializationJourneyCard()
    }

    // MARK: - Skills Section

    @ViewBuilder
    private var skillsSection: some View {
        SkillsPreviewCard(eventStore: eventStore, skillProgressStore: skillProgressStore)
    }
}

// MARK: - Skills Preview Card

/// Compact preview of current week's training focus
private struct SkillsPreviewCard: View {
    @ObservedObject var eventStore: EventStore
    @ObservedObject var skillProgressStore: SkillProgressStore
    @StateObject private var trainingStore = TrainingPlanStore()
    @EnvironmentObject var profileStore: ProfileStore

    @State private var showTodaysTraining = false

    @Environment(\.colorScheme) private var colorScheme

    /// Determine if user has any training progress
    private var hasStartedTraining: Bool {
        trainingStore.masteryProgress.mastered > 0 ||
        trainingStore.allSkillsWithStatus.contains { $0.sessionCount > 0 }
    }

    /// Check if there are skills to train today
    private var hasSkillsToTrain: Bool {
        !skillProgressStore.skillsNeedingWork.isEmpty ||
        !skillProgressStore.skillsDueForReview.isEmpty ||
        !skillProgressStore.skillsInActiveLearning.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with description
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(Color.otisAccent)
                        .accessibilityHidden(true)
                    Text(Strings.Train.skills)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                }

                Text(Strings.Train.skillsDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if trainingStore.trainingPlan != nil {
                // Mastery progress
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let nextSkill = trainingStore.nextSkill {
                            Text(Strings.Training.Progression.nextUp)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.tertiary)
                                .textCase(.uppercase)

                            HStack(spacing: 6) {
                                Image(systemName: nextSkill.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.otisAccent)
                                Text(nextSkill.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        } else {
                            Text(Strings.Training.Progression.allSkillsMastered)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    Spacer()

                    // Progress ring
                    ProgressRing(
                        completed: trainingStore.masteryProgress.mastered,
                        total: trainingStore.masteryProgress.total,
                        size: .compact
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Strings.Train.progressRingAccessibility)
                    .accessibilityValue(Strings.Train.progressValue(started: trainingStore.masteryProgress.mastered, total: trainingStore.masteryProgress.total))
                }

                // Actionable links at the bottom
                Divider()

                // Today's Training button (primary action when skills available)
                if hasStartedTraining && hasSkillsToTrain {
                    Button {
                        showTodaysTraining = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.otisAccent)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(Strings.Training.todaysTraining)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)

                                Text(Strings.Training.smartSessionPlan)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    Divider()
                }

                NavigationLink {
                    TrainingView(eventStore: eventStore)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: hasStartedTraining ? "list.bullet" : "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.otisAccent)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            )

                        Text(hasStartedTraining ? Strings.Training.viewAllSkills : Strings.Train.startTraining)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.otisAccent)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            } else {
                // Loading or no plan
                Text(Strings.Common.loading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .glassCard(tint: .accent)
        .onAppear {
            trainingStore.setEventStore(eventStore)
        }
        .sheet(isPresented: $showTodaysTraining) {
            TodaysTrainingView(
                skillProgressStore: skillProgressStore,
                eventStore: eventStore,
                trainingStore: trainingStore,
                puppyAgeWeeks: profileStore.profile?.ageInWeeks ?? 12,
                onDismiss: { showTodaysTraining = false }
            )
        }
    }

}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return TrainTabView(
        viewModel: viewModel,
        onSettingsTap: { print("Settings tapped") }
    )
    .environmentObject(eventStore)
    .environmentObject(SocializationStore())
    .environmentObject(profileStore)
}
