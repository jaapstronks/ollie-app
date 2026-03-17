//
//  TheoryFlowSheet.swift
//  Ollie-app
//
//  Container for theory pages with horizontal swipe navigation.
//  User reads through all phases before practice begins.
//

import SwiftUI
import OtisShared

/// Theory flow for reading skill phases before practice
struct TheoryFlowSheet: View {
    let skill: Skill
    @Bindable var theoryStore: TrainingTheoryStore
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @State private var currentPage: Int = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var phases: [SkillPhase] {
        skill.effectivePhases
    }

    private var totalPages: Int {
        phases.count
    }

    /// Check if current page has been read
    private var currentPageRead: Bool {
        theoryStore.progress(forSkill: skill.id)?.pagesRead.contains(currentPage) ?? false
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                    TheoryPageView(
                        skill: skill,
                        phase: phase,
                        phaseIndex: index,
                        totalPhases: totalPages
                    )
                    .tag(index)
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
                bottomBar
            }
            .onChange(of: currentPage) { _, newPage in
                // Mark page as read when viewed
                theoryStore.markPageRead(newPage, forSkill: skill.id, totalPages: totalPages)
            }
            .onAppear {
                // Mark first page as read
                theoryStore.markPageRead(0, forSkill: skill.id, totalPages: totalPages)
            }
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 12) {
            Divider()

            VStack(spacing: 8) {
                // Progress text
                Text(Strings.Training.Matrix.readingProgress(
                    read: theoryStore.pagesReadCount(forSkill: skill.id),
                    total: totalPages
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    // Skip button (always available)
                    Button {
                        HapticFeedback.light()
                        theoryStore.skipTheory(forSkill: skill.id)
                        onComplete()
                    } label: {
                        Text(Strings.Training.Matrix.alreadyKnowThis)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            )
                    }

                    // Continue / Start Practice button
                    Button {
                        HapticFeedback.medium()
                        if currentPage < totalPages - 1 {
                            // Move to next page
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            // Last page - complete theory
                            onComplete()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if currentPage == totalPages - 1 {
                                Image(systemName: "checkmark.circle.fill")
                                Text(Strings.Training.Matrix.startPracticing)
                            } else {
                                Text(Strings.Common.continue_)
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.otisAccent)
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Preview

#Preview {
    TheoryFlowSheet(
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
                SkillPhase(id: "lureToPosition", howToStepIndices: [0, 1], tipIndices: [0]),
                SkillPhase(id: "captureAndStrengthen", howToStepIndices: [2], tipIndices: [1]),
                SkillPhase(id: "addVerbalCue", howToStepIndices: [3, 4], tipIndices: [2])
            ]
        ),
        theoryStore: TrainingTheoryStore(),
        onComplete: {},
        onDismiss: {}
    )
}
