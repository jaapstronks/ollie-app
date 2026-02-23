//
//  InsightsView.swift
//  Ollie-app
//
//  The "Inzichten" (Stats) tab - patterns, stats, health, walks, and spots
//  Expanded to include content from Health, Walk history, and Spots

import SwiftUI
import MapKit

/// Stats tab showing patterns, stats, health, walks, and spots
struct InsightsView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var momentsViewModel: MomentsViewModel
    @ObservedObject var spotStore: SpotStore

    @EnvironmentObject var locationManager: LocationManager

    @State private var showWeightSheet = false
    @State private var showAllSpots = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Week Overview section (grid + trend chart)
                    weekOverviewSection

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

                    // Health section
                    healthSection

                    // Walk history section
                    walkHistorySection

                    // Spots section
                    spotsSection
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.Insights.title)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showWeightSheet) {
                WeightLogSheet(isPresented: $showWeightSheet) { weight in
                    logWeight(weight)
                }
            }
            .sheet(isPresented: $showAllSpots) {
                AllSpotsMapView(spots: spotStore.spots)
            }
        }
    }

    // MARK: - Additional Computed Properties

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

    // MARK: - Data

    private var todayEvents: [PuppyEvent] {
        viewModel.events
    }

    private var recentEvents: [PuppyEvent] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return viewModel.eventStore.getEvents(from: sevenDaysAgo, to: Date())
    }

    /// Calculate week stats for the grid and trend chart
    private var weekStats: [DayStats] {
        WeekCalculations.calculateWeekStats { date in
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            return viewModel.eventStore.getEvents(from: startOfDay, to: endOfDay)
        }
    }

    // MARK: - Week Overview Section

    @ViewBuilder
    private var weekOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ollieInfo)
                    .accessibilityHidden(true)

                Text(Strings.Insights.weekOverview)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)

            // Week grid
            WeekGridView(weekStats: weekStats)

            // Potty trend chart
            PottyTrendChart(weekStats: weekStats)
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

    // MARK: - Health Section

    @ViewBuilder
    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader(
                    title: Strings.Stats.health,
                    icon: "heart.fill",
                    tint: .ollieDanger
                )

                Spacer()

                // See all link
                NavigationLink {
                    HealthView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 4) {
                        Text(Strings.Common.seeAll)
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ollieAccent)
                }
            }

            // Weight summary card
            VStack(spacing: 12) {
                if let latest = latestWeight {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Health.weight)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(WeightCalculations.formatWeight(latest.weight))
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        // Delta badge
                        if let delta = weightDelta {
                            HStack(spacing: 4) {
                                Image(systemName: delta.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption)
                                Text(WeightCalculations.formatDelta(delta.delta))
                                    .font(.caption)
                            }
                            .foregroundStyle(delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (delta.delta >= 0 ? Color.ollieSuccess : Color.ollieWarning)
                                    .opacity(colorScheme == .dark ? 0.2 : 0.1)
                            )
                            .clipShape(Capsule())
                        }
                    }

                    // Log weight button
                    Button {
                        showWeightSheet = true
                    } label: {
                        Label(Strings.Health.logWeight, systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .cornerRadius(8)
                } else {
                    // Empty state
                    VStack(spacing: 8) {
                        Text(Strings.Health.noWeightData)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            showWeightSheet = true
                        } label: {
                            Label(Strings.Health.logWeight, systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.ollieAccent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding()
            .glassCard(tint: .danger)
        }
    }

    private func logWeight(_ weight: Double) {
        let event = PuppyEvent(
            time: Date(),
            type: .gewicht,
            weightKg: weight
        )
        viewModel.addEvent(event)
    }

    // MARK: - Walk History Section

    @ViewBuilder
    private var walkHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: Strings.Stats.walkHistory,
                icon: "figure.walk",
                tint: .ollieAccent
            )

            VStack(spacing: 12) {
                // Week summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Stats.thisWeek)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            // Walk count
                            HStack(spacing: 4) {
                                Text("\(weekWalkStats.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(Strings.WalksTab.walks)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            // Total duration
                            if weekWalkStats.totalMinutes > 0 {
                                HStack(spacing: 4) {
                                    Text("\(weekWalkStats.totalMinutes)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(Strings.Common.minutes)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "figure.walk")
                        .font(.title)
                        .foregroundStyle(Color.ollieAccent)
                }

                // Recent walks list (last 5)
                if !recentWalks.isEmpty {
                    Divider()

                    ForEach(Array(recentWalks.prefix(5))) { walk in
                        walkRow(walk)
                    }
                }
            }
            .padding()
            .glassCard(tint: .accent)
        }
    }

    @ViewBuilder
    private func walkRow(_ walk: PuppyEvent) -> some View {
        HStack(spacing: 12) {
            // Date
            Text(walk.time, format: .dateTime.weekday(.abbreviated).hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            // Duration
            if let duration = walk.durationMin {
                Text("\(duration) \(Strings.Common.minutes)")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // Spot name
            if let spotName = walk.spotName {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(spotName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Spots Section

    @ViewBuilder
    private var spotsSection: some View {
        if !spotStore.spots.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionHeader(
                        title: Strings.Stats.spots,
                        icon: "map.fill",
                        tint: .ollieSuccess
                    )

                    Spacer()

                    // See all link
                    Button {
                        showAllSpots = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(Strings.Common.seeAll)
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.ollieAccent)
                    }
                }

                VStack(spacing: 12) {
                    // Mini map preview
                    AllSpotsPreviewMap(spots: spotStore.spots)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onTapGesture {
                            showAllSpots = true
                        }

                    // Favorite spots (top 3)
                    let favorites = spotStore.favoriteSpots.prefix(3)
                    if !favorites.isEmpty {
                        Divider()

                        ForEach(Array(favorites)) { spot in
                            NavigationLink {
                                SpotDetailView(spotStore: spotStore, spot: spot)
                            } label: {
                                spotRow(spot)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .glassCard(tint: .success)
            }
        }
    }

    @ViewBuilder
    private func spotRow(_ spot: WalkSpot) -> some View {
        HStack(spacing: 12) {
            Image(systemName: spot.isFavorite ? "star.fill" : "mappin.circle.fill")
                .font(.body)
                .foregroundStyle(spot.isFavorite ? .yellow : Color.ollieAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if spot.visitCount > 0 {
                    Text(Strings.WalkLocations.visitCount(spot.visitCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Section Header Helper

    @ViewBuilder
    private func sectionHeader(title: String, icon: String, tint: Color) -> some View {
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
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)
    let spotStore = SpotStore()

    return InsightsView(
        viewModel: viewModel,
        momentsViewModel: momentsViewModel,
        spotStore: spotStore
    )
    .environmentObject(LocationManager())
}
