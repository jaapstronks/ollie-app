//
//  SkillLearningFlowSheet.swift
//  Otis-app
//
//  Main entry point for skill learning flow.
//  Shows SkillPhasesPage with theory + phases as list rows.
//  Each row opens a detail sheet for that phase.
//

import SwiftUI
import OtisShared

/// Main coordinator for skill learning
struct SkillLearningFlowSheet: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let recentSessions: [PuppyEvent]
    let onStartTraining: (SkillPhase?) -> Void
    let onLogSession: () -> Void
    let onToggleMastered: () -> Void
    let onDismiss: () -> Void

    @Bindable var progressStore: TrainingProgressStore
    var skillProgressStore: SkillProgressStore
    @Bindable var theoryStore: TrainingTheoryStore

    var body: some View {
        SkillPhasesPage(
            skill: skill,
            skillProgressStore: skillProgressStore,
            theoryStore: theoryStore,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Legacy Flow Sheet (for skills without phases)

/// Original horizontal swipe flow for simpler skills
struct SkillLearningLegacyFlowSheet: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let recentSessions: [PuppyEvent]
    let onStartTraining: (SkillPhase?) -> Void
    let onLogSession: () -> Void
    let onToggleMastered: () -> Void
    let onDismiss: () -> Void

    @Bindable var progressStore: TrainingProgressStore
    var skillProgressStore: SkillProgressStore

    @State private var currentPage: Int = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: SkillProgress {
        skillProgressStore.progress(for: skill.id)
    }

    private var phases: [SkillPhase] {
        skill.effectivePhases
    }

    private var totalPages: Int {
        1 + phases.count
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                // Page 0: Overview
                SkillOverviewPage(
                    skill: skill,
                    status: status,
                    sessionCount: sessionCount,
                    phases: phases,
                    progressStore: progressStore,
                    skillProgress: progress,
                    onStartLearning: {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                            currentPage = 1
                        }
                    }
                )
                .tag(0)

                // Pages 1-n: Phase pages
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    SkillPhasePage(
                        skill: skill,
                        phase: phase,
                        phaseIndex: index,
                        totalPhases: phases.count,
                        isLastPhase: index == phases.count - 1,
                        progressStore: progressStore,
                        onContinue: {
                            if index < phases.count - 1 {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                    currentPage = index + 2
                                }
                            }
                        },
                        onStartTraining: {
                            onDismiss()
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.3))
                                onStartTraining(phase)
                            }
                        }
                    )
                    .tag(index + 1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: currentPage)
            .navigationTitle(skill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    if totalPages > 1 {
                        PhaseProgressIndicator(
                            currentPage: currentPage,
                            totalPages: totalPages
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if currentPage == totalPages - 1 {
                    bottomActionBar
                }
            }
        }
    }

    @ViewBuilder
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                Button {
                    HapticFeedback.light()
                    onDismiss()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        onLogSession()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text(Strings.Training.logSession)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.otisAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.otisAccent, lineWidth: 1.5)
                    )
                }

                Button {
                    HapticFeedback.medium()
                    onToggleMastered()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: status == .mastered ? "checkmark.circle.fill" : "checkmark.circle")
                        Text(status == .mastered ? Strings.Training.unmarkMastered : Strings.Training.markMastered)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(status == .mastered ? Color.otisSuccess : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Preview

private let previewSkill = Skill(
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
)

#Preview {
    SkillLearningFlowSheet(
        skill: previewSkill,
        status: .started,
        sessionCount: 3,
        recentSessions: [],
        onStartTraining: { _ in },
        onLogSession: {},
        onToggleMastered: {},
        onDismiss: {},
        progressStore: TrainingProgressStore(),
        skillProgressStore: SkillProgressStore(),
        theoryStore: TrainingTheoryStore()
    )
}
