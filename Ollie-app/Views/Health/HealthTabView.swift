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
    @State private var showAllMilestones = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Medical milestones section (top priority)
                    if let birthDate = profileStore.profile?.birthDate {
                        medicalMilestonesSection(birthDate: birthDate)
                            .animatedAppear(delay: 0)
                    }

                    // Health section (growth story)
                    GrowthStoryCard(
                        growthStory: viewModel.cachedGrowthStory,
                        latestWeight: latestWeight,
                        firstWeight: viewModel.cachedFirstWeight,
                        weightDelta: weightDelta,
                        weighReminder: weighReminder,
                        puppyName: profileStore.profile?.name ?? "Puppy",
                        sizeCategory: profileStore.profile?.sizeCategory ?? .medium,
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
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.Tabs.health)
            .navigationBarTitleDisplayMode(.inline)
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

    /// Smart weigh reminder based on puppy age and time since last measurement
    private var weighReminder: WeighReminder? {
        guard let profile = profileStore.profile else { return nil }
        let ageInWeeks = profile.ageInWeeks
        return WeightCalculations.weighReminder(
            lastWeightDate: latestWeight?.date,
            ageInWeeks: ageInWeeks
        )
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
        let today = Date()
        let calendar = Calendar.current

        // Sort all milestones chronologically by target date
        let sortedMilestones = healthMilestones.sorted { m1, m2 in
            let date1 = m1.completedDate ?? m1.targetDate(birthDate: birthDate) ?? .distantFuture
            let date2 = m2.completedDate ?? m2.targetDate(birthDate: birthDate) ?? .distantFuture
            return date1 < date2
        }

        // Recent completed: within last 30 days, sorted most recent first
        let recentCompleted = sortedMilestones
            .filter { milestone in
                guard milestone.isCompleted, let completedDate = milestone.completedDate else { return false }
                let daysSinceCompletion = calendar.dateComponents([.day], from: completedDate, to: today).day ?? 0
                return daysSinceCompletion <= 30
            }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }

        // Upcoming: not completed, within next 90 days (or overdue), sorted by target date
        let upcomingMilestones = sortedMilestones
            .filter { milestone in
                guard !milestone.isCompleted else { return false }
                guard let targetDate = milestone.targetDate(birthDate: birthDate) else { return false }
                let daysUntil = calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
                // Include overdue (negative days) and upcoming within 90 days
                return daysUntil <= 90
            }
            .sorted { m1, m2 in
                let date1 = m1.targetDate(birthDate: birthDate) ?? .distantFuture
                let date2 = m2.targetDate(birthDate: birthDate) ?? .distantFuture
                return date1 < date2
            }

        // Determine what to show in collapsed vs expanded state
        let collapsedUpcomingCount = min(2, upcomingMilestones.count)
        let collapsedCompletedCount = min(1, recentCompleted.count)
        let hasMoreToShow = upcomingMilestones.count > collapsedUpcomingCount ||
                           recentCompleted.count > collapsedCompletedCount

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
                // Upcoming health milestones (next up first - overdue items appear first)
                if !upcomingMilestones.isEmpty {
                    let displayCount = showAllMilestones ? upcomingMilestones.count : collapsedUpcomingCount
                    ForEach(upcomingMilestones.prefix(displayCount)) { milestone in
                        HealthMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            isCompleted: false
                        ) {
                            selectedMilestone = milestone
                        }
                    }
                }

                // Recently completed milestones
                if !recentCompleted.isEmpty {
                    let displayCount = showAllMilestones ? recentCompleted.count : collapsedCompletedCount
                    ForEach(recentCompleted.prefix(displayCount)) { milestone in
                        HealthMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            isCompleted: true
                        ) {
                            selectedMilestone = milestone
                        }
                    }
                }

                // Show more/less button
                if hasMoreToShow {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAllMilestones.toggle()
                        }
                    } label: {
                        HStack {
                            Text(showAllMilestones ? Strings.Common.tapToCollapse : Strings.Common.tapToExpand)
                                .font(.subheadline)
                            Image(systemName: showAllMilestones ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.ollieAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }

                // Empty state (only if no relevant milestones at all)
                if upcomingMilestones.isEmpty && recentCompleted.isEmpty {
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
