//
//  StatsView.swift
//  Ollie-app
//
//  Statistics dashboard showing potty gaps, streaks, and sleep data
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI

/// Full statistics view with all metrics
/// Uses liquid glass card styling throughout
struct StatsView: View {
    @ObservedObject var viewModel: TimelineViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak section
                    statsSection(title: Strings.Stats.outdoorStreak, icon: "flame.fill", tint: .ollieAccent) {
                        StreakStatsCard(streakInfo: viewModel.streakInfo)
                    }

                    // Potty gaps section
                    statsSection(title: Strings.Stats.pottyGaps, icon: "chart.bar.fill", tint: .ollieInfo) {
                        GapStatsCard(events: recentEvents)
                    }

                    // Today's summary
                    statsSection(title: Strings.Stats.today, icon: "calendar", tint: .ollieSuccess) {
                        TodayStatsCard(events: todayEvents)
                    }

                    // Sleep summary
                    statsSection(title: Strings.Stats.sleepToday, icon: "moon.fill", tint: .ollieSleep) {
                        SleepStatsCard(events: todayEvents)
                    }

                    // Pattern analysis
                    statsSection(title: Strings.Stats.patterns, icon: "waveform.path.ecg", tint: .ollieInfo) {
                        PatternAnalysisCard(analysis: viewModel.patternAnalysis)
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Stats.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var todayEvents: [PuppyEvent] {
        viewModel.events
    }

    private var recentEvents: [PuppyEvent] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return viewModel.eventStore.getEvents(from: sevenDaysAgo, to: Date())
    }

    @ViewBuilder
    private func statsSection<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header with icon
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)

            content()
        }
    }
}

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
                    iconColor: .ollieAccent
                )
            }

            if streakInfo.currentStreak > 0 {
                Text(StreakCalculations.message(for: streakInfo.currentStreak))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ollieAccent)
            }
        }
        .padding()
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
                        iconColor: .ollieInfo
                    )

                    GlassSeparator()

                    StatItem(
                        value: GapCalculations.formatDuration(stats.avgMinutes),
                        label: Strings.Stats.average,
                        iconName: "chart.line.uptrend.xyaxis",
                        iconColor: .ollieInfo
                    )
                }

                GlassDivider()

                HStack {
                    StatItem(
                        value: GapCalculations.formatDuration(stats.minMinutes),
                        label: Strings.Stats.shortest,
                        iconName: "bolt.fill",
                        iconColor: .ollieWarning
                    )

                    GlassSeparator()

                    StatItem(
                        value: GapCalculations.formatDuration(stats.maxMinutes),
                        label: Strings.Stats.longest,
                        iconName: "tortoise.fill",
                        iconColor: .ollieMuted
                    )
                }

                GlassDivider()

                // Indoor vs outdoor breakdown
                HStack {
                    Label(Strings.Stats.outsideCount(stats.outdoorCount), systemImage: "leaf.fill")
                        .foregroundStyle(Color.ollieSuccess)
                        .font(.subheadline)

                    Spacer()

                    Label(Strings.Stats.insideCount(stats.indoorCount), systemImage: "house.fill")
                        .foregroundStyle(stats.indoorCount > 0 ? Color.ollieDanger : .secondary)
                        .font(.subheadline)

                    Spacer()

                    Text("\(stats.outdoorPercentage)\(Strings.Stats.outsidePercent)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stats.outdoorPercentage >= 80 ? Color.ollieSuccess : Color.ollieWarning)
                }
            }
        }
        .padding()
        .glassCard(tint: .info)
    }
}

// MARK: - Today Stats Card

struct TodayStatsCard: View {
    let events: [PuppyEvent]

    private var pottyCount: Int {
        events.filter { $0.type == .plassen }.count
    }

    private var outdoorCount: Int {
        events.filter { $0.type == .plassen && $0.location == .buiten }.count
    }

    private var indoorCount: Int {
        events.filter { $0.type == .plassen && $0.location == .binnen }.count
    }

    private var mealCount: Int {
        events.filter { $0.type == .eten }.count
    }

    private var poopCount: Int {
        events.filter { $0.type == .poepen }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(
                    value: "\(pottyCount)",
                    label: Strings.Stats.timesPeed,
                    iconName: "drop.fill",
                    iconColor: .ollieInfo
                )

                GlassSeparator()

                StatItem(
                    value: "\(mealCount)",
                    label: Strings.Stats.meals,
                    iconName: "fork.knife",
                    iconColor: .ollieAccent
                )

                GlassSeparator()

                StatItem(
                    value: "\(poopCount)",
                    label: Strings.Stats.timesPooped,
                    iconName: "circle.inset.filled",
                    iconColor: .ollieAccent
                )
            }

            if pottyCount > 0 {
                GlassDivider()

                HStack {
                    Label(Strings.Stats.outsideCount(outdoorCount), systemImage: "leaf.fill")
                        .foregroundStyle(Color.ollieSuccess)
                        .font(.subheadline)

                    Spacer()

                    if indoorCount > 0 {
                        Label(Strings.Stats.insideCount(indoorCount), systemImage: "house.fill")
                            .foregroundStyle(Color.ollieDanger)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
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
        events.filter { $0.type == .slapen }.count
    }

    private var goalMinutes: Int { 18 * 60 }

    private var progress: Double {
        min(1.0, Double(totalSleepMinutes) / Double(goalMinutes))
    }

    private var progressColor: Color {
        progress >= 0.8 ? Color.ollieSuccess : Color.ollieSleep
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(
                    value: formatSleepTime(totalSleepMinutes),
                    label: Strings.Stats.totalSlept,
                    iconName: "moon.zzz.fill",
                    iconColor: .ollieSleep
                )

                GlassSeparator()

                StatItem(
                    value: "\(sleepSessions)",
                    label: Strings.Stats.naps,
                    iconName: "bed.double.fill",
                    iconColor: .ollieSleep
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
        .padding()
        .glassCard(tint: .sleep)
    }

    private func formatSleepTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 {
            return "\(mins) min"
        } else if mins == 0 {
            return "\(hours) uur"
        } else {
            return "\(hours)u \(mins)m"
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String
    let iconName: String
    let iconColor: Color

    init(value: String, label: String, iconName: String, iconColor: Color) {
        self.value = value
        self.label = label
        self.iconName = iconName
        self.iconColor = iconColor
    }

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

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    return StatsView(viewModel: viewModel)
}
