//
//  EnrichmentCard.swift
//  Otis-app
//
//  Card showing daily enrichment suggestion and weekly progress
//

import SwiftUI
import OtisShared

/// Card showing enrichment suggestion and weekly activity summary
struct EnrichmentCard: View {
    let activities: [EnrichmentActivity]
    let suggestion: EnrichmentType?
    let onLogActivity: () -> Void
    let onTap: () -> Void

    private var weeklyCount: Int {
        activities.thisWeek.count
    }

    private var weeklyMinutes: Int {
        activities.weeklyMinutes
    }

    private var todayCount: Int {
        activities.completedToday.count
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Suggestion section
                if let suggestion = suggestion {
                    suggestionSection(type: suggestion)
                }

                Divider()

                // Weekly stats
                weeklyStatsSection
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Suggestion Section

    @ViewBuilder
    private func suggestionSection(type: EnrichmentType) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 24))
                .foregroundStyle(.green)
                .frame(width: 44, height: 44)
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Enrichment.todaySuggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(type.label)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: type.category.icon)
                    Text(type.category.label)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Log button
            Button(action: onLogActivity) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekly Stats Section

    @ViewBuilder
    private var weeklyStatsSection: some View {
        HStack(spacing: 16) {
            // Today's count
            VStack(spacing: 4) {
                Text("\(todayCount)")
                    .font(.title2.bold())
                    .foregroundStyle(todayCount > 0 ? .green : .secondary)

                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Weekly count
            VStack(spacing: 4) {
                Text("\(weeklyCount)")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("This week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Weekly minutes
            VStack(spacing: 4) {
                Text("\(weeklyMinutes)")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        EnrichmentCard(
            activities: [
                EnrichmentActivity(type: .puzzleToy, durationMinutes: 15),
                EnrichmentActivity(type: .nosework, completedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60), durationMinutes: 20),
                EnrichmentActivity(type: .tugPlay, completedAt: Date().addingTimeInterval(-3 * 24 * 60 * 60), durationMinutes: 10)
            ],
            suggestion: .snuffleMat,
            onLogActivity: {},
            onTap: {}
        )

        EnrichmentCard(
            activities: [],
            suggestion: .puzzleToy,
            onLogActivity: {},
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
