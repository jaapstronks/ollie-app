//
//  TrainingView.swift
//  Otis-app
//
//  Main training view with linear skill progression and preparation gate
//

import SwiftUI
import OtisShared

/// Main training view with preparation gate and linear skill progression
struct TrainingView: View {
    @ObservedObject var eventStore: EventStore

    @StateObject private var trainingStore = TrainingPlanStore()
    @StateObject private var progressStore = TrainingProgressStore()
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedSkill: Skill?
    @State private var activeTrainingSkill: Skill?
    @State private var skillForDetailSheet: Skill?
    @State private var skillForQuickLog: Skill?
    @State private var completedSessionData: TrainingSessionData?
    @State private var showRulesReference = false
    @State private var ruleToAcknowledge: TrainingRule?
    @State private var skillPendingRuleAcknowledgement: Skill?
    @State private var showOtisPlusSheet = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPreparationComplete: Bool {
        guard let plan = trainingStore.trainingPlan else { return false }
        return progressStore.isPreparationComplete(requiredItems: plan.preparationItems)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Preparation Section (gated)
                if !isPreparationComplete {
                    if let plan = trainingStore.trainingPlan {
                        PreparationSection(
                            progressStore: progressStore,
                            preparationItems: plan.preparationItems
                        )
                    }

                    // Show locked message for training content
                    preparationLockedMessage
                } else {
                    // 2. Training content (only if preparation complete)
                    trainingContent
                }
            }
            .padding()
        }
        .navigationTitle(Strings.Training.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            trainingStore.setEventStore(eventStore)
        }
        .task {
            await trainingStore.initialSync()
        }
        // Full-screen training session
        .fullScreenCover(item: $activeTrainingSkill) { skill in
            TrainingSessionView(
                skill: skill,
                onComplete: { data in
                    activeTrainingSkill = nil
                    completedSessionData = data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedSkill = skill
                    }
                },
                onCancel: {
                    activeTrainingSkill = nil
                }
            )
        }
        // Skill learning flow sheet (stepped learning with phases)
        .sheet(item: $skillForDetailSheet) { skill in
            let status = trainingStore.status(for: skill.id)
            let sessionCount = trainingStore.sessionCount(for: skill.id)
            let recentSessions = trainingStore.recentSessions(for: skill.id)

            SkillLearningFlowSheet(
                skill: skill,
                status: status,
                sessionCount: sessionCount,
                recentSessions: recentSessions,
                onStartTraining: {
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
                progressStore: progressStore
            )
            .presentationDetents([.large])
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
                }
            )
            .presentationDetents([.height(500)])
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
                }
            )
            .presentationDetents([.height(500)])
        }
        // Rules reference sheet
        .sheet(isPresented: $showRulesReference) {
            if let plan = trainingStore.trainingPlan {
                TrainingRulesReference(
                    progressStore: progressStore,
                    allRules: plan.rules
                )
            }
        }
        // Rule acknowledgment modal
        .sheet(item: $ruleToAcknowledge) { rule in
            RuleAcknowledgeSheet(
                rule: rule,
                onAcknowledge: {
                    progressStore.markRuleAsSeen(rule.id)
                    ruleToAcknowledge = nil
                    // Auto-start training after rule acknowledgement
                    if let skill = skillPendingRuleAcknowledgement {
                        skillPendingRuleAcknowledgement = nil
                        // Small delay to allow sheet dismissal animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            activeTrainingSkill = skill
                        }
                    }
                }
            )
            .presentationDetents([.medium])
        }
        // Otis+ upsell sheet
        .sheet(isPresented: $showOtisPlusSheet) {
            OtisPlusSheet(
                onDismiss: { showOtisPlusSheet = false },
                onSubscribed: { showOtisPlusSheet = false }
            )
        }
    }

    // MARK: - Preparation Locked Message

    private var preparationLockedMessage: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(.tertiary)

            Text(Strings.Training.Progression.preparationRequired)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    // MARK: - Training Content

    @ViewBuilder
    private var trainingContent: some View {
        // All skills mastered celebration (if applicable)
        if trainingStore.masteryProgress.mastered == trainingStore.masteryProgress.total {
            allMasteredCard
        }

        // Unified skill list
        allSkillsSection

        // Rules Reference link
        if let plan = trainingStore.trainingPlan {
            let seenCount = progressStore.getSeenRules(from: plan.rules).count
            if seenCount > 0 {
                TrainingRulesLink(
                    seenRulesCount: seenCount,
                    onTap: { showRulesReference = true }
                )
            }
        }
    }

    // MARK: - All Skills Section

    @ViewBuilder
    private var allSkillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(Strings.Training.skillTracker)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Progress indicator
                let progress = trainingStore.masteryProgress
                Text("\(progress.mastered)/\(progress.total)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    )
            }

            // Skill rows
            VStack(spacing: 6) {
                ForEach(trainingStore.allSkillsWithStatus, id: \.skill.id) { info in
                    SkillProgressRow(
                        info: info,
                        onTap: {
                            if info.isNextUp {
                                // For next up skill, start training (with rule check)
                                checkForRulesAndStartTraining(info.skill)
                            } else if !info.isLocked {
                                // For other unlocked skills, show detail sheet
                                skillForDetailSheet = info.skill
                            }
                        },
                        onQuickDone: {
                            quickLogSession(for: info.skill)
                        }
                    )
                }
            }
        }
    }

    // MARK: - All Mastered Card

    private var allMasteredCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text(Strings.Training.Progression.allSkillsMastered)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassStatusCard(tintColor: .yellow.opacity(0.3))
    }

    // MARK: - Helpers

    /// Instantly logs a minimal training session for quick "done" marking
    private func quickLogSession(for skill: Skill) {
        // Use the skill's recommended duration or default to 3 minutes
        let duration = skill.durationMinutes ?? 3

        let event = PuppyEvent(
            time: Date(),
            type: .training,
            note: nil,
            exercise: skill.id,
            result: nil,
            durationMin: duration
        )

        eventStore.addEvent(event)
        HapticFeedback.success()
    }

    private func checkForRulesAndStartTraining(_ skill: Skill) {
        // Check if there are any unseen rules for this skill's first step
        guard let plan = trainingStore.trainingPlan else {
            activeTrainingSkill = skill
            return
        }

        // For skills with steps, check the first step for prerequisite rules
        if let steps = skill.steps, let firstStep = steps.first,
           let ruleId = firstStep.prerequisiteRuleId,
           !progressStore.hasSeenRule(ruleId),
           let rule = plan.rule(withId: ruleId) {
            // Store the skill so we can auto-start after rule acknowledgement
            skillPendingRuleAcknowledgement = skill
            // Show rule acknowledgment first
            ruleToAcknowledge = rule
        } else {
            activeTrainingSkill = skill
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrainingView(eventStore: EventStore())
            .environmentObject(SubscriptionManager.shared)
    }
}
