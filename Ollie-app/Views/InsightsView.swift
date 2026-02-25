//
//  InsightsView.swift
//  Ollie-app
//
//  The "Inzichten" (Stats) tab - patterns, stats, health, walks, and spots
//

import SwiftUI
import OllieShared
import MapKit

/// Stats tab showing patterns, stats, health, walks, and spots
struct InsightsView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var momentsViewModel: MomentsViewModel
    @ObservedObject var spotStore: SpotStore
    let onSettingsTap: () -> Void

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var showWeightSheet = false
    @State private var showAllSpots = false
    @State private var showOlliePlusSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Week Overview section (grid + trend chart)
                    InsightsWeekOverviewSection(weekStats: weekStats)
                        .animatedAppear(delay: 0)

                    // Streak section
                    statsSection(title: Strings.Stats.outdoorStreak, icon: "flame.fill", tint: .ollieAccent) {
                        StreakStatsCard(streakInfo: viewModel.streakInfo)
                    }
                    .animatedAppear(delay: 0.05)

                    // Potty gaps section
                    statsSection(title: Strings.Stats.pottyGaps, icon: "chart.bar.fill", tint: .ollieInfo) {
                        GapStatsCard(events: recentEvents)
                    }
                    .animatedAppear(delay: 0.10)

                    // Today's summary
                    statsSection(title: Strings.Stats.today, icon: "calendar", tint: .ollieSuccess) {
                        TodayStatsCard(events: todayEvents)
                    }
                    .animatedAppear(delay: 0.15)

                    // Sleep summary
                    statsSection(title: Strings.Stats.sleepToday, icon: "moon.fill", tint: .ollieSleep) {
                        SleepStatsCard(events: todayEvents)
                    }
                    .animatedAppear(delay: 0.20)

                    // Pattern analysis (Ollie+ feature)
                    Group {
                        if subscriptionManager.hasAccess(to: .advancedAnalytics) {
                            statsSection(title: Strings.Stats.patterns, icon: "waveform.path.ecg", tint: .ollieInfo) {
                                PatternAnalysisCard(analysis: viewModel.patternAnalysis)
                            }
                        } else {
                            LockedFeatureCard(
                                title: Strings.OlliePlus.lockedPatterns,
                                description: Strings.OlliePlus.lockedPatternsDesc,
                                icon: "waveform.path.ecg",
                                onUnlock: { showOlliePlusSheet = true }
                            )
                        }
                    }
                    .animatedAppear(delay: 0.25)

                    // Health section
                    InsightsHealthSection(
                        latestWeight: latestWeight,
                        weightDelta: weightDelta,
                        viewModel: viewModel,
                        showWeightSheet: $showWeightSheet
                    )
                    .animatedAppear(delay: 0.30)

                    // Walk history section
                    InsightsWalkHistorySection(
                        recentWalks: recentWalks,
                        weekWalkStats: weekWalkStats
                    )
                    .animatedAppear(delay: 0.35)

                    // Spots section
                    InsightsSpotsSection(
                        spotStore: spotStore,
                        showAllSpots: $showAllSpots
                    )
                    .animatedAppear(delay: 0.40)
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.Insights.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSettingsTap()
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel(Strings.Tabs.settings)
                }
            }
            .sheet(isPresented: $showWeightSheet) {
                WeightLogSheet(isPresented: $showWeightSheet) { weight in
                    logWeight(weight)
                }
            }
            .sheet(isPresented: $showAllSpots) {
                AllSpotsMapView(spots: spotStore.spots)
            }
            .sheet(isPresented: $showOlliePlusSheet) {
                OlliePlusSheet(
                    onDismiss: { showOlliePlusSheet = false },
                    onSubscribed: { showOlliePlusSheet = false }
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        viewModel.profileStore.profile
    }

    private var allEvents: [PuppyEvent] {
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return viewModel.eventStore.getEvents(from: oneYearAgo, to: Date())
    }

    private var latestWeight: (weight: Double, date: Date)? {
        WeightCalculations.latestWeight(events: allEvents)
    }

    private var weightDelta: (delta: Double, previousDate: Date)? {
        WeightCalculations.weightDelta(events: allEvents)
    }

    private var recentWalks: [PuppyEvent] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return viewModel.eventStore.getEvents(from: sevenDaysAgo, to: Date()).walks()
    }

    private var weekWalkStats: (count: Int, totalMinutes: Int) {
        let walks = recentWalks
        let totalMinutes = walks.compactMap { $0.durationMin }.reduce(0, +)
        return (walks.count, totalMinutes)
    }

    private var todayEvents: [PuppyEvent] {
        viewModel.events
    }

    private var recentEvents: [PuppyEvent] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return viewModel.eventStore.getEvents(from: sevenDaysAgo, to: Date())
    }

    private var weekStats: [DayStats] {
        WeekCalculations.calculateWeekStats { date in
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            return viewModel.eventStore.getEvents(from: startOfDay, to: endOfDay)
        }
    }

    // MARK: - Stats Section Builder

    @ViewBuilder
    private func statsSection<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightsSectionHeader(title: title, icon: icon, tint: tint)
            content()
        }
    }

    // MARK: - Actions

    private func logWeight(_ weight: Double) {
        let event = PuppyEvent(
            time: Date(),
            type: .gewicht,
            weightKg: weight
        )
        viewModel.addEvent(event)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)
    let spotStore = SpotStore()

    InsightsView(
        viewModel: viewModel,
        momentsViewModel: momentsViewModel,
        spotStore: spotStore,
        onSettingsTap: { print("Settings tapped") }
    )
    .environmentObject(LocationManager())
    .environmentObject(SubscriptionManager.shared)
}
