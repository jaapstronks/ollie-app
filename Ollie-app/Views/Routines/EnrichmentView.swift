//
//  EnrichmentView.swift
//  Otis-app
//
//  Full enrichment activity library and history view
//

import SwiftUI
import OtisShared

/// Full view for browsing enrichment activities and viewing history
struct EnrichmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineStore.self) private var routineStore

    @State private var selectedTab: Int = 0
    @State private var showLogSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    Text("Library").tag(0)
                    Text("History").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                if selectedTab == 0 {
                    libraryView
                } else {
                    historyView
                }
            }
            .navigationTitle(Strings.Enrichment.activities)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showLogSheet) {
                EnrichmentLogDetailSheet()
            }
        }
    }

    // MARK: - Library View

    @ViewBuilder
    private var libraryView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(EnrichmentCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        // Category header
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .foregroundStyle(colorForCategory(category))

                            Text(category.label)
                                .font(.headline)
                        }

                        // Activity grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(EnrichmentType.allCases.filter { $0.category == category }, id: \.self) { type in
                                EnrichmentTypeCard(
                                    type: type,
                                    recentCount: routineStore.enrichmentActivities.byType[type]?.count ?? 0,
                                    onTap: {
                                        routineStore.addEnrichment(type: type)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - History View

    @ViewBuilder
    private var historyView: some View {
        if routineStore.enrichmentActivities.isEmpty {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text(Strings.Enrichment.noActivities)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button {
                    selectedTab = 0
                } label: {
                    Text("Browse activities")
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
        } else {
            List {
                // Weekly summary
                Section(Strings.Enrichment.weeklyProgress) {
                    HStack {
                        Text(Strings.Enrichment.activitiesThisWeek(routineStore.weeklyEnrichmentActivities.count))
                        Spacer()
                        Text(Strings.Enrichment.minutesThisWeek(routineStore.enrichmentActivities.weeklyMinutes))
                            .foregroundStyle(.secondary)
                    }

                    // Category breakdown
                    let categoryCounts = routineStore.enrichmentActivities.weeklyCategoryCounts
                    if !categoryCounts.isEmpty {
                        ForEach(EnrichmentCategory.allCases, id: \.self) { category in
                            if let count = categoryCounts[category], count > 0 {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(colorForCategory(category))
                                    Text(category.label)
                                    Spacer()
                                    Text("\(count)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Recent activities
                Section(Strings.Enrichment.recentActivities) {
                    ForEach(routineStore.enrichmentActivities.prefix(20)) { activity in
                        HStack(spacing: 12) {
                            Image(systemName: activity.type.icon)
                                .foregroundStyle(colorForCategory(activity.category))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.type.label)
                                    .font(.subheadline)

                                Text(activity.formattedDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if let duration = activity.formattedDuration {
                                Text(duration)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let activity = Array(routineStore.enrichmentActivities.prefix(20))[index]
                            routineStore.deleteEnrichmentActivity(activity)
                        }
                    }
                }
            }
        }
    }

    private func colorForCategory(_ category: EnrichmentCategory) -> Color {
        switch category {
        case .mental: return .purple
        case .physical: return .blue
        case .social: return .orange
        case .training: return .green
        case .calming: return .pink
        }
    }
}

// MARK: - Enrichment Type Card

private struct EnrichmentTypeCard: View {
    let type: EnrichmentType
    let recentCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(.green)

                Text(type.label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if recentCount > 0 {
                    Text("\(recentCount)x")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enrichment Log Detail Sheet

private struct EnrichmentLogDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineStore.self) private var routineStore

    @State private var selectedType: EnrichmentType = .puzzleToy
    @State private var duration: Int = 15
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(Strings.Enrichment.category) {
                    ForEach(EnrichmentCategory.allCases, id: \.self) { category in
                        DisclosureGroup(category.label) {
                            ForEach(EnrichmentType.allCases.filter { $0.category == category }, id: \.self) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    HStack {
                                        Image(systemName: type.icon)
                                            .foregroundStyle(.green)
                                        Text(type.label)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedType == type {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section(Strings.Enrichment.duration) {
                    Stepper("\(duration) min", value: $duration, in: 5...120, step: 5)
                }

                Section {
                    TextField(Strings.Common.note, text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(Strings.Enrichment.logActivity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        routineStore.addEnrichment(
                            type: selectedType,
                            durationMinutes: duration,
                            note: note.isEmpty ? nil : note
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EnrichmentView()
        .environment(RoutineStore())
}
