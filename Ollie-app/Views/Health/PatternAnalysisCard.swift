//
//  PatternAnalysisCard.swift
//  Ollie-app
//
//  Card showing trigger pattern success rates

import SwiftUI
import OllieShared

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
        .cornerRadius(LayoutConstants.cornerRadiusM)
    }

    private var triggersWithData: [PatternTrigger] {
        analysis.triggers.filter { $0.hasData }
    }

    private var noDataView: some View {
        Text(Strings.Patterns.insufficientData)
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
            // Header with icon, name, and success rate
            HStack {
                Image(systemName: trigger.iconName)
                    .font(.title3)
                    .foregroundStyle(trigger.iconColor)
                    .accessibilityHidden(true)

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

            // Success rate bar - minimum 16pt height for accessibility
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)

                    // Success portion (outdoor)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(successColor)
                        .frame(width: geometry.size.width * CGFloat(trigger.successRate) / 100, height: 16)
                }
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trigger.name): \(Strings.Patterns.successRate(trigger.successRate)) \(Strings.Patterns.percentSuccess)")
        .accessibilityValue("\(Strings.Patterns.count(trigger.totalCount)) \(Strings.Patterns.timesMeasured)")
    }

    private var successColor: Color {
        let rate = trigger.successRate
        if rate >= 80 {
            return .ollieSuccess
        } else if rate >= 60 {
            return .ollieAccent
        } else if rate >= 40 {
            return .ollieWarning
        } else {
            return .ollieDanger
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

/// Small badge showing trigger icon and success rate
struct CompactTriggerBadge: View {
    let trigger: PatternTrigger

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trigger.iconName)
                .font(.caption)
                .foregroundStyle(trigger.iconColor)
                .accessibilityHidden(true)

            Text("\(trigger.successRate)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(successColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trigger.name): \(Strings.Patterns.successRate(trigger.successRate))")
    }

    private var successColor: Color {
        let rate = trigger.successRate
        if rate >= 80 {
            return .ollieSuccess
        } else if rate >= 60 {
            return .ollieAccent
        } else if rate >= 40 {
            return .ollieWarning
        } else {
            return .ollieDanger
        }
    }
}

// MARK: - Previews

#Preview("Full Card") {
    VStack {
        PatternAnalysisCard(
            analysis: PatternAnalysis(
                triggers: [
                    PatternTrigger(id: "sleep", name: Strings.Patterns.afterSleep, iconName: "moon.zzz.fill", iconColor: .ollieSleep, outdoorCount: 8, indoorCount: 2),
                    PatternTrigger(id: "meal", name: Strings.Patterns.afterEating, iconName: "fork.knife", iconColor: .ollieAccent, outdoorCount: 5, indoorCount: 1),
                    PatternTrigger(id: "walk", name: Strings.Patterns.duringWalk, iconName: "figure.walk", iconColor: .ollieAccent, outdoorCount: 12, indoorCount: 0),
                    PatternTrigger(id: "water", name: Strings.Patterns.afterDrinking, iconName: "drop.fill", iconColor: .ollieInfo, outdoorCount: 3, indoorCount: 2)
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
                    PatternTrigger(id: "sleep", name: Strings.Patterns.afterSleep, iconName: "moon.zzz.fill", iconColor: .ollieSleep, outdoorCount: 8, indoorCount: 2),
                    PatternTrigger(id: "meal", name: Strings.Patterns.afterEating, iconName: "fork.knife", iconColor: .ollieAccent, outdoorCount: 5, indoorCount: 1),
                    PatternTrigger(id: "walk", name: Strings.Patterns.duringWalk, iconName: "figure.walk", iconColor: .ollieAccent, outdoorCount: 12, indoorCount: 0)
                ],
                periodDays: 7
            )
        )
        .padding()

        Spacer()
    }
}
