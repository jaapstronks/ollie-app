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

    @Environment(\.colorScheme) private var colorScheme

    // Sheet state for training guides
    @State private var showPottyGuide = false
    @State private var showCrateGuide = false

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
            // Potty Training Guide
            TrainingGuideEntryCard(
                icon: "target",
                title: Strings.Training.Guides.pottyTitle,
                subtitle: Strings.Training.Guides.pottySubtitle,
                statValue: viewModel.outdoorPercentage > 0 ? "\(viewModel.outdoorPercentage)%" : nil,
                tintColor: .otisSuccess
            ) {
                showPottyGuide = true
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
        SkillsPreviewCard(eventStore: eventStore)
    }
}

// MARK: - Skills Preview Card

/// Compact preview of current week's training focus
private struct SkillsPreviewCard: View {
    @ObservedObject var eventStore: EventStore
    @StateObject private var trainingStore = TrainingPlanStore()

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (matching Potty Progress and Socialization style)
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
                    ZStack {
                        let progress = trainingStore.masteryProgress
                        let progressFraction = progress.total > 0 ? CGFloat(progress.mastered) / CGFloat(progress.total) : 0

                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: progressFraction)
                            .stroke(Color.otisAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text("\(progress.mastered)/\(progress.total)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Strings.Train.progressRingAccessibility)
                    .accessibilityValue(Strings.Train.progressValue(started: trainingStore.masteryProgress.mastered, total: trainingStore.masteryProgress.total))
                }

                // Unlocked skills chips
                let unlockedSkills = trainingStore.unlockedSkills
                if !unlockedSkills.isEmpty {
                    Divider()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(unlockedSkills.prefix(5)) { skill in
                                skillChip(skill)
                            }
                        }
                    }
                }

                // "See all" link at the bottom (matching "All Categories" style)
                Divider()

                NavigationLink {
                    TrainingView(eventStore: eventStore)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            )

                        Text(Strings.Common.seeAll)
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
    }

    @ViewBuilder
    private func skillChip(_ skill: Skill) -> some View {
        let status = trainingStore.status(for: skill.id)

        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: status))
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)

            Text(skill.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor(for: status).opacity(colorScheme == .dark ? 0.2 : 0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Train.skillAccessibility(name: skill.name, status: statusAccessibilityLabel(for: status)))
    }

    private func statusAccessibilityLabel(for status: SkillStatus) -> String {
        switch status {
        case .notStarted: return Strings.Train.skillNotStarted
        case .started: return Strings.Train.skillStarted
        case .practicing: return Strings.Train.skillPracticing
        case .mastered: return Strings.Train.skillMastered
        }
    }

    private func statusColor(for status: SkillStatus) -> Color {
        switch status {
        case .notStarted: return .secondary
        case .started: return .otisAccent
        case .practicing: return .otisWarning
        case .mastered: return .otisSuccess
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
