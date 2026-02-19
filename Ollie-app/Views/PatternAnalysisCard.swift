//
//  PatternAnalysisCard.swift
//  Ollie-app
//
//  Card showing trigger pattern success rates

import SwiftUI

/// Card displaying pattern analysis with trigger success rates
struct PatternAnalysisCard: View {
    let analysis: PatternAnalysis

    var body: some View {
        VStack(spacing: 12) {
            if !analysis.hasTriggers {
                noDataView
            } else {
                ForEach(triggersWithData) { trigger in
                    TriggerRow(trigger: trigger)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var triggersWithData: [PatternTrigger] {
        analysis.triggers.filter { $0.hasData }
    }

    private var noDataView: some View {
        Text("Nog niet genoeg data voor patronen")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
    }
}

/// Single row showing a trigger pattern with success bar
struct TriggerRow: View {
    let trigger: PatternTrigger

    var body: some View {
        VStack(spacing: 6) {
            // Header with emoji, name, and success rate
            HStack {
                Text(trigger.emoji)
                    .font(.title3)

                Text(trigger.name)
                    .font(.subheadline)

                Spacer()

                Text("\(trigger.successRate)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(successColor)

                Text("(\(trigger.totalCount)x)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Success rate bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Success portion (outdoor)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(successColor)
                        .frame(width: geometry.size.width * CGFloat(trigger.successRate) / 100, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private var successColor: Color {
        let rate = trigger.successRate
        if rate >= 80 {
            return .green
        } else if rate >= 60 {
            return .yellow
        } else if rate >= 40 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Compact version of pattern analysis for smaller displays
struct PatternAnalysisCompact: View {
    let analysis: PatternAnalysis

    var body: some View {
        if analysis.hasTriggers {
            HStack(spacing: 16) {
                ForEach(topTriggers) { trigger in
                    CompactTriggerBadge(trigger: trigger)
                }
            }
        }
    }

    /// Top 3 triggers with the most data
    private var topTriggers: [PatternTrigger] {
        Array(analysis.triggers
            .filter { $0.hasData }
            .sorted { $0.totalCount > $1.totalCount }
            .prefix(3))
    }
}

/// Small badge showing trigger emoji and success rate
struct CompactTriggerBadge: View {
    let trigger: PatternTrigger

    var body: some View {
        HStack(spacing: 4) {
            Text(trigger.emoji)
                .font(.caption)

            Text("\(trigger.successRate)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(successColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    private var successColor: Color {
        let rate = trigger.successRate
        if rate >= 80 {
            return .green
        } else if rate >= 60 {
            return .yellow
        } else if rate >= 40 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Previews

#Preview("Full Card") {
    VStack {
        PatternAnalysisCard(
            analysis: PatternAnalysis(
                triggers: [
                    PatternTrigger(id: "sleep", name: "Na slaap", emoji: "😴", outdoorCount: 8, indoorCount: 2),
                    PatternTrigger(id: "meal", name: "Na eten", emoji: "🍽️", outdoorCount: 5, indoorCount: 1),
                    PatternTrigger(id: "walk", name: "Bij wandeling", emoji: "🚶", outdoorCount: 12, indoorCount: 0),
                    PatternTrigger(id: "water", name: "Na drinken", emoji: "💧", outdoorCount: 3, indoorCount: 2)
                ],
                periodDays: 7
            )
        )
        .padding()

        Spacer()
    }
}

#Preview("No Data") {
    VStack {
        PatternAnalysisCard(analysis: .empty)
            .padding()

        Spacer()
    }
}

#Preview("Compact") {
    VStack {
        PatternAnalysisCompact(
            analysis: PatternAnalysis(
                triggers: [
                    PatternTrigger(id: "sleep", name: "Na slaap", emoji: "😴", outdoorCount: 8, indoorCount: 2),
                    PatternTrigger(id: "meal", name: "Na eten", emoji: "🍽️", outdoorCount: 5, indoorCount: 1),
                    PatternTrigger(id: "walk", name: "Bij wandeling", emoji: "🚶", outdoorCount: 12, indoorCount: 0)
                ],
                periodDays: 7
            )
        )
        .padding()

        Spacer()
    }
}
