//
//  TeamContributionCard.swift
//  Otis-app
//
//  Card showing team contribution statistics with leaderboard
//

import SwiftUI
import OtisShared

/// Card displaying team contribution statistics
struct TeamContributionCard: View {
    let stats: [ContributionStats]
    let period: ContributionPeriod
    let summary: ContributionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with period
            HStack {
                Text(OtisShared.Strings.ContributionStats.teamContributions)
                    .font(.headline)

                Spacer()

                CapsuleBadge(period.label)
            }

            if stats.isEmpty {
                emptyState
            } else {
                // Team summary
                teamSummarySection

                Divider()

                // Individual contributions
                contributorsList
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        CompactEmptyState(icon: "person.3", message: "No contributions yet")
    }

    private var teamSummarySection: some View {
        HStack(spacing: 16) {
            StatBadge(
                value: summary.totalEvents,
                label: OtisShared.Strings.ContributionStats.eventsLogged,
                icon: "list.bullet",
                color: .otisInfo
            )

            StatBadge(
                value: summary.totalWalks,
                label: OtisShared.Strings.ContributionStats.walks,
                icon: "figure.walk",
                color: .otisSuccess
            )

            StatBadge(
                value: summary.totalWalkMinutes,
                label: OtisShared.Strings.ContributionStats.walkMinutes,
                icon: "timer",
                color: .otisAccent
            )
        }
    }

    private var contributorsList: some View {
        VStack(spacing: 12) {
            ForEach(stats.prefix(5)) { stat in
                ContributorRow(stat: stat, isTopContributor: stat.id == summary.topContributor?.id)
            }
        }
    }
}

/// Single contributor row in the leaderboard
struct ContributorRow: View {
    let stat: ContributionStats
    let isTopContributor: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            UserAvatarFromRecordID(cloudKitRecordID: stat.userRecordID, size: 32)

            // Name and role
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(stat.displayName)
                        .font(.subheadline)
                        .fontWeight(stat.isCurrentUser ? .semibold : .regular)

                    if stat.isCurrentUser {
                        Text("(you)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isTopContributor {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                // Stats summary
                HStack(spacing: 8) {
                    if stat.walkCount > 0 {
                        Label("\(stat.walkCount)", systemImage: "figure.walk")
                    }
                    if stat.trainingSessions > 0 {
                        Label("\(stat.trainingSessions)", systemImage: "star")
                    }
                    if stat.momentsLogged > 0 {
                        Label("\(stat.momentsLogged)", systemImage: "camera")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Contribution percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(stat.totalEvents)")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(OtisShared.Strings.ContributionStats.percentageOfEvents(Int(stat.contributionPercentage * 100)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Your Contribution Card

/// Card showing just the current user's contributions
struct YourContributionCard: View {
    let stat: ContributionStats
    let period: ContributionPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(OtisShared.Strings.ContributionStats.yourContributions)
                    .font(.headline)

                Spacer()

                CapsuleBadge(period.label)
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCell(
                    value: stat.walkCount,
                    label: OtisShared.Strings.ContributionStats.walks,
                    icon: "figure.walk",
                    color: .otisSuccess
                )

                StatCell(
                    value: stat.walkMinutes,
                    label: OtisShared.Strings.ContributionStats.walkMinutes,
                    icon: "timer",
                    color: .otisAccent
                )

                StatCell(
                    value: stat.trainingSessions,
                    label: OtisShared.Strings.ContributionStats.trainingSessions,
                    icon: "star.fill",
                    color: .yellow
                )

                StatCell(
                    value: stat.pottyBreaks,
                    label: OtisShared.Strings.ContributionStats.pottyBreaks,
                    icon: "drop.fill",
                    color: .otisInfo
                )

                StatCell(
                    value: stat.momentsLogged,
                    label: OtisShared.Strings.ContributionStats.momentsCaptured,
                    icon: "camera.fill",
                    color: .pink
                )

                StatCell(
                    value: stat.mealsLogged,
                    label: OtisShared.Strings.ContributionStats.mealsLogged,
                    icon: "fork.knife",
                    color: .orange
                )
            }

            // Outdoor potty success rate
            if stat.pottyBreaks > 0 {
                Divider()

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text("Outdoor success rate: \(Int(stat.outdoorSuccessRate * 100))%")
                        .font(.subheadline)

                    Spacer()

                    Text("\(stat.outdoorPottyBreaks)/\(stat.pottyBreaks)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("Team Contribution") {
    let stats = [
        ContributionStats(
            userRecordID: "user1",
            displayName: "Sarah",
            isCurrentUser: false,
            totalEvents: 45,
            walkCount: 12,
            walkMinutes: 180,
            trainingSessions: 8,
            pottyBreaks: 20,
            outdoorPottyBreaks: 18,
            momentsLogged: 5,
            mealsLogged: 0,
            socialEvents: 0,
            startDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            endDate: Date()
        ),
        ContributionStats(
            userRecordID: "user2",
            displayName: "John",
            isCurrentUser: true,
            totalEvents: 30,
            walkCount: 8,
            walkMinutes: 120,
            trainingSessions: 4,
            pottyBreaks: 15,
            outdoorPottyBreaks: 12,
            momentsLogged: 3,
            mealsLogged: 0,
            socialEvents: 0,
            startDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            endDate: Date()
        )
    ]

    let summary = ContributionCalculations.getSummary(stats: stats)

    return TeamContributionCard(
        stats: stats,
        period: .thisWeek,
        summary: summary
    )
    .padding()
}

#Preview("Your Contribution") {
    YourContributionCard(
        stat: ContributionStats(
            userRecordID: "user1",
            displayName: "John",
            isCurrentUser: true,
            totalEvents: 30,
            walkCount: 8,
            walkMinutes: 120,
            trainingSessions: 4,
            pottyBreaks: 15,
            outdoorPottyBreaks: 12,
            momentsLogged: 3,
            mealsLogged: 6,
            socialEvents: 2,
            startDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            endDate: Date()
        ),
        period: .thisWeek
    )
    .padding()
}
