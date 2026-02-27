//
//  TodaysScheduleCard.swift
//  Ollie-app
//
//  Shows today's appointments on the Today view

import SwiftUI
import OllieShared

/// Card showing today's scheduled appointments
struct TodaysScheduleCard: View {
    @ObservedObject var appointmentStore: AppointmentStore
    var onViewAll: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private var todaysAppointments: [DogAppointment] {
        appointmentStore.todaysAppointments
    }

    var body: some View {
        if !todaysAppointments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                headerView

                // Appointment list
                VStack(spacing: 8) {
                    ForEach(todaysAppointments.prefix(3)) { appointment in
                        appointmentRow(appointment)
                    }

                    // Show more indicator if needed
                    if todaysAppointments.count > 3 {
                        showMoreButton
                    }
                }
            }
            .padding()
            .glassCard(tint: .accent)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        Button {
            onViewAll?()
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.ollieAccent)

                Text(Strings.Appointments.todaysSchedule)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                // Count badge
                Text("\(todaysAppointments.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())

                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Appointment Row

    @ViewBuilder
    private func appointmentRow(_ appointment: DogAppointment) -> some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: appointment.appointmentType.icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 28, height: 28)
                .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(Circle())

            // Title and time
            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if appointment.isAllDay {
                        Text(Strings.Appointments.allDay)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(appointment.startDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Show end time if different from start time
                        if appointment.endDate != appointment.startDate {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(appointment.endDate.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let location = appointment.location, !location.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Completed indicator
            if appointment.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.ollieSuccess)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Show More

    @ViewBuilder
    private var showMoreButton: some View {
        Button {
            onViewAll?()
        } label: {
            HStack {
                Spacer()
                Text(Strings.Appointments.moreAppointments(count: todaysAppointments.count - 3))
                    .font(.caption)
                    .foregroundStyle(Color.ollieAccent)
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let appointmentStore = AppointmentStore()

    return VStack {
        TodaysScheduleCard(appointmentStore: appointmentStore) {
            print("View all tapped")
        }
    }
    .padding()
}
