//
//  SkillsPreviewCard.swift
//  Otis-app
//
//  Compact preview card showing current training status and quick actions
//

import OtisShared
import SwiftUI

/// Compact preview of current week's training focus
struct SkillsPreviewCard: View {
    var eventStore: EventStore
    var skillProgressStore: SkillProgressStore
    @State private var trainingStore = TrainingPlanStore()
    @State private var progressStore = TrainingProgressStore()
    @Environment(ProfileStore.self) var profileStore
    @Environment(TrainingTheoryStore.self) var trainingTheoryStore

    @State private var skillForDetailSheet: Skill?
    @State private var skillForQuickLog: Skill?
    @State private var activeTrainingSkill: Skill?
    @State private var activeTrainingPhase: SkillPhase?
    @State private var completedSessionData: TrainingSessionData?
    @State private var selectedSkill: Skill?

    @Environment(\.colorScheme) private var colorScheme

    /// Enhanced skill list with smart training data from SkillProgressStore
    private var enhancedSkillsWithStatus: [SkillProgressInfo] {
        trainingStore.allSkillsWithStatus.map { info in
            let progress = skillProgressStore.progress(for: info.skill.id)

            var daysUntilReview: Int?
            if let nextReview = progress.nextReviewDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: nextReview).day ?? 0
                daysUntilReview = max(0, days)
            }

            let isDue = progress.phase == .maintaining && skillProgressStore.skillsDueForReview.contains { $0.skillId == info.skill.id }

