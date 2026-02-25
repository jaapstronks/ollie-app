//
//  PottyProgressSummaryCard.swift
//  Ollie-app
//
//  Compact card combining streak and poop count in a single row
//

import SwiftUI
import OllieShared

/// Compact inline card showing both streak and poop stats in a single row
/// Design: two stat "pills" side by side with subtle glass styling
struct PottyProgressSummaryCard: View {
    let streakInfo: StreakInfo
    let poopStatus: PoopStatus

    @Environment(\.colorScheme) private var colorScheme

    /// Only show when there's meaningful data
    private var shouldShow: Bool {
        !poopStatus.urgency.isHidden &&
        (streakInfo.currentStreak > 0 || streakInfo.bestStreak > 0 || poopStatus.todayCount > 0)
    }

    var body: some View {
        if shouldShow {
            HStack(spacing: 8) {
                // Streak pill (left side)
                if streakInfo.currentStreak > 0 || streakInfo.bestStreak > 0 {
                    streakPill
                }

                // Poop pill (right side)
                poopPill

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassStatusCard(tintColor: nil, cornerRadius: LayoutConstants.cornerRadiusM)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    // MARK: - Streak Pill

    @ViewBuilder
    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: StreakCalculations.iconName(for: streakInfo.currentStreak))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(StreakCalculations.iconColor(for: streakInfo.currentStreak))

            if streakInfo.currentStreak > 0 {
                Text(Strings.PottyProgress.streakCount(streakInfo.currentStreak))
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Text(Strings.Streak.streakBroken)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(pillBackground(tint: StreakCalculations.iconColor(for: streakInfo.currentStreak)))
        .clipShape(Capsule())
    }

    // MARK: - Poop Pill

    @ViewBuilder
    private var poopPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(poopStatus.urgency.iconColor)

            if poopStatus.hasPatternData {
                Text(Strings.PottyProgress.poopCountWithExpected(
                    count: poopStatus.todayCount,
                    lower: poopStatus.expectedRange.lowerBound,
                    upper: poopStatus.expectedRange.upperBound
                ))
                .font(.subheadline)
                .fontWeight(.medium)
            } else {
                Text(Strings.PottyProgress.poopCountSimple(poopStatus.todayCount))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(pillBackground(tint: poopStatus.urgency.iconColor))
        .clipShape(Capsule())
    }

    // MARK: - Pill Background

    @ViewBuilder
    private func pillBackground(tint: Color) -> some View {
        ZStack {
            if colorScheme == .dark {
                tint.opacity(0.15)
            } else {
                tint.opacity(0.1)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts: [String] = []

        if streakInfo.currentStreak > 0 {
            parts.append(Strings.PottyProgress.streakAccessibility(streakInfo.currentStreak))
        }

        parts.append(Strings.PottyProgress.poopAccessibility(
            count: poopStatus.todayCount,
            hasPattern: poopStatus.hasPatternData,
            lower: poopStatus.expectedRange.lowerBound,
            upper: poopStatus.expectedRange.upperBound
        ))

        return parts.joined(separator: ". ")
    }
}

// MARK: - Previews

#Preview("With streak and poops") {
    VStack {
        PottyProgressSummaryCard(
            streakInfo: StreakInfo(
                currentStreak: 5,
                bestStreak: 8,
                lastOutdoorTime: Date(),
                lastIndoorTime: nil
            ),
            poopStatus: PoopStatus(
                todayCount: 2,
                expectedRange: 2...3,
                lastPoopTime: Date().addingTimeInterval(-3600),
                daytimeMinutesSinceLast: 60,
                recentWalkWithoutPoop: false,
                urgency: .good,
                message: nil,
                hasPatternData: true,
                patternDailyMedian: 2.5
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Small streak") {
    VStack {
        PottyProgressSummaryCard(
            streakInfo: StreakInfo(
                currentStreak: 2,
                bestStreak: 5,
                lastOutdoorTime: Date(),
                lastIndoorTime: nil
            ),
            poopStatus: PoopStatus(
                todayCount: 1,
                expectedRange: 2...4,
                lastPoopTime: Date().addingTimeInterval(-7200),
                daytimeMinutesSinceLast: 120,
                recentWalkWithoutPoop: false,
                urgency: .info,
                message: nil,
                hasPatternData: true,
                patternDailyMedian: 3.0
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("No streak, just poops") {
    VStack {
        PottyProgressSummaryCard(
            streakInfo: StreakInfo(
                currentStreak: 0,
                bestStreak: 0,
                lastOutdoorTime: nil,
                lastIndoorTime: nil
            ),
            poopStatus: PoopStatus(
                todayCount: 1,
                expectedRange: 2...3,
                lastPoopTime: Date().addingTimeInterval(-3600),
                daytimeMinutesSinceLast: 60,
                recentWalkWithoutPoop: false,
                urgency: .good,
                message: nil,
                hasPatternData: false,
                patternDailyMedian: nil
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Streak broken with record") {
    VStack {
        PottyProgressSummaryCard(
            streakInfo: StreakInfo(
                currentStreak: 0,
                bestStreak: 12,
                lastOutdoorTime: nil,
                lastIndoorTime: Date()
            ),
            poopStatus: PoopStatus(
                todayCount: 0,
                expectedRange: 2...4,
                lastPoopTime: nil,
                daytimeMinutesSinceLast: nil,
                recentWalkWithoutPoop: false,
                urgency: .info,
                message: nil,
                hasPatternData: true,
                patternDailyMedian: 3.0
            )
        )
        Spacer()
    }
    .padding()
}
