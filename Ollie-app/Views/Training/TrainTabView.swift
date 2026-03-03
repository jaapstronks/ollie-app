//
//  TrainTabView.swift
//  Otis-app
//
//  Combined training tab with Potty Progress, Socialization, and Skills sections

import OtisShared
import SwiftUI

/// Train tab - unified view with potty progress, socialization checklist, skills tracker, and developmental milestones
struct TrainTabView: View {
    @ObservedObject var viewModel: TimelineViewModel
    let onSettingsTap: () -> Void

    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var milestoneStore: MilestoneStore

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    /// Calculate outdoor percentage for the past 7 days
    private var outdoorPercentage: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        let peeEvents = recentEvents.pee()

        let outdoorCount = peeEvents.filter { $0.location == .buiten }.count
        let totalCount = peeEvents.count

        guard totalCount > 0 else { return 0 }
        return (outdoorCount * 100) / totalCount
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section 0: Developmental Milestones (fear periods, socialization window)
                    if let profile = profileStore.profile {
                        developmentalMilestonesSection(for: profile)
                            .animatedAppear(delay: 0)
                    }

                    // Section 1: Potty Progress
                    pottyProgressSection
                        .animatedAppear(delay: 0.05)

                    // Section 2: Skills
                    skillsSection
                        .animatedAppear(delay: 0.10)

                    // Section 3: Socialization
                    socializationSection
                        .animatedAppear(delay: 0.15)
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.Tabs.train)
            .navigationBarTitleDisplayMode(.inline)
            .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
        }
    }

    // MARK: - Developmental Milestones Section

    /// Section showing active developmental periods (fear periods, socialization window)
    @ViewBuilder
    private func developmentalMilestonesSection(for profile: PuppyProfile) -> some View {
        let activePeriods = milestoneStore.activeDevelopmentalPeriods(birthDate: profile.birthDate)

        // Only show if there are active developmental periods
        if !activePeriods.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(Color.otisPurple)
                        .accessibilityHidden(true)
                    Text(Strings.Development.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                }

                DevelopmentalPeriodBanners(
                    milestones: activePeriods,
                    birthDate: profile.birthDate,
                    puppyName: profile.name
                )
            }
        }
    }

    // MARK: - Potty Progress Section

    @ViewBuilder
    private var pottyProgressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PottyProgressCard(
                streakInfo: viewModel.streakInfo,
                patternAnalysis: viewModel.patternAnalysis,
                outdoorPercentage: outdoorPercentage
            )
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
    .environmentObject(MilestoneStore())
}
