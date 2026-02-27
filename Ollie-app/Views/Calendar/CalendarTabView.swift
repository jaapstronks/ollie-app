//
//  CalendarTabView.swift
//  Ollie-app
//
//  Calendar tab showing age, appointments, and milestones

import SwiftUI
import OllieShared

/// Main Calendar tab view displaying age header, appointments, and milestones
struct CalendarTabView: View {
    @ObservedObject var milestoneStore: MilestoneStore
    @ObservedObject var appointmentStore: AppointmentStore
    @ObservedObject var socializationStore: SocializationStore
    let onSettingsTap: () -> Void

    @EnvironmentObject var profileStore: ProfileStore

    @State private var showAppointmentsView = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Age header
                    if let profile = profileStore.profile {
                        CalendarAgeHeader(profile: profile)
                            .animatedAppear(delay: 0)
                    }

                    // Socialization section (if in socialization window)
                    if let profile = profileStore.profile, showSocializationTimeline(for: profile) {
                        socializationSection(for: profile)
                            .animatedAppear(delay: 0.05)
                    }

                    // Appointments section
                    CalendarAppointmentsSection(
                        appointmentStore: appointmentStore,
                        onViewAll: { showAppointmentsView = true }
                    )
                    .animatedAppear(delay: 0.10)

                    // Milestones section
                    if let birthDate = profileStore.profile?.birthDate {
                        CalendarMilestonesSection(
                            milestoneStore: milestoneStore,
                            birthDate: birthDate
                        )
                        .animatedAppear(delay: 0.15)
                    }
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.Tabs.calendar)
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
            .navigationDestination(isPresented: $showAppointmentsView) {
                AppointmentsView(appointmentStore: appointmentStore)
            }
        }
    }

    // MARK: - Helpers

    private func showSocializationTimeline(for profile: PuppyProfile) -> Bool {
        profile.ageInMonths < 6
    }

    // MARK: - Socialization Section

    @ViewBuilder
    private func socializationSection(for profile: PuppyProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Socialization week timeline
            let weeklyProgress = socializationStore.allWeeklyProgress(profile: profile)

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

    @ViewBuilder
    private func windowBadge(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    let milestoneStore = MilestoneStore()
    let appointmentStore = AppointmentStore()
    let socializationStore = SocializationStore()
    let profileStore = ProfileStore()

    CalendarTabView(
        milestoneStore: milestoneStore,
        appointmentStore: appointmentStore,
        socializationStore: socializationStore,
        onSettingsTap: { print("Settings tapped") }
    )
    .environmentObject(profileStore)
}
