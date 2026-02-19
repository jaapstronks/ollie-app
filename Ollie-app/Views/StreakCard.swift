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
            Image(systemName: StreakCalculations.iconName(for: streakInfo.currentStreak))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(StreakCalculations.iconColor(for: streakInfo.currentStreak))
                .frame(width: 40, height: 40)
                .background(iconBackground)
                .clipShape(Circle())
                .overlay(iconOverlay)

            VStack(alignment: .leading, spacing: 3) {
                // Main streak text
                HStack(spacing: 4) {
                    Text("\(streakInfo.currentStreak)x buiten")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(textColor)

                    if streakInfo.isOnFire {
                        Text("op rij!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.ollieAccent)
                    }
                }

                // Subtitle with best streak
                if streakInfo.bestStreak > streakInfo.currentStreak {
                    Text("Record: \(streakInfo.bestStreak)x")
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
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(glassOverlay)
    }

    // MARK: - Glass Components

    @ViewBuilder
    private var iconBackground: some View {
        ZStack {
            progressColor.opacity(colorScheme == .dark ? 0.2 : 0.15)

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var iconOverlay: some View {
        Circle()
            .strokeBorder(
                progressColor.opacity(0.3),
                lineWidth: 0.5
            )
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.05)
            } else {
                Color.white.opacity(0.7)
            }

            // Tint based on streak level
            progressColor.opacity(colorScheme == .dark ? 0.06 : 0.04)

            // Top highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                        progressColor.opacity(colorScheme == .dark ? 0.08 : 0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
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

            // Glass progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(progressColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 44, height: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(progressColor.opacity(0.2), lineWidth: 0.5)
                    )

                RoundedRectangle(cornerRadius: 3)
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
                    .frame(width: 44 * progress, height: 6)
            }
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
