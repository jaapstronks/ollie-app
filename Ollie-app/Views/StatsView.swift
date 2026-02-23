//
//  StatsView.swift
//  Ollie-app
//
//  Statistics dashboard showing potty gaps, streaks, and sleep data
//  Uses liquid glass design for iOS 26 aesthetic
//

import SwiftUI
import OllieShared

/// Full statistics view with all metrics
/// Uses liquid glass card styling throughout
struct StatsView: View {
    @ObservedObject var viewModel: TimelineViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak section
                    StreakStatsCard(streakInfo: viewModel.streakInfo)
                        .inSection(title: Strings.Stats.outdoorStreak, icon: "flame.fill", tint: .ollieAccent)

                    // Potty gaps section
                    GapStatsCard(events: recentEvents)
                        .inSection(title: Strings.Stats.pottyGaps, icon: "chart.bar.fill", tint: .ollieInfo)

                    // Today's summary
                    TodayStatsCard(events: todayEvents)
                        .inSection(title: Strings.Stats.today, icon: "calendar", tint: .ollieSuccess)

                    // Sleep summary
                    SleepStatsCard(events: todayEvents)
                        .inSection(title: Strings.Stats.sleepToday, icon: "moon.fill", tint: .ollieSleep)

                    // Pattern analysis
                    PatternAnalysisCard(analysis: viewModel.patternAnalysis)
                        .inSection(title: Strings.Stats.patterns, icon: "waveform.path.ecg", tint: .ollieInfo)
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
