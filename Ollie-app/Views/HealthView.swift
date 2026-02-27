//
//  HealthView.swift
//  Ollie-app
//
//  Health tracking view: weight chart and health milestones timeline

import SwiftUI
import OllieShared

/// Main health view showing weight tracking and health milestones
struct HealthView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var milestoneStore: MilestoneStore

    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var showWeightSheet = false
    @State private var showAddMilestoneSheet = false

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        viewModel.profileStore.profile
    }

    private var allEvents: [PuppyEvent] {
        // Get all events, not just today's
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return viewModel.eventStore.getEvents(from: oneYearAgo, to: Date())
    }

    private var weightMeasurements: [WeightMeasurement] {
        guard let birthDate = profile?.birthDate else { return [] }
        return WeightCalculations.weightMeasurements(events: allEvents, birthDate: birthDate)
    }

    private var latestWeight: (weight: Double, date: Date)? {
        WeightCalculations.latestWeight(events: allEvents)
    }

    private var weightDelta: (delta: Double, previousDate: Date)? {
        WeightCalculations.weightDelta(events: allEvents)
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
                // Weight section
                weightSection

                // Milestones section
                milestonesSection
            }
            .padding()
        }
        .navigationTitle(Strings.Health.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWeightSheet) {
            WeightLogSheet(isPresented: $showWeightSheet) { weight in
                logWeight(weight)
            }
        }
    }

    // MARK: - Weight Section

    @ViewBuilder
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ollieAccent)

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
                if weightMeasurements.isEmpty {
                    WeightChartEmptyView(referenceCurve: referenceCurve)
                } else {
                    WeightChartView(
                        measurements: weightMeasurements,
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
            Text(WeightCalculations.formatWeight(weight))
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
                    Text(Strings.Health.sinceLast(WeightCalculations.formatDelta(delta.delta)))
                        .font(.caption)
                }
                .foregroundStyle(delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
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
                    .foregroundStyle(Color.ollieDanger)

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

    // MARK: - Actions

    private func logWeight(_ weight: Double) {
        let event = PuppyEvent(
            time: Date(),
            type: .gewicht,
            weightKg: weight
        )
        viewModel.addEvent(event)
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
}
