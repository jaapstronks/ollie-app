//
//  CalendarAppointmentsSection.swift
//  Ollie-app
//
//  Inline appointments display for Calendar tab

import SwiftUI
import OllieShared

/// Section showing upcoming appointments with inline list
struct CalendarAppointmentsSection: View {
    @ObservedObject var appointmentStore: AppointmentStore
    let onViewAll: () -> Void

    @State private var showingAddSheet = false

    private var upcomingAppointments: [DogAppointment] {
        // Show next 5 upcoming appointments
        Array(appointmentStore.upcomingAppointments.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with view all link
            HStack {
                SectionHeader(
                    title: Strings.Calendar.upcomingAppointments,
                    icon: "calendar.badge.clock",
                    tint: .ollieAccent
                )

                Spacer()

                if !appointmentStore.upcomingAppointments.isEmpty {
                    Button {
                        onViewAll()
                    } label: {
                        HStack(spacing: 4) {
                            Text(Strings.Common.seeAll)
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.ollieAccent)
                    }
                }
            }

            if upcomingAppointments.isEmpty {
                // Empty state
                emptyState
            } else {
                // Appointment list
                VStack(spacing: 8) {
                    ForEach(upcomingAppointments) { appointment in
                        NavigationLink {
                            AppointmentDetailView(
                                appointment: appointment,
                                appointmentStore: appointmentStore
                            )
                        } label: {
                            CalendarAppointmentRow(appointment: appointment)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditAppointmentSheet(appointmentStore: appointmentStore)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(Strings.Calendar.noAppointments)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(Strings.Calendar.noAppointmentsHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddSheet = true
            } label: {
                Text(Strings.Calendar.addAppointment)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Appointment Row

struct CalendarAppointmentRow: View {
    let appointment: DogAppointment

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(Color.ollieAccent)
                    .frame(width: 36, height: 36)

                Image(systemName: appointment.appointmentType.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)

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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            Color.ollieAccent.opacity(colorScheme == .dark ? 0.1 : 0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var formattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(appointment.startDate) {
            if appointment.isAllDay {
                return Strings.Appointments.today
            } else {
                let timeString = appointment.startDate.formatted(date: .omitted, time: .shortened)
                return Strings.Appointments.todayAt(time: timeString)
            }
        } else if calendar.isDateInTomorrow(appointment.startDate) {
            if appointment.isAllDay {
                return Strings.Appointments.tomorrow
            } else {
                let timeString = appointment.startDate.formatted(date: .omitted, time: .shortened)
                return Strings.Appointments.tomorrowAt(time: timeString)
            }
        } else {
            if appointment.isAllDay {
                return appointment.startDate.formatted(.dateTime.month(.abbreviated).day())
            } else {
                return appointment.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute())
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            CalendarAppointmentsSection(
                appointmentStore: AppointmentStore(),
                onViewAll: {}
            )
            .padding()
        }
    }
}
