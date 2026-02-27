//
//  PlanSection.swift
//  Ollie-app
//
//  Plan section for InsightsView - age stage, socialization, milestones

import SwiftUI
import OllieShared

/// Plan section showing puppy age, socialization progress, and upcoming milestones
struct PlanSection: View {
    @ObservedObject var socializationStore: SocializationStore
    @ObservedObject var milestoneStore: MilestoneStore
    @EnvironmentObject var profileStore: ProfileStore

    @State private var showMilestoneDetail = false
    @State private var selectedMilestone: Milestone?
    @State private var showWeekDetail = false
    @State private var selectedWeek: WeeklyProgress?

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var ageInWeeks: Int {
        profile?.ageInWeeks ?? 0
    }

    private var upcomingMilestones: [Milestone] {
        guard let birthDate = profile?.birthDate else { return [] }
        return milestoneStore.upcomingMilestones(birthDate: birthDate, withinDays: 14)
            .prefix(3)
            .map { $0 }
    }

    private var overdueMilestones: [Milestone] {
        guard let birthDate = profile?.birthDate else { return [] }
        return milestoneStore.overdueMilestones(birthDate: birthDate)
    }

    private var weeklyProgress: [WeeklyProgress] {
        guard let profile = profile else { return [] }
        return socializationStore.allWeeklyProgress(profile: profile)
    }

