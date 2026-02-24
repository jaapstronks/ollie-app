//
//  TrainingView.swift
//  Ollie-app
//
//  Main training view showing skills by category with progress tracking
//

import SwiftUI
import OllieShared

/// Main training view with skill tracker
struct TrainingView: View {
    @ObservedObject var eventStore: EventStore

    @StateObject private var trainingStore = TrainingPlanStore()
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedSkill: Skill?
    @State private var activeTrainingSkill: Skill?
    @State private var skillForInfoSheet: Skill?
    @State private var completedSessionData: TrainingSessionData?
    @State private var scrollToSkillId: String?
    @State private var showOlliePlusSheet = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    // Week hero card
                    if let weekPlan = trainingStore.currentWeekPlan {
                        WeekHeroCard(
                            currentWeek: trainingStore.currentWeek,
                            weekTitle: weekPlan.title,
                            focusSkills: trainingStore.currentFocusSkills,
                            progress: trainingStore.weekProgress,
                            onSkillTap: { skill in
                                scrollToSkillId = skill.id
                            }
                        )
                    }

                    // Skills by category
                    ForEach(TrainingCategory.allCases) { category in
                        categorySection(for: category)
                    }
                }
                .padding()
            }
            .onChange(of: scrollToSkillId) { _, skillId in
                if let skillId = skillId {
                    withAnimation {
                        proxy.scrollTo(skillId, anchor: .center)
                    }
                    scrollToSkillId = nil
                }
            }
        }
        .navigationTitle(Strings.Training.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            trainingStore.setEventStore(eventStore)
        }
        .task {
            // Initial CloudKit sync for mastered skills
            await trainingStore.initialSync()
        }
        // Full-screen training session
        .fullScreenCover(item: $activeTrainingSkill) { skill in
            TrainingSessionView(
                skill: skill,
                onComplete: { data in
                    activeTrainingSkill = nil
                    completedSessionData = data
                    // Small delay to allow cover to dismiss, then show log sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedSkill = skill
                    }
                },
                onCancel: {
                    activeTrainingSkill = nil
                }
            )
        }
        // Skill info sheet
        .sheet(item: $skillForInfoSheet) { skill in
            let status = trainingStore.status(for: skill.id)
            let sessionCount = trainingStore.sessionCount(for: skill.id)
            let recentSessions = trainingStore.recentSessions(for: skill.id)

            SkillInfoSheet(
                skill: skill,
                status: status,
                sessionCount: sessionCount,
                recentSessions: recentSessions,
                onStartTraining: {
                    // Start training after info sheet dismisses
                    activeTrainingSkill = skill
                },
                onDismiss: {
                    skillForInfoSheet = nil
                }
            )
            .presentationDetents([.large])
        }
        // Training log sheet (for completing sessions)
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
        // Ollie+ upsell sheet
        .sheet(isPresented: $showOlliePlusSheet) {
            OlliePlusSheet(
                onDismiss: { showOlliePlusSheet = false },
                onSubscribed: { showOlliePlusSheet = false }
            )
        }
    }

    // MARK: - Category Section

    /// Calculate the global skill index for subscription gating
    private func globalSkillIndex(for skill: Skill, in category: TrainingCategory) -> Int {
        guard let plan = trainingStore.trainingPlan else { return 0 }

        var index = 0
        for cat in TrainingCategory.allCases {
            let skills = plan.skills(for: cat)
            if cat == category {
                // Find index within this category
                if let skillIndex = skills.firstIndex(where: { $0.id == skill.id }) {
                    return index + skillIndex
                }
            }
            index += skills.count
            if cat == category { break }
        }
        return index
    }

    @ViewBuilder
    private func categorySection(for category: TrainingCategory) -> some View {
        let skills = trainingStore.trainingPlan?.skills(for: category) ?? []
        let progress = trainingStore.categoryProgress(for: category)

        if !skills.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Section header
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.body)
                        .foregroundStyle(category.color)

                    Text(category.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Progress badge
                    Text("\(progress.started)/\(progress.total)")
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
                .padding(.horizontal, 4)

                // Skill cards
                ForEach(skills) { skill in
                    let globalIndex = globalSkillIndex(for: skill, in: category)
                    let canAccess = subscriptionManager.canAccessSkill(at: globalIndex)

                    if canAccess {
                        let isLocked = trainingStore.isLocked(skill)
                        let status = trainingStore.status(for: skill.id)
                        let sessionCount = trainingStore.sessionCount(for: skill.id)
                        let missingReqs = trainingStore.missingRequirements(for: skill)
                        let recentSessions = trainingStore.recentSessions(for: skill.id)

                        SkillCard(
                            skill: skill,
                            status: status,
                            sessionCount: sessionCount,
                            isLocked: isLocked,
                            missingRequirements: missingReqs,
                            recentSessions: recentSessions,
                            onStartTraining: {
                                activeTrainingSkill = skill
                            },
                            onViewInfo: {
                                skillForInfoSheet = skill
                            },
                            onToggleMastered: {
                                trainingStore.toggleMastered(skill.id)
                            }
                        )
                        .id(skill.id)
                    } else {
                        // Locked skill card for Ollie+ upsell
                        PremiumLockedSkillCard(
                            skillName: skill.name,
                            category: category.label,
                            onUnlock: { showOlliePlusSheet = true }
                        )
                        .id(skill.id)
                    }
                }
            }
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
