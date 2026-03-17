//
//  SkillPhasesPage.swift
//  Ollie-app
//
//  Parent overview page for a skill showing theory + phase rows.
//  Each row shows inline location status and opens a detail sheet when tapped.
//  This is the main entry point for the redesigned skill learning flow.
//

import SwiftUI
import OtisShared

/// Parent overview page for a skill with phases as list rows
struct SkillPhasesPage: View {
    let skill: Skill
    @Bindable var skillProgressStore: SkillProgressStore
    @Bindable var theoryStore: TrainingTheoryStore
    let onDismiss: () -> Void

    @State private var selectedPhase: SkillPhase?
    @State private var showingTheory = false
    @Environment(\.colorScheme) private var colorScheme

    private var phases: [SkillPhase] {
        skill.effectivePhases
    }

    private var progress: SkillProgress {
        skillProgressStore.progress(for: skill.id)
    }

    private var theoryComplete: Bool {
        theoryStore.isTheoryComplete(forSkill: skill.id)
    }

    /// Check if a phase is unlocked (at least inside is available)
    private func isPhaseUnlocked(_ phase: SkillPhase) -> Bool {
        guard let phaseIndex = phases.firstIndex(where: { $0.id == phase.id }) else {
            return false
        }

        // First phase is always unlocked
        if phaseIndex == 0 { return true }

        // Check if previous phase is mastered inside
        let prevPhase = phases[phaseIndex - 1]
        let prevInsideCell = progress.cell(for: prevPhase.id, location: .inside)
        return prevInsideCell?.state == .mastered
    }

    /// Get the prerequisite phase name for a locked phase
    private func prerequisitePhase(for phase: SkillPhase) -> String? {
        guard let phaseIndex = phases.firstIndex(where: { $0.id == phase.id }),
              phaseIndex > 0 else {
            return nil
        }
        return phases[phaseIndex - 1].name(for: skill.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Progress header (not tappable)
                    progressSummaryHeader

                    // Theory row
                    theoryRowCard

                    // Phase rows
                    ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                        PhaseRowCard(
                            skill: skill,
                            phase: phase,
                            phaseIndex: index,
                            progress: progress,
                            isUnlocked: isPhaseUnlocked(phase),
                            prerequisiteName: prerequisitePhase(for: phase),
                            onTap: {
                                selectedPhase = phase
                            }
                        )
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(skill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTheory) {
                TheoryFlowSheet(
                    skill: skill,
                    theoryStore: theoryStore,
                    onComplete: {
                        showingTheory = false
                        // Initialize matrix when theory completes
                        skillProgressStore.migrateToMatrix(skillId: skill.id, phaseIds: phases.map(\.id))
                    },
                    onDismiss: {
                        showingTheory = false
                    }
                )
            }
            .sheet(item: $selectedPhase) { phase in
                PhaseDetailSheet(
                    skill: skill,
                    phase: phase,
                    phaseIndex: phases.firstIndex(where: { $0.id == phase.id }) ?? 0,
                    skillProgressStore: skillProgressStore,
                    onDismiss: {
                        selectedPhase = nil
                    }
                )
                .presentationDetents([.large])
            }
        }
        .onAppear {
            // Initialize matrix if theory is complete but matrix is empty
            if theoryComplete && progress.phaseLocationMatrix.isEmpty {
                skillProgressStore.migrateToMatrix(skillId: skill.id, phaseIds: phases.map(\.id))
            }
        }
    }

    // MARK: - Progress Summary Card