    private var showSocializationTimeline: Bool {
        guard let profile = profile else { return false }
        return profile.ageInMonths < 6
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Error banner (if store has error)
            if let error = milestoneStore.lastError {
                errorBanner(message: error.message)
            }

            // Age stage header
            ageStageHeader

            // Socialization week timeline (if < 6 months)
            if showSocializationTimeline {
                socializationSection
            }

            // Overdue milestones (if any)
            if !overdueMilestones.isEmpty {
                overdueMilestonesSection
            }

            // Upcoming milestones
            if !upcomingMilestones.isEmpty {
                upcomingMilestonesSection
            }
        }
        // Week detail sheet
        .sheet(isPresented: $showWeekDetail) {
            if let week = selectedWeek, let profile = profile {
                let rawProgress = socializationStore.categoryProgressForWeek(week, profile: profile)
                let categoryProgress = rawProgress.map { item in
                    CategoryWeekProgress(
                        id: item.category.id,
                        category: item.category,
                        count: item.count,
                        total: item.total
                    )
                }

                WeekDetailSheet(
                    weekProgress: week,
                    categoryProgress: categoryProgress,
                    focusSuggestions: socializationStore.focusSuggestions(for: week, profile: profile),
                    onLogExposure: {
                        // Navigate to log exposure - handled by parent view
                    }
                )
            }
        }
        // Milestone completion sheet (for both overdue and upcoming)
        .sheet(isPresented: $showMilestoneDetail) {
            if let milestone = selectedMilestone {
                MilestoneCompletionSheet(
                    milestone: milestone,
                    isPresented: $showMilestoneDetail,
                    onComplete: { notes, photoID, vetClinic, completionDate in
                        milestoneStore.completeMilestone(
                            milestone,
                            notes: notes,
                            photoID: photoID,
                            vetClinicName: vetClinic,
                            completionDate: completionDate
                        )
                    }
                )
            }
        }
    }

    // MARK: - Age Stage Header

    @ViewBuilder
    private var ageStageHeader: some View {
        if let profile = profile {
            VStack(spacing: 8) {
                // Puppy name and age
                HStack(spacing: 16) {
                    // Weeks old
                    VStack(spacing: 2) {
                        Text("\(profile.ageInWeeks)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.ollieAccent)
                        Text(Strings.Common.weeks)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 36)

                    // Days home
                    VStack(spacing: 2) {
                        Text("\(profile.daysHome)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.ollieSuccess)
                        Text(Strings.Common.days)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Age stage badge
                    Text(ageStageLabel(for: profile))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ageStageColor(for: profile))
                        .clipShape(Capsule())
                }

                // Readable age text
                Text(ageDescription(for: profile))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassCard(tint: .accent)
        }
    }

    private func ageDescription(for profile: PuppyProfile) -> String {
        let months = profile.ageInWeeks / 4
        if months >= 2 {
            return Strings.PlanTab.monthsOld(months)
        } else {
            return Strings.PlanTab.weeksOld(profile.ageInWeeks)
        }
    }

    private func ageStageLabel(for profile: PuppyProfile) -> String {
        let weeks = profile.ageInWeeks
        if weeks < 8 {
            return String(localized: "Newborn")
        } else if weeks <= 16 {
            return String(localized: "Socialization")
        } else if weeks <= 26 {
            return String(localized: "Juvenile")
        } else if weeks <= 52 {
            return String(localized: "Adolescent")
        } else {
            return String(localized: "Adult")
        }
    }

    private func ageStageColor(for profile: PuppyProfile) -> Color {
        let weeks = profile.ageInWeeks
        if weeks < 8 {
            return .ollieSleep
        } else if weeks <= 16 {
            return .ollieAccent
        } else if weeks <= 26 {
            return .ollieInfo
        } else if weeks <= 52 {
            return .ollieSuccess
        } else {
            return .secondary
        }
    }

    // MARK: - Socialization Section

    @ViewBuilder
    private var socializationSection: some View {
        if let profile = profile {
            VStack(alignment: .leading, spacing: 8) {
                // Socialization week timeline
                SocializationWeekTimeline(
                    weeklyProgress: weeklyProgress,
                    currentWeek: profile.ageInWeeks,
                    onWeekTap: { weekNumber in
                        if let week = weeklyProgress.first(where: { $0.weekNumber == weekNumber }) {
                            Analytics.trackWeekDetailViewed(
                                weekNumber: week.weekNumber,
                                exposureCount: week.exposureCount,
                                isComplete: week.isComplete
                            )
                            selectedWeek = week
                            showWeekDetail = true
                        }
                    }
                )

                // Socialization progress card with navigation
                NavigationLink {
                    SocializationFullListView()
                } label: {
                    SocializationProgressCard()
                }
                .buttonStyle(.plain)

                // Window status badge
                if socializationStore.socializationWindowClosed(profile: profile) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark.fill")
                        Text(Strings.Socialization.windowClosed)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                } else if SocializationWindow.weeksRemaining(ageWeeks: profile.ageInWeeks) <= 2 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(Strings.Socialization.windowClosing)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.ollieWarning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.ollieWarning.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Overdue Milestones Section

    @ViewBuilder
    private var overdueMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Health.overdue,
                icon: "exclamationmark.triangle.fill",
                tint: .ollieWarning
            )

            VStack(spacing: 8) {
                ForEach(overdueMilestones.prefix(3)) { milestone in
                    MilestonePreviewRow(
                        milestone: milestone,
                        birthDate: profile?.birthDate ?? Date(),
                        isOverdue: true
                    ) {
                        selectedMilestone = milestone
                        showMilestoneDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Milestones Section

    @ViewBuilder
    private var upcomingMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(
                    title: Strings.Health.upcomingMilestones,
                    icon: "calendar.badge.clock",
                    tint: .ollieAccent
                )

                Spacer()

                // See all link
                NavigationLink {
                    HealthTimelineView(
                        milestones: milestoneStore.milestones,
                        birthDate: profile?.birthDate ?? Date(),
                        onToggle: { milestone in
                            milestoneStore.toggleMilestoneCompletion(milestone)
                        }
                    )
                    .navigationTitle(Strings.Health.milestones)
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

            VStack(spacing: 8) {
                ForEach(upcomingMilestones) { milestone in
                    MilestonePreviewRow(
                        milestone: milestone,
                        birthDate: profile?.birthDate ?? Date(),
                        isOverdue: false
                    ) {
                        selectedMilestone = milestone
                        showMilestoneDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.ollieWarning)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                milestoneStore.clearError()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            Color.ollieWarning.opacity(colorScheme == .dark ? 0.15 : 0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Milestone Preview Row

struct MilestonePreviewRow: View {
    let milestone: Milestone
    let birthDate: Date
    let isOverdue: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isOverdue ? Color.ollieWarning : Color.ollieAccent)
                        .frame(width: 32, height: 32)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let period = milestone.periodLabel(birthDate: birthDate) {
                        Text(period)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Days indicator
                if let days = milestone.daysUntil(birthDate: birthDate) {
                    if days < 0 {
                        Text(Strings.Health.daysOverdue(abs(days)))
                            .font(.caption)
                            .foregroundStyle(Color.ollieWarning)
                    } else if days == 0 {
                        Text(Strings.Health.today)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.ollieAccent)
                    } else {
                        Text(Strings.Health.inDays(days))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                (isOverdue ? Color.ollieWarning : Color.ollieAccent)
                    .opacity(colorScheme == .dark ? 0.1 : 0.05)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            PlanSection(
                socializationStore: SocializationStore(),
                milestoneStore: MilestoneStore()
            )
            .padding()
        }
        .environmentObject(ProfileStore())
    }
}
