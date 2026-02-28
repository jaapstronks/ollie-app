//
//  CalendarDayCell.swift
//  Ollie-app
//
//  Individual day cell in the calendar month grid

import SwiftUI
import OllieShared

/// Represents a milestone span for background tinting
struct MilestoneSpan: Identifiable {
    let id: UUID
    let milestone: Milestone
    let weekStartDate: Date
    let weekEndDate: Date

    var color: Color {
        milestone.category.tintColor
    }
}

/// Individual day cell in the calendar month grid
struct CalendarDayCell: View {
    let date: Date
    let appointments: [DogAppointment]
    let milestoneSpan: MilestoneSpan?
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool

    private let calendar = Calendar.current
    private let maxDots = 3

    var body: some View {
        VStack(spacing: 2) {
            // Day number
            Text(dayNumber)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)

            // Appointment indicators
            appointmentDots
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(selectionOverlay)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Subviews

    @ViewBuilder
    private var appointmentDots: some View {
        if !appointments.isEmpty {
            HStack(spacing: 2) {
                ForEach(Array(appointments.prefix(maxDots).enumerated()), id: \.offset) { _, appointment in
                    if appointment.isAllDay {
                        // All-day appointments get a pill shape
                        Capsule()
                            .fill(appointmentColor(for: appointment))
                            .frame(width: 12, height: 4)
                    } else {
                        // Regular appointments get dots
                        Circle()
                            .fill(appointmentColor(for: appointment))
                            .frame(width: 6, height: 6)
                    }
                }

                // Show overflow indicator if more than 3 appointments
                if appointments.count > maxDots {
                    Text("+")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            // Spacer to maintain consistent height
            Spacer()
                .frame(height: 6)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            // Milestone span background
            if let span = milestoneSpan {
                span.color.opacity(0.15)
            }

            // Today highlight
            if isToday {
                Color.ollieAccent
            }
        }
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected && !isToday {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.ollieAccent, lineWidth: 2)
        }
    }

    // MARK: - Computed Properties

    private var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private var textColor: Color {
        if isToday {
            return .white
        } else if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else {
            return .primary
        }
    }

    private func appointmentColor(for appointment: DogAppointment) -> Color {
        // Map appointment type color names to actual colors
        switch appointment.appointmentType.color {
        case "vetBlue":
            return .ollieInfo
        case "emergencyRed":
            return .ollieDanger
        case "groomingPurple":
            return .olliePurple
        case "trainingGreen":
            return .ollieSuccess
        case "careOrange":
            return .ollieAccent
        case "walkTeal":
            return .ollieInfo
        case "playdatePink":
            return .ollieRose
        default:
            return .ollieMuted
        }
    }

    private var accessibilityLabel: String {
        Strings.Calendar.dayCellAccessibility(date: date, appointmentCount: appointments.count)
    }
}

#Preview {
    let today = Date()
    let calendar = Calendar.current

    HStack(spacing: 4) {
        // Regular day
        CalendarDayCell(
            date: today,
            appointments: [],
            milestoneSpan: nil,
            isSelected: false,
            isToday: false,
            isCurrentMonth: true
        )

        // Today
        CalendarDayCell(
            date: today,
            appointments: [],
            milestoneSpan: nil,
            isSelected: false,
            isToday: true,
            isCurrentMonth: true
        )

        // Selected day
        CalendarDayCell(
            date: calendar.date(byAdding: .day, value: 1, to: today)!,
            appointments: [],
            milestoneSpan: nil,
            isSelected: true,
            isToday: false,
            isCurrentMonth: true
        )

        // Day with appointments
        CalendarDayCell(
            date: calendar.date(byAdding: .day, value: 2, to: today)!,
            appointments: [
                DogAppointment(
                    title: "Vet Visit",
                    appointmentType: .vetCheckup,
                    startDate: today,
                    endDate: today
                ),
                DogAppointment(
                    title: "Training",
                    appointmentType: .training,
                    startDate: today,
                    endDate: today
                )
            ],
            milestoneSpan: nil,
            isSelected: false,
            isToday: false,
            isCurrentMonth: true
        )

        // Outside current month
        CalendarDayCell(
            date: calendar.date(byAdding: .day, value: -5, to: today)!,
            appointments: [],
            milestoneSpan: nil,
            isSelected: false,
            isToday: false,
            isCurrentMonth: false
        )
    }
    .padding()
}
