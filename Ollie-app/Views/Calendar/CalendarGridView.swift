//
//  CalendarGridView.swift
//  Ollie-app
//
//  Main calendar grid container view
//

import SwiftUI
import OtisShared

/// Main calendar grid view with month/week navigation and day detail
struct CalendarGridView: View {
    @ObservedObject var appointmentStore: AppointmentStore
    @ObservedObject var milestoneStore: MilestoneStore
    @ObservedObject var socializationStore: SocializationStore
    let profile: PuppyProfile?
    let onAppointmentTap: (DogAppointment) -> Void
    let onMilestoneTap: (Milestone) -> Void
    let onSocializationTap: () -> Void
    var onDevelopmentTap: (() -> Void)? = nil
    var onSocializationWindowTap: (() -> Void)? = nil

    @State private var displayedMonth: Date = Date()
    @State private var displayedWeek: Date = Date()
    @State private var selectedDate: Date = Date()
    @AppStorage("calendarGridMode") private var gridMode: CalendarGridMode = .list

    // First-visit tip tracking
    @AppStorage("hasSeenCalendarTip") private var hasSeenCalendarTip = false

    private let calendar = Calendar.current
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var birthDate: Date? { profile?.birthDate }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    // First-visit tip
                    if !hasSeenCalendarTip {
                        FeatureTipCard(
                            tip: .scheduleCalendar,
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hasSeenCalendarTip = true
                                }
                            }
                        )
                    }

                    // Context header (age + socialization) - reactive to selected date in month view
                    if let profile = profile {
                        CalendarContextHeader(
                            profile: profile,
                            forDate: gridMode == .month ? selectedDate : Date(),
                            onDevelopmentTap: onDevelopmentTap,
                            onSocializationTap: onSocializationTap
                        )
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
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selectedDate)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: gridMode)
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
        VStack(alignment: .leading, spacing: 20) {
            // Today section
            CalendarTodaySection(
                appointments: appointmentStore.appointments(for: Date()),
                onAppointmentTap: onAppointmentTap
            )

            // This Week section
            if let birthDate = birthDate {
                CalendarThisWeekSection(
                    appointments: appointmentStore.appointmentsThisWeek.filter { !calendar.isDateInToday($0.startDate) },
                    milestones: milestoneStore.milestonesThisWeek(birthDate: birthDate),
                    birthDate: birthDate,
                    onAppointmentTap: onAppointmentTap,
                    onMilestoneTap: onMilestoneTap
                )
            }

            // Coming Up section (2-4 weeks out)
            if let birthDate = birthDate {
                CalendarComingUpSection(
                    appointments: appointmentStore.appointmentsComingUp,
                    milestones: milestoneStore.milestonesComingUp(birthDate: birthDate),
                    birthDate: birthDate,
                    onAppointmentTap: onAppointmentTap,
                    onMilestoneTap: onMilestoneTap
                )
            }

            // Sheet Links section
            CalendarSheetLinksSection(
                profile: profile,
                onDevelopmentTap: onDevelopmentTap,
                onSocializationWindowTap: onSocializationWindowTap
            )
        }
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
    let socializationStore = SocializationStore()
    let profileStore = ProfileStore()

    CalendarGridView(
        appointmentStore: appointmentStore,
        milestoneStore: milestoneStore,
        socializationStore: socializationStore,
        profile: profileStore.profile,
        onAppointmentTap: { _ in },
        onMilestoneTap: { _ in },
        onSocializationTap: { }
    )
    .environmentObject(profileStore)
    .environmentObject(milestoneStore)
}
