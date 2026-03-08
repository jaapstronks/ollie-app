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
    @EnvironmentObject var skillProgressStore: SkillProgressStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedSkill: Skill?
    @State private var activeTrainingSkill: Skill?
    @State private var activeTrainingPhase: SkillPhase?  // Phase for focused training session
    @State private var skillForDetailSheet: Skill?
    @State private var skillForQuickLog: Skill?
    @State private var completedSessionData: TrainingSessionData?
    @State private var showRulesReference = false
    @State private var ruleToAcknowledge: TrainingRule?
    @State private var skillPendingRuleAcknowledgement: Skill?
    @State private var showOtisPlusSheet = false
    @State private var skillForRefresher: Skill?
    @State private var skillWithPrerequisiteWarning: SkillProgressInfo?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // First-visit tip tracking
    @AppStorage("hasSeenTrainingSkillsTip") private var hasSeenTrainingSkillsTip = false

    private var isPreparationComplete: Bool {
        guard let plan = trainingStore.trainingPlan else { return false }
        return progressStore.isPreparationComplete(requiredItems: plan.preparationItems)
    }

    /// Enhanced skill list with smart training data from SkillProgressStore
    private var enhancedSkillsWithStatus: [SkillProgressInfo] {
        trainingStore.allSkillsWithStatus.map { info in
            // Look up enhanced data from SkillProgressStore
            let progress = skillProgressStore.progress(for: info.skill.id)

            // Calculate days until review
            var daysUntilReview: Int?
            if let nextReview = progress.nextReviewDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: nextReview).day ?? 0
                daysUntilReview = max(0, days)
            }

            // Check if due for review
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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // First-visit tip
                if !hasSeenTrainingSkillsTip {
                    FeatureTipCard(
                        tip: .trainingSkillsIntro,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                hasSeenTrainingSkillsTip = true
                            }
                        }
                    )
                }

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
            trainingStore.setSkillProgressStore(skillProgressStore)
        }
        .task {
            await trainingStore.initialSync()
        }
        // Full-screen training session (clicker or simple based on skill type)
        .fullScreenCover(item: $activeTrainingSkill) { skill in
            if skill.usesClicker {
                TrainingSessionView(
                    skill: skill,
                    phase: activeTrainingPhase,  // Pass the phase for focused steps
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
                    phase: activeTrainingPhase,  // Pass the phase for focused steps
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
                onStartTraining: { phase in
                    activeTrainingPhase = phase  // Store the phase
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
                skillProgressStore: skillProgressStore
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
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
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
        // Skill refresher sheet (for maintenance mode)
        .sheet(item: $skillForRefresher) { skill in
            SkillRefresherSheet(
                skill: skill,
                onStartPractice: {
                    // Start a training session for this skill
                    activeTrainingSkill = skill
                    // Record the maintenance refresh
                    skillProgressStore.recordMaintenanceRefresh(for: skill.id)
                },
                onDismiss: {
                    skillForRefresher = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
        // Prerequisite warning alert (soft-lock instead of hard-lock)
        .alert(
            Strings.Training.Progression.skipPrerequisitesTitle,
            isPresented: Binding(
                get: { skillWithPrerequisiteWarning != nil },
                set: { if !$0 { skillWithPrerequisiteWarning = nil } }
            ),
            presenting: skillWithPrerequisiteWarning
        ) { info in
            Button(Strings.Training.Progression.startAnyway) {
                // Allow user to proceed anyway
                skillForDetailSheet = info.skill
                skillWithPrerequisiteWarning = nil
            }
            Button(Strings.Training.Progression.learnPrerequisitesFirst, role: .cancel) {
                skillWithPrerequisiteWarning = nil
            }
        } message: { info in
            let prereqNames = info.missingRequirements.map { $0.name }.joined(separator: ", ")
            Text(Strings.Training.Progression.skipPrerequisitesMessage(prereqNames))
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

    /// Check if there are skills needing attention
    private var hasSkillsNeedingAttention: Bool {
        !skillProgressStore.skillsNeedingWork.isEmpty ||
        !skillProgressStore.skillsDueForReview.isEmpty
    }

    /// Get SkillProgressInfo for regression skills
    private var regressionSkillInfos: [SkillProgressInfo] {
        skillProgressStore.skillsNeedingWork.compactMap { progress in
            guard let skillInfo = enhancedSkillsWithStatus.first(where: { $0.skill.id == progress.skillId }) else {
                return nil
            }
            return skillInfo
        }
    }

    /// Get SkillProgressInfo for due for review skills
    private var dueForReviewInfos: [SkillProgressInfo] {
        skillProgressStore.skillsDueForReview.compactMap { progress in
            // Skip if already in regression list
            guard !skillProgressStore.skillsNeedingWork.contains(where: { $0.skillId == progress.skillId }) else {
                return nil
            }
            guard let skillInfo = enhancedSkillsWithStatus.first(where: { $0.skill.id == progress.skillId }) else {
                return nil
            }
            return skillInfo
        }
    }

    @ViewBuilder
    private var trainingContent: some View {
        // Skills needing attention (NEW - at top)
        if hasSkillsNeedingAttention {
            needsAttentionSection
        }

        // Maintenance mode section (shows skills needing refresh)
        if !skillProgressStore.skillsInMaintenanceMode.isEmpty {
            MaintenanceSkillsSection(
                skillProgressStore: skillProgressStore,
                trainingStore: trainingStore,
                onSkillTap: { skill in
                    skillForDetailSheet = skill
                },
                onRefresh: { skill, _ in
                    // Record the refresh and give haptic feedback
                    skillProgressStore.recordMaintenanceRefresh(for: skill.id)
                    HapticFeedback.success()
                },
                onShowRefresher: { skill in
                    skillForRefresher = skill
                }
            )
        }

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

            // Skill rows (enhanced with smart training data)
            VStack(spacing: 6) {
                ForEach(enhancedSkillsWithStatus, id: \.skill.id) { info in
                    SkillProgressRow(
                        info: info,
                        onTap: {
                            // Show prerequisite warning for skills with unmet prerequisites
                            if info.hasUnmetPrerequisites && !info.missingRequirements.isEmpty {
                                skillWithPrerequisiteWarning = info
                                return
                            }

                            // Skills with phases should show the learning flow first
                            if info.skill.phases != nil && !info.skill.phases!.isEmpty {
                                skillForDetailSheet = info.skill
                            } else if info.isNextUp {
                                // For next up skill without phases, start training directly
                                checkForRulesAndStartTraining(info.skill)
                            } else {
                                // For other unlocked skills, show detail sheet
                                skillForDetailSheet = info.skill
                            }
                        },
                        onQuickDone: {
                            quickLogSession(for: info.skill)
                        },
                        onToggleMastered: {
                            trainingStore.toggleMastered(info.skill.id)
                            HapticFeedback.success()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Needs Attention Section

    @ViewBuilder
    private var needsAttentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(Strings.Training.needsAttention)
                    .font(.headline)
                Spacer()
            }

            // Regression skills first
            ForEach(regressionSkillInfos, id: \.skill.id) { info in
                SkillProgressRow(
                    info: info,
                    onTap: {
                        skillForDetailSheet = info.skill
                    },
                    onQuickDone: {
                        quickLogSession(for: info.skill)
                    }
                )
            }

            // Then due for review
            ForEach(dueForReviewInfos, id: \.skill.id) { info in
                SkillProgressRow(
                    info: info,
                    onTap: {
                        skillForDetailSheet = info.skill
                    },
                    onQuickDone: {
                        quickLogSession(for: info.skill)
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.orange.opacity(0.08) : Color.orange.opacity(0.05))
        )
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
