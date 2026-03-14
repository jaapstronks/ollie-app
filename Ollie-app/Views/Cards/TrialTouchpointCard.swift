//
//  TrialTouchpointCard.swift
//  Otis-app
//
//  Touchpoint cards shown during the 14-day trial at strategic intervals
//  Day 1: AI is learning, Day 7: Value summary, Day 12: Warning, Day 14: Conversion

import OtisShared
import SwiftUI

/// Router view that displays the appropriate card for the current touchpoint
struct TrialTouchpointCard: View {
    let touchpoint: TrialTouchpoint
    let puppyName: String
    let onDismiss: () -> Void
    let onSubscribe: () -> Void

    var body: some View {
        // Only show cards for touchpoints that have in-app cards
        if touchpoint.showsInAppCard {
            Group {
                switch touchpoint {
                case .day1FirstInsight:
                    Day1FirstInsightCard(
                        puppyName: puppyName,
                        onDismiss: {
                            Analytics.track(.trialTouchpointDismissed, properties: ["day": touchpoint.day])
                            onDismiss()
                        }
                    )
                case .day7ValueSummary:
                    Day7ValueSummaryCard(onDismiss: {
                        Analytics.track(.trialTouchpointDismissed, properties: ["day": touchpoint.day])
                        onDismiss()
                    })
                case .day12Warning:
                    Day12WarningCard(
                        puppyName: puppyName,
                        onSubscribe: {
                            Analytics.track(.trialTouchpointSubscribeTapped, properties: ["day": touchpoint.day])
                            onSubscribe()
                        },
                        onDismiss: {
                            Analytics.track(.trialTouchpointDismissed, properties: ["day": touchpoint.day])
                            onDismiss()
                        }
                    )
                case .day14Conversion:
                    Day14ConversionCard(
                        puppyName: puppyName,
                        onSubscribe: {
                            Analytics.track(.trialTouchpointSubscribeTapped, properties: ["day": touchpoint.day])
                            onSubscribe()
                        },
                        onDismiss: {
                            Analytics.track(.trialTouchpointDismissed, properties: ["day": touchpoint.day])
                            onDismiss()
                        }
                    )
                case .day3Notification:
                    EmptyView() // Day 3 is notification only
                }
            }
            .onAppear {
                Analytics.track(.trialTouchpointShown, properties: ["day": touchpoint.day])
            }
        }
    }
}

// MARK: - Day 1: First Insight Card

/// Shows on day 1 to set expectations about AI learning
struct Day1FirstInsightCard: View {
    let puppyName: String
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "brain.head.profile")
                        .font(.body)
                        .foregroundStyle(.blue)
                }
                .accessibilityHidden(true)

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Trial.day1Title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.Trial.day1Subtitle(name: puppyName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Text(Strings.Trial.day1Dismiss)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    )
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: .blue.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Trial.day1Title)
    }
}

// MARK: - Day 7: Value Summary Card

/// Shows on day 7 with stats about what the AI has learned
struct Day7ValueSummaryCard: View {
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(EventStore.self) private var eventStore

    // Cached stats - computed once on appear, not on every render
    @State private var cachedPatternsLearned: Int = 0
    @State private var cachedInsightsGenerated: Int = 0

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundStyle(.green)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Trial.day7Title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.Trial.day7Subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Stats row
            HStack(spacing: 16) {
                StatPill(
                    icon: "chart.line.uptrend.xyaxis",
                    text: Strings.Trial.day7PatternsLearned(cachedPatternsLearned)
                )

                StatPill(
                    icon: "lightbulb.fill",
                    text: Strings.Trial.day7InsightsGenerated(cachedInsightsGenerated)
                )
            }

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Text(Strings.Trial.day7KeepGoing)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green)
                    )
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: .green.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Trial.day7Title)
        .task {
            // Compute expensive stats once on appear, not on every render
            await computeStats()
        }
    }

    /// Compute stats off the main actor for better performance
    private func computeStats() async {
        let events = eventStore.events

        // Compute on background to avoid blocking UI
        let (patterns, insights) = await Task.detached(priority: .userInitiated) {
            let uniqueTypes = Set(events.map { $0.type })
            let calendar = Calendar.current
            let uniqueDates = Set(events.map { calendar.startOfDay(for: $0.time) })
            return (uniqueTypes.count, uniqueDates.count)
        }.value

        await MainActor.run {
            cachedPatternsLearned = patterns
            cachedInsightsGenerated = insights
        }
    }
}

/// Small pill showing a stat with icon
private struct StatPill: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
    }
}

// MARK: - Day 12: Warning Card

/// Shows on day 12 with urgency to subscribe
struct Day12WarningCard: View {
    let puppyName: String
    let onSubscribe: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.body)
                        .foregroundStyle(.orange)
                }
                .accessibilityHidden(true)

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Trial.day12Title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.Trial.day12Subtitle(name: puppyName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text(Strings.Trial.day12Later)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        )
                }

                // Subscribe button
                Button {
                    onSubscribe()
                } label: {
                    Text(Strings.Trial.day12Subscribe)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.orange)
                        )
                }
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: .orange.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Trial.day12Title)
    }
}

// MARK: - Day 14: Conversion Card

/// Shows on day 14 (last day) with strong conversion push
struct Day14ConversionCard: View {
    let puppyName: String
    let onSubscribe: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .accessibilityHidden(true)

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Trial.day14Title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.Trial.day14Subtitle(name: puppyName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text(Strings.Trial.day14Dismiss)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        )
                }

                // Subscribe button
                Button {
                    onSubscribe()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text(Strings.Trial.day14Subscribe)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.red)
                    )
                }
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: .red.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Trial.day14Title)
    }
}

// MARK: - Preview

#Preview("Day 1") {
    VStack(spacing: 16) {
        Day1FirstInsightCard(
            puppyName: "Max",
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
    .environment(EventStore())
}

#Preview("Day 7") {
    VStack(spacing: 16) {
        Day7ValueSummaryCard(
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
    .environment(EventStore())
}

#Preview("Day 12") {
    VStack(spacing: 16) {
        Day12WarningCard(
            puppyName: "Max",
            onSubscribe: { print("Subscribe") },
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
}

#Preview("Day 14") {
    VStack(spacing: 16) {
        Day14ConversionCard(
            puppyName: "Max",
            onSubscribe: { print("Subscribe") },
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
}
