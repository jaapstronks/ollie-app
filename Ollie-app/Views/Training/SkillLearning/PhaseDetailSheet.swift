//
//  PhaseDetailSheet.swift
//  Ollie-app
//
//  Detail sheet for a single phase showing:
//  - Instructions (howTo steps, tips)
//  - Progress for both locations with action buttons
//

import SwiftUI
import OtisShared

/// Detail sheet for a single phase
struct PhaseDetailSheet: View {
    let skill: Skill
    let phase: SkillPhase
    let phaseIndex: Int
    @Bindable var skillProgressStore: SkillProgressStore
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    /// Get current progress from store (reactive)
    private var progress: SkillProgress {
        skillProgressStore.progress(for: skill.id)
    }

    private var phaseName: String {
        phase.name(for: skill.id)
    }

    private var phaseSubtitle: String {
        phase.subtitle(for: skill.id)
    }

    /// Get howTo steps for this phase
    private var howToSteps: [String] {
        phase.howToStepIndices.compactMap { index in
            guard index >= 0 && index < skill.howTo.count else { return nil }
            return skill.howTo[index]
        }
    }

    /// Get tips for this phase
    private var tips: [String] {
        guard let tipIndices = phase.tipIndices else { return [] }
        return tipIndices.compactMap { index in
            guard index >= 0 && index < skill.tips.count else { return nil }
            return skill.tips[index]
        }
    }

    /// Get cell for a location
    private func cell(for location: LocationTier) -> PhaseLocationCell? {
        progress.cell(for: phase.id, location: location)
    }

    /// Check if outside location is unlocked (inside must be mastered first)
    private var isOutsideUnlocked: Bool {
        cell(for: .inside)?.state == .mastered
    }

    /// Update state for a location
    private func updateState(location: LocationTier, state: PhaseLocationState) {
        skillProgressStore.updateMatrixCell(
            skillId: skill.id,
            phaseId: phase.id,
            location: location,
            state: state
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Phase header
                    phaseHeader

                    // Instructions section
                    instructionsSection

                    // Tips section
                    if !tips.isEmpty {
                        tipsSection
                    }

                    // Progress section
                    progressSection
                }
                .padding()
            }
            .textSelection(.enabled)
            .navigationTitle(Strings.Training.Matrix.phaseNumber(phaseIndex + 1))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Phase Header

    @ViewBuilder
    private var phaseHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(phaseName)
                .font(.title2)
                .fontWeight(.bold)

