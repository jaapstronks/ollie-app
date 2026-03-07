//
//  HealthView.swift
//  Otis-app
//
//  Health tracking view: weight chart and health milestones timeline

import SwiftUI
import OtisShared

/// Main health view showing weight tracking and health milestones
struct HealthView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var milestoneStore: MilestoneStore

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var weightStore: WeightStore

    @State private var showWeightSheet = false
    @State private var showAddMilestoneSheet = false
    @State private var showSymptomLogSheet = false
    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnitRaw = WeightUnit.kg.rawValue

    @StateObject private var symptomStore = HealthSymptomStore.shared
    @StateObject private var checkInStore = HealthCheckInStore.shared

    @Environment(\.colorScheme) private var colorScheme

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        viewModel.profileStore.profile
    }

    private var chartPoints: [WeightChartPoint] {
        guard let birthDate = profile?.birthDate else { return [] }
        return weightStore.chartPoints(birthDate: birthDate)
    }

    private var latestWeight: (weight: Double, date: Date)? {
        weightStore.latestWeight
    }

    private var weightDelta: (delta: Double, previousDate: Date)? {
        weightStore.weightDelta
    }

    private var referenceCurve: [GrowthReference] {
        guard let size = profile?.sizeCategory else {
            return GrowthCurves.goldenRetrieverFemale
        }
        return GrowthCurves.curve(for: size)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Symptoms section (for dogs with conditions)
                if hasActiveConditions {
                    symptomsSection
                }

                // Weight section
                weightSection

                // Milestones section
                milestonesSection
            }
            .padding()
        }
        .navigationTitle(Strings.Health.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Analytics.track(.healthTimelineViewed)
        }
        .sheet(isPresented: $showWeightSheet) {
            WeightLogSheet(isPresented: $showWeightSheet)
        }
        .sheet(isPresented: $showSymptomLogSheet) {
            SymptomLogSheet(
                onSave: { symptom in
                    symptomStore.log(symptom)
                    showSymptomLogSheet = false
                },
                onCancel: {
                    showSymptomLogSheet = false
                }
            )
            .environmentObject(viewModel.profileStore)
        }
    }

    private var hasActiveConditions: Bool {
        guard let profile = profile else { return false }
        return !profile.healthConditions.filter { $0.status == .active }.isEmpty ||
               profile.lifecyclePhase == .senior
    }

    // MARK: - Symptoms Section

    @ViewBuilder
    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.teal)

                Text(Strings.HealthLogging.symptomTrends)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                // Log symptom button
                Button {
                    showSymptomLogSheet = true
                } label: {
                    Label(Strings.HealthLogging.logSymptom, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 4)

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

    private var recentSymptomsSummary: [(type: SymptomType, count: Int)] {
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
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.otisAccent)

                Text(Strings.Health.weight)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                // Log weight button
                Button {
                    showWeightSheet = true
                } label: {
                    Label(Strings.Health.logWeight, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 4)

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
    private func weightHeroCard(weight: Double, date: Date) -> some View {
        VStack(spacing: 8) {
            // Big weight number
            Text(weightUnit.format(weight))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Date
            Text(formattedDate(date))
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
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.otisDanger)

                Text(Strings.Health.milestones)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

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
            .padding(.horizontal, 4)

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

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let milestoneStore = MilestoneStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    NavigationStack {
        HealthView(viewModel: viewModel, milestoneStore: milestoneStore)
    }
    .environmentObject(SubscriptionManager.shared)
    .environmentObject(WeightStore())
}
