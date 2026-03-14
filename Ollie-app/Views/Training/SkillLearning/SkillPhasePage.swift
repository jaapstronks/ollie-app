//
//  SkillPhasePage.swift
//  Otis-app
//
//  Individual phase page showing focused steps and tips
//

import SwiftUI
import OtisShared

/// A single phase page with focused howTo steps and relevant tips
struct SkillPhasePage: View {
    let skill: Skill
    let phase: SkillPhase
    let phaseIndex: Int
    let totalPhases: Int
    let isLastPhase: Bool
    var progressStore: TrainingProgressStore
    let onContinue: () -> Void
    let onStartTraining: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCompleted: Bool {
        progressStore.isPhaseCompleted(phase.id, forSkill: skill.id)
    }

    /// Get the howTo steps for this phase
    private var phaseSteps: [(index: Int, text: String)] {
        phase.howToStepIndices.compactMap { idx in
            guard idx < skill.howTo.count else { return nil }
            return (idx, skill.howTo[idx])
        }
    }

    /// Get the tips for this phase
    private var phaseTips: [String] {
        guard let tipIndices = phase.tipIndices else { return [] }
        return tipIndices.compactMap { idx in
            guard idx < skill.tips.count else { return nil }
            return skill.tips[idx]
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Phase header
                phaseHeader

                // How to steps for this phase
                stepsSection

                // Tips for this phase (if any)
                if !phaseTips.isEmpty {
                    tipsSection
                }

                // Completion checkbox
                completionCheckbox

                // Continue / Start Training button
                actionButton
                    .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Phase Header

    @ViewBuilder
    private var phaseHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Phase number
            Text(Strings.Training.Phases.phaseProgress(current: phaseIndex + 1, total: totalPhases))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            // Phase title
            Text(phase.name(for: skill.id))
                .font(.title2)
                .fontWeight(.bold)

            // Phase subtitle
            if !phase.subtitle(for: skill.id).isEmpty {
                Text(phase.subtitle(for: skill.id))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Steps Section

    @ViewBuilder
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.howTo, icon: "list.number")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(phaseSteps, id: \.index) { step in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number badge
                        Text("\(step.index + 1).")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.otisAccent)
                            .frame(width: 24, alignment: .leading)

                        Text(step.text)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
        }
    }

    // MARK: - Tips Section

    @ViewBuilder
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.tips, icon: "lightbulb")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(phaseTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(Color.otisWarning)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Completion Checkbox

    @ViewBuilder
    private var completionCheckbox: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                progressStore.togglePhase(phase.id, forSkill: skill.id)
                HapticFeedback.light()
            }
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isCompleted ? Color.otisSuccess : Color.secondary.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.otisSuccess)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }

                Text(Strings.Training.Phases.phaseComplete)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isCompleted ? Color.otisSuccess : .primary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isCompleted
                          ? Color.otisSuccess.opacity(colorScheme == .dark ? 0.15 : 0.1)
                          : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if isLastPhase {
            // Start Training button
            Button {
                HapticFeedback.medium()
                onStartTraining()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(Strings.Training.Phases.startTraining)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.otisAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        } else {
            // Continue button
            Button {
                HapticFeedback.light()
                onContinue()
            } label: {
                HStack(spacing: 8) {
                    Text(Strings.Training.Phases.continueButton)
                    Image(systemName: "arrow.right")
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

#Preview("Phase 1") {
    NavigationStack {
        SkillPhasePage(
            skill: previewSkill,
            phase: previewSkill.effectivePhases[0],
            phaseIndex: 0,
            totalPhases: 3,
            isLastPhase: false,
            progressStore: TrainingProgressStore(),
            onContinue: {},
            onStartTraining: {}
        )
        .navigationTitle(previewSkill.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Last Phase") {
    NavigationStack {
        SkillPhasePage(
            skill: previewSkill,
            phase: previewSkill.effectivePhases[2],
            phaseIndex: 2,
            totalPhases: 3,
            isLastPhase: true,
            progressStore: TrainingProgressStore(),
            onContinue: {},
            onStartTraining: {}
        )
        .navigationTitle(previewSkill.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