            if !phaseSubtitle.isEmpty {
                Text(phaseSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Instructions Section

    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(Strings.Training.Matrix.howToDoIt, systemImage: "list.number")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(howToSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number circle
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.otisAccent))

                        Text(step)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
        )
    }

    // MARK: - Tips Section

    @ViewBuilder
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.tips, systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.yellow.opacity(0.1))
        )
    }

    // MARK: - Progress Section

    @ViewBuilder
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(Strings.Training.Matrix.yourProgress, systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            // Inside location card
            locationProgressCard(location: .inside, isLocked: false)

            // Outside location card
            locationProgressCard(location: .outside, isLocked: !isOutsideUnlocked)
        }
    }

    @ViewBuilder
    private func locationProgressCard(location: LocationTier, isLocked: Bool) -> some View {
        let currentCell = cell(for: location)
        let state = currentCell?.state ?? .notStarted
        let lastPracticed = currentCell?.lastPracticedAt

        VStack(alignment: .leading, spacing: 12) {
            // Location header
            HStack {
                Image(systemName: location.icon)
                    .font(.title3)
                    .foregroundStyle(isLocked ? .secondary : locationColor(location))

                VStack(alignment: .leading, spacing: 2) {
                    Text(locationLabel(location))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isLocked ? .secondary : .primary)

                    if isLocked {
                        Text(Strings.Training.Matrix.lockedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let lastPracticed {
                        Text(Strings.Training.Matrix.lastPracticed(lastPracticed.relativeFormatted()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(Strings.Training.Matrix.neverPracticed)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // State badge
                HStack(spacing: 4) {
                    Image(systemName: state.icon)
                    Text(stateLabel(state))
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(stateColor(state))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(stateColor(state).opacity(0.15))
                )
            }

            // Action buttons
            if !isLocked {
                actionButtons(for: location, currentState: state)
            } else {
                // Practice anyway button for locked locations
                Button {
                    HapticFeedback.medium()
                    updateState(location: location, state: .inProgress)
                } label: {
                    Label(Strings.Training.Matrix.practiceAnyway, systemImage: "arrow.right.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardBackground(isLocked: isLocked))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(state == .mastered ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(isLocked ? 0.7 : 1.0)
    }

    @ViewBuilder
    private func actionButtons(for location: LocationTier, currentState: PhaseLocationState) -> some View {
        switch currentState {
        case .locked, .notStarted:
            HStack(spacing: 12) {
                Button {
                    HapticFeedback.medium()
                    updateState(location: location, state: .inProgress)
                } label: {
                    Text(Strings.Training.Matrix.iPracticedThis)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    HapticFeedback.success()
                    updateState(location: location, state: .mastered)
                } label: {
                    Text(Strings.Training.Matrix.myDogHasMastered)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

        case .inProgress:
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        HapticFeedback.medium()
                        // Re-set inProgress to update the timestamp
                        updateState(location: location, state: .inProgress)
                    } label: {
                        Label(Strings.Training.Matrix.logPractice, systemImage: "plus.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.orange, lineWidth: 1.5)
                            )
                    }

                    Button {
                        HapticFeedback.success()
                        updateState(location: location, state: .mastered)
                    } label: {
                        Label(Strings.Training.Matrix.myDogHasMastered, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

        case .mastered:
            HStack(spacing: 12) {
                Button {
                    HapticFeedback.light()
                    updateState(location: location, state: .inProgress)
                } label: {
                    Label(Strings.Training.Matrix.unmarkMastered, systemImage: "arrow.uturn.backward")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Helpers

    private func locationLabel(_ location: LocationTier) -> String {
        switch location {
        case .inside: return Strings.Training.Matrix.insideLocation
        case .outside: return Strings.Training.Matrix.outsideLocation
        }
    }

    private func locationColor(_ location: LocationTier) -> Color {
        switch location {
        case .inside: return .blue
        case .outside: return .green
        }
    }

    private func stateLabel(_ state: PhaseLocationState) -> String {
        switch state {
        case .locked: return Strings.Training.Matrix.locked
        case .notStarted: return Strings.Training.Matrix.notStarted
        case .inProgress: return Strings.Training.Matrix.inProgress
        case .mastered: return Strings.Training.Matrix.mastered
        }
    }

    private func stateColor(_ state: PhaseLocationState) -> Color {
        switch state {
        case .locked: return .gray
        case .notStarted: return .secondary
        case .inProgress: return .orange
        case .mastered: return .green
        }
    }

    private func cardBackground(isLocked: Bool) -> Color {
        if isLocked {
            return colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)
        }
        return colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03)
    }
}

// MARK: - Date Extension

private extension Date {
    func relativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    PhaseDetailSheet(
        skill: Skill(
            id: "sit",
            icon: "figure.seated",
            category: .basicCommands,
            sortOrder: 5,
            requires: [],
            method: nil,
            durationMinutes: 5,
            sessionsPerDay: 2,
            steps: nil,
            phases: [
                SkillPhase(id: "lureToPosition", howToStepIndices: [0, 1, 2], tipIndices: [0, 1]),
                SkillPhase(id: "captureAndStrengthen", howToStepIndices: [3, 4], tipIndices: [2])
            ]
        ),
        phase: SkillPhase(id: "lureToPosition", howToStepIndices: [0, 1, 2], tipIndices: [0, 1]),
        phaseIndex: 0,
        skillProgressStore: SkillProgressStore(),
        onDismiss: {}
    )
}
