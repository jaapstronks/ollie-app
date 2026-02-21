//
//  InsightsView.swift
//  Ollie-app
//
//  The "Inzichten" (Insights) tab - patterns, stats, and navigation to detail views
//  Combines stats with navigation links to Training, Health, and Moments

import SwiftUI

/// Insights tab showing patterns, stats, and navigation to detail views
struct InsightsView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var momentsViewModel: MomentsViewModel

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

                    // Explore section with navigation links
                    exploreSection
                }
                .padding()
            }
            .navigationTitle(Strings.Insights.title)
            .navigationBarTitleDisplayMode(.large)
        }
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

    // MARK: - Explore Section

    @ViewBuilder
    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ollieAccent)
                    .accessibilityHidden(true)

                Text(Strings.Insights.explore)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)

            // Navigation cards
            VStack(spacing: 12) {
                // Training card
                NavigationLink {
                    TrainingView(eventStore: viewModel.eventStore)
                } label: {
                    exploreCard(
                        icon: "graduationcap.fill",
                        title: Strings.Insights.training,
                        description: Strings.Insights.trainingDescription,
                        tint: .ollieAccent
                    )
                }
                .buttonStyle(.plain)

                // Health card
                NavigationLink {
                    HealthView(viewModel: viewModel)
                } label: {
                    exploreCard(
                        icon: "heart.fill",
                        title: Strings.Insights.health,
                        description: Strings.Insights.healthDescription,
                        tint: .ollieDanger
                    )
                }
                .buttonStyle(.plain)

                // Moments card
                NavigationLink {
                    MomentsGalleryView(viewModel: momentsViewModel)
                } label: {
                    exploreCard(
                        icon: "photo.on.rectangle.angled",
                        title: Strings.Insights.momentsTitle,
                        description: Strings.Insights.momentsDescription,
                        tint: .ollieInfo
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func exploreCard(
        icon: String,
        title: String,
        description: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tint)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(exploreCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(exploreCardOverlay)
    }

    @ViewBuilder
    private var exploreCardBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.06)
            } else {
                Color.white.opacity(0.8)
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var exploreCardOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)

    return InsightsView(viewModel: viewModel, momentsViewModel: momentsViewModel)
}
