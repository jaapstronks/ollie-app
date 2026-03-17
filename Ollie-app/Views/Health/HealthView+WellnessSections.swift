//
//  HealthView+WellnessSections.swift
//  Ollie-app
//
//  Senior and adult wellness sections for the health view.
//

import SwiftUI
import OtisShared

extension HealthView {

    // MARK: - Adult Wellness Section

    @ViewBuilder
    var adultWellnessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.AdultWellness.title, icon: "figure.walk.motion", tint: .green) {
                NavigationLink(destination: RoutineView().environment(routineStore)) {
                    Text(Strings.Common.seeAll)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            // Adult wellness content
            VStack(spacing: 12) {
                // Grooming due card (if any due)
                let dueGrooming = routineStore.dueGroomingActivities
                if !dueGrooming.isEmpty {
                    GroomingCard(
                        activities: routineStore.groomingActivities,
                        onMarkComplete: { activity in
                            routineStore.markGroomingCompleted(activity)
                        },
                        onTap: {}
                    )
                }

                // Enrichment suggestion
                if let suggestion = routineStore.enrichmentSuggestion() {
                    EnrichmentCard(
                        activities: routineStore.enrichmentActivities,
                        suggestion: suggestion,
                        onLogActivity: {
                            routineStore.addEnrichment(type: suggestion)
                        },
                        onTap: {}
                    )
                }

                // Weight goal progress (if active goal exists)
                WeightGoalCard(
                    goal: routineStore.weightGoal,
                    currentWeight: weightStore.latestWeight?.weight,
                    latestBCS: routineStore.bodyConditionScores.first,
                    onGoalTap: {},
                    onBCSTap: {}
                )
            }
        }
    }

    // MARK: - Senior Wellness Section

    @ViewBuilder
    var seniorWellnessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.SeniorWellness.title, icon: "heart.circle.fill", tint: .pink) {
                NavigationLink(destination: SeniorWellnessView().environment(viewModel.profileStore)) {
                    Text(Strings.Common.seeAll)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            // Senior wellness card
            VStack(spacing: 16) {
                // Quick mobility check
                MobilityTrendCard(
                    onLogTap: { showMobilitySheet = true },
                    onViewHistoryTap: {
                        // Navigate to history
                    }
                )
                .environment(viewModel.profileStore)

                // Additional assessments reminder
                if seniorWellnessStore.cognitiveAssessmentDue || seniorWellnessStore.qolAssessmentDue {
                    VStack(spacing: 8) {
                        if seniorWellnessStore.cognitiveAssessmentDue {
                            AssessmentDueCard(
                                title: Strings.SeniorWellness.cognitiveAssessment,
                                icon: "brain.head.profile",
                                iconColor: .purple,
                                lastDate: seniorWellnessStore.latestCognitive?.createdAt,
                                action: { showCognitiveSheet = true }
                            )
                        }

                        if seniorWellnessStore.qolAssessmentDue {
                            AssessmentDueCard(
                                title: Strings.SeniorWellness.qualityOfLife,
                                icon: "heart.circle.fill",
                                iconColor: .pink,
                                lastDate: seniorWellnessStore.latestQoL?.createdAt,
                                action: { showQoLSheet = true }
                            )
                        }
                    }
                }

                // RRR tracking (for heart conditions)
                let activeConditions = profile?.healthConditions.filter { $0.status == .active } ?? []
                if seniorWellnessStore.shouldShowRRRTracking(activeConditions: activeConditions) {
                    RRRQuickCard(
                        latestReading: seniorWellnessStore.latestRRR,
                        onLogTap: { showRRRSheet = true }
                    )
                }
            }
        }
    }
}
