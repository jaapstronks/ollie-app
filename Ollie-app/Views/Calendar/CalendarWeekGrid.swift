//
//  CalendarWeekGrid.swift
//  Ollie-app
//
//  Week grid view showing 7 days with appointments and milestones

import SwiftUI
import OllieShared

/// Week grid view displaying a single week with detailed appointment and milestone info
struct CalendarWeekGrid: View {
    @Binding var displayedWeek: Date  // Any date in the week to display
    @Binding var selectedDate: Date
    let appointments: [DogAppointment]
    let milestoneSpans: [MilestoneSpan]
    let birthDate: Date?
    let onAppointmentTap: (DogAppointment) -> Void
    let onMilestoneTap: (Milestone) -> Void

    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(spacing: 16) {
            // Week header with navigation
            weekHeader

            // Week days row
            weekDaysRow

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

    // MARK: - Week Header

    @ViewBuilder
    private var weekHeader: some View {
        HStack {
            // Previous week button
            Button {
                navigateWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.ollieAccent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous week")

            Spacer()

            // Week range title
            VStack(spacing: 2) {
                Text(weekRangeTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let weekNumber = weekNumber {
                    Text("Week \(weekNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Today button
            Button {
                goToToday()
            } label: {
                Text(Strings.Calendar.today)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ollieAccent)
            }

            // Next week button
            Button {
                navigateWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.ollieAccent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Next week")
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Week Days Row

    @ViewBuilder
    private var weekDaysRow: some View {
        HStack(spacing: 4) {
            ForEach(daysInWeek, id: \.self) { date in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDate = date
                    }
                } label: {
                    WeekDayCell(
                        date: date,
                        appointments: appointments(for: date),
                        milestoneSpan: milestoneSpan(for: date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Computed Properties

    private var daysInWeek: [Date] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: displayedWeek)?.start else {
            return []
        }

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }

    private var weekRangeTitle: String {
        guard let weekStart = daysInWeek.first,
              let weekEnd = daysInWeek.last else {
            return ""
        }

        let startMonth = calendar.component(.month, from: weekStart)
        let endMonth = calendar.component(.month, from: weekEnd)

        let formatter = DateFormatter()

        if startMonth == endMonth {
            // Same month: "Mar 3 - 9"
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: weekStart)
            formatter.dateFormat = "d"
            let endString = formatter.string(from: weekEnd)
            return "\(startString) - \(endString)"
        } else {
            // Different months: "Feb 28 - Mar 6"
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: weekStart)
            let endString = formatter.string(from: weekEnd)
            return "\(startString) - \(endString)"
        }
    }

    private var weekNumber: Int? {
        calendar.component(.weekOfYear, from: displayedWeek)
    }

    private var appointmentsForSelectedDate: [DogAppointment] {
        appointments.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var milestonesForSelectedWeek: [Milestone] {
        guard birthDate != nil else { return [] }

        // Get milestones from spans that overlap with selected date
        return milestoneSpans.compactMap { span in
            if selectedDate >= span.weekStartDate && selectedDate < span.weekEndDate {
                return span.milestone
            }
            return nil
        }
    }

    private func appointments(for date: Date) -> [DogAppointment] {
        appointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    private func milestoneSpan(for date: Date) -> MilestoneSpan? {
        milestoneSpans.first { span in
            date >= span.weekStartDate && date < span.weekEndDate
        }
    }

    private func navigateWeek(by value: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let newWeek = calendar.date(byAdding: .weekOfYear, value: value, to: displayedWeek) {
                displayedWeek = newWeek
                // Also update selected date to first day of new week
                if let weekStart = calendar.dateInterval(of: .weekOfYear, for: newWeek)?.start {
                    selectedDate = weekStart
                }
            }
        }
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.2)) {
            let today = Date()
            displayedWeek = today
            selectedDate = today
        }
    }
}

// MARK: - Week Day Cell

/// Individual day cell for the week view (larger than month view cells)
private struct WeekDayCell: View {
    let date: Date
    let appointments: [DogAppointment]
    let milestoneSpan: MilestoneSpan?
    let isSelected: Bool
    let isToday: Bool

    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(spacing: 4) {
            // Weekday name
            Text(weekdayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .secondary)

            // Day number
            Text(dayNumber)
                .font(.system(size: 18, weight: isToday ? .bold : .semibold))
                .foregroundStyle(dayNumberColor)

            // Indicators
            HStack(spacing: 2) {
                // Appointment indicator
                if !appointments.isEmpty {
                    Circle()
                        .fill(isSelected ? Color.white : Color.ollieAccent)
                        .frame(width: 5, height: 5)
                }

                // Milestone indicator
                if milestoneSpan != nil {
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(isSelected ? Color.white : Color.olliePurple)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(backgroundStyle)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(todayOverlay)
    }

    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }

    private var dayNumberColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color.ollieAccent
        } else {
            return .primary
        }
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isSelected {
            Color.ollieAccent
        } else {
            Color(.secondarySystemBackground)
        }
    }

    @ViewBuilder
    private var todayOverlay: some View {
        if isToday && !isSelected {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.ollieAccent, lineWidth: 2)
        }
    }
}

#Preview {
    @Previewable @State var displayedWeek = Date()
    @Previewable @State var selectedDate = Date()

    ScrollView {
        CalendarWeekGrid(
            displayedWeek: $displayedWeek,
            selectedDate: $selectedDate,
            appointments: [
                DogAppointment(
                    title: "Vet Checkup",
                    appointmentType: .vetCheckup,
                    startDate: Date(),
                    endDate: Date()
                )
            ],
            milestoneSpans: [],
            birthDate: Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date()),
            onAppointmentTap: { _ in },
            onMilestoneTap: { _ in }
        )
        .padding()
    }
}
