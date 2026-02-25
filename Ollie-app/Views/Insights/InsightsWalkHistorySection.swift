//
//  InsightsWalkHistorySection.swift
//  Ollie-app
//
//  Walk history section
//

import SwiftUI
import OllieShared

/// Walk history section showing recent walks
struct InsightsWalkHistorySection: View {
    let recentWalks: [PuppyEvent]
    let weekWalkStats: (count: Int, totalMinutes: Int)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightsSectionHeader(
                title: Strings.Stats.walkHistory,
                icon: "figure.walk",
                tint: .ollieAccent
            )

            VStack(spacing: 12) {
                // Week summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Stats.thisWeek)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            // Walk count
                            HStack(spacing: 4) {
                                Text("\(weekWalkStats.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(Strings.WalksTab.walks)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            // Total duration
                            if weekWalkStats.totalMinutes > 0 {
                                HStack(spacing: 4) {
                                    Text("\(weekWalkStats.totalMinutes)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(Strings.Common.minutes)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "figure.walk")
                        .font(.title)
                        .foregroundStyle(Color.ollieAccent)
                }

                // Recent walks list (last 5)
                if !recentWalks.isEmpty {
                    Divider()

                    ForEach(Array(recentWalks.prefix(5))) { walk in
                        InsightsWalkRow(walk: walk)
                    }
                }
            }
            .padding()
            .glassCard(tint: .accent)
        }
    }
}

// MARK: - Walk Row

struct InsightsWalkRow: View {
    let walk: PuppyEvent

    var body: some View {
        HStack(spacing: 12) {
            // Date
            Text(walk.time, format: .dateTime.weekday(.abbreviated).hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            // Duration
            if let duration = walk.durationMin {
                Text("\(duration) \(Strings.Common.minutes)")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // Spot name
            if let spotName = walk.spotName {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(spotName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
