//
//  StreakCard.swift
//  Ollie-app
//
//  Card showing outdoor potty streak

import SwiftUI

/// Compact card showing current outdoor potty streak
struct StreakCard: View {
    let streakInfo: StreakInfo

    var body: some View {
        // Only show if there's relevant streak data
        if streakInfo.currentStreak > 0 || streakInfo.bestStreak > 0 {
            cardContent
                .padding(.horizontal)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack {
            // Emoji indicator
            Text(StreakCalculations.emoji(for: streakInfo.currentStreak))
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                // Main streak text
                HStack(spacing: 4) {
                    Text("\(streakInfo.currentStreak)x buiten")
                        .font(.headline)
                        .foregroundColor(textColor)

                    if streakInfo.isOnFire {
                        Text("op rij!")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }

                // Subtitle with best streak
                if streakInfo.bestStreak > streakInfo.currentStreak {
                    Text("Record: \(streakInfo.bestStreak)x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if streakInfo.currentStreak > 0 {
                    Text(StreakCalculations.message(for: streakInfo.currentStreak))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Progress toward next milestone
            if streakInfo.currentStreak > 0 {
                nextMilestoneView
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    @ViewBuilder
    private var nextMilestoneView: some View {
        let milestone = nextMilestone(for: streakInfo.currentStreak)
        let progress = Double(streakInfo.currentStreak) / Double(milestone)

        VStack(alignment: .trailing, spacing: 2) {
            Text("\(milestone)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Mini progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(progressColor)
                    .frame(width: 40 * progress, height: 4)
            }
        }
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        if streakInfo.currentStreak >= 5 {
            return .orange
        } else if streakInfo.currentStreak > 0 {
            return .primary
        } else {
            return .secondary
        }
    }

    private var backgroundColor: Color {
        if streakInfo.currentStreak >= 5 {
            return Color.orange.opacity(0.1)
        } else if streakInfo.currentStreak > 0 {
            return Color.green.opacity(0.1)
        } else {
            return Color(.secondarySystemBackground)
        }
    }

    private var progressColor: Color {
        if streakInfo.currentStreak >= 5 {
            return .orange
        } else {
            return .green
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
