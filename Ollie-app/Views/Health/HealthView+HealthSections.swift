//
//  HealthView+HealthSections.swift
//  Ollie-app
//
//  Symptoms, weight, and milestones sections for the health view.
//

import SwiftUI
import OtisShared

extension HealthView {

    // MARK: - Symptoms Section

    @ViewBuilder
    var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.HealthLogging.symptomTrends, icon: "stethoscope", tint: .teal) {
                Button {
                    showSymptomLogSheet = true
                } label: {
                    Label(Strings.HealthLogging.logSymptom, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Symptoms content
            VStack(spacing: 16) {
                // Recent symptoms summary
                let recentSymptoms = symptomStore.recentSymptoms()
                if recentSymptoms.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                        Text(Strings.HealthLogging.noRecentSymptoms)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    // Show recent symptoms grouped by type
                    ForEach(recentSymptomsSummary, id: \.type) { summary in
                        HStack {
                            Image(systemName: summary.type.icon)
                                .foregroundStyle(.teal)
                            Text(summary.type.label)
                                .font(.subheadline)
                            Spacer()
                            Text(Strings.HealthLogging.episodes(summary.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Quick log cards for active conditions
                if let profile = profile {
                    let activeConditions = profile.healthConditions.filter { $0.status == .active }
                    if !activeConditions.isEmpty {
                        ForEach(activeConditions) { condition in
                            ConditionQuickLogCard(
                                condition: condition,
                                onLogSymptom: { symptomType in
                                    let log = HealthSymptomLog(
                                        symptomType: symptomType,
                                        relatedConditionId: condition.id
                                    )
                                    symptomStore.log(log)
                                },
                                onLogGoodDay: {
                                    // Could track "good days" for trends
                                },
                                onViewDetails: {
                                    // Could navigate to condition detail
                                }
                            )
                        }
                    }
                }
            }
            .padding()
            .glassCard(tint: .info)
        }
    }

    var recentSymptomsSummary: [(type: SymptomType, count: Int)] {
        let symptoms = symptomStore.recentSymptoms()
        let grouped = Dictionary(grouping: symptoms) { $0.symptomType }
        return grouped
            .map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Weight Section

    @ViewBuilder
    var weightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.Health.weight, icon: "scalemass.fill", tint: .otisAccent) {
                Button {
                    showWeightSheet = true
                } label: {
                    Label(Strings.Health.logWeight, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Weight card
            VStack(spacing: 16) {
                // Current weight hero (if available)
                if let latest = latestWeight {
                    weightHeroCard(weight: latest.weight, date: latest.date)
                }

                // Growth curve chart
                if chartPoints.isEmpty {
                    WeightChartEmptyView(referenceCurve: referenceCurve)
                } else {
                    WeightChartView(
                        measurements: chartPoints,
                        referenceCurve: referenceCurve,
                        puppyName: profile?.name ?? "Puppy"
                    )
                }
            }
            .padding()
            .glassCard(tint: .accent)
        }
    }

    @ViewBuilder
    func weightHeroCard(weight: Double, date: Date) -> some View {
        VStack(spacing: 8) {
            // Big weight number
            Text(weightUnit.format(weight))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Date
            Text(date.formattedMedium())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Delta since last (if available)
            if let delta = weightDelta {
                HStack(spacing: 4) {
                    Image(systemName: delta.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(Strings.Health.sinceLast(weightUnit.formatDelta(delta.delta)))
                        .font(.caption)
                }
                .foregroundStyle(delta.delta >= 0 ? Color.otisSuccess : Color.otisWarning)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (delta.delta >= 0 ? Color.otisSuccess : Color.otisWarning)
                        .opacity(colorScheme == .dark ? 0.2 : 0.1)
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Milestones Section

    @ViewBuilder
    var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.Health.milestones, icon: "heart.fill", tint: .otisDanger) {
                // Add button (premium)
                if subscriptionManager.hasAccess(to: .customMilestones) {
                    Button {
                        showAddMilestoneSheet = true
                    } label: {
                        Label(Strings.Health.addMilestone, systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }

            // Timeline
            HealthTimelineView(
                milestones: milestoneStore.milestones,
                birthDate: profile?.birthDate ?? Date(),
                onToggle: { milestone in
                    milestoneStore.toggleMilestoneCompletion(milestone)
                }
            )
            .padding()
            .glassCard(tint: .danger)
        }
        .sheet(isPresented: $showAddMilestoneSheet) {
            AddMilestoneSheet(isPresented: $showAddMilestoneSheet) { milestone in
                milestoneStore.toggleMilestoneCompletion(milestone)
            }
        }
    }

    // MARK: - Breed Risk Section

    @ViewBuilder
    func breedRiskSection(for profile: PuppyProfile) -> some View {
        let breedRisks = BreedHealthRisk.risks(for: profile.breed)
        let sizeRisks = BreedHealthRisk.sizeBasedRisks(for: profile.sizeCategory)

        if breedRisks != nil || !sizeRisks.isEmpty {
            BreedRiskCard(
                breedRisks: breedRisks,
                sizeRisks: sizeRisks,
                existingConditions: profile.healthConditions,
                ageMonths: profile.ageInMonths,
                onScheduleScreening: { risk in
                    appointmentPrefill = (risk.conditionType, "\(risk.conditionType.label) Screening")
                    showAppointmentForm = true
                }
            )
        }
    }

    // MARK: - Follow-up Reminders Section

    @ViewBuilder
    func followUpRemindersSection(for profile: PuppyProfile) -> some View {
        let activeConditions = profile.healthConditions.filter { $0.status == .active || $0.status == .monitoring }

        if !activeConditions.isEmpty {
            FollowUpRemindersCard(
                conditions: activeConditions,
                onScheduleFollowUp: { followUp in
                    appointmentPrefill = (followUp.conditionType, "\(followUp.followUpType.rawValue.capitalized) for \(followUp.conditionType.label)")
                    showAppointmentForm = true
                }
            )
        }
    }
}
