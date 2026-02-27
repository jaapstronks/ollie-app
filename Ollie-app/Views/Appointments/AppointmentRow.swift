//
//  AppointmentRow.swift
//  Ollie-app
//
//  Row component for displaying an appointment in a list

import SwiftUI
import OllieShared

/// Row view for displaying an appointment in a list
struct AppointmentRow: View {
    let appointment: DogAppointment

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: appointment.appointmentType.icon)
                .font(.system(size: 20))
                .foregroundColor(.ollieAccent)
                .frame(width: 40, height: 40)
                .background(Color.ollieAccent.opacity(0.1))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                HStack {
                    Text(appointment.title)
                        .font(.headline)
                        .lineLimit(1)

                    if appointment.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                // Date and time
                HStack(spacing: 8) {
                    Text(appointment.dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !appointment.isAllDay {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(appointment.timeRangeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Location preview
                if let location = appointment.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Recurring indicator
            if appointment.isRecurring {
                Image(systemName: "repeat")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(appointment.isCompleted ? 0.7 : 1.0)
    }
}

#Preview {
    List {
        AppointmentRow(appointment: DogAppointment(
            title: "Annual Checkup",
            appointmentType: .vetCheckup,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Dierenkliniek Utrecht"
        ))

        AppointmentRow(appointment: DogAppointment(
            title: "Puppy Training Week 2",
            appointmentType: .training,
            startDate: Date().addingTimeInterval(86400),
            endDate: Date().addingTimeInterval(86400 + 3600),
            recurrence: .weekly(on: 5, forWeeks: 4)
        ))

        AppointmentRow(appointment: DogAppointment(
            title: "2nd Vaccination",
            appointmentType: .vetVaccination,
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date().addingTimeInterval(-86400 + 1800),
            isCompleted: true
        ))

        AppointmentRow(appointment: DogAppointment(
            title: "Grooming",
            appointmentType: .grooming,
            startDate: Date().addingTimeInterval(86400 * 7),
            endDate: Date().addingTimeInterval(86400 * 7 + 5400),
            isAllDay: true
        ))
    }
}
