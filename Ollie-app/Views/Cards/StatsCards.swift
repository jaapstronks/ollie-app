//
//  StatsCards.swift
//  Otis-app
//
//  Card components for statistics display
//

import SwiftUI
import OtisShared

// MARK: - Streak Stats Card

struct StreakStatsCard: View {
    let streakInfo: StreakInfo

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(
                    value: "\(streakInfo.currentStreak)",
                    label: Strings.Stats.currentStreak,
                    iconName: StreakCalculations.iconName(for: streakInfo.currentStreak),
                    iconColor: StreakCalculations.iconColor(for: streakInfo.currentStreak)
                )

                GlassSeparator()

                StatItem(
                    value: "\(streakInfo.bestStreak)",
                    label: Strings.Stats.bestEver,
                    iconName: "trophy.fill",
                    iconColor: .otisAccent
                )
            }

            if streakInfo.currentStreak > 0 {
                Text(StreakCalculations.message(for: streakInfo.currentStreak))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.otisAccent)
            }
        }
        .cardPadding()
        .glassCard(tint: .accent)
    }
}

// MARK: - Gap Stats Card

struct GapStatsCard: View {
    let events: [PuppyEvent]

    private var gaps: [PottyGap] {
        GapCalculations.recentGaps(events: events, days: 7)
    }

    private var stats: GapStats {
        GapCalculations.calculateGapStats(gaps: gaps)
    }

    var body: some View {
        VStack(spacing: 12) {
            if stats.count == 0 {
                Text(Strings.Stats.insufficientData)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                HStack {
                    StatItem(
                        value: GapCalculations.formatDuration(stats.medianMinutes),
                        label: Strings.Stats.median,
                        iconName: "chart.bar.fill",
                        iconColor: .otisInfo
                    )

                    GlassSeparator()

                    StatItem(
                        value: GapCalculations.formatDuration(stats.avgMinutes),
                        label: Strings.Stats.average,
                        iconName: "chart.line.uptrend.xyaxis",
                        iconColor: .otisInfo
                    )
                }

                GlassDivider()

                HStack {
                    StatItem(
                        value: GapCalculations.formatDuration(stats.minMinutes),
                        label: Strings.Stats.shortest,
                        iconName: "bolt.fill",
                        iconColor: .otisWarning
                    )

                    GlassSeparator()

                    StatItem(
                        value: GapCalculations.formatDuration(stats.maxMinutes),
                        label: Strings.Stats.longest,
                        iconName: "tortoise.fill",
                        iconColor: .otisMuted
                    )
                }

                GlassDivider()

                // Indoor vs outdoor breakdown
                HStack {
                    Label(Strings.Stats.outsideCount(stats.outdoorCount), systemImage: "leaf.fill")
                        .foregroundStyle(Color.otisSuccess)
                        .font(.subheadline)

                    Spacer()

                    Label(Strings.Stats.insideCount(stats.indoorCount), systemImage: "house.fill")
                        .foregroundStyle(stats.indoorCount > 0 ? Color.otisDanger : .secondary)
                        .font(.subheadline)

                    Spacer()

                    Text("\(stats.outdoorPercentage)\(Strings.Stats.outsidePercent)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stats.outdoorPercentage >= 80 ? Color.otisSuccess : Color.otisWarning)
                }
            }
        }
        .cardPadding()
        .glassCard(tint: .info)
    }
}

// MARK: - Today Stats Card

struct TodayStatsCard: View {
    let events: [PuppyEvent]

    private var pottyCount: Int {
        events.pee().count
    }

    private var outdoorCount: Int {
        events.outdoorPee().count
    }

    private var indoorCount: Int {
        events.pee().indoor().count
    }

    private var mealCount: Int {
        events.meals().count
    }

    private var poopCount: Int {
        events.poop().count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(
                    value: "\(pottyCount)",
                    label: Strings.Stats.timesPeed,
                    iconName: "drop.fill",
                    iconColor: .otisInfo
                )

                GlassSeparator()

                StatItem(
                    value: "\(mealCount)",
                    label: Strings.Stats.meals,
                    iconName: "fork.knife",
                    iconColor: .otisAccent
                )

                GlassSeparator()

                StatItem(
                    value: "\(poopCount)",
                    label: Strings.Stats.timesPooped,
                    iconName: "circle.inset.filled",
                    iconColor: .otisAccent
                )
            }

            if pottyCount > 0 {
                GlassDivider()

                HStack {
                    Label(Strings.Stats.outsideCount(outdoorCount), systemImage: "leaf.fill")
                        .foregroundStyle(Color.otisSuccess)
                        .font(.subheadline)

                    Spacer()

                    if indoorCount > 0 {
                        Label(Strings.Stats.insideCount(indoorCount), systemImage: "house.fill")
                            .foregroundStyle(Color.otisDanger)
                            .font(.subheadline)
                    }
                }
            }
        }
        .cardPadding()
        .glassCard(tint: .success)
    }
}

// MARK: - Sleep Stats Card

struct SleepStatsCard: View {
    let events: [PuppyEvent]

    @Environment(\.colorScheme) private var colorScheme

    private var totalSleepMinutes: Int {
        SleepCalculations.totalSleepToday(events: events)
    }

    private var sleepSessions: Int {
        events.sleeps().count
    }

    private var goalMinutes: Int { 18 * 60 }

    private var progress: Double {
        min(1.0, Double(totalSleepMinutes) / Double(goalMinutes))
    }

    private var progressColor: Color {
        progress >= 0.8 ? Color.otisSuccess : Color.otisSleep
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(
                    value: formatSleepTime(totalSleepMinutes),
                    label: Strings.Stats.totalSlept,
                    iconName: "moon.zzz.fill",
                    iconColor: .otisSleep
                )

                GlassSeparator()

                StatItem(
                    value: "\(sleepSessions)",
                    label: Strings.Stats.naps,
                    iconName: "bed.double.fill",
                    iconColor: .otisSleep
                )
            }

            // Progress toward 18h daily sleep goal with glass styling
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(Strings.Stats.sleepGoal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)
                }

                // Glass progress bar - minimum 16pt height for accessibility
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(progressColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                            .frame(height: 16)
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
                            .frame(width: geometry.size.width * progress, height: 16)
                            .shadow(color: progressColor.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .frame(height: 16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Strings.Stats.sleepProgress)
                .accessibilityValue("\(Int(progress * 100)) \(Strings.Stats.percentOfGoal)")
            }
        }
        .cardPadding()
        .glassCard(tint: .sleep)
    }

    private func formatSleepTime(_ minutes: Int) -> String {
        DurationFormatter.format(minutes, style: .compact)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#Preview("Stat Cards") {
    ScrollView {
        VStack(spacing: 20) {
            StreakStatsCard(streakInfo: StreakInfo(
                currentStreak: 5,
                bestStreak: 12,
                lastOutdoorTime: Date(),
                lastIndoorTime: nil
            ))
            TodayStatsCard(events: [])
        }
        .padding()
    }
}
