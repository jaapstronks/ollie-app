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
    @Environment(ProfileStore.self) var profileStore

    @State private var showTodaysTraining = false

    @Environment(\.colorScheme) private var colorScheme

    /// Determine if user has any training progress
    private var hasStartedTraining: Bool {
        trainingStore.masteryProgress.mastered > 0 ||
        trainingStore.allSkillsWithStatus.contains { $0.sessionCount > 0 }
    }

    /// Count of urgent skills (regression + due for review)
    private var urgentCount: Int {
        skillProgressStore.skillsNeedingWork.count +
        skillProgressStore.skillsDueForReview.count
    }

    /// Generate session summary text
    private var sessionSummaryText: String {
        let plan = skillProgressStore.generateSessionPlan()
        let totalSkills = plan.allSkillsInOrder.count

        if plan.isEmpty {
            return Strings.Training.noSkillsDue
        }

        let focusCount = plan.primaryFocus.count
        let reviewCount = plan.maintenance.count

        if focusCount > 0 && reviewCount > 0 {
            return Strings.Train.focusAndReview(focus: focusCount, review: reviewCount)
        } else if focusCount > 0 {
            return Strings.Train.skillsToPractice(focusCount)
        } else {
            return Strings.Train.skillsToReview(totalSkills)
        }
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
                // Primary CTA: Start Training button
                Button {
                    showTodaysTraining = true
                } label: {
                    HStack(spacing: 10) {
                        // Icon with optional badge
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "play.fill")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.otisAccent))

                            if urgentCount > 0 {
                                Circle()
                                    .fill(Color.otisDanger)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 2, y: -2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(hasStartedTraining ? Strings.Train.continueTraining : Strings.Training.startSession)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text(sessionSummaryText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                    )
                }
                .buttonStyle(.plain)

                // Secondary: View all skills link (inline, subtle)
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
        .sheet(isPresented: $showTodaysTraining) {
            TodaysTrainingView(
                skillProgressStore: skillProgressStore,
                eventStore: eventStore,
                trainingStore: trainingStore,
                puppyAgeWeeks: profileStore.profile?.ageInWeeks ?? 12,
                onDismiss: { showTodaysTraining = false }
            )
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
    .padding()
}
