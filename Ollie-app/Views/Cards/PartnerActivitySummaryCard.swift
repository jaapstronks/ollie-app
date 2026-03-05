//
//  PartnerActivitySummaryCard.swift
//  Otis-app
//
//  Partner activity handoff card - shows what partners logged while user was away
//

import SwiftUI
import OtisShared

/// Dismissable card showing partner activities since user's last visit
struct PartnerActivitySummaryCard: View {
    let summary: PartnerActivitySummary
    let householdMembers: HouseholdMembers
    let onDismiss: () -> Void

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with partner info and dismiss button
            header

            // Time range badge
            timeRangeBadge

            // Summary text
            summaryText

            // Highlighted activities
            highlightedActivities

            // Expand/collapse for remaining events
            if remainingEventCount > 0 {
                expandableSection
            }
        }
        .padding()
        .glassCard(tint: .accent)
        .onAppear {
            Analytics.track(.partnerActivityCardViewed)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 8) {
            // Partner avatar(s)
            partnerAvatars

            Text(Strings.Handoff.whileYouWereAway)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()

            // Dismiss button
            Button {
                HapticFeedback.selection()
                Analytics.track(.partnerActivityCardDismissed)
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Strings.Handoff.dismiss)
        }
    }

    // MARK: - Partner Avatars

    @ViewBuilder
    private var partnerAvatars: some View {
        HStack(spacing: -6) {
            ForEach(summary.partnerIds.prefix(3), id: \.self) { partnerId in
                if let member = householdMembers.member(byId: partnerId) {
                    HouseholdMemberAvatar(member: member, size: 24)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    colorScheme == .dark ? Color.black : Color.white,
                                    lineWidth: 1.5
                                )
                        )
                }
            }
        }
    }

    // MARK: - Time Range Badge

    @ViewBuilder
    private var timeRangeBadge: some View {
        Text(Strings.Handoff.timeRange(start: summary.startTime, end: summary.endTime))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
    }

    // MARK: - Summary Text

    @ViewBuilder
    private var summaryText: some View {
        let count = summary.totalEventCount
        let text = count == 1
            ? Strings.Handoff.partnerLoggedActivity(summary.partnerDisplayName)
            : Strings.Handoff.partnerLoggedActivities(summary.partnerDisplayName, count: count)

        Text(text)
            .font(.subheadline)
            .foregroundStyle(.primary)
    }

    // MARK: - Highlighted Activities

    @ViewBuilder
    private var highlightedActivities: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Training events
            ForEach(Array(summary.trainingEvents.prefix(2))) { event in
                activityRow(
                    icon: "graduationcap.fill",
                    iconColor: .orange,
                    text: event.exercise.map { Strings.Handoff.trainingExercise($0) } ?? Strings.Handoff.training
                )
            }

            // Socialization events
            ForEach(Array(summary.socializationEvents.prefix(2))) { event in
                activityRow(
                    icon: "dog.fill",
                    iconColor: .purple,
                    text: event.who.map { Strings.Handoff.metSomeone($0) } ?? Strings.Handoff.socialization
                )
            }

            // Walk events
            ForEach(Array(summary.walkEvents.prefix(2))) { event in
                activityRow(
                    icon: "figure.walk",
                    iconColor: .green,
                    text: walkTextFor(event)
                )
            }
        }
    }

    // MARK: - Activity Row

    @ViewBuilder
    private func activityRow(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(iconColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
        }
    }

    // MARK: - Expandable Section

    @ViewBuilder
    private var expandableSection: some View {
        if isExpanded {
            // Show remaining events
            VStack(alignment: .leading, spacing: 8) {
                ForEach(remainingEvents) { event in
                    activityRow(
                        icon: event.type.icon,
                        iconColor: .secondary,
                        text: event.type.label
                    )
                }
            }

            // Collapse button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded = false
                }
                HapticFeedback.selection()
            } label: {
                HStack {
                    Spacer()
                    Text(Strings.Handoff.showLess)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        } else {
            // Expand button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded = true
                }
                HapticFeedback.selection()
            } label: {
                HStack {
                    Spacer()
                    Text(Strings.Handoff.moreEvents(remainingEventCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
        }
    }

    // MARK: - Helpers

    /// Generate walk text for an event
    private func walkTextFor(_ event: PuppyEvent) -> String {
        if let duration = event.durationMin, duration > 0 {
            return Strings.Handoff.walkWithDuration(duration)
        } else if let spotName = event.spotName, !spotName.isEmpty {
            return "\(Strings.Handoff.walk) - \(spotName)"
        } else {
            return Strings.Handoff.walk
        }
    }

    // MARK: - Computed Properties

    /// Number of highlighted events shown
    private var highlightedCount: Int {
        min(summary.trainingEvents.count, 2) +
        min(summary.socializationEvents.count, 2) +
        min(summary.walkEvents.count, 2)
    }

    /// Number of events not shown in highlights
    private var remainingEventCount: Int {
        max(0, summary.totalEventCount - highlightedCount)
    }

    /// Events not shown in highlights
    private var remainingEvents: [PuppyEvent] {
        // Get IDs of highlighted events
        let highlightedIds = Set(
            summary.trainingEvents.prefix(2).map(\.id) +
            summary.socializationEvents.prefix(2).map(\.id) +
            summary.walkEvents.prefix(2).map(\.id)
        )

        // Return events not in highlights
        return summary.events.filter { !highlightedIds.contains($0.id) }
    }
}

// MARK: - Preview

#Preview {
    let summary = PartnerActivitySummary(
        partnerIds: [UUID()],
        partnerNames: ["Sarah"],
        events: [
            PuppyEvent(type: .training, exercise: "Sit"),
            PuppyEvent(type: .uitlaten, durationMin: 30),
            PuppyEvent(type: .sociaal, who: "Luna the Labrador")
        ],
        startTime: Date().addingTimeInterval(-3600 * 3),
        endTime: Date().addingTimeInterval(-3600),
        trainingEvents: [PuppyEvent(type: .training, exercise: "Sit")],
        socializationEvents: [PuppyEvent(type: .sociaal, who: "Luna the Labrador")],
        walkEvents: [PuppyEvent(type: .uitlaten, durationMin: 30)],
        otherNotableEvents: []
    )

    return VStack {
        PartnerActivitySummaryCard(
            summary: summary,
            householdMembers: HouseholdMembers(members: [
                HouseholdMember(name: "Sarah", colorHex: "#4ECDC4")
            ]),
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
}
