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
    @StateObject private var contributionViewModel: ContributionStatsViewModel

    init(viewModel: TimelineViewModel) {
        self.viewModel = viewModel
        _contributionViewModel = StateObject(wrappedValue: ContributionStatsViewModel(eventStore: viewModel.eventStore))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker for contributions
                    if contributionViewModel.currentUserStats != nil {
                        ContributionPeriodPicker(selectedPeriod: $contributionViewModel.selectedPeriod)
                            .onChange(of: contributionViewModel.selectedPeriod) { _, newPeriod in
                                contributionViewModel.selectPeriod(newPeriod)
                                Analytics.track(.contributionStatsViewed, properties: [
                                    "period": newPeriod.rawValue,
                                    "is_team": contributionViewModel.hasTeam
                                ])
                            }
                    }

                    // Team contributions section (only show if team has multiple members)
                    if contributionViewModel.hasTeam, let summary = contributionViewModel.summary {
                        TeamContributionCard(
                            stats: contributionViewModel.stats,
                            period: contributionViewModel.selectedPeriod,
                            summary: summary
                        )
                        .inSection(title: OtisShared.Strings.ContributionStats.teamContributions, icon: "person.3.fill", tint: .otisAccent)
                    } else if let userStats = contributionViewModel.currentUserStats {
                        // Show individual stats if solo user
                        YourContributionCard(
                            stat: userStats,
                            period: contributionViewModel.selectedPeriod
                        )
                        .inSection(title: OtisShared.Strings.ContributionStats.yourContributions, icon: "person.fill", tint: .otisAccent)
                    }

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
            .onAppear {
                contributionViewModel.refresh()
            }
        }
    }

    private var todayEvents: [PuppyEvent] {
        viewModel.events
    }

    private var recentEvents: [PuppyEvent] {
        viewModel.eventStore.getEvents(from: Date.daysAgo(7), to: Date())
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    return StatsView(viewModel: viewModel)
}
