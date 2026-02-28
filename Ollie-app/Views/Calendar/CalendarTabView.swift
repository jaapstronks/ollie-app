//
//  CalendarTabView.swift
//  Ollie-app
//
//  Schedule tab showing age, appointments, milestones, and contacts

import SwiftUI
import OllieShared

/// Main Schedule tab view displaying age header, appointments, milestones, and contacts
struct CalendarTabView: View {
    @ObservedObject var milestoneStore: MilestoneStore
    @ObservedObject var appointmentStore: AppointmentStore
    @ObservedObject var socializationStore: SocializationStore
    @ObservedObject var contactStore: ContactStore
    let onSettingsTap: () -> Void

    @EnvironmentObject var profileStore: ProfileStore
    @StateObject private var achievementService = AchievementService.shared

    // View mode state with persistence
    @AppStorage("calendarViewMode") private var viewMode: CalendarViewMode = .development

    @State private var showAppointmentsView = false
    @State private var showRoadmap = false
    @State private var selectedMilestone: Milestone?
    @State private var selectedAppointment: DogAppointment?
    @State private var celebrationAchievement: Achievement?
    @State private var celebrationMilestone: Milestone?
    @State private var showTier2Celebration = false
    @State private var showTier3Celebration = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode toggle
                CalendarViewModeToggle(mode: $viewMode)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Content based on view mode
                switch viewMode {
                case .development:
                    developmentView
                case .calendar:
                    CalendarGridView(
                        appointmentStore: appointmentStore,
                        milestoneStore: milestoneStore,
                        profile: profileStore.profile,
                        onAppointmentTap: { appointment in
                            selectedAppointment = appointment
                        },
                        onMilestoneTap: { milestone in
                            selectedMilestone = milestone
                        },
                        onSocializationTap: {
                            // Navigate to Train tab (socialization is there)
                        }
                    )
                case .contacts:
                    ContactsView(
                        contactStore: contactStore,
                        appointmentStore: appointmentStore
                    )
                }
            }
            .navigationTitle(Strings.Tabs.schedule)
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
            .navigationDestination(isPresented: $showAppointmentsView) {
                AppointmentsView(appointmentStore: appointmentStore)
            }
            .navigationDestination(isPresented: $showRoadmap) {
                if let profile = profileStore.profile {
                    DevelopmentRoadmapView(
                        profile: profile,
                        milestoneStore: milestoneStore
                    )
                }
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

                        // Check for achievement
                        if let achievement = achievementService.checkMilestoneCompletion(milestone: milestone) {
                            selectedMilestone = nil
                            celebrationMilestone = milestone
                            celebrationAchievement = achievement
                            // Delay celebration to allow sheet dismissal
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                triggerCelebration(for: achievement)
                            }
                        } else {
                            selectedMilestone = nil
                        }
                    }
                )
            }
            // Tier 2 celebration sheet
            .sheet(isPresented: $showTier2Celebration) {
                if let achievement = celebrationAchievement {
                    Tier2CelebrationCard(
                        achievement: achievement,
                        puppyName: profileStore.profile?.name ?? "Puppy",
                        onAddPhoto: {
                            // TODO: Open photo picker
                            showTier2Celebration = false
                        },
                        onShare: {
                            // TODO: Share functionality
                            showTier2Celebration = false
                        },
                        onDismiss: {
                            showTier2Celebration = false
                            celebrationAchievement = nil
                            celebrationMilestone = nil
                        }
                    )
                    .presentationBackground(.clear)
                }
            }
            // Tier 3 celebration full screen
            .fullScreenCover(isPresented: $showTier3Celebration) {
                if let achievement = celebrationAchievement {
                    Tier3CelebrationView(
                        achievement: achievement,
                        puppyName: profileStore.profile?.name ?? "Puppy",
                        onTakePhoto: {
                            // TODO: Open camera
                            showTier3Celebration = false
                        },
                        onAddFromLibrary: {
                            // TODO: Open photo library
                            showTier3Celebration = false
                        },
                        onSkip: {
                            showTier3Celebration = false
                            celebrationAchievement = nil
                            celebrationMilestone = nil
                        }
                    )
                }
            }
        }
    }

    // MARK: - Development View

    @ViewBuilder
    private var developmentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Age header
                if let profile = profileStore.profile {
                    CalendarAgeHeader(profile: profile)
                        .animatedAppear(delay: 0)
                }

                // Right Now section - developmental periods and socialization
                if let profile = profileStore.profile {
                    rightNowSection(for: profile)
                        .animatedAppear(delay: 0.05)
                }

                // This Week section
                if let birthDate = profileStore.profile?.birthDate {
                    thisWeekSection(birthDate: birthDate)
                        .animatedAppear(delay: 0.10)
                }

                // Coming Up section (2-4 weeks) with roadmap link
                if let birthDate = profileStore.profile?.birthDate {
                    comingUpSection(birthDate: birthDate)
                        .animatedAppear(delay: 0.15)
                }
            }
            .padding()
        }
    }

    // MARK: - Celebration Handling

    private func triggerCelebration(for achievement: Achievement) {
        guard let effectiveTier = achievementService.determineEffectiveTier(for: achievement) else {
            // Celebrations disabled
            return
        }

        switch effectiveTier {
        case .major:
            showTier3Celebration = true
        case .notable:
            showTier2Celebration = true
        case .subtle:
            // Subtle celebrations are inline, no sheet needed
            // Could trigger a banner or shimmer effect here
            break
        }
    }

    // MARK: - Right Now Section

    @ViewBuilder
    private func rightNowSection(for profile: PuppyProfile) -> some View {
        let activePeriods = milestoneStore.activeDevelopmentalPeriods(birthDate: profile.birthDate)
        let showSocialization = showSocializationTimeline(for: profile)

        // Only show if there's content
        if !activePeriods.isEmpty || showSocialization {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: Strings.Calendar.rightNow,
                    icon: "sparkles",
                    tint: .olliePurple
                )

                VStack(spacing: 12) {
                    // Developmental period banners
                    if !activePeriods.isEmpty {
                        DevelopmentalPeriodBanners(
                            milestones: activePeriods,
                            birthDate: profile.birthDate
                        )
                    }

                    // Socialization week timeline
                    if showSocialization {
                        socializationContent(for: profile)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func socializationContent(for profile: PuppyProfile) -> some View {
        let weeklyProgress = socializationStore.allWeeklyProgress(profile: profile)

        VStack(alignment: .leading, spacing: 8) {
            SocializationWeekTimeline(
                weeklyProgress: weeklyProgress,
                currentWeek: profile.ageInWeeks,
                onWeekTap: { _ in
                    // Week taps handled by timeline component
                }
            )

            // Window status badge
            if socializationStore.socializationWindowClosed(profile: profile) {
                windowBadge(
                    icon: "clock.badge.checkmark.fill",
                    text: Strings.Socialization.windowClosed,
                    color: .secondary
                )
            } else if SocializationWindow.weeksRemaining(ageWeeks: profile.ageInWeeks) <= 2 {
                windowBadge(
                    icon: "exclamationmark.triangle.fill",
                    text: Strings.Socialization.windowClosing,
                    color: .ollieWarning
                )
            }
        }
    }

    // MARK: - This Week Section

    @ViewBuilder
    private func thisWeekSection(birthDate: Date) -> some View {
        let appointments = appointmentStore.appointmentsThisWeek
        let milestones = milestoneStore.milestonesThisWeek(birthDate: birthDate)

        if !appointments.isEmpty || !milestones.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: Strings.Calendar.thisWeek,
                    icon: "calendar",
                    tint: .ollieAccent
                )

                VStack(spacing: 8) {
                    // Appointments this week
                    ForEach(appointments.prefix(3)) { appointment in
                        ThisWeekAppointmentRow(appointment: appointment)
                    }

                    // Milestones this week
                    ForEach(milestones.prefix(3)) { milestone in
                        ThisWeekMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate
                        ) {
                            selectedMilestone = milestone
                        }
                    }

                    // View all link if more items
                    if appointments.count > 3 || milestones.count > 3 {
                        Button {
                            showAppointmentsView = true
                        } label: {
                            HStack {
                                Text(Strings.Common.seeAll)
                                Image(systemName: "chevron.right")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.ollieAccent)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 4)
                    }
                }
            }
        } else {
            // Empty state for this week
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: Strings.Calendar.thisWeek,
                    icon: "calendar",
                    tint: .ollieAccent
                )

                emptyThisWeekState
            }
        }
    }

    @ViewBuilder
    private var emptyThisWeekState: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Calendar.nothingThisWeek)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Coming Up Section

    @ViewBuilder
    private func comingUpSection(birthDate: Date) -> some View {
        let appointments = appointmentStore.appointmentsComingUp
        let milestones = milestoneStore.milestonesComingUp(birthDate: birthDate)

        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Calendar.comingUp,
                icon: "calendar.badge.clock",
                tint: .ollieInfo
            )

            VStack(spacing: 8) {
                if !appointments.isEmpty || !milestones.isEmpty {
                    // Appointments coming up
                    ForEach(appointments.prefix(3)) { appointment in
                        ComingUpAppointmentRow(appointment: appointment)
                    }

                    // Milestones coming up
                    ForEach(milestones.prefix(3)) { milestone in
                        ComingUpMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate
                        ) {
                            selectedMilestone = milestone
                        }
                    }
                } else {
                    // Empty state
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(Strings.Calendar.nothingComingUp)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                // Roadmap link - always show
                roadmapLink
            }
        }
    }

    // MARK: - Roadmap Link

    @ViewBuilder
    private var roadmapLink: some View {
        Button {
            showRoadmap = true
        } label: {
            HStack {
                Image(systemName: "map.fill")
                    .font(.body)

                Text(Strings.Calendar.seeRoadmap)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(Color.ollieAccent)
            .padding()
            .background(Color.ollieAccent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func showSocializationTimeline(for profile: PuppyProfile) -> Bool {
        profile.ageInMonths < 6
    }

    @ViewBuilder
    private func windowBadge(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .accessibilityHidden(true)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - This Week Rows

private struct ThisWeekAppointmentRow: View {
    let appointment: DogAppointment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ollieAccent.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: appointment.appointmentType.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ollieAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(formattedDateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if appointment.isToday {
                Text(Strings.Health.today)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ollieAccent)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var formattedDateTime: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(appointment.startDate) {
            if appointment.isAllDay {
                return Strings.Common.today
            } else {
                return appointment.startDate.formatted(date: .omitted, time: .shortened)
            }
        } else if calendar.isDateInTomorrow(appointment.startDate) {
            if appointment.isAllDay {
                return Strings.Common.tomorrow
            } else {
                let timeString = appointment.startDate.formatted(date: .omitted, time: .shortened)
                return "\(Strings.Common.tomorrow), \(timeString)"
            }
        } else {
            if appointment.isAllDay {
                return appointment.startDate.formatted(.dateTime.month(.abbreviated).day())
            } else {
                return appointment.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute())
            }
        }
    }
}

private struct ThisWeekMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.ollieAccent.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ollieAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                        Text(periodLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

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
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coming Up Rows

private struct ComingUpAppointmentRow: View {
    let appointment: DogAppointment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ollieInfo.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: appointment.appointmentType.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ollieInfo)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(appointment.dateString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ComingUpMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.ollieInfo.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ollieInfo)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                        Text(periodLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let milestoneStore = MilestoneStore()
    let appointmentStore = AppointmentStore()
    let socializationStore = SocializationStore()
    let contactStore = ContactStore()
    let profileStore = ProfileStore()

    CalendarTabView(
        milestoneStore: milestoneStore,
        appointmentStore: appointmentStore,
        socializationStore: socializationStore,
        contactStore: contactStore,
        onSettingsTap: { print("Settings tapped") }
    )
    .environmentObject(profileStore)
}
