//
//  PottyProgressCard.swift
//  Ollie-app
//
//  Compact card showing potty training progress: streak, outdoor %, and top triggers

import SwiftUI

/// Compact potty progress card for the Train tab
struct PottyProgressCard: View {
    let streakInfo: StreakInfo
    let patternAnalysis: PatternAnalysis
    let outdoorPercentage: Int

    @Environment(\.colorScheme) private var colorScheme

    private var topTriggers: [PatternTrigger] {
        patternAnalysis.triggers
            .filter { $0.hasData }
            .sorted { $0.successRate > $1.successRate }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Color.ollieAccent)
                Text(Strings.Train.pottyProgress)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Main stats row
            HStack(spacing: 20) {
                // Outdoor percentage
                outdoorPercentageView

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 50)

                // Current streak
                streakView
            }

            // Top triggers (if available)
            if !topTriggers.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Train.topTriggers)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        ForEach(topTriggers) { trigger in
                            triggerBadge(trigger)
                        }
                    }
                }
            }
        }
        .padding()
        .glassCard(tint: .accent)
    }

    // MARK: - Outdoor Percentage View

    @ViewBuilder
    private var outdoorPercentageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(outdoorPercentage)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(percentageColor)
                Text("%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(percentageColor.opacity(0.8))
            }

            Text(Strings.Train.outdoorThisWeek)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var percentageColor: Color {
        switch outdoorPercentage {
        case 90...: return .ollieSuccess
        case 70...: return .ollieAccent
        case 50...: return .orange
        default: return .ollieWarning
        }
    }

    // MARK: - Streak View

    @ViewBuilder
    private var streakView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: StreakCalculations.iconName(for: streakInfo.currentStreak))
                    .font(.title2)
                    .foregroundStyle(StreakCalculations.iconColor(for: streakInfo.currentStreak))

                Text("\(streakInfo.currentStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(streakInfo.currentStreak > 0 ? .primary : .secondary)
            }

            Text(Strings.Train.dayStreak)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Trigger Badge

    @ViewBuilder
    private func triggerBadge(_ trigger: PatternTrigger) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trigger.iconName)
                .font(.caption)
                .foregroundStyle(trigger.iconColor)

            Text("\(trigger.successRate)%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(trigger.iconColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
        )
    }
}

// MARK: - Preview

#Preview("With Data") {
    PottyProgressCard(
        streakInfo: StreakInfo(
            currentStreak: 5,
            bestStreak: 8,
            lastOutdoorTime: Date(),
            lastIndoorTime: nil
        ),
        patternAnalysis: PatternAnalysis(
            triggers: [
                PatternTrigger(id: "sleep", name: Strings.Patterns.afterSleep, iconName: "moon.zzz.fill", iconColor: .ollieSleep, outdoorCount: 9, indoorCount: 1),
                PatternTrigger(id: "meal", name: Strings.Patterns.afterEating, iconName: "fork.knife", iconColor: .ollieAccent, outdoorCount: 7, indoorCount: 2),
                PatternTrigger(id: "walk", name: Strings.Patterns.duringWalk, iconName: "figure.walk", iconColor: .ollieAccent, outdoorCount: 10, indoorCount: 0)
            ],
            periodDays: 7
        ),
        outdoorPercentage: 82
    )
    .padding()
}

#Preview("No Streak") {
    PottyProgressCard(
        streakInfo: .empty,
        patternAnalysis: .empty,
        outdoorPercentage: 45
    )
    .padding()
}
