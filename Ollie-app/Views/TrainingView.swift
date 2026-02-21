//
//  TrainingView.swift
//  Ollie-app
//
//  Main training view showing skills by category with progress tracking
//

import SwiftUI

/// Main training view with skill tracker
struct TrainingView: View {
    @ObservedObject var eventStore: EventStore
    @StateObject private var trainingStore = TrainingPlanStore()

    @State private var selectedSkill: Skill?
    @State private var showingLogSheet = false
    @State private var scrollToSkillId: String?

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
        .sheet(isPresented: $showingLogSheet) {
            if let skill = selectedSkill {
                TrainingLogSheet(
                    skill: skill,
                    onSave: { event in
                        eventStore.addEvent(event)
                        showingLogSheet = false
                        selectedSkill = nil
                    },
                    onCancel: {
                        showingLogSheet = false
                        selectedSkill = nil
                    }
                )
                .presentationDetents([.height(500)])
            }
        }
    }

    // MARK: - Category Section

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
                        onLogSession: {
                            selectedSkill = skill
                            showingLogSheet = true
                        },
                        onToggleMastered: {
                            trainingStore.toggleMastered(skill.id)
                        }
                    )
                    .id(skill.id)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrainingView(eventStore: EventStore())
    }
}
