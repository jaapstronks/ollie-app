//
//  CalendarRowComponents.swift
//  Otis-app
//
//  Reusable row components for calendar/schedule views
//  Extracted from CalendarTabView.swift
//

import SwiftUI
import OtisShared

// MARK: - Phone Call Helper

@MainActor
private func callPhoneNumber(_ number: String) {
    let cleaned = number.replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")
    if let url = URL(string: "tel://\(cleaned)") {
        UIApplication.shared.open(url)
    }
}

// MARK: - This Week Rows

struct ThisWeekAppointmentRow: View {
    let appointment: DogAppointment
    let linkedContact: DogContact?
    let onTap: () -> Void
    let onCallContact: ((String) -> Void)?
    let onOpenAddress: ((String) -> Void)?

    init(
        appointment: DogAppointment,
        linkedContact: DogContact? = nil,
        onTap: @escaping () -> Void,
        onCallContact: ((String) -> Void)? = nil,
        onOpenAddress: ((String) -> Void)? = nil
    ) {
        self.appointment = appointment
        self.linkedContact = linkedContact
        self.onTap = onTap
        self.onCallContact = onCallContact
        self.onOpenAddress = onOpenAddress
    }

    var body: some View {
        Button(action: onTap) {
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
                        .foregroundStyle(.primary)

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

                // Contact action buttons
                if let contact = linkedContact {
                    HStack(spacing: 8) {
                        if let phone = contact.phone, !phone.isEmpty {
                            Button {
                                onCallContact?(phone)
                            } label: {
                                Image(systemName: "phone.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Color.otisSuccess)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        if contact.hasLocation, let address = contact.address, !address.isEmpty {
                            Button {
                                onOpenAddress?(address)
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Color.otisInfo)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
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
    let vetContact: DogContact?
    let onTap: () -> Void
    let onCallVet: ((String) -> Void)?

    init(
        milestone: Milestone,
        birthDate: Date,
        vetContact: DogContact? = nil,
        onTap: @escaping () -> Void,
        onCallVet: ((String) -> Void)? = nil
    ) {
        self.milestone = milestone
        self.birthDate = birthDate
        self.vetContact = vetContact
        self.onTap = onTap
        self.onCallVet = onCallVet
    }

    private var showVetCallButton: Bool {
        // Show vet call button for health milestones when a vet contact with phone exists
        milestone.category == .health && vetContact != nil && !(vetContact?.phone?.isEmpty ?? true)
    }

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

                // Vet call button for health milestones
                if showVetCallButton, let phone = vetContact?.phone {
                    Button {
                        onCallVet?(phone)
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.otisSuccess)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
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
    let linkedContact: DogContact?
    let onTap: () -> Void
    let onCallContact: ((String) -> Void)?

    init(
        appointment: DogAppointment,
        linkedContact: DogContact? = nil,
        onTap: @escaping () -> Void,
        onCallContact: ((String) -> Void)? = nil
    ) {
        self.appointment = appointment
        self.linkedContact = linkedContact
        self.onTap = onTap
        self.onCallContact = onCallContact
    }

    var body: some View {
        Button(action: onTap) {
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
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Text(appointment.dateString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let contact = linkedContact {
                            Text("·")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(contact.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Call button if contact has phone
                if let phone = linkedContact?.phone, !phone.isEmpty {
                    Button {
                        onCallContact?(phone)
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Color.otisSuccess)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ComingUpMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let vetContact: DogContact?
    let onTap: () -> Void
    let onCallVet: ((String) -> Void)?

    init(
        milestone: Milestone,
        birthDate: Date,
        vetContact: DogContact? = nil,
        onTap: @escaping () -> Void,
        onCallVet: ((String) -> Void)? = nil
    ) {
        self.milestone = milestone
        self.birthDate = birthDate
        self.vetContact = vetContact
        self.onTap = onTap
        self.onCallVet = onCallVet
    }

    private var showVetCallButton: Bool {
        milestone.category == .health && vetContact != nil && !(vetContact?.phone?.isEmpty ?? true)
    }

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

                // Vet call button for health milestones
                if showVetCallButton, let phone = vetContact?.phone {
                    Button {
                        onCallVet?(phone)
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Color.otisSuccess)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
