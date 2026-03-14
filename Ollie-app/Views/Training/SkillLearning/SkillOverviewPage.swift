//
//  SkillOverviewPage.swift
//  Otis-app
//
//  Overview page showing skill introduction and phases preview
//

import SwiftUI
import OtisShared

/// First page of the learning flow - shows big picture and phases preview
struct SkillOverviewPage: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let phases: [SkillPhase]
    var progressStore: TrainingProgressStore
    let skillProgress: SkillProgress?
    let onStartLearning: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    /// Number of phases completed for this skill
    private var completedPhasesCount: Int {
        progressStore.completedPhaseCount(for: skill)
    }

    /// Whether any phases have been completed (skill is in progress)
    private var hasStartedPhases: Bool {
        completedPhasesCount > 0
    }

    /// Whether all phases are completed
    private var allPhasesCompleted: Bool {
        progressStore.allPhasesCompleted(for: skill)
    }

    // MARK: - Phase-Based Status Display

    /// Status icon based on phase completion, not session count
    private var phaseBasedStatusIcon: String {
        if status == .mastered {
            return "checkmark.circle.fill"
        } else if allPhasesCompleted {
            return "checkmark.circle"
        } else if hasStartedPhases {
            return "circle.lefthalf.filled"
        } else {
            return "circle"
        }
    }

    /// Status label based on phase completion
    private var phaseBasedStatusLabel: String {
        if status == .mastered {
            return Strings.Training.statusMastered
        } else if allPhasesCompleted {
            return Strings.Training.statusPracticing
        } else if hasStartedPhases {
            // Show "X of Y phases completed" for in-progress skills
            return Strings.Training.Phases.phasesCompleted(completedPhasesCount, total: phases.count)
        } else {
            return Strings.Training.statusNotStarted
        }
    }

    /// Status color based on phase completion
    private var phaseBasedStatusColor: Color {
        if status == .mastered {
            return .otisSuccess
        } else if allPhasesCompleted {
            return .otisSuccess.opacity(0.8)
        } else if hasStartedPhases {
            return .otisInfo
        } else {
            return .secondary
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header card with icon and status
                headerCard

                // Smart training progress visualization
                if let progress = skillProgress, progress.phase != .notStarted {
                    smartTrainingSection(progress)
                }

                // Description
                Text(skill.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                // Done when (goal)
                goalSection

                // Phases preview (only if multiple phases)
                if phases.count > 1 {
                    phasesPreviewSection
                }

                // Session recommendation
                if let recommendation = skill.sessionRecommendation {
                    sessionRecommendationRow(recommendation)
                }

                // Start Learning button
                startLearningButton
                    .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Header Card

    @ViewBuilder
    private var headerCard: some View {
        HStack(spacing: 16) {
            // Skill icon
            ZStack {
                Circle()
                    .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.otisAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Status badge - shows phase progress when phases exist
                HStack(spacing: 6) {
                    Image(systemName: phaseBasedStatusIcon)
                        .font(.caption2)
                    Text(phaseBasedStatusLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(phaseBasedStatusColor)

                // Method and session count
                HStack(spacing: 8) {
                    if let method = skill.method {
                        HStack(spacing: 4) {
                            Image(systemName: method.icon)
                                .font(.caption2)
                            Text(method.label)
                                .font(.caption)
                        }
                        .foregroundStyle(method == .operant ? Color.purple : Color.blue)
                    }

                    if sessionCount > 0 {
                        if skill.method != nil {
                            Text("\u{2022}")
                                .foregroundStyle(.tertiary)
                        }
                        Text(Strings.Training.sessionCount(sessionCount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .glassStatusCard(tintColor: (status == .mastered || allPhasesCompleted) ? .otisSuccess : nil)
    }

    // MARK: - Goal Section

    @ViewBuilder
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Use target icon for header - "Goal" is aspirational, not achieved
            sectionHeader(Strings.Training.Phases.goalTitle, icon: "target")

            HStack(alignment: .top, spacing: 12) {
                // Show checkmark only when goal is achieved (all phases completed or mastered)
                // Otherwise show a target/flag icon to indicate this is the goal we're working toward
                Image(systemName: goalIconName)
                    .font(.subheadline)
                    .foregroundStyle(goalIconColor)
                Text(skill.doneWhen)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Icon for goal section - checkmark when achieved, target when not
    private var goalIconName: String {
        if status == .mastered || allPhasesCompleted {
            return "checkmark.circle.fill"
        } else {
            return "flag.circle"
        }
    }

    /// Color for goal icon - green when achieved, secondary when not
    private var goalIconColor: Color {
        if status == .mastered || allPhasesCompleted {
            return .otisSuccess
        } else {
            return .secondary
        }
    }

    // MARK: - Phases Preview Section

    @ViewBuilder
    private var phasesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.Phases.whatYouWillLearn, icon: "list.number")

            VStack(spacing: 8) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    let isCompleted = progressStore.isPhaseCompleted(phase.id, forSkill: skill.id)

                    HStack(spacing: 12) {
                        // Phase number badge
                        ZStack {
                            Circle()
                                .fill(isCompleted ? Color.otisSuccess : Color.otisAccent.opacity(0.15))
                                .frame(width: 28, height: 28)

                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.otisAccent)
                            }
                        }

                        // Phase info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(phase.name(for: skill.id))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(isCompleted ? .secondary : .primary)

                            Text(phase.subtitle(for: skill.id))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.otisSuccess)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                    )
                }
            }
        }
    }

    // MARK: - Session Recommendation

    @ViewBuilder
    private func sessionRecommendationRow(_ recommendation: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.caption)
                .foregroundStyle(.teal)

            Text(recommendation)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.teal.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }

    // MARK: - Start/Continue Learning Button

    @ViewBuilder
    private var startLearningButton: some View {
        Button {
            HapticFeedback.medium()
            onStartLearning()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: hasStartedPhases ? "arrow.right.circle.fill" : "play.circle.fill")
                Text(buttonLabel)
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.otisAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    /// Button label based on phase completion state
    private var buttonLabel: String {
        if hasStartedPhases {
            // Already started - show "Continue"
            return phases.count > 1
                ? Strings.Training.Phases.continueLearning
                : Strings.Training.Phases.continueTraining
        } else {
            // Not started - show "Start"
            return phases.count > 1
                ? Strings.Training.Phases.startLearning
                : Strings.Training.Phases.startTraining
        }
    }

    // MARK: - Smart Training Section

    @ViewBuilder
    private func smartTrainingSection(_ progress: SkillProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Phase timeline
            SkillPhaseTimeline(currentPhase: progress.phase, isCompact: false)

            // Regression alert
            if progress.phase == .needsWork {
                HStack(spacing: 8) {
                    RegressionBadge(isCompact: false)
                    Spacer()
                }

                Text(Strings.Training.regressionNormalMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Maintenance info for mastered skills
            if progress.phase == .maintaining {
                MaintenanceScheduleIndicator(
                    tier: progress.maintenanceTier,
                    nextReviewDate: progress.nextReviewDate,
                    isCompact: false
                )
            }

            // 3D progress for proofing phase
            if progress.phase == .proofing || progress.phase == .generalizing {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("3Ds Progress", icon: "chart.bar.fill")
                    Proofing3DIndicator(levels: progress.proofingLevels, isCompact: false)
                }
            }

            // Context badges for generalizing
            if progress.phase == .generalizing && !progress.practicedContexts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Practiced in", icon: "location.fill")
                    ContextBadges(contexts: progress.practicedContexts)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        )
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
        }
    }
}

// MARK: - Preview

private let previewSkill = Skill(
    id: "collarLeash",
    icon: "dog.fill",
    category: .safety,
    sortOrder: 5,
    requires: [],
    method: nil,
    durationMinutes: 5,
    sessionsPerDay: 2,
    steps: nil,
    phases: [
        SkillPhase(id: "introduction", howToStepIndices: [0, 1], tipIndices: [0]),
        SkillPhase(id: "buildDuration", howToStepIndices: [2], tipIndices: [1]),
        SkillPhase(id: "leashWork", howToStepIndices: [3, 4], tipIndices: [2, 3])
    ]
)

#Preview {
    NavigationStack {
        SkillOverviewPage(
            skill: previewSkill,
            status: .started,
            sessionCount: 3,
            phases: previewSkill.effectivePhases,
            progressStore: TrainingProgressStore(),
            skillProgress: SkillProgress(skillId: previewSkill.id, phase: .proofing),
            onStartLearning: {}
        )
        .navigationTitle(previewSkill.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