            return SkillProgressInfo(
                skill: info.skill,
                status: info.status,
                sessionCount: info.sessionCount,
                isLocked: info.isLocked,
                isNextUp: info.isNextUp,
                missingRequirements: info.missingRequirements,
                learningPhase: progress.phase == .notStarted ? nil : progress.phase,
                confidenceScore: progress.confidenceScore > 0 ? progress.confidenceScore : nil,
                isDueForReview: isDue,
                daysUntilReview: daysUntilReview,
                proofingLevels: progress.proofingLevels,
                practicedContexts: progress.practicedContexts,
                maintenanceTier: progress.maintenanceTier > 0 ? progress.maintenanceTier : nil,
                nextReviewDate: progress.nextReviewDate
            )
        }
    }

    /// Get the featured skill to show: first skill in progress, or the "next up" skill
    private var featuredSkill: SkillProgressInfo? {
        // Priority 1: Skills needing work (regression)
        if let regression = enhancedSkillsWithStatus.first(where: { $0.isInRegression }) {
            return regression
        }

        // Priority 2: Skills due for review
        if let dueForReview = enhancedSkillsWithStatus.first(where: { $0.isDueForReview }) {
            return dueForReview
        }

        // Priority 3: Skills in active learning (in progress)
        if let inProgress = enhancedSkillsWithStatus.first(where: {
            $0.learningPhase?.isActiveLearning == true
        }) {
            return inProgress
        }

        // Priority 4: Next up skill
        if let nextUp = enhancedSkillsWithStatus.first(where: { $0.isNextUp }) {
            return nextUp
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with title and progress ring
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .foregroundStyle(Color.otisAccent)
                            .accessibilityHidden(true)
                        Text(Strings.Train.skills)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .accessibilityAddTraits(.isHeader)
                    }

                    Text(Strings.Train.skillsDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if trainingStore.trainingPlan != nil {
                    ProgressRing(
                        completed: trainingStore.masteryProgress.mastered,
                        total: trainingStore.masteryProgress.total,
                        size: .compact
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Strings.Train.progressRingAccessibility)
                    .accessibilityValue(Strings.Train.progressValue(started: trainingStore.masteryProgress.mastered, total: trainingStore.masteryProgress.total))
                }
            }

            if trainingStore.trainingPlan != nil {
                // Featured skill row - shows first in progress or next up skill
                if let featured = featuredSkill {
                    SkillProgressRow(
                        info: featured,
                        onTap: {
                            skillForDetailSheet = featured.skill
                        },
                        onQuickDone: {
                            skillForQuickLog = featured.skill
                        },
                        onToggleMastered: {
                            trainingStore.toggleMastered(featured.skill.id)
                        }
                    )
                }

                // View all skills link
                NavigationLink {
                    TrainingView(eventStore: eventStore)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                        Text(Strings.Training.viewAllSkills)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.otisAccent)
                }
                .buttonStyle(.plain)
            } else {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .padding()
        .glassCard(tint: .accent)
        .onAppear {
            trainingStore.setEventStore(eventStore)
            trainingStore.setSkillProgressStore(skillProgressStore)
        }
        // Skill learning flow sheet
        .sheet(item: $skillForDetailSheet) { skill in
            let status = trainingStore.status(for: skill.id)
            let sessionCount = trainingStore.sessionCount(for: skill.id)
            let recentSessions = trainingStore.recentSessions(for: skill.id)

            SkillLearningFlowSheet(
                skill: skill,
                status: status,
                sessionCount: sessionCount,
                recentSessions: recentSessions,
                onStartTraining: { phase in
                    activeTrainingPhase = phase
                    activeTrainingSkill = skill
                },
                onLogSession: {
                    skillForQuickLog = skill
                },
                onToggleMastered: {
                    trainingStore.toggleMastered(skill.id)
                },
                onDismiss: {
                    skillForDetailSheet = nil
                },
                progressStore: progressStore,
                skillProgressStore: skillProgressStore,
                theoryStore: trainingTheoryStore
            )
            .presentationDetents([.large])
        }
        // Quick log sheet
        .sheet(item: $skillForQuickLog) { skill in
            TrainingLogSheet(
                skill: skill,
                prefillData: nil,
                onSave: { event in
                    eventStore.addEvent(event)
                    skillForQuickLog = nil
                },
                onCancel: {
                    skillForQuickLog = nil
                },
                onRecordProgress: { skillId, successReps, failedReps, context in
                    skillProgressStore.recordTrainingSession(
                        skillId: skillId,
                        successReps: successReps,
                        failedReps: failedReps,
                        context: context
                    )
                }
            )
            .presentationDetents([.height(580)])
        }
        // Training log sheet (for completing in-app sessions)
        .sheet(item: $selectedSkill) { skill in
            TrainingLogSheet(
                skill: skill,
                prefillData: completedSessionData,
                onSave: { event in
                    eventStore.addEvent(event)
                    selectedSkill = nil
                    completedSessionData = nil
                },
                onCancel: {
                    selectedSkill = nil
                    completedSessionData = nil
                },
                onRecordProgress: { skillId, successReps, failedReps, context in
                    skillProgressStore.recordTrainingSession(
                        skillId: skillId,
                        successReps: successReps,
                        failedReps: failedReps,
                        context: context
                    )
                }
            )
            .presentationDetents([.height(580)])
        }
        // Full-screen training session
        .fullScreenCover(item: $activeTrainingSkill) { skill in
            if skill.usesClicker {
                TrainingSessionView(
                    skill: skill,
                    phase: activeTrainingPhase,
                    onComplete: { data in
                        activeTrainingSkill = nil
                        activeTrainingPhase = nil
                        completedSessionData = data
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
                            selectedSkill = skill
                        }
                    },
                    onCancel: {
                        activeTrainingSkill = nil
                        activeTrainingPhase = nil
                    }
                )
            } else {
                SimpleTrainingSessionView(
                    skill: skill,
                    phase: activeTrainingPhase,
                    onComplete: { data in
                        activeTrainingSkill = nil
                        activeTrainingPhase = nil
                        completedSessionData = data
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
                            selectedSkill = skill
                        }
                    },
                    onCancel: {
                        activeTrainingSkill = nil
                        activeTrainingPhase = nil
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let skillProgressStore = SkillProgressStore()

    SkillsPreviewCard(
        eventStore: eventStore,
        skillProgressStore: skillProgressStore
    )
    .environment(ProfileStore())
    .environment(TrainingTheoryStore())
    .padding()
}
