//
//  DevelopmentJourneySheet.swift
//  Otis-app
//
//  Comprehensive sheet showing the puppy's developmental journey
//  Single source of truth for development information
//

import SwiftUI
import OtisShared

/// Comprehensive sheet showing development journey, stages, and active periods
struct DevelopmentJourneySheet: View {
    @Environment(ProfileStore.self) var profileStore
    @Environment(MilestoneStore.self) var milestoneStore

    var onNavigateToSocialization: (() -> Void)?
    var onNavigateToMedical: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var ageInWeeks: Int {
        profile?.ageInWeeks ?? 0
    }

    private var currentStage: DevelopmentStage {
        profile?.currentDevelopmentStage ?? .socialization
    }

    private var stageProgress: Double {
        profile?.developmentStageProgress ?? 0.5
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero header with puppy info
                    heroHeader

                    // Active sensitive periods section
                    if let profile = profile {
                        let activePeriods = milestoneStore.activeDevelopmentalPeriods(birthDate: profile.birthDate)
                        if !activePeriods.isEmpty {
                            activePeriodsSection(activePeriods: activePeriods, profile: profile)
                        }
                    }

                    // Development stages timeline
                    stagesTimeline

                    // Cross-links to related sheets
                    crossLinksSection
                }
                .padding()
            }
            .navigationTitle(Strings.Development.roadmapTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Hero Header

    @ViewBuilder
    private var heroHeader: some View {
        VStack(spacing: 16) {
            // Puppy avatar placeholder
            ZStack {
                Circle()
                    .fill(currentStage.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: currentStage.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(currentStage.color)
            }

            // Age and stage info
            VStack(spacing: 4) {
                if let puppyName = profile?.name {
                    Text(puppyName)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // Age display
                if ageInWeeks <= 16 {
                    Text(Strings.Socialization.weekNumber(ageInWeeks))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let months = profile?.ageInMonths ?? 0
                    Text(Strings.Health.monthsOld(months))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Current stage badge with progress
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(currentStage.title)
                        .font(.headline)
                        .foregroundStyle(currentStage.color)

                    Text(Strings.Development.currentStage)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(currentStage.color)
                        .clipShape(Capsule())
                }

                Text(currentStage.ageRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Progress bar
                ProgressView(value: stageProgress)
                    .tint(currentStage.color)
                    .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(currentStage.color.opacity(colorScheme == .dark ? 0.1 : 0.05))
        )
    }

    // MARK: - Active Periods Section

    @ViewBuilder
    private func activePeriodsSection(activePeriods: [Milestone], profile: PuppyProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Development.activePeriods)
                .font(.headline)
                .fontWeight(.semibold)

            DevelopmentalPeriodBanners(
                milestones: activePeriods,
                birthDate: profile.birthDate,
                puppyName: profile.name
            )
        }
    }

    // MARK: - Stages Timeline

    @ViewBuilder
    private var stagesTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Development.roadmapTitle)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                ForEach(DevelopmentStage.allCases) { stage in
                    StageTimelineRow(
                        stage: stage,
                        isCurrentStage: currentStage == stage,
                        isPastStage: ageInWeeks > stage.endWeek,
                        milestones: milestonesFor(stage: stage)
                    )
                }
            }
        }
    }

    // MARK: - Cross-links Section

    @ViewBuilder
    private var crossLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Common.seeAlso)
                .font(.headline)
                .fontWeight(.semibold)

            // Socialization Window link
            if ageInWeeks <= 20, let onNavigate = onNavigateToSocialization {
                Button {
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        onNavigate()
                    }
                } label: {
                    crossLinkRow(
                        icon: "person.3.fill",
                        title: Strings.Development.socializationWindow,
                        color: .otisAccent
                    )
                }
                .buttonStyle(.plain)
            }

            // Medical Care link
            if let onNavigate = onNavigateToMedical {
                Button {
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        onNavigate()
                    }
                } label: {
                    crossLinkRow(
                        icon: "cross.case.fill",
                        title: Strings.Health.medicalTimeline,
                        color: .otisHealth
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func crossLinkRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Helpers

    private func milestonesFor(stage: DevelopmentStage) -> [Milestone] {
        guard profile != nil else { return [] }
        return milestoneStore.milestones.filter { milestone in
            guard let targetWeeks = milestone.targetAgeWeeks else {
                if let targetMonths = milestone.targetAgeMonths {
                    let targetWeeksApprox = targetMonths * 4
                    return targetWeeksApprox >= stage.startWeek && targetWeeksApprox <= stage.endWeek
                }
                return false
            }
            return targetWeeks >= stage.startWeek && targetWeeks <= stage.endWeek
        }.sorted { m1, m2 in
            let w1 = m1.targetAgeWeeks ?? (m1.targetAgeMonths ?? 0) * 4
            let w2 = m2.targetAgeWeeks ?? (m2.targetAgeMonths ?? 0) * 4
            return w1 < w2
        }
    }
}

// MARK: - Stage Timeline Row

private struct StageTimelineRow: View {
    let stage: DevelopmentStage
    let isCurrentStage: Bool
    let isPastStage: Bool
    let milestones: [Milestone]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line and marker
            VStack(spacing: 0) {
                Rectangle()
                    .fill(lineColor)
                    .frame(width: 2, height: 16)

                ZStack {
                    Circle()
                        .fill(isCurrentStage ? stage.color : lineColor)
                        .frame(width: 20, height: 20)

                    if isCurrentStage {
                        Circle()
                            .fill(.white)
                            .frame(width: 6, height: 6)
                    }
                }

                Rectangle()
                    .fill(lineColor)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            // Stage content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: stage.icon)
                        .font(.caption)
                        .foregroundStyle(isCurrentStage ? stage.color : .secondary)

                    Text(stage.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isCurrentStage ? .primary : .secondary)

                    if isCurrentStage {
                        Text(Strings.Development.youAreHere)
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(stage.color)
                            .clipShape(Capsule())
                    }
                }

                Text(stage.ageRange)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                // Show first few milestones inline
                if !milestones.isEmpty && isCurrentStage {
                    VStack(spacing: 4) {
                        ForEach(milestones.prefix(3)) { milestone in
                            HStack(spacing: 6) {
                                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.caption2)
                                    .foregroundStyle(milestone.isCompleted ? Color.otisSuccess : Color.secondary)

                                Text(milestone.localizedLabel)
                                    .font(.caption)
                                    .foregroundStyle(milestone.isCompleted ? Color.secondary : Color.primary)
                                    .strikethrough(milestone.isCompleted)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
    }

    private var lineColor: Color {
        isPastStage ? stage.color.opacity(0.5) : Color.secondary.opacity(0.3)
    }
}

// MARK: - Preview

#Preview {
    DevelopmentJourneySheet(
        onNavigateToSocialization: { print("Navigate to socialization") },
        onNavigateToMedical: { print("Navigate to medical") }
    )
    .environment(ProfileStore())
    .environment(MilestoneStore())
}
