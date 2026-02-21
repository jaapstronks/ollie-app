//
//  StreakCard.swift
//  Ollie-app
//
//  Card showing outdoor potty streak
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI

/// Compact card showing current outdoor potty streak
/// Uses liquid glass design with celebratory styling for high streaks
struct StreakCard: View {
    let streakInfo: StreakInfo

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Only show if there's relevant streak data
        if streakInfo.currentStreak > 0 || streakInfo.bestStreak > 0 {
            cardContent
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack(spacing: 12) {
            // Icon with glass circle background
            GlassIconCircle(tintColor: progressColor) {
                Image(systemName: StreakCalculations.iconName(for: streakInfo.currentStreak))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(StreakCalculations.iconColor(for: streakInfo.currentStreak))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                // Main streak text
                HStack(spacing: 4) {
                    if streakInfo.currentStreak > 0 {
                        Text(Strings.Streak.outdoorStreak(count: streakInfo.currentStreak))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(textColor)

                        if streakInfo.isOnFire {
                            Text(Strings.Streak.inARow)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.ollieAccent)
                        }
                    } else {
                        Text(Strings.Streak.streakBroken)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }

                // Subtitle with best streak or motivational message
                if streakInfo.currentStreak == 0 && streakInfo.bestStreak > 0 {
                    Text(Strings.Streak.recordTryAgain(count: streakInfo.bestStreak))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if streakInfo.bestStreak > streakInfo.currentStreak {
                    Text(Strings.Streak.record(count: streakInfo.bestStreak))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if streakInfo.currentStreak > 0 {
                    Text(StreakCalculations.message(for: streakInfo.currentStreak))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Progress toward next milestone
            if streakInfo.currentStreak > 0 {
                nextMilestoneView
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassStatusCard(tintColor: progressColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Streak.accessibility)
        .accessibilityValue(Strings.Streak.accessibilityValue(current: streakInfo.currentStreak, record: streakInfo.bestStreak))
    }

    @ViewBuilder
    private var nextMilestoneView: some View {
        let milestone = nextMilestone(for: streakInfo.currentStreak)
        let progress = Double(streakInfo.currentStreak) / Double(milestone)

        VStack(alignment: .trailing, spacing: 4) {
            Text("\(milestone)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(progressColor)

            // Glass progress bar - minimum 16pt height for accessibility
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(progressColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 44, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(progressColor.opacity(0.2), lineWidth: 0.5)
                    )

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                progressColor,
                                progressColor.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 44 * progress, height: 16)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Strings.Streak.progressHint)
            .accessibilityValue(Strings.Streak.progressAccessibilityValue(current: streakInfo.currentStreak, milestone: milestone))
        }
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        if streakInfo.currentStreak >= 5 {
            return .ollieAccent
        } else if streakInfo.currentStreak > 0 {
            return .primary
        } else {
            return .secondary
        }
    }

    private var backgroundColor: Color {
        if streakInfo.currentStreak >= 5 {
            return Color.ollieAccent.opacity(0.1)
        } else if streakInfo.currentStreak > 0 {
            return Color.ollieSuccess.opacity(0.1)
        } else {
            return Color(.secondarySystemBackground)
        }
    }

    private var progressColor: Color {
        if streakInfo.currentStreak >= 5 {
            return .ollieAccent
        } else {
            return .ollieSuccess
        }
    }

    private func nextMilestone(for streak: Int) -> Int {
        let milestones = [3, 5, 10, 15, 20, 25, 30, 50, 100]
        return milestones.first { $0 > streak } ?? streak + 10
    }
}

// MARK: - Previews

#Preview("No Streak") {
    VStack {
        StreakCard(streakInfo: .empty)
        Spacer()
    }
    .padding()
}

#Preview("Streak Broken") {
    VStack {
        StreakCard(
            streakInfo: StreakInfo(
                currentStreak: 0,
                bestStreak: 8,
                lastOutdoorTime: nil,
                lastIndoorTime: Date()
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Small Streak") {
    VStack {
        StreakCard(
            streakInfo: StreakInfo(
                currentStreak: 2,
                bestStreak: 5,
                lastOutdoorTime: Date(),
                lastIndoorTime: nil
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("On Fire") {
    VStack {
        StreakCard(
            streakInfo: StreakInfo(
                currentStreak: 7,
                bestStreak: 7,
                lastOutdoorTime: Date(),
                lastIndoorTime: nil
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Big Streak") {
    VStack {
        StreakCard(
            streakInfo: StreakInfo(
                currentStreak: 12,
                bestStreak: 15,
                lastOutdoorTime: Date(),
                lastIndoorTime: nil
            )
        )
        Spacer()
    }
    .padding()
}
