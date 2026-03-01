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
    @AppStorage("calendarGridMode") private var gridMode: CalendarGridMode = .list

    private let calendar = Calendar.current

    private var birthDate: Date? { profile?.birthDate }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    // Context header (age + socialization) - reactive to selected date in month view
                    if let profile = profile {
                        calendarContextHeader(profile: profile, forDate: gridMode == .month ? selectedDate : Date())
                    }

                    // Grid based on mode
                    switch gridMode {
                    case .list:
                        calendarListView

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
                .padding(.bottom, 80) // Space for sticky toggle
            }

            // Sticky bottom toggle
            VStack(spacing: 0) {
                Divider()
                gridModeToggle
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
            }
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
    private func calendarContextHeader(profile: PuppyProfile, forDate date: Date) -> some View {
        let ageWeeks = ageInWeeks(birthDate: profile.birthDate, atDate: date)

        VStack(spacing: 8) {
            // Age row
            HStack(spacing: 12) {
                // Age badge
                HStack(spacing: 6) {
                    Text("\(ageWeeks)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ollieAccent)
                    Text(Strings.Common.weeks)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Developmental stage
                Text(ageStageLabel(weeks: ageWeeks))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ageStageColor(weeks: ageWeeks))
                    .clipShape(Capsule())
            }

            // Socialization banner (if in window)
            if SocializationWindow.isInWindow(ageWeeks: ageWeeks) {
                Button(action: onSocializationTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.ollieAccent)

                        Text(socializationBannerText(ageWeeks: ageWeeks))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        // Weeks remaining
                        let remaining = SocializationWindow.weeksRemaining(ageWeeks: ageWeeks)
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

    /// Calculate age in weeks at a specific date
    private func ageInWeeks(birthDate: Date, atDate date: Date) -> Int {
        let components = calendar.dateComponents([.day], from: birthDate, to: date)
        let days = components.day ?? 0
        return max(0, days / 7)
    }

    private func socializationBannerText(ageWeeks: Int) -> String {
        let weekInWindow = ageWeeks - SocializationWindow.startWeek + 1
        let totalWeeks = SocializationWindow.endWeek - SocializationWindow.startWeek + 1
        return Strings.Calendar.socializationWeek(weekInWindow, of: totalWeeks)
    }

    private func ageStageLabel(weeks: Int) -> String {
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

    private func ageStageColor(weeks: Int) -> Color {
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

    // MARK: - List View

    @ViewBuilder
    private var calendarListView: some View {
        let upcoming = appointmentStore.upcomingAppointments
        let grouped = groupAppointmentsByDate(upcoming)

        if upcoming.isEmpty {
            emptyListState
        } else {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(grouped, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Date header
                        Text(listDateHeader(for: group.date))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        // Appointments for this date
                        ForEach(group.appointments) { appointment in
                            Button {
                                onAppointmentTap(appointment)
                            } label: {
                                ListAppointmentRow(appointment: appointment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyListState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(Strings.Calendar.noAppointments)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Strings.Calendar.noAppointmentsHint)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    /// Group appointments by date
    private func groupAppointmentsByDate(_ appointments: [DogAppointment]) -> [(date: Date, appointments: [DogAppointment])] {
        let grouped = Dictionary(grouping: appointments) { appointment in
            calendar.startOfDay(for: appointment.startDate)
        }
        return grouped.map { (date: $0.key, appointments: $0.value.sorted { $0.startDate < $1.startDate }) }
            .sorted { $0.date < $1.date }
    }

    /// Format date header for list view
    private func listDateHeader(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return Strings.Calendar.today
        } else if calendar.isDateInTomorrow(date) {
            return String(localized: "Tomorrow")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - List Appointment Row

private struct ListAppointmentRow: View {
    let appointment: DogAppointment

    private var typeColor: Color {
        Color(appointment.appointmentType.color)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Circle()
                .fill(typeColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: appointment.appointmentType.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(typeColor)
                }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    // Time
                    Text(appointment.timeRangeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Location if present
                    if let location = appointment.location, !location.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
