//
//  WeeklyWalkSummaryCard.swift
//  Otis-app
//
//  Weekly walk summary card for teenage+ dogs
//  Shows walk count, total duration, and days-with-walks indicator
//

import SwiftUI
import OtisShared

/// Card showing weekly walk statistics for teenage and older dogs
/// Part of the lifecycle transition feature to keep the app relevant
/// as dogs grow past the puppy phase
struct WeeklyWalkSummaryCard: View {
    /// Per-day statistics for the past 7 days
    let weekStats: [DayStats]

    /// Total walks this week
    let totalWalks: Int

    /// Total walk duration in minutes (if available)
    let totalMinutes: Int

    @Environment(\.colorScheme) private var colorScheme

    /// Number of days with at least one walk
    private var daysWithWalks: Int {
        weekStats.filter { $0.walks > 0 }.count
    }

    /// Formatted duration string (e.g., "3.2 hours")
    private var durationText: String? {
        guard totalMinutes > 0 else { return nil }

        let hours = Double(totalMinutes) / 60.0
        if hours < 1 {
            return Strings.WalkSummary.minutes(totalMinutes)
        } else {
            return Strings.WalkSummary.hours(hours)
        }
    }

    /// Summary text (e.g., "5 walks · 3.2 hours")
    private var summaryText: String {
        var parts: [String] = []

        // Walk count
        parts.append(Strings.WalksTab.walksCount(totalWalks))

        // Duration if available
        if let duration = durationText {
            parts.append(duration)
        }

        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.body)
                    .foregroundStyle(Color.otisInfo)

                Text(Strings.WalkSummary.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Stats summary
            Text(summaryText)
                .font(.callout)
                .foregroundStyle(.primary)

            // Week progress indicator
            weekProgressIndicator
        }
        .padding(14)
        .glassCard(tint: .info)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.WalkSummary.accessibilityLabel(walks: totalWalks, days: daysWithWalks))
    }

    // MARK: - Week Progress Indicator

    @ViewBuilder
    private var weekProgressIndicator: some View {
        HStack(spacing: 4) {
            // Day indicators (7 blocks)
            ForEach(Array(weekStats.enumerated()), id: \.offset) { _, day in
                let hasWalk = day.walks > 0

                RoundedRectangle(cornerRadius: 2)
                    .fill(hasWalk ? Color.otisInfo : Color.secondary.opacity(0.2))
                    .frame(height: 6)
            }

            Spacer(minLength: 8)

            // Days count label
            Text(Strings.WalkSummary.daysProgress(days: daysWithWalks))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("With Duration") {
    let sampleStats = (0..<7).map { daysAgo in
        DayStats(
            date: Calendar.current.date(byAdding: .day, value: -(6 - daysAgo), to: Date())!,
            outdoorPotty: 0,
            indoorPotty: 0,
            meals: 0,
            walks: daysAgo % 2 == 0 ? 2 : 0, // Walks on alternating days
            sleepHours: 0,
            trainingSessions: 0
        )
    }

    return VStack {
        WeeklyWalkSummaryCard(
            weekStats: sampleStats,
            totalWalks: 8,
            totalMinutes: 195 // ~3.25 hours
        )
    }
    .padding()
}

#Preview("No Duration") {
    let sampleStats = (0..<7).map { daysAgo in
        DayStats(
            date: Calendar.current.date(byAdding: .day, value: -(6 - daysAgo), to: Date())!,
            outdoorPotty: 0,
            indoorPotty: 0,
            meals: 0,
            walks: 1,
            sleepHours: 0,
            trainingSessions: 0
        )
    }

    return VStack {
        WeeklyWalkSummaryCard(
            weekStats: sampleStats,
            totalWalks: 7,
            totalMinutes: 0
        )
    }
    .padding()
}

#Preview("Few Walks") {
    let sampleStats = (0..<7).map { daysAgo in
        DayStats(
            date: Calendar.current.date(byAdding: .day, value: -(6 - daysAgo), to: Date())!,
            outdoorPotty: 0,
            indoorPotty: 0,
            meals: 0,
            walks: daysAgo < 2 ? 1 : 0, // Only 2 days with walks
            sleepHours: 0,
            trainingSessions: 0
        )
    }

    return VStack {
        WeeklyWalkSummaryCard(
            weekStats: sampleStats,
            totalWalks: 2,
            totalMinutes: 45
        )
    }
    .padding()
}
