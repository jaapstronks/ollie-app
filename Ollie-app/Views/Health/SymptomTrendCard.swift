//
//  SymptomTrendCard.swift
//  Ollie-app
//
//  Shows symptom patterns over time for a condition
//  Part of Brief 04: Health Logging
//

import SwiftUI
import OtisShared

struct SymptomTrendCard: View {
    let conditionName: String
    let conditionId: UUID?
    let trendSummary: SymptomTrendSummary
    let onViewDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.teal)
                Text(Strings.HealthLogging.symptomTrends)
                    .font(.headline)
                Spacer()
            }

            // Condition name
            Text(conditionName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Episode counts
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.HealthLogging.thisWeek)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Strings.HealthLogging.episodes(trendSummary.episodesThisWeek))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.HealthLogging.lastWeek)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Strings.HealthLogging.episodes(trendSummary.episodesLastWeek))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Trend indicator
                TrendBadge(trend: trendSummary.trend)
            }

            // Common triggers
            if !trendSummary.commonTriggers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.HealthLogging.commonTriggers)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(topTriggers, id: \.trigger) { trigger, count in
                            CapsuleBadge("\(trigger) (\(count)x)")
                        }
                    }
                }
            }

            // View details button
            Button(action: onViewDetails) {
                HStack {
                    Text(Strings.HealthLogging.viewDetails)
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.teal)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var topTriggers: [(trigger: String, count: Int)] {
        trendSummary.commonTriggers
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { (trigger: $0.key, count: $0.value) }
    }
}

// MARK: - Trend Badge

private struct TrendBadge: View {
    let trend: SymptomTrend

    var body: some View {
        CapsuleBadge(trend.label, icon: trend.icon, color: trendColor, style: .tinted)
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .blue
        case .worsening: return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SymptomTrendCard(
            conditionName: "Arthritis",
            conditionId: nil,
            trendSummary: SymptomTrendSummary(
                conditionId: nil,
                episodesThisWeek: 3,
                episodesLastWeek: 5,
                trend: .improving,
                commonTriggers: [
                    "After walk": 2,
                    "Cold weather": 1
                ]
            ),
            onViewDetails: {}
        )
        .padding()

        SymptomTrendCard(
            conditionName: "Food Allergy",
            conditionId: nil,
            trendSummary: SymptomTrendSummary(
                conditionId: nil,
                episodesThisWeek: 4,
                episodesLastWeek: 2,
                trend: .worsening,
                commonTriggers: [
                    "After eating": 3,
                    "New food": 1
                ]
            ),
            onViewDetails: {}
        )
        .padding()
    }
}
