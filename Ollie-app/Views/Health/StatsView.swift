//
//  StatsView.swift
//  Otis-app
//
//  Statistics dashboard showing potty gaps, streaks, and sleep data
//  Uses liquid glass design for iOS 26 aesthetic
//

import SwiftUI
import OtisShared

/// Full statistics view with all metrics
/// Uses liquid glass card styling throughout
struct StatsView: View {
    @ObservedObject var viewModel: TimelineViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak section
                    StreakStatsCard(streakInfo: viewModel.streakInfo)
                        .inSection(title: Strings.Stats.outdoorStreak, icon: "flame.fill", tint: .otisAccent)

                    // Potty gaps section
                    GapStatsCard(events: recentEvents)
                        .inSection(title: Strings.Stats.pottyGaps, icon: "chart.bar.fill", tint: .otisInfo)

                    // Today's summary
                    TodayStatsCard(events: todayEvents)
                        .inSection(title: Strings.Stats.today, icon: "calendar", tint: .otisSuccess)

                    // Sleep summary
                    SleepStatsCard(events: todayEvents)
                        .inSection(title: Strings.Stats.sleepToday, icon: "moon.fill", tint: .otisSleep)

                    // Pattern analysis
                    PatternAnalysisCard(analysis: viewModel.patternAnalysis)
                        .inSection(title: Strings.Stats.patterns, icon: "waveform.path.ecg", tint: .otisInfo)
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
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    return StatsView(viewModel: viewModel)
}
