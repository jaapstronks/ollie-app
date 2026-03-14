//
//  BehaviorSupportView.swift
//  Otis-app
//
//  Full view for behavior management - shows all issues, interventions, and progress
//

import SwiftUI
import OtisShared

/// Full view for managing behavior challenges
/// Includes professional disclaimer, active issues, and intervention tracking
struct BehaviorSupportView: View {
    @Environment(EventStore.self) var eventStore
    @Environment(ProfileStore.self) var profileStore

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showBehaviorLogSheet = false
    @State private var showDisclaimerExpanded = false
    @State private var selectedCategory: BehaviorCategory?
    @State private var showInterventionSheet = false
    @State private var interventionSheetCategory: BehaviorCategory = .reactivity

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    /// All behavior incidents (filter once, reuse for time-based filtering)
    private var allBehaviorIncidents: [PuppyEvent] {
        eventStore.events.filter { $0.isBehaviorIncident }
    }

    /// All behavior incidents from last 30 days
    private var recentIncidents: [PuppyEvent] {
        allBehaviorIncidents
            .lastDays(30)
            .sorted { $0.time > $1.time }
    }

    /// Incidents from the last 7 days (filtered from recentIncidents for efficiency)
    private var thisWeekIncidents: [PuppyEvent] {
        recentIncidents.filter { $0.time.isThisWeek }
    }

    /// Incidents from 7-14 days ago (for comparison)
    private var lastWeekIncidents: [PuppyEvent] {
        recentIncidents.filter { $0.time.isLastWeek }
    }

    /// Aggregate incidents by category (last 30 days)
    private var incidentsByCategory: [(category: BehaviorCategory, thisWeek: Int, lastWeek: Int, total: Int, incidents: [PuppyEvent])] {
        let allIncidents = recentIncidents
        let grouped = Dictionary(grouping: allIncidents) { $0.behaviorCategoryEnum }

        return grouped.compactMap { category, incidents in
            guard let cat = category else { return nil }

            let thisWeekCount = incidents.filter { $0.time.isThisWeek }.count
            let lastWeekCount = incidents.filter { $0.time.isLastWeek }.count

            return (category: cat, thisWeek: thisWeekCount, lastWeek: lastWeekCount, total: incidents.count, incidents: incidents)
        }
        .sorted { $0.thisWeek > $1.thisWeek }
    }

