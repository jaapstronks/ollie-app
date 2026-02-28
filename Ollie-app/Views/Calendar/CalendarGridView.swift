//
//  CalendarGridView.swift
//  Ollie-app
//
//  Main calendar grid container view

import SwiftUI
import OllieShared

/// Main calendar grid view with month/week navigation and day detail
struct CalendarGridView: View {
    @ObservedObject var appointmentStore: AppointmentStore
    @ObservedObject var milestoneStore: MilestoneStore
    let profile: PuppyProfile?
    let onAppointmentTap: (DogAppointment) -> Void
    let onMilestoneTap: (Milestone) -> Void
    let onSocializationTap: () -> Void

    @State private var displayedMonth: Date = Date()
    @State private var displayedWeek: Date = Date()
    @State private var selectedDate: Date = Date()
    @AppStorage("calendarGridMode") private var gridMode: CalendarGridMode = .week

    private let calendar = Calendar.current

    private var birthDate: Date? { profile?.birthDate }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Week/Month toggle
                gridModeToggle

                // Context header (age + socialization)
                if let profile = profile {
                    calendarContextHeader(profile: profile)
                }

                // Grid based on mode
                switch gridMode {
                case .week:
                    CalendarWeekGrid(
                        displayedWeek: $displayedWeek,
                        selectedDate: $selectedDate,
                        appointments: appointmentsForDisplayedWeek,
                        milestoneSpans: milestoneSpansForDisplayedWeek,
                        birthDate: birthDate,
                        onAppointmentTap: onAppointmentTap,
                        onMilestoneTap: onMilestoneTap
                    )

                case .month:
                    VStack(spacing: 20) {
                        // Month grid
                        CalendarMonthGrid(
                            displayedMonth: $displayedMonth,
                            selectedDate: $selectedDate,
                            appointments: appointmentsForDisplayedMonth,
                            milestoneSpans: milestoneSpansForDisplayedMonth,
                            birthDate: birthDate
                        )

                        // Selected day detail
                        CalendarDayDetailView(
                            date: selectedDate,
                            appointments: appointmentsForSelectedDate,
                            milestones: milestonesForSelectedWeek,
                            birthDate: birthDate,
                            onAppointmentTap: onAppointmentTap,
                            onMilestoneTap: onMilestoneTap
                        )
                    }
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
        .animation(.easeInOut(duration: 0.2), value: gridMode)
    }

    // MARK: - Grid Mode Toggle

    @ViewBuilder
    private var gridModeToggle: some View {
        Picker(selection: $gridMode) {
            ForEach(CalendarGridMode.allCases, id: \.self) { mode in
                Label(mode.label, systemImage: mode.icon)
                    .tag(mode)
            }
        } label: {
            Text("View Mode")
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Context Header

    @ViewBuilder
    private func calendarContextHeader(profile: PuppyProfile) -> some View {
        VStack(spacing: 8) {
            // Age row
            HStack(spacing: 12) {
                // Age badge
                HStack(spacing: 6) {
                    Text("\(profile.ageInWeeks)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ollieAccent)
                    Text(Strings.Common.weeks)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Developmental stage
                Text(ageStageLabel(for: profile))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ageStageColor(for: profile))
                    .clipShape(Capsule())
            }

            // Socialization banner (if in window)
            if SocializationWindow.isInWindow(ageWeeks: profile.ageInWeeks) {
                Button(action: onSocializationTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.ollieAccent)

                        Text(socializationBannerText(for: profile))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        // Weeks remaining
                        let remaining = SocializationWindow.weeksRemaining(ageWeeks: profile.ageInWeeks)
                        if remaining <= 4 && remaining > 0 {
                            Text(Strings.Socialization.weeksRemaining(remaining))
                                .font(.caption2)
                                .foregroundStyle(remaining <= 2 ? Color.ollieWarning : .secondary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.ollieAccent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func socializationBannerText(for profile: PuppyProfile) -> String {
        let weekInWindow = profile.ageInWeeks - SocializationWindow.startWeek + 1
        let totalWeeks = SocializationWindow.endWeek - SocializationWindow.startWeek + 1
        return Strings.Calendar.socializationWeek(weekInWindow, of: totalWeeks)
    }

    private func ageStageLabel(for profile: PuppyProfile) -> String {
        let weeks = profile.ageInWeeks
        if weeks < 8 {
            return Strings.PlanTab.ageStageNewborn
        } else if weeks <= 16 {
            return Strings.PlanTab.ageStageSocialization
        } else if weeks <= 26 {
            return Strings.PlanTab.ageStageJuvenile
        } else if weeks <= 52 {
            return Strings.PlanTab.ageStageAdolescent
        } else {
            return Strings.PlanTab.ageStageAdult
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

    // MARK: - Computed Properties

    /// Get all appointments for the displayed month
    private var appointmentsForDisplayedMonth: [DogAppointment] {
        appointmentStore.appointments(inMonthOf: displayedMonth)
    }

    /// Get all appointments for the displayed week
    private var appointmentsForDisplayedWeek: [DogAppointment] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: displayedWeek) else {
            return []
        }
        return appointmentStore.appointments.filter { appointment in
            appointment.startDate >= weekInterval.start && appointment.startDate < weekInterval.end
        }
    }

    /// Get appointments for the selected date
    private var appointmentsForSelectedDate: [DogAppointment] {
        appointmentStore.appointments(for: selectedDate)
    }

    /// Get milestone spans for the displayed month
    private var milestoneSpansForDisplayedMonth: [MilestoneSpan] {
        guard let birthDate = birthDate else { return [] }

        // Get the start and end of the displayed month (with buffer for visible days)
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }

        // Add buffer for days from adjacent months visible in the grid
        guard let startBuffer = calendar.date(byAdding: .day, value: -7, to: monthStart),
              let endBuffer = calendar.date(byAdding: .day, value: 7, to: monthEnd) else {
            return []
        }

        return milestoneStore.milestoneSpans(
            from: startBuffer,
            to: endBuffer,
            birthDate: birthDate
        )
    }

    /// Get milestone spans for the displayed week
    private var milestoneSpansForDisplayedWeek: [MilestoneSpan] {
        guard let birthDate = birthDate,
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: displayedWeek) else {
            return []
        }

        // Add small buffer around week
        guard let startBuffer = calendar.date(byAdding: .day, value: -1, to: weekInterval.start),
              let endBuffer = calendar.date(byAdding: .day, value: 1, to: weekInterval.end) else {
            return []
        }

        return milestoneStore.milestoneSpans(
            from: startBuffer,
            to: endBuffer,
            birthDate: birthDate
        )
    }

    /// Get milestones for the week containing the selected date
    private var milestonesForSelectedWeek: [Milestone] {
        guard let birthDate = birthDate else { return [] }
        return milestoneStore.milestones(inWeekOf: selectedDate, birthDate: birthDate)
    }
}

#Preview {
    let milestoneStore = MilestoneStore()
    let appointmentStore = AppointmentStore()
    let profileStore = ProfileStore()

    CalendarGridView(
        appointmentStore: appointmentStore,
        milestoneStore: milestoneStore,
        profile: profileStore.profile,
        onAppointmentTap: { _ in },
        onMilestoneTap: { _ in },
        onSocializationTap: { }
    )
}
