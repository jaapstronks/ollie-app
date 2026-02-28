//
//  CalendarDayDetailView.swift
//  Ollie-app
//
//  Detail view for selected day showing appointments and milestones

import SwiftUI
import OllieShared

/// Detail view showing appointments and milestones for the selected day
struct CalendarDayDetailView: View {
    let date: Date
    let appointments: [DogAppointment]
    let milestones: [Milestone]
    let birthDate: Date?
    let onAppointmentTap: (DogAppointment) -> Void
    let onMilestoneTap: (Milestone) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            Text(Strings.Calendar.selectedDayHeader(date: date))
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)

            // Content
            if appointments.isEmpty && milestones.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    // Appointments
                    ForEach(appointments) { appointment in
                        DayDetailAppointmentRow(
                            appointment: appointment,
                            onTap: { onAppointmentTap(appointment) }
                        )
                    }

                    // Milestones due this week
                    if !milestones.isEmpty {
                        milestonesSection
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(Strings.Calendar.noAppointmentsOnDay)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Milestones Section

    @ViewBuilder
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Color.ollieAccent)

                Text(Strings.Calendar.milestonesDueThisWeek)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            ForEach(milestones) { milestone in
                DayDetailMilestoneRow(
                    milestone: milestone,
                    birthDate: birthDate,
                    onTap: { onMilestoneTap(milestone) }
                )
            }
        }
    }
}

// MARK: - Day Detail Appointment Row

private struct DayDetailAppointmentRow: View {
    let appointment: DogAppointment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: appointment.appointmentType.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(typeColor)
                }

                // Title and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        if let location = appointment.location, !location.isEmpty {
                            Text(location)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Time and indicators
                VStack(alignment: .trailing, spacing: 4) {
                    if appointment.isAllDay {
                        Text(String(localized: "All Day"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(appointment.startDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    // Indicators
                    HStack(spacing: 4) {
                        if appointment.isRecurring {
                            Image(systemName: "repeat")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }

                        if appointment.isSyncedToCalendar {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var typeColor: Color {
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
}

// MARK: - Day Detail Milestone Row

private struct DayDetailMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(milestone.category.tintColor.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(milestone.category.tintColor)
                }

                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let birthDate = birthDate,
                       let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                        Text(periodLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let today = Date()
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -10, to: today)

    VStack(spacing: 20) {
        // With content
        CalendarDayDetailView(
            date: today,
            appointments: [
                DogAppointment(
                    title: "Vet Checkup",
                    appointmentType: .vetCheckup,
                    startDate: today,
                    endDate: today,
                    location: "Dierenkliniek Amsterdam"
                ),
                DogAppointment(
                    title: "Puppy Training",
                    appointmentType: .training,
                    startDate: today,
                    endDate: today,
                    recurrence: RecurrenceRule(frequency: .weekly)
                )
            ],
            milestones: [],
            birthDate: birthDate,
            onAppointmentTap: { _ in },
            onMilestoneTap: { _ in }
        )

        // Empty state
        CalendarDayDetailView(
            date: today,
            appointments: [],
            milestones: [],
            birthDate: birthDate,
            onAppointmentTap: { _ in },
            onMilestoneTap: { _ in }
        )
    }
    .padding()
}
