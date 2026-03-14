//
//  SkillLearningFlowSheet.swift
//  Otis-app
//
//  Paged learning flow for training skills using progressive disclosure
//

import SwiftUI
import OtisShared

/// Main container for the stepped learning flow
struct SkillLearningFlowSheet: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let recentSessions: [PuppyEvent]
    let onStartTraining: (SkillPhase?) -> Void  // Now passes the current phase
    let onLogSession: () -> Void
    let onToggleMastered: () -> Void
    let onDismiss: () -> Void

    @Bindable var progressStore: TrainingProgressStore
    var skillProgressStore: SkillProgressStore

    @State private var currentPage: Int = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Get progress for this skill from smart training system
    private var progress: SkillProgress {
        skillProgressStore.progress(for: skill.id)
    }

    private var phases: [SkillPhase] {
        skill.effectivePhases
    }

    /// Total pages: 1 overview + n phases
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
                                onStartTraining(phase)  // Pass the current phase
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
                // Bottom action bar (only show on last page)
                if currentPage == totalPages - 1 {
                    bottomActionBar
                }
            }
        }
    }

    // MARK: - Bottom Action Bar

    @ViewBuilder
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                // Log session button
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

                // Toggle mastered (always available)
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
        skillProgressStore: SkillProgressStore()
    )
}
