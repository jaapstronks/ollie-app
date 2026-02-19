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
                    statsSection(title: "Buiten Streak", icon: "flame.fill", tint: .ollieAccent) {
                        StreakStatsCard(streakInfo: viewModel.streakInfo)
                    }

                    // Potty gaps section
                    statsSection(title: "Plas Intervallen (7 dagen)", icon: "chart.bar.fill", tint: .ollieInfo) {
                        GapStatsCard(events: recentEvents)
                    }

                    // Today's summary
                    statsSection(title: "Vandaag", icon: "calendar", tint: .ollieSuccess) {
                        TodayStatsCard(events: todayEvents)
                    }

                    // Sleep summary
                    statsSection(title: "Slaap Vandaag", icon: "moon.fill", tint: .ollieSleep) {
                        SleepStatsCard(events: todayEvents)
                    }

                    // Pattern analysis
                    statsSection(title: "Patronen (7 dagen)", icon: "waveform.path.ecg", tint: .ollieInfo) {
                        PatternAnalysisCard(analysis: viewModel.patternAnalysis)
                    }
                }
                .padding()
            }
            .navigationTitle("Statistieken")
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

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            content()
        }
    }
}

// MARK: - Streak Stats Card

struct StreakStatsCard: View {
    let streakInfo: StreakInfo

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(
                    value: "\(streakInfo.currentStreak)",
                    label: "Huidige streak",
                    emoji: StreakCalculations.emoji(for: streakInfo.currentStreak)
                )

                glassSeperator

                StatItem(
                    value: "\(streakInfo.bestStreak)",
                    label: "Beste ooit",
                    emoji: "🏆"
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

    private var glassSeperator: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.08))
            .frame(width: 1, height: 40)
    }
}

// MARK: - Gap Stats Card

struct GapStatsCard: View {
    let events: [PuppyEvent]

    @Environment(\.colorScheme) private var colorScheme

    private var gaps: [PottyGap] {
        GapCalculations.recentGaps(events: events, days: 7)
    }

    private var stats: GapStats {
        GapCalculations.calculateGapStats(gaps: gaps)
    }

    var body: some View {
        VStack(spacing: 12) {
            if stats.count == 0 {
                Text("Nog niet genoeg data")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                HStack {
                    StatItem(
                        value: GapCalculations.formatDuration(stats.medianMinutes),
                        label: "Mediaan",
                        emoji: "📊"
                    )

                    glassSeperator

                    StatItem(
                        value: GapCalculations.formatDuration(stats.avgMinutes),
                        label: "Gemiddeld",
                        emoji: "📈"
                    )
                }

                glassDivider

                HStack {
                    StatItem(
                        value: GapCalculations.formatDuration(stats.minMinutes),
                        label: "Kortste",
                        emoji: "⚡️"
                    )

                    glassSeperator

                    StatItem(
                        value: GapCalculations.formatDuration(stats.maxMinutes),
                        label: "Langste",
                        emoji: "🐢"
                    )
                }

                glassDivider

                // Indoor vs outdoor breakdown
                HStack {
                    Label("\(stats.outdoorCount) buiten", systemImage: "leaf.fill")
                        .foregroundStyle(Color.ollieSuccess)
                        .font(.subheadline)

                    Spacer()

                    Label("\(stats.indoorCount) binnen", systemImage: "house.fill")
                        .foregroundStyle(stats.indoorCount > 0 ? Color.ollieDanger : .secondary)
                        .font(.subheadline)

                    Spacer()

                    Text("\(stats.outdoorPercentage)% buiten")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stats.outdoorPercentage >= 80 ? Color.ollieSuccess : Color.ollieWarning)
                }
            }
        }
        .padding()
        .glassCard(tint: .info)
    }

    private var glassSeperator: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.08))
            .frame(width: 1, height: 40)
    }

    private var glassDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06))
            .frame(height: 1)
    }
}

// MARK: - Today Stats Card

struct TodayStatsCard: View {
    let events: [PuppyEvent]

    @Environment(\.colorScheme) private var colorScheme

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
                    label: "Keer geplast",
                    emoji: "🚽"
                )

                glassSeperator

                StatItem(
                    value: "\(mealCount)",
                    label: "Maaltijden",
                    emoji: "🍽️"
                )

                glassSeperator

                StatItem(
                    value: "\(poopCount)",
                    label: "Keer gepoept",
                    emoji: "💩"
                )
            }

            if pottyCount > 0 {
                glassDivider

                HStack {
                    Label("\(outdoorCount) buiten", systemImage: "leaf.fill")
                        .foregroundStyle(Color.ollieSuccess)
                        .font(.subheadline)

                    Spacer()

                    if indoorCount > 0 {
                        Label("\(indoorCount) binnen", systemImage: "house.fill")
                            .foregroundStyle(Color.ollieDanger)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .glassCard(tint: .success)
    }

    private var glassSeperator: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.08))
            .frame(width: 1, height: 40)
    }

    private var glassDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06))
            .frame(height: 1)
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
                    label: "Totaal geslapen",
                    emoji: "😴"
                )

                glassSeperator

                StatItem(
                    value: "\(sleepSessions)",
                    label: "Dutjes",
                    emoji: "🛏️"
                )
            }

            // Progress toward 18h daily sleep goal with glass styling
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Doel: 18 uur")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)
                }

                // Glass progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(progressColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                            .frame(height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(progressColor.opacity(0.2), lineWidth: 0.5)
                            )

                        RoundedRectangle(cornerRadius: 5)
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
                            .frame(width: geometry.size.width * progress, height: 10)
                            .shadow(color: progressColor.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding()
        .glassCard(tint: .sleep)
    }

    private var glassSeperator: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.08))
            .frame(width: 1, height: 40)
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

    /// Legacy initializer with emoji (will be removed)
    init(value: String, label: String, emoji: String) {
        self.value = value
        self.label = label
        // Map common emoji to icons
        switch emoji {
        case "🔥", "🔥🔥", "🔥🔥🔥": self.iconName = "flame.fill"; self.iconColor = .ollieAccent
        case "💔": self.iconName = "heart.slash.fill"; self.iconColor = .ollieDanger
        case "👍": self.iconName = "hand.thumbsup.fill"; self.iconColor = .ollieSuccess
        case "🏆": self.iconName = "trophy.fill"; self.iconColor = .ollieAccent
        case "📊": self.iconName = "chart.bar.fill"; self.iconColor = .ollieInfo
        case "📈": self.iconName = "chart.line.uptrend.xyaxis"; self.iconColor = .ollieInfo
        case "⚡️": self.iconName = "bolt.fill"; self.iconColor = .ollieWarning
        case "🐢": self.iconName = "tortoise.fill"; self.iconColor = .ollieMuted
        case "🚽": self.iconName = "drop.fill"; self.iconColor = .ollieInfo
        case "🍽️": self.iconName = "fork.knife"; self.iconColor = .ollieAccent
        case "💩": self.iconName = "circle.inset.filled"; self.iconColor = .ollieAccent
        case "😴": self.iconName = "moon.fill"; self.iconColor = .ollieSleep
        case "🛏️": self.iconName = "bed.double.fill"; self.iconColor = .ollieSleep
        default: self.iconName = "circle.fill"; self.iconColor = .ollieMuted
        }
    }

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

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    return StatsView(viewModel: viewModel)
}
