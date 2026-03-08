//
//  BehaviorSupportCard.swift
//  Otis-app
//
//  Compact card for Train tab - shows active behavior issues and quick logging
//

import SwiftUI
import OtisShared

/// Compact card for behavior support shown in Train tab
/// Shows for teenage+ dogs OR when behavior incidents have been logged
struct BehaviorSupportCard: View {
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var profileStore: ProfileStore

    @Environment(\.colorScheme) private var colorScheme

    @State private var showBehaviorLogSheet = false
    @State private var showFullView = false

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    /// All behavior incidents from last 30 days
    private var recentIncidents: [PuppyEvent] {
        eventStore.events
            .filter { $0.isBehaviorIncident }
            .lastDays(30)
            .sorted { $0.time > $1.time }
    }

    /// Incidents from the last 7 days
    private var thisWeekIncidents: [PuppyEvent] {
        eventStore.events
            .filter { $0.isBehaviorIncident }
            .thisWeek()
    }

    /// Aggregate incidents by category
    private var incidentsByCategory: [(category: BehaviorCategory, count: Int, incidents: [PuppyEvent])] {
        let grouped = Dictionary(grouping: thisWeekIncidents) { $0.behaviorCategoryEnum }
        return grouped.compactMap { category, incidents in
            guard let cat = category else { return nil }
            return (category: cat, count: incidents.count, incidents: incidents)
        }
        .sorted { $0.count > $1.count }
    }

    /// Whether to show this card
    /// Shows for teenage+ dogs OR if any behavior incidents exist
    var shouldShow: Bool {
        guard let profile = profile else { return false }
        let isTeenageOrOlder = profile.lifecyclePhase != .puppy
        let hasIncidents = !recentIncidents.isEmpty
        return isTeenageOrOlder || hasIncidents
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(OtisShared.Strings.BehaviorSupport.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            // Content
            if incidentsByCategory.isEmpty {
                emptyStateContent
            } else {
                activeIssuesContent
            }

            // Footer with actions
            Divider()

            HStack {
                if !thisWeekIncidents.isEmpty {
                    Text(OtisShared.Strings.BehaviorSupport.incidentsThisWeek(thisWeekIncidents.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NavigationLink {
                    BehaviorSupportView()
                } label: {
                    HStack(spacing: 4) {
                        Text(OtisShared.Strings.BehaviorSupport.viewAll)
                            .font(.caption)
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .glassCard(tint: .custom(.orange))
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(OtisShared.Strings.BehaviorSupport.behaviorSupportAccessibilityLabel)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(OtisShared.Strings.BehaviorSupport.noActiveIssues)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showBehaviorLogSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text(OtisShared.Strings.BehaviorSupport.logIncident)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Active Issues Content

    @ViewBuilder
    private var activeIssuesContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show top 2 categories
            ForEach(incidentsByCategory.prefix(2), id: \.category) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.category.icon)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.category.label)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(OtisShared.Strings.Behavior.incidentCount(item.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Trend indicator (simplified for now)
                    trendIndicator(for: item.category)
                }
            }

            // Quick log button
            Button {
                showBehaviorLogSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text(OtisShared.Strings.BehaviorSupport.logIncident)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Trend Indicator

    @ViewBuilder
    private func trendIndicator(for category: BehaviorCategory) -> some View {
        // Simplified trend: compare this week vs last week
        let thisWeek = thisWeekIncidents.filter { $0.behaviorCategoryEnum == category }.count
        let lastWeekIncidents = eventStore.events
            .filter { $0.isBehaviorIncident && $0.behaviorCategoryEnum == category }
            .lastWeek()
            .count

        let trend: TrendDirection = {
            if lastWeekIncidents == 0 {
                return .new
            } else if thisWeek < lastWeekIncidents {
                return .improving
            } else if thisWeek > lastWeekIncidents {
                return .worsening
            }
            return .stable
        }()

        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.caption2)
            Text(trend.label)
                .font(.caption2)
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.15))
        )
    }

    // MARK: - Save Incident

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

// MARK: - Trend Direction

enum TrendDirection {
    case improving, stable, worsening, new

    var icon: String {
        switch self {
        case .improving: return "arrow.down"
        case .stable: return "arrow.right"
        case .worsening: return "arrow.up"
        case .new: return "sparkles"
        }
    }

    var label: String {
        switch self {
        case .improving: return OtisShared.Strings.BehaviorSupport.trendImproving
        case .stable: return OtisShared.Strings.BehaviorSupport.trendStable
        case .worsening: return OtisShared.Strings.BehaviorSupport.trendWorsening
        case .new: return OtisShared.Strings.BehaviorSupport.trendNew
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .secondary
        case .worsening: return .orange
        case .new: return .blue
        }
    }
}

// MARK: - Preview

private struct BehaviorSupportCardPreview: View {
    let withData: Bool

    var body: some View {
        let eventStore = EventStore()
        let profileStore = ProfileStore()

        if withData {
            let _ = eventStore.addEvent(PuppyEvent.behaviorIncident(
                time: Date(),
                category: .reactivity,
                trigger: "Other dogs",
                intensity: .moderate,
                outcome: .managed,
                context: .walk
            ))
            let _ = eventStore.addEvent(PuppyEvent.behaviorIncident(
                time: Date().addingTimeInterval(-86400),
                category: .pulling,
                trigger: "Squirrels",
                intensity: .high,
                outcome: .redirected,
                context: .walk
            ))
        }

        return NavigationStack {
            ScrollView {
                BehaviorSupportCard()
                    .padding()
            }
        }
        .environmentObject(eventStore)
        .environmentObject(profileStore)
    }
}

#Preview("With Incidents") {
    BehaviorSupportCardPreview(withData: true)
}

#Preview("Empty State") {
    BehaviorSupportCardPreview(withData: false)
}