    /// Active interventions from profile
    private var activeInterventions: [BehaviorIntervention] {
        profileStore.activeInterventions()
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Professional Disclaimer
                disclaimerSection

                // Log Incident CTA
                logIncidentButton

                // Active Issues
                if !incidentsByCategory.isEmpty {
                    activeIssuesSection
                } else {
                    emptyStateSection
                }

                // Recent Incidents Timeline
                if !recentIncidents.isEmpty {
                    recentIncidentsSection
                }

                // Progress Summary (only if there are incidents)
                if !recentIncidents.isEmpty {
                    progressSummarySection
                }

                // Interventions
                interventionsSection
            }
            .padding()
        }
        .navigationTitle(OtisShared.Strings.BehaviorSupport.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showBehaviorLogSheet) {
            BehaviorLogSheet(
                onSave: { category, trigger, intensity, outcome, context, time, note in
                    saveBehaviorIncident(
                        category: category,
                        trigger: trigger,
                        intensity: intensity,
                        outcome: outcome,
                        context: context,
                        time: time,
                        note: note
                    )
                    showBehaviorLogSheet = false
                },
                onCancel: {
                    showBehaviorLogSheet = false
                }
            )
        }
        .sheet(isPresented: $showInterventionSheet) {
            InterventionLogSheet(
                category: interventionSheetCategory,
                onSave: { intervention in
                    profileStore.addIntervention(intervention)
                    showInterventionSheet = false
                    HapticFeedback.success()
                },
                onCancel: {
                    showInterventionSheet = false
                }
            )
        }
    }

    // MARK: - Disclaimer Section

    @ViewBuilder
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDisclaimerExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)

                    Text(OtisShared.Strings.BehaviorSupport.disclaimerTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: showDisclaimerExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showDisclaimerExpanded {
                Text(OtisShared.Strings.BehaviorSupport.disclaimerBody)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
    }

    // MARK: - Log Incident Button

    @ViewBuilder
    private var logIncidentButton: some View {
        Button {
            showBehaviorLogSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text(OtisShared.Strings.BehaviorSupport.logIncident)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Issues Section

    @ViewBuilder
    private var activeIssuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(OtisShared.Strings.BehaviorSupport.activeIssues)
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(incidentsByCategory, id: \.category) { item in
                BehaviorCategoryRow(
                    category: item.category,
                    thisWeekCount: item.thisWeek,
                    lastWeekCount: item.lastWeek,
                    totalCount: item.total,
                    commonTriggers: extractCommonTriggers(from: item.incidents)
                )
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green.opacity(0.6))

            Text(OtisShared.Strings.BehaviorSupport.noActiveIssues)
                .font(.headline)

            Text(OtisShared.Strings.BehaviorSupport.noActiveIssuesDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Recent Incidents Section

    @ViewBuilder
    private var recentIncidentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(OtisShared.Strings.Behavior.recentIncidents)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text(OtisShared.Strings.BehaviorSupport.last7Days)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(thisWeekIncidents.prefix(5), id: \.id) { incident in
                RecentIncidentRow(incident: incident)
            }

            if thisWeekIncidents.count > 5 {
                Text("+ \(thisWeekIncidents.count - 5) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Progress Summary Section

    @ViewBuilder
    private var progressSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(OtisShared.Strings.BehaviorSupport.progress)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                // Week comparison
                weekComparisonView

                // Trigger patterns (if we have data)
                if !topTriggers.isEmpty {
                    triggerPatternsView
                }

                // Intervention effectiveness
                if !activeInterventions.isEmpty {
                    interventionEffectivenessView
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            )
        }
    }

    @ViewBuilder
    private var weekComparisonView: some View {
        let change = thisWeekIncidents.count - lastWeekIncidents.count
        let trend = calculateOverallTrend()

        HStack(spacing: 16) {
            // This week
            VStack(spacing: 4) {
                Text("\(thisWeekIncidents.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(trend.color)
                Text(OtisShared.Strings.BehaviorSupport.last7Days)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Trend arrow
            Image(systemName: trend.icon)
                .font(.title2)
                .foregroundStyle(trend.color)

            // Last week
            VStack(spacing: 4) {
                Text("\(lastWeekIncidents.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Text(OtisShared.Strings.BehaviorSupport.previousWeek)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }

        // Change summary
        if change != 0 {
            HStack {
                Image(systemName: change < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundStyle(change < 0 ? .green : .orange)
                Text(change < 0 ?
                     OtisShared.Strings.BehaviorSupport.fewerIncidents(abs(change)) :
                     OtisShared.Strings.BehaviorSupport.moreIncidents(change))
                    .font(.subheadline)
                    .foregroundStyle(change < 0 ? .green : .orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill((change < 0 ? Color.green : Color.orange).opacity(colorScheme == .dark ? 0.15 : 0.08))
            )
        }
    }

    private var topTriggers: [(trigger: String, count: Int)] {
        let allTriggers = thisWeekIncidents.compactMap { $0.behaviorTrigger }
        let counted = Dictionary(grouping: allTriggers) { $0 }.mapValues { $0.count }
        return counted.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    @ViewBuilder
    private var triggerPatternsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(OtisShared.Strings.BehaviorSupport.commonTriggers)
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(topTriggers.prefix(3), id: \.trigger) { item in
                HStack {
                    Text(item.trigger)
                        .font(.subheadline)
                    Spacer()
                    Text("\(item.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var interventionEffectivenessView: some View {
        let practicing = activeInterventions.filter { $0.practiceCountThisWeek > 0 }

        if !practicing.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(OtisShared.Strings.BehaviorSupport.activePractice)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(practicing) { intervention in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(intervention.name)
                            .font(.caption)
                        Spacer()
                        Text(OtisShared.Strings.BehaviorSupport.practicedCount(intervention.practiceCountThisWeek))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func calculateOverallTrend() -> TrendDirection {
        if lastWeekIncidents.isEmpty && !thisWeekIncidents.isEmpty {
            return .new
        } else if thisWeekIncidents.count < lastWeekIncidents.count {
            return .improving
        } else if thisWeekIncidents.count > lastWeekIncidents.count {
            return .worsening
        }
        return .stable
    }

    // MARK: - Interventions Section

    @ViewBuilder
    private var interventionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(OtisShared.Strings.BehaviorSupport.interventions)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    // Default to first category with incidents, or reactivity
                    interventionSheetCategory = incidentsByCategory.first?.category ?? .reactivity
                    showInterventionSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text(OtisShared.Strings.BehaviorSupport.addIntervention)
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }

            if activeInterventions.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text(OtisShared.Strings.BehaviorSupport.noInterventions)
                        .font(.subheadline)

                    Text(OtisShared.Strings.BehaviorSupport.noInterventionsDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
            } else {
                // Active interventions list
                ForEach(activeInterventions) { intervention in
                    InterventionRow(
                        intervention: intervention,
                        onMarkPracticed: {
                            profileStore.markInterventionPracticed(id: intervention.id)
                            HapticFeedback.light()
                        },
                        onToggleActive: {
                            profileStore.toggleInterventionActive(id: intervention.id)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func extractCommonTriggers(from incidents: [PuppyEvent]) -> [String] {
        let triggers = incidents.compactMap { $0.behaviorTrigger }
        let counted = Dictionary(grouping: triggers) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        return Array(counted)
    }

    private func saveBehaviorIncident(
        category: BehaviorCategory,
        trigger: String?,
        intensity: BehaviorIntensity?,
        outcome: BehaviorOutcome?,
        context: BehaviorContext?,
        time: Date,
        note: String?
    ) {
        let event = PuppyEvent.behaviorIncident(
            time: time,
            category: category,
            trigger: trigger,
            intensity: intensity,
            outcome: outcome,
            context: context,
            note: note
        )
        eventStore.addEvent(event)
        HapticFeedback.success()
    }
}

// MARK: - Preview

private struct BehaviorSupportViewPreview: View {
    let withData: Bool

    var body: some View {
        let eventStore = EventStore()
        let profileStore = ProfileStore()

        if withData {
            let _ = [
                PuppyEvent.behaviorIncident(time: Date(), category: .reactivity, trigger: "Other dogs", intensity: .moderate, context: .walk),
                PuppyEvent.behaviorIncident(time: Date().addingTimeInterval(-86400), category: .reactivity, trigger: "Cyclists", intensity: .high, context: .walk),
                PuppyEvent.behaviorIncident(time: Date().addingTimeInterval(-172800), category: .pulling, trigger: "Squirrels", intensity: .moderate, context: .walk),
                PuppyEvent.behaviorIncident(time: Date().addingTimeInterval(-259200), category: .barking, trigger: "Doorbell", intensity: .low, context: .home)
            ].forEach { eventStore.addEvent($0) }
        }

        return NavigationStack {
            BehaviorSupportView()
        }
        .environment(eventStore)
        .environment(profileStore)
    }
}

#Preview("With Data") {
    BehaviorSupportViewPreview(withData: true)
}

#Preview("Empty") {
    BehaviorSupportViewPreview(withData: false)
}
