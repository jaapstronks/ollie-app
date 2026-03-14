//
//  HealthCalendarView.swift
//  Ollie-app
//
//  Calendar view showing health events, appointments, and milestones.
//

import SwiftUI
import OtisShared

/// Calendar view displaying health-related events and schedules
struct HealthCalendarView: View {
    @Environment(AppointmentStore.self) private var appointmentStore
    @Environment(MilestoneStore.self) private var milestoneStore
    @Environment(ProfileStore.self) private var profileStore

    @State private var selectedMonth: Date = Date()
    @State private var selectedDate: Date?
    @State private var showAppointmentSheet = false

    private let calendar = Calendar.current

    private var profile: PuppyProfile? {
        profileStore.activeProfile
    }

    // Events for the selected month
    private var monthAppointments: [DogAppointment] {
        appointmentStore.appointments.filter { appointment in
            Calendar.current.isDate(appointment.startDate, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var upcomingAppointments: [DogAppointment] {
        Array(appointmentStore.upcomingAppointments.prefix(5))
    }

    private var healthMilestones: [Milestone] {
        milestoneStore.milestones.filter { $0.category == .health && !$0.isCompleted }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Calendar header
                calendarHeader

                // Calendar grid
                calendarGrid

                // Legend
                legendSection

                Divider()

                // Upcoming section
                upcomingSection

                // Active medications section
                medicationsSection

                // Health milestones
                milestonesSection

                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Strings.VetVisit.Calendar.title)
        .sheet(isPresented: $showAppointmentSheet) {
            if let date = selectedDate {
                AppointmentDaySheet(date: date, appointments: appointmentsForDate(date))
            }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.otisAccent)
            }

            Spacer()

            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.semibold))

            Spacer()

            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.otisAccent)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = generateDaysForMonth()

        return VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let hasAppointment = hasAppointment(on: date)
        let hasMedication = hasMedicationDue(on: date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        return Button {
            selectedDate = date
            if hasAppointment {
                showAppointmentSheet = true
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 32, height: 32)
                    .background {
                        if isToday {
                            Circle().fill(Color.otisAccent)
                        } else if isSelected {
                            Circle().stroke(Color.otisAccent, lineWidth: 2)
                        }
                    }

                // Event indicators
                HStack(spacing: 2) {
                    if hasAppointment {
                        Circle()
                            .fill(Color.otisDanger)
                            .frame(width: 4, height: 4)
                    }
                    if hasMedication {
                        Circle()
                            .fill(Color.otisInfo)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 40)
    }

    // MARK: - Legend

    private var legendSection: some View {
        HStack(spacing: 16) {
            legendItem(color: Color.otisDanger, label: Strings.VetVisit.Calendar.appointments)
            legendItem(color: Color.otisInfo, label: Strings.VetVisit.Calendar.medications)
            legendItem(color: .otisSuccess, label: Strings.VetVisit.Calendar.milestones)
        }
        .font(.caption)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Calendar.upcoming, icon: "calendar")

            if upcomingAppointments.isEmpty {
                emptyState(Strings.VetVisit.Calendar.noEvents)
            } else {
                ForEach(upcomingAppointments, id: \.id) { appointment in
                    appointmentRow(appointment)
                }
            }
        }
    }

    private func appointmentRow(_ appointment: DogAppointment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: appointment.appointmentType.icon)
                .font(.title3)
                .foregroundStyle(appointment.appointmentType.isHealthRelated ? Color.otisDanger : Color.otisAccent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline.weight(.medium))

                Text(appointment.dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if appointment.isToday {
                CapsuleBadge(Strings.VetVisit.visitToday, color: .otisDanger, style: .filled)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Medications Section

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Calendar.medications, icon: "pills.fill")

            let activeMeds = profile?.medicationSchedule.medications.filter { $0.isActive } ?? []

            if activeMeds.isEmpty {
                emptyState(Strings.VetVisit.Summary.noMedications)
            } else {
                ForEach(Array(activeMeds.prefix(3)), id: \.id) { med in
                    HStack(spacing: 12) {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(Color.otisInfo)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(.subheadline.weight(.medium))

                            Text(med.recurrence.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Calendar.milestones, icon: "flag.fill")

            if healthMilestones.isEmpty {
                emptyState(Strings.VetVisit.Calendar.noEvents)
            } else if let birthDate = profile?.birthDate {
                ForEach(Array(healthMilestones.prefix(3)), id: \.id) { milestone in
                    let status = milestone.status(birthDate: birthDate)

                    HStack(spacing: 12) {
                        Image(systemName: milestone.icon)
                            .foregroundStyle(status == .overdue ? Color.otisDanger : .otisSuccess)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.localizedLabel)
                                .font(.subheadline.weight(.medium))

                            if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                                Text(periodLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if status == .overdue {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.otisDanger)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.otisAccent)

            Text(title)
                .font(.headline)

            Spacer()
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func generateDaysForMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func hasAppointment(on date: Date) -> Bool {
        monthAppointments.contains { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    private func hasMedicationDue(on date: Date) -> Bool {
        // Simplified: check if any active medication would be due
        guard let medications = profile?.medicationSchedule.medications else { return false }
        return medications.contains { $0.isActive }
    }

    private func appointmentsForDate(_ date: Date) -> [DogAppointment] {
        monthAppointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    }
}

// MARK: - Appointment Day Sheet

struct AppointmentDaySheet: View {
    let date: Date
    let appointments: [DogAppointment]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(appointments, id: \.id) { appointment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: appointment.appointmentType.icon)
                                .foregroundStyle(Color.otisAccent)

                            Text(appointment.title)
                                .font(.headline)
                        }

                        Label(appointment.timeRangeString, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let location = appointment.location, !location.isEmpty {
                            Label(location, systemImage: "mappin")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let notes = appointment.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(date.formatted(.dateTime.day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HealthCalendarView()
            .environment(AppointmentStore())
            .environment(MilestoneStore())
            .environment(ProfileStore.shared)
    }
}
