//
//  HealthTabView.swift
//  Ollie-app
//
//  The "Health" tab - medical, weight, potty training, patterns, and stats
//

import SwiftUI
import OllieShared

/// Health tab showing medical timeline, weight, potty training, and stats
struct HealthTabView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var momentsViewModel: MomentsViewModel
    let onSettingsTap: () -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var milestoneStore: MilestoneStore
    @EnvironmentObject var appointmentStore: AppointmentStore

    @State private var showWeightSheet = false
    @State private var showOlliePlusSheet = false
    @State private var selectedMilestone: Milestone?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Medical milestones section (top priority)
                    if let birthDate = profileStore.profile?.birthDate {
                        medicalMilestonesSection(birthDate: birthDate)
                            .animatedAppear(delay: 0)
                    }

                    // Health section (weight tracking)
                    InsightsHealthSection(
                        latestWeight: latestWeight,
                        weightDelta: weightDelta,
                        viewModel: viewModel,
                        showWeightSheet: $showWeightSheet
                    )
                    .animatedAppear(delay: 0.05)

                    // Combined potty training section (streak + gaps)
                    pottyTrainingSection
                        .animatedAppear(delay: 0.10)

                    // Week Overview section (grid + trend chart)
                    InsightsWeekOverviewSection(weekStats: weekStats)
                        .animatedAppear(delay: 0.15)

                    // Today's summary
                    statsSection(title: Strings.Stats.today, icon: "calendar", tint: .ollieSuccess) {
                        TodayStatsCard(events: todayEvents)
                    }
                    .animatedAppear(delay: 0.20)

                    // Sleep summary
                    statsSection(title: Strings.Stats.sleepToday, icon: "moon.fill", tint: .ollieSleep) {
                        SleepStatsCard(events: todayEvents)
                    }
                    .animatedAppear(delay: 0.25)

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
                    .animatedAppear(delay: 0.30)

                    // Walk history section
                    InsightsWalkHistorySection(
                        recentWalks: recentWalks,
                        weekWalkStats: weekWalkStats
                    )
                    .animatedAppear(delay: 0.35)
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.Tabs.health)
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
            .sheet(isPresented: $showWeightSheet) {
                WeightLogSheet(isPresented: $showWeightSheet) { weight in
                    logWeight(weight)
                }
            }
            .sheet(isPresented: $showOlliePlusSheet) {
                OlliePlusSheet(
                    onDismiss: { showOlliePlusSheet = false },
                    onSubscribed: { showOlliePlusSheet = false }
                )
            }
            .sheet(item: $selectedMilestone) { milestone in
                MilestoneCompletionSheet(
                    milestone: milestone,
                    onDismiss: { selectedMilestone = nil },
                    onComplete: { notes, photoID, vetClinic, completionDate in
                        milestoneStore.completeMilestone(
                            milestone,
                            notes: notes,
                            photoID: photoID,
                            vetClinicName: vetClinic,
                            completionDate: completionDate
                        )
                        selectedMilestone = nil
                    }
                )
            }
        }
    }

    // MARK: - Computed Properties (using ViewModel caches to avoid per-frame recomputation)

    private var profile: PuppyProfile? {
        viewModel.profileStore.profile
    }

    /// Uses cached year events from ViewModel (refreshed on event changes)
    private var latestWeight: (weight: Double, date: Date)? {
        viewModel.cachedLatestWeight
    }

    /// Uses cached weight delta from ViewModel
    private var weightDelta: (delta: Double, previousDate: Date)? {
        viewModel.cachedWeightDelta
    }

    /// Uses cached recent walks from ViewModel (7 days)
    private var recentWalks: [PuppyEvent] {
        viewModel.cachedRecentWalks
    }

    /// Uses cached walk stats from ViewModel
    private var weekWalkStats: (count: Int, totalMinutes: Int) {
        viewModel.cachedWeekWalkStats
    }

    /// Today's events from in-memory array
    private var todayEvents: [PuppyEvent] {
        viewModel.events
    }

    /// Uses cached recent events from ViewModel (7 days)
    private var recentEvents: [PuppyEvent] {
        viewModel.cachedRecentEvents
    }

    /// Uses cached week stats from ViewModel (computed with batch method)
    private var weekStats: [DayStats] {
        viewModel.cachedWeekStats
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

    // MARK: - Combined Potty Training Section

    @ViewBuilder
    private var pottyTrainingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            InsightsSectionHeader(
                title: Strings.Stats.pottyTraining,
                icon: "leaf.fill",
                tint: .ollieSuccess
            )

            VStack(spacing: 12) {
                // Outdoor streak card
                StreakStatsCard(streakInfo: viewModel.streakInfo)

                // Potty gaps card
                GapStatsCard(events: recentEvents)
            }
        }
    }

    // MARK: - Medical Milestones Section

    @ViewBuilder
    private func medicalMilestonesSection(birthDate: Date) -> some View {
        let healthMilestones = milestoneStore.milestones(for: .health)
        let completedMilestones = healthMilestones.filter { $0.isCompleted }
        let upcomingMilestones = healthMilestones.filter { !$0.isCompleted }
            .sorted { ($0.targetAgeWeeks ?? 0) < ($1.targetAgeWeeks ?? 0) }

        VStack(alignment: .leading, spacing: 10) {
            // Header with View All link
            HStack {
                InsightsSectionHeader(
                    title: Strings.Health.medicalMilestones,
                    icon: "cross.case.fill",
                    tint: .ollieHealth
                )

                Spacer()

                NavigationLink {
                    MedicalTimelineView(
                        milestoneStore: milestoneStore,
                        appointmentStore: appointmentStore,
                        birthDate: birthDate,
                        puppyName: profileStore.profile?.name ?? "Puppy"
                    )
                } label: {
                    Text(Strings.Common.seeAll)
                        .font(.subheadline)
                        .foregroundStyle(Color.ollieAccent)
                }
            }

            VStack(spacing: 8) {
                // Upcoming health milestones (next 2)
                if !upcomingMilestones.isEmpty {
                    ForEach(upcomingMilestones.prefix(2)) { milestone in
                        HealthMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            isCompleted: false
                        ) {
                            selectedMilestone = milestone
                        }
                    }
                }

                // Completed health milestones (last 3)
                if !completedMilestones.isEmpty {
                    ForEach(completedMilestones.suffix(3)) { milestone in
                        HealthMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            isCompleted: true
                        ) {
                            selectedMilestone = milestone
                        }
                    }
                }

                // Empty state
                if healthMilestones.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(Strings.Health.noMedicalMilestones)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
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

// MARK: - Health Milestone Row

/// Row component for displaying a health milestone in the Health tab
private struct HealthMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.ollieSuccess.opacity(0.2) : Color.ollieHealth.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: isCompleted ? "checkmark.circle.fill" : milestone.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(isCompleted ? Color.ollieSuccess : Color.ollieHealth)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if isCompleted, let completedDate = milestone.completedDate {
                        Text(completedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                        Text(periodLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !isCompleted {
                    if let days = milestone.daysUntil(birthDate: birthDate) {
                        if days < 0 {
                            Text(Strings.Health.daysOverdue(abs(days)))
                                .font(.caption)
                                .foregroundStyle(Color.ollieWarning)
                        } else if days == 0 {
                            Text(Strings.Health.today)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.ollieHealth)
                        } else {
                            Text(Strings.Health.inDays(days))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)

    HealthTabView(
        viewModel: viewModel,
        momentsViewModel: momentsViewModel,
        onSettingsTap: { print("Settings tapped") }
    )
    .environmentObject(SubscriptionManager.shared)
    .environmentObject(profileStore)
    .environmentObject(MilestoneStore())
    .environmentObject(AppointmentStore())
}