    @ViewBuilder
    private var progressSummaryHeader: some View {
        let masteredCount = progress.masteredPhaseCount(phaseIds: phases.map(\.id))
        let progressFraction = Double(masteredCount) / Double(max(phases.count, 1))

        VStack(spacing: 16) {
            // Skill icon - larger, centered
            ZStack {
                Circle()
                    .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: skill.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(Color.otisAccent)
            }

            // Progress info - centered
            VStack(spacing: 8) {
                if progress.isFullyMastered {
                    Label(Strings.Training.Matrix.allPhasesMastered, systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                } else {
                    Text(Strings.Training.Matrix.phasesProgress(
                        mastered: masteredCount,
                        total: phases.count
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Progress bar - full width
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.otisAccent)
                            .frame(width: max(0, CGFloat(progressFraction) * 200), height: 8)
                    }
                    .frame(width: 200)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Theory Row Card

    @ViewBuilder
    private var theoryRowCard: some View {
        Button {
            showingTheory = true
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theoryComplete ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "book.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(theoryComplete ? .green : .orange)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Training.Matrix.learnTheory)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if theoryComplete {
                        Label(Strings.Training.Matrix.theoryComplete, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        let pagesRead = theoryStore.pagesReadCount(forSkill: skill.id)
                        if pagesRead > 0 {
                            Text(Strings.Training.Matrix.readingProgress(read: pagesRead, total: phases.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(Strings.Training.Matrix.theoryNotStarted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(theoryComplete ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Phase Row Card

struct PhaseRowCard: View {
    let skill: Skill
    let phase: SkillPhase
    let phaseIndex: Int
    let progress: SkillProgress
    let isUnlocked: Bool
    let prerequisiteName: String?
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var insideCell: PhaseLocationCell? {
        progress.cell(for: phase.id, location: .inside)
    }

    private var outsideCell: PhaseLocationCell? {
        progress.cell(for: phase.id, location: .outside)
    }

    private var phaseName: String {
        phase.name(for: skill.id)
    }

    /// Check if this phase is fully mastered (both locations)
    private var isFullyMastered: Bool {
        insideCell?.state == .mastered && outsideCell?.state == .mastered
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Phase number badge
                ZStack {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 32, height: 32)

                    if isFullyMastered {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    } else {
                        Text("\(phaseIndex + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(isUnlocked ? .white : .secondary)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(phaseName)
                        .font(.headline)
                        .foregroundStyle(isUnlocked ? .primary : .secondary)
                        .lineLimit(2)

                    if isUnlocked {
                        // Location status indicators
                        HStack(spacing: 16) {
                            locationStatusBadge(location: .inside, cell: insideCell)
                            locationStatusBadge(location: .outside, cell: outsideCell)
                        }
                    } else {
                        // Locked message
                        if let prereq = prerequisiteName {
                            Label {
                                Text(Strings.Training.Matrix.masterPhaseFirst(prereq))
                            } icon: {
                                Image(systemName: "lock.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if isUnlocked {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isFullyMastered ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .opacity(isUnlocked ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private var badgeColor: Color {
        if isFullyMastered {
            return .green
        } else if isUnlocked {
            return .otisAccent
        } else {
            return .gray.opacity(0.5)
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03)
    }

    @ViewBuilder
    private func locationStatusBadge(location: LocationTier, cell: PhaseLocationCell?) -> some View {
        let state = cell?.state ?? .notStarted

        HStack(spacing: 6) {
            Image(systemName: location.icon)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: state.icon)
                    .font(.caption)
                    .foregroundStyle(stateColor(state))

                Text(stateLabel(state))
                    .font(.caption2)
                    .foregroundStyle(stateColor(state))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(stateColor(state).opacity(0.1))
        )
    }

    private func stateColor(_ state: PhaseLocationState) -> Color {
        switch state {
        case .locked: return .gray
        case .notStarted: return .secondary
        case .inProgress: return .orange
        case .mastered: return .green
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
}

// MARK: - Preview

#Preview {
    SkillPhasesPage(
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
                SkillPhase(id: "captureAndStrengthen", howToStepIndices: [3, 4], tipIndices: [2]),
                SkillPhase(id: "addVerbalCue", howToStepIndices: [5, 6, 7], tipIndices: [3]),
                SkillPhase(id: "proofThreeDs", howToStepIndices: [8, 9, 10], tipIndices: [4, 5])
            ]
        ),
        skillProgressStore: SkillProgressStore(),
        theoryStore: TrainingTheoryStore(),
        onDismiss: {}
    )
}
