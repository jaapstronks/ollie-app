//
//  GrowthDetailSheet.swift
//  Otis-app
//
//  Detail view showing full weight chart and growth statistics
//

import SwiftUI
import OtisShared

/// Detail sheet showing the full weight chart and growth metrics
struct GrowthDetailSheet: View {
    let referenceCurve: [GrowthReference]
    let puppyName: String
    @Binding var showWeightSheet: Bool

    @Environment(WeightStore.self) var weightStore
    @Environment(ProfileStore.self) var profileStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(UnitPreferences.self) var unitPreferences

    @State private var measurementToDelete: WeightMeasurement?
    @State private var showDeleteConfirmation = false
    @State private var measurementToEdit: WeightMeasurement?
    @State private var showEditSheet = false

    private var weightUnit: WeightUnit {
        unitPreferences.weightUnit
    }

    // Computed from weightStore for live updates
    private var chartPoints: [WeightChartPoint] {
        guard let birthDate = profileStore.profile?.birthDate else { return [] }
        return weightStore.chartPoints(birthDate: birthDate)
    }

    private var latestWeight: (weight: Double, date: Date)? {
        weightStore.latestWeight
    }

    private var weightDelta: (delta: Double, previousDate: Date)? {
        weightStore.weightDelta
    }

    private var growthStory: GrowthStory? {
        guard let profile = profileStore.profile else { return nil }
        return weightStore.growthStory(
            homeDate: profile.homeDate,
            sizeCategory: profile.sizeCategory
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current weight summary
                    if let latest = latestWeight {
                        currentWeightSection(weight: latest.weight, date: latest.date)
                    }

                    // Growth chart
                    chartSection

                    // Growth statistics
                    if let story = growthStory {
                        statisticsSection(story: story)
                    }

                    // Measurement history
                    if !chartPoints.isEmpty {
                        measurementHistorySection
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Growth.growthChart)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showWeightSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog(
                Strings.Growth.deleteMeasurement,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Common.delete, role: .destructive) {
                    if let measurement = measurementToDelete {
                        deleteMeasurement(measurement)
                    }
                }
                Button(Strings.Common.cancel, role: .cancel) {
                    measurementToDelete = nil
                }
            } message: {
                if let measurement = measurementToDelete {
                    Text(Strings.Growth.deleteMeasurementMessage(weightUnit.format(measurement.weightKg)))
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let measurement = measurementToEdit {
                    WeightLogSheet(
                        isPresented: $showEditSheet,
                        measurementToEdit: measurement
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteMeasurement(_ measurement: WeightMeasurement) {
        HapticFeedback.warning()
        weightStore.deleteMeasurement(measurement)
        measurementToDelete = nil
    }

    private func editMeasurement(_ measurement: WeightMeasurement) {
        measurementToEdit = measurement
        showEditSheet = true
    }

    // MARK: - Current Weight Section

    @ViewBuilder
    private func currentWeightSection(weight: Double, date: Date) -> some View {
        VStack(spacing: 8) {
            Text(weightUnit.format(weight))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            if let delta = weightDelta {
                HStack(spacing: 4) {
                    Image(systemName: delta.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.subheadline)
                    Text(Strings.Growth.weightChange(weightUnit.formatDelta(delta.delta)))
                        .font(.subheadline)
                }
                .foregroundStyle(delta.delta >= 0 ? Color.otisSuccess : Color.otisWarning)
            }

            Text(Strings.Growth.lastMeasured(date.formattedMedium()))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Health.growthCurve)
                .font(.headline)
                .fontWeight(.semibold)

            if chartPoints.isEmpty {
                WeightChartEmptyView(referenceCurve: referenceCurve)
            } else {
                WeightChartView(
                    measurements: chartPoints,
                    referenceCurve: referenceCurve,
                    puppyName: puppyName
                )
            }
        }
        .padding()
        .glassCard(tint: .none)
    }

    // MARK: - Statistics Section

    @ViewBuilder
    private func statisticsSection(story: GrowthStory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Growth.growthStats)
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statCard(
                    title: Strings.Growth.totalGain,
                    value: weightUnit.format(story.currentWeight - story.firstWeight),
                    icon: "arrow.up.right.circle.fill",
                    color: .otisSuccess
                )

                statCard(
                    title: Strings.Growth.growthRatioLabel,
                    value: String(format: "%.1fx", story.growthRatio),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .otisAccent
                )

                statCard(
                    title: Strings.Growth.percentOfAdultShort,
                    value: "\(Int(story.percentToAdult))%",
                    icon: "dog.fill",
                    color: .otisInfo
                )

                statCard(
                    title: Strings.Growth.estimatedAdult,
                    value: weightUnit.format(story.estimatedAdultWeight),
                    icon: "target",
                    color: .otisMuted
                )
            }
        }
        .padding()
        .glassCard(tint: .accent)
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(colorScheme == .dark ? 0.1 : 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Measurement History

    @ViewBuilder
    private var measurementHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Growth.measurementHistory)
                .font(.headline)
                .fontWeight(.semibold)

            // Sorted by date descending (most recent first)
            let sortedMeasurements = weightStore.measurements.sorted { $0.date > $1.date }

            List {
                ForEach(sortedMeasurements) { measurement in
                    measurementRow(measurement: measurement)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color(.secondarySystemBackground))
                }
                .onDelete { indexSet in
                    // Get the measurement at the deleted index
                    for index in indexSet {
                        let measurement = sortedMeasurements[index]
                        measurementToDelete = measurement
                        showDeleteConfirmation = true
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: CGFloat(sortedMeasurements.count) * 60)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func measurementRow(measurement: WeightMeasurement) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.date.formattedMedium())
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let birthDate = profileStore.profile?.birthDate {
                    Text(Strings.Health.weekNumber(measurement.ageWeeks(birthDate: birthDate)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(weightUnit.format(measurement.weightKg))
                .font(.body)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                editMeasurement(measurement)
            } label: {
                Label(Strings.Common.edit, systemImage: "pencil")
            }

            Button(role: .destructive) {
                measurementToDelete = measurement
                showDeleteConfirmation = true
            } label: {
                Label(Strings.Common.delete, systemImage: "trash")
            }
        }
    }

}

// MARK: - Preview

#Preview("With Data") {
    GrowthDetailSheet(
        referenceCurve: GrowthCurves.goldenRetrieverFemale,
        puppyName: "Max",
        showWeightSheet: .constant(false)
    )
    .environment(WeightStore())
    .environment(ProfileStore())
}

#Preview("Empty") {
    GrowthDetailSheet(
        referenceCurve: GrowthCurves.goldenRetrieverFemale,
        puppyName: "Max",
        showWeightSheet: .constant(false)
    )
    .environment(WeightStore())
    .environment(ProfileStore())
}
