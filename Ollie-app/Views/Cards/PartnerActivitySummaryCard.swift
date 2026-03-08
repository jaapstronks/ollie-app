//
//  PartnerActivitySummaryCard.swift
//  Otis-app
//
//  Partner activity handoff card - shows what partners logged while user was away
//  Updated to use CloudKit-based identity and Phase 2 features (featured moments, summaries)
//

import SwiftUI
import OtisShared

/// Dismissable card showing partner activities since user's last visit
struct PartnerActivitySummaryCard: View {
    let summary: PartnerActivitySummary
    let onDismiss: () -> Void

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Featured moment photo (if available)
            if summary.hasFeaturedMoment {
                featuredMomentSection
            }

            // Header with partner info and dismiss button
            header

            // Time range badge
            timeRangeBadge

            // Natural language summary (Phase 2) or legacy summary
            if let handoverSummary = summary.handoverSummary, !handoverSummary.isEmpty {
                naturalLanguageSummary(handoverSummary)
            } else {
                summaryText
            }

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
        // Show partner initial in a colored circle
        // In Phase 2, ParticipantResolver will provide actual partner info
        HStack(spacing: -6) {
            ForEach(summary.partnerNames.prefix(3), id: \.self) { name in
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
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

    // MARK: - Time Range Badge

    @ViewBuilder
    private var timeRangeBadge: some View {
        CapsuleBadge(Strings.Handoff.timeRange(start: summary.startTime, end: summary.endTime))
    }

    // MARK: - Featured Moment Section

    @ViewBuilder
    private var featuredMomentSection: some View {
        if let moment = summary.featuredMoment {
            VStack(alignment: .leading, spacing: 6) {
                // Thumbnail
                if let thumbnailPath = moment.thumbnailPath {
                    AsyncThumbnailView(relativePath: thumbnailPath)
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Caption if available
                if let note = moment.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - Natural Language Summary

    @ViewBuilder
    private func naturalLanguageSummary(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
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
                ActivityRow(
                    icon: "graduationcap.fill",
                    iconColor: .orange,
                    text: event.exercise.map { Strings.Handoff.trainingExercise($0) } ?? Strings.Handoff.training
                )
            }

            // Socialization events
            ForEach(Array(summary.socializationEvents.prefix(2))) { event in
                ActivityRow(
                    icon: "dog.fill",
                    iconColor: .purple,
                    text: event.who.map { Strings.Handoff.metSomeone($0) } ?? Strings.Handoff.socialization
                )
            }

            // Walk events
            ForEach(Array(summary.walkEvents.prefix(2))) { event in
                ActivityRow(
                    icon: "figure.walk",
                    iconColor: .green,
                    text: walkTextFor(event)
                )
            }
        }
    }


    // MARK: - Expandable Section

    @ViewBuilder
    private var expandableSection: some View {
        if isExpanded {
            // Show remaining events
            VStack(alignment: .leading, spacing: 8) {
                ForEach(remainingEvents) { event in
                    ActivityRow(
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
    let trainingEvent = PuppyEvent(type: .training, exercise: "Sit")
    let walkEvent = PuppyEvent(type: .uitlaten, durationMin: 30)
    let socialEvent = PuppyEvent(type: .sociaal, who: "Luna the Labrador")

    let summary = PartnerActivitySummary(
        partnerRecordIDs: ["partner-123"],
        partnerNames: ["Sarah"],
        events: [trainingEvent, walkEvent, socialEvent],
        startTime: Date().addingTimeInterval(-3600 * 3),
        endTime: Date().addingTimeInterval(-3600),
        trainingEvents: [trainingEvent],
        socializationEvents: [socialEvent],
        walkEvents: [walkEvent],
        otherNotableEvents: [],
        featuredMoment: nil,
        handoverSummary: "1 nap, 30 min walk, training — all potty outside!"
    )

    return VStack {
        PartnerActivitySummaryCard(
            summary: summary,
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
}
