//
//  CalendarMonthGrid.swift
//  Ollie-app
//
//  Month grid view with day cells for the calendar view

import SwiftUI
import OllieShared

/// Month grid view displaying days with appointment and milestone indicators
struct CalendarMonthGrid: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let appointments: [DogAppointment]
    let milestoneSpans: [MilestoneSpan]
    let birthDate: Date?

    @Environment(\.calendar) private var calendar

    // Grid layout: 7 columns for days of week
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            // Month header with navigation
            monthHeader

            // Weekday headers
            weekdayHeaders

            // Day grid
            dayGrid
        }
    }

    // MARK: - Month Header

    @ViewBuilder
    private var monthHeader: some View {
        HStack {
            // Previous month button
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.ollieAccent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous month")

            Spacer()

            // Month/Year title
            Text(Strings.Calendar.monthHeader(date: displayedMonth))
                .font(.headline)
                .fontWeight(.semibold)

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

            // Next month button
            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.ollieAccent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Weekday Headers

    @ViewBuilder
    private var weekdayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid

    @ViewBuilder
    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(daysInMonth, id: \.self) { date in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDate = date
                    }
                } label: {
                    CalendarDayCell(
                        date: date,
                        appointments: appointments(for: date),
                        milestoneSpan: milestoneSpan(for: date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helper Methods

    private var weekdaySymbols: [String] {
        // Get short weekday symbols starting from the locale's first day of week
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1 // Convert to 0-indexed

        return Array(symbols[firstWeekday...]) + Array(symbols[..<firstWeekday])
    }

    private var daysInMonth: [Date] {
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }

        // Get the weekday of the first day (0 = Sunday in default calendar)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Calculate offset to start from the correct day of week
        let firstDayOffset = calendar.firstWeekday
        let offset = (firstWeekday - firstDayOffset + 7) % 7

        // Start date (may be in previous month)
        guard let startDate = calendar.date(byAdding: .day, value: -offset, to: firstDayOfMonth) else { return [] }

        // Generate 42 days (6 weeks) to ensure we cover all month layouts
        return (0..<42).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startDate)
        }
    }

    private func appointments(for date: Date) -> [DogAppointment] {
        appointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    private func milestoneSpan(for date: Date) -> MilestoneSpan? {
        milestoneSpans.first { span in
            date >= span.weekStartDate && date < span.weekEndDate
        }
    }

    private func navigateMonth(by value: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.2)) {
            let today = Date()
            displayedMonth = today
            selectedDate = today
        }
    }
}

#Preview {
    @Previewable @State var displayedMonth = Date()
    @Previewable @State var selectedDate = Date()

    CalendarMonthGrid(
        displayedMonth: $displayedMonth,
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
        birthDate: Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date())
    )
    .padding()
}
