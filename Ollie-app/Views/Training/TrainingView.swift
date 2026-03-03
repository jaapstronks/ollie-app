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
        // Skill detail sheet (replaces SkillInfoSheet)
        .sheet(item: $skillForDetailSheet) { skill in
            let status = trainingStore.status(for: skill.id)
            let sessionCount = trainingStore.sessionCount(for: skill.id)
            let recentSessions = trainingStore.recentSessions(for: skill.id)

            SkillDetailSheet(
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
                }
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
        // Next Up card (prominent)
        if let nextSkill = trainingStore.nextSkill {
            let status = trainingStore.status(for: nextSkill.id)
            let sessionCount = trainingStore.sessionCount(for: nextSkill.id)

            NextUpCard(
                skill: nextSkill,
                status: status,
                sessionCount: sessionCount,
                onStartTraining: {
                    checkForRulesAndStartTraining(nextSkill)
                },
                onViewInfo: {
                    skillForDetailSheet = nextSkill
                }
            )
        } else if trainingStore.masteryProgress.mastered == trainingStore.masteryProgress.total {
            // All skills mastered celebration
            allMasteredCard
        }

        // In Progress skills (unlocked but not the next one)
        let inProgressSkills = trainingStore.unlockedSkills.filter { skill in
            skill.id != trainingStore.nextSkill?.id
        }
        if !inProgressSkills.isEmpty {
            inProgressSection(skills: inProgressSkills)
        }

        // Mastered skills (compact list)
        let masteredSkills = trainingStore.masteredSkillsList
        if !masteredSkills.isEmpty {
            masteredSection(skills: masteredSkills)
        }

        // Locked skills (subtle, shows what's coming)
        let lockedSkills = trainingStore.lockedSkills
        if !lockedSkills.isEmpty {
            lockedSection(skills: lockedSkills)
        }

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

    // MARK: - In Progress Section

    @ViewBuilder
    private func inProgressSection(skills: [Skill]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.Progression.inProgressSection)

            ForEach(skills) { skill in
                let status = trainingStore.status(for: skill.id)
                let sessionCount = trainingStore.sessionCount(for: skill.id)
                let missingReqs = trainingStore.missingRequirements(for: skill)

                CompactSkillCard(
                    skill: skill,
                    status: status,
                    sessionCount: sessionCount,
                    isLocked: false,
                    missingRequirements: missingReqs,
                    onTap: {
                        skillForDetailSheet = skill
                    }
                )
            }
        }
    }

    // MARK: - Mastered Section

    @ViewBuilder
    private func masteredSection(skills: [Skill]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.Progression.masteredSection)

            VStack(spacing: 8) {
                ForEach(skills) { skill in
                    MasteredSkillCard(skill: skill) {
                        skillForDetailSheet = skill
                    }
                }
            }
        }
    }

    // MARK: - Locked Section

    @ViewBuilder
    private func lockedSection(skills: [Skill]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.Progression.lockedSection)

            VStack(spacing: 4) {
                ForEach(skills) { skill in
                    let missingReqs = trainingStore.missingRequirements(for: skill)
                    LockedSkillRow(skill: skill, missingRequirements: missingReqs)
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
            )
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
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
