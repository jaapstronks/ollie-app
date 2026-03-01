//
//  CalendarRowComponents.swift
//  Otis-app
//
//  Reusable row components for calendar/schedule views
//  Extracted from CalendarTabView.swift
//

import SwiftUI
import OtisShared

// MARK: - This Week Rows

struct ThisWeekAppointmentRow: View {
    let appointment: DogAppointment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.otisAccent.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: appointment.appointmentType.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.otisAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(formattedDateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if appointment.isToday {
                Text(Strings.Health.today)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.otisAccent)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var formattedDateTime: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(appointment.startDate) {
            if appointment.isAllDay {
                return Strings.Common.today
            } else {
                return appointment.startDate.formatted(date: .omitted, time: .shortened)
            }
        } else if calendar.isDateInTomorrow(appointment.startDate) {
            if appointment.isAllDay {
                return Strings.Common.tomorrow
            } else {
                let timeString = appointment.startDate.formatted(date: .omitted, time: .shortened)
                return "\(Strings.Common.tomorrow), \(timeString)"
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

struct ThisWeekMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.otisAccent.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.otisAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                        Text(periodLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let days = milestone.daysUntil(birthDate: birthDate) {
                    if days < 0 {
                        Text(Strings.Health.daysOverdue(abs(days)))
                            .font(.caption)
                            .foregroundStyle(Color.otisWarning)
                    } else if days == 0 {
                        Text(Strings.Health.today)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.otisAccent)
                    } else {
                        Text(Strings.Health.inDays(days))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coming Up Rows

struct ComingUpAppointmentRow: View {
    let appointment: DogAppointment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.otisInfo.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: appointment.appointmentType.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.otisInfo)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(appointment.dateString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ComingUpMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.otisInfo.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.otisInfo)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
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
