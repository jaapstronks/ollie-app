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
    @ObservedObject var progressStore: TrainingProgressStore
    let onStartLearning: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header card with icon and status
                headerCard

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
                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .font(.caption2)
                    Text(status.label)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(status.color)

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
        .glassStatusCard(tintColor: status == .mastered ? .otisSuccess : nil)
    }

    // MARK: - Goal Section

    @ViewBuilder
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.Phases.goalTitle, icon: "checkmark.circle")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.otisSuccess)
                Text(skill.doneWhen)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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

    // MARK: - Start Learning Button

    @ViewBuilder
    private var startLearningButton: some View {
        Button {
            HapticFeedback.medium()
            onStartLearning()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                Text(phases.count > 1 ? Strings.Training.Phases.startLearning : Strings.Training.Phases.startTraining)
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
            onStartLearning: {}
        )
        .navigationTitle(previewSkill.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
