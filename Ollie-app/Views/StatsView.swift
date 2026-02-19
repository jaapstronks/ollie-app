//
//  StatsView.swift
//  Ollie-app
//
//  Statistics dashboard showing potty gaps, streaks, and sleep data

import SwiftUI

/// Full statistics view with all metrics
struct StatsView: View {
    @ObservedObject var viewModel: TimelineViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Streak section
                    statsSection(title: "Buiten Streak") {
                        StreakStatsCard(streakInfo: viewModel.streakInfo)
                    }

                    // Potty gaps section
                    statsSection(title: "Plas Intervallen (7 dagen)") {
                        GapStatsCard(events: recentEvents)
                    }

                    // Today's summary
                    statsSection(title: "Vandaag") {
                        TodayStatsCard(events: todayEvents)
                    }

                    // Sleep summary
                    statsSection(title: "Slaap Vandaag") {
                        SleepStatsCard(events: todayEvents)
                    }

                    // Pattern analysis
                    statsSection(title: "Patronen (7 dagen)") {
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
    private func statsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

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
                    label: "Huidige streak",
                    emoji: StreakCalculations.emoji(for: streakInfo.currentStreak)
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: "\(streakInfo.bestStreak)",
                    label: "Beste ooit",
                    emoji: "🏆"
                )
            }

            if streakInfo.currentStreak > 0 {
                Text(StreakCalculations.message(for: streakInfo.currentStreak))
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
                Text("Nog niet genoeg data")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                HStack {
                    StatItem(
                        value: GapCalculations.formatDuration(stats.medianMinutes),
                        label: "Mediaan",
                        emoji: "📊"
                    )

                    Divider()
                        .frame(height: 40)

                    StatItem(
                        value: GapCalculations.formatDuration(stats.avgMinutes),
                        label: "Gemiddeld",
                        emoji: "📈"
                    )
                }

                Divider()

                HStack {
                    StatItem(
                        value: GapCalculations.formatDuration(stats.minMinutes),
                        label: "Kortste",
                        emoji: "⚡️"
                    )

                    Divider()
                        .frame(height: 40)

                    StatItem(
                        value: GapCalculations.formatDuration(stats.maxMinutes),
                        label: "Langste",
                        emoji: "🐢"
                    )
                }

                Divider()

                // Indoor vs outdoor breakdown
                HStack {
                    Label("\(stats.outdoorCount) buiten", systemImage: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)

                    Spacer()

                    Label("\(stats.indoorCount) binnen", systemImage: "house.fill")
                        .foregroundColor(stats.indoorCount > 0 ? .orange : .secondary)
                        .font(.subheadline)

                    Spacer()

                    Text("\(stats.outdoorPercentage)% buiten")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(stats.outdoorPercentage >= 80 ? .green : .orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
                    label: "Keer geplast",
                    emoji: "🚽"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: "\(mealCount)",
                    label: "Maaltijden",
                    emoji: "🍽️"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: "\(poopCount)",
                    label: "Keer gepoept",
                    emoji: "💩"
                )
            }

            if pottyCount > 0 {
                Divider()

                HStack {
                    Label("\(outdoorCount) buiten", systemImage: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)

                    Spacer()

                    if indoorCount > 0 {
                        Label("\(indoorCount) binnen", systemImage: "house.fill")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sleep Stats Card

struct SleepStatsCard: View {
    let events: [PuppyEvent]

    private var totalSleepMinutes: Int {
        SleepCalculations.totalSleepToday(events: events)
    }

    private var sleepSessions: Int {
        events.filter { $0.type == .slapen }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(
                    value: formatSleepTime(totalSleepMinutes),
                    label: "Totaal geslapen",
                    emoji: "😴"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: "\(sleepSessions)",
                    label: "Dutjes",
                    emoji: "🛏️"
                )
            }

            // Progress toward 18h daily sleep goal
            let goalMinutes = 18 * 60
            let progress = min(1.0, Double(totalSleepMinutes) / Double(goalMinutes))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Doel: 18 uur")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(progress >= 0.8 ? .green : .orange)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress >= 0.8 ? Color.green : Color.orange)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
    let emoji: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)

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
