//
//  CalendarListSections.swift
//  Ollie-app
//
//  List view sections for the calendar tab (Today, This Week, Coming Up, Sheet Links)
//

import SwiftUI
import OtisShared

// MARK: - Today Section

struct CalendarTodaySection: View {
    let appointments: [DogAppointment]
    let contactStore: ContactStore?
    let onAppointmentTap: (DogAppointment) -> Void
    let onCallContact: ((String) -> Void)?
    let onOpenAddress: ((String) -> Void)?

    init(
        appointments: [DogAppointment],
        contactStore: ContactStore? = nil,
        onAppointmentTap: @escaping (DogAppointment) -> Void,
        onCallContact: ((String) -> Void)? = nil,
        onOpenAddress: ((String) -> Void)? = nil
    ) {
        self.appointments = appointments
        self.contactStore = contactStore
        self.onAppointmentTap = onAppointmentTap
        self.onCallContact = onCallContact
        self.onOpenAddress = onOpenAddress
    }

    var body: some View {
        if !appointments.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: Strings.Calendar.today,
                    icon: "sun.max.fill",
                    tint: .otisAccent
                )

                VStack(spacing: 8) {
                    ForEach(appointments) { appointment in
                        let linkedContact = appointment.linkedContactID.flatMap { contactStore?.contact(withId: $0) }
                        ThisWeekAppointmentRow(
                            appointment: appointment,
                            linkedContact: linkedContact,
                            onTap: { onAppointmentTap(appointment) },
                            onCallContact: onCallContact,
                            onOpenAddress: onOpenAddress
                        )
                    }
                }
            }
        }
    }
}

// MARK: - This Week Section

struct CalendarThisWeekSection: View {
    let appointments: [DogAppointment]
    let milestones: [Milestone]
    let birthDate: Date
    let contactStore: ContactStore?
    let vetContact: DogContact?
    let onAppointmentTap: (DogAppointment) -> Void
    let onMilestoneTap: (Milestone) -> Void
    let onCallVet: ((String) -> Void)?
    let onCallContact: ((String) -> Void)?
    let onOpenAddress: ((String) -> Void)?

    init(
        appointments: [DogAppointment],
        milestones: [Milestone],
        birthDate: Date,
        contactStore: ContactStore? = nil,
        vetContact: DogContact? = nil,
        onAppointmentTap: @escaping (DogAppointment) -> Void,
        onMilestoneTap: @escaping (Milestone) -> Void,
        onCallVet: ((String) -> Void)? = nil,
        onCallContact: ((String) -> Void)? = nil,
        onOpenAddress: ((String) -> Void)? = nil
    ) {
        self.appointments = appointments
        self.milestones = milestones
        self.birthDate = birthDate
        self.contactStore = contactStore
        self.vetContact = vetContact
        self.onAppointmentTap = onAppointmentTap
        self.onMilestoneTap = onMilestoneTap
        self.onCallVet = onCallVet
        self.onCallContact = onCallContact
        self.onOpenAddress = onOpenAddress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Calendar.thisWeek,
                icon: "calendar",
                tint: .otisAccent
            )

            if !appointments.isEmpty || !milestones.isEmpty {
                VStack(spacing: 8) {
                    // Appointments this week (excluding today)
                    ForEach(appointments.prefix(3)) { appointment in
                        let linkedContact = appointment.linkedContactID.flatMap { contactStore?.contact(withId: $0) }
                        ThisWeekAppointmentRow(
                            appointment: appointment,
                            linkedContact: linkedContact,
                            onTap: { onAppointmentTap(appointment) },
                            onCallContact: onCallContact,
                            onOpenAddress: onOpenAddress
                        )
                    }

                    // Milestones this week
                    ForEach(milestones.prefix(3)) { milestone in
                        ThisWeekMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            vetContact: vetContact,
                            onTap: { onMilestoneTap(milestone) },
                            onCallVet: onCallVet
                        )
                    }
                }
            } else {
                EmptyThisWeekState()
            }
        }
    }
}

// MARK: - Coming Up Section

struct CalendarComingUpSection: View {
    let appointments: [DogAppointment]
    let milestones: [Milestone]
    let birthDate: Date
    let contactStore: ContactStore?
    let vetContact: DogContact?
    let onAppointmentTap: (DogAppointment) -> Void
    let onMilestoneTap: (Milestone) -> Void
    let onCallVet: ((String) -> Void)?
    let onCallContact: ((String) -> Void)?

    init(
        appointments: [DogAppointment],
        milestones: [Milestone],
        birthDate: Date,
        contactStore: ContactStore? = nil,
        vetContact: DogContact? = nil,
        onAppointmentTap: @escaping (DogAppointment) -> Void,
        onMilestoneTap: @escaping (Milestone) -> Void,
        onCallVet: ((String) -> Void)? = nil,
        onCallContact: ((String) -> Void)? = nil
    ) {
        self.appointments = appointments
        self.milestones = milestones
        self.birthDate = birthDate
        self.contactStore = contactStore
        self.vetContact = vetContact
        self.onAppointmentTap = onAppointmentTap
        self.onMilestoneTap = onMilestoneTap
        self.onCallVet = onCallVet
        self.onCallContact = onCallContact
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Calendar.comingUp,
                icon: "calendar.badge.clock",
                tint: .otisInfo
            )

            VStack(spacing: 8) {
                if !appointments.isEmpty || !milestones.isEmpty {
                    // Appointments coming up
                    ForEach(appointments.prefix(3)) { appointment in
                        let linkedContact = appointment.linkedContactID.flatMap { contactStore?.contact(withId: $0) }
                        ComingUpAppointmentRow(
                            appointment: appointment,
                            linkedContact: linkedContact,
                            onTap: { onAppointmentTap(appointment) },
                            onCallContact: onCallContact
                        )
                    }

                    // Milestones coming up
                    ForEach(milestones.prefix(3)) { milestone in
                        ComingUpMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            vetContact: vetContact,
                            onTap: { onMilestoneTap(milestone) },
                            onCallVet: onCallVet
                        )
                    }
                } else {
                    EmptyComingUpState()
                }
            }
        }
    }
}

// MARK: - Sheet Links Section

struct CalendarSheetLinksSection: View {
    let profile: PuppyProfile?
    let onDevelopmentTap: (() -> Void)?
    let onSocializationWindowTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            // Development Journey link
            Button {
                onDevelopmentTap?()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.otisPurple.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.otisPurple)
                    }

                    Text(Strings.Calendar.viewDevelopmentJourney)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            // Socialization Window link (only show if puppy is under 6 months)
            if let profile = profile, profile.ageInMonths < 6 {
                Button {
                    onSocializationWindowTap?()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.otisAccent.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.otisAccent)
                        }

                        Text(Strings.Calendar.viewSocializationWindow)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Empty States

struct EmptyThisWeekState: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Calendar.nothingThisWeek)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct EmptyComingUpState: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(Strings.Calendar.nothingComingUp)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct EmptyCalendarListState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(Strings.Calendar.noAppointments)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Strings.Calendar.noAppointmentsHint)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Previews

#Preview("This Week Section") {
    CalendarThisWeekSection(
        appointments: [],
        milestones: [],
        birthDate: Date(),
        onAppointmentTap: { _ in },
        onMilestoneTap: { _ in }
    )
    .padding()
}

#Preview("Empty States") {
    VStack(spacing: 16) {
        EmptyThisWeekState()
        EmptyComingUpState()
        EmptyCalendarListState()
    }
    .padding()
}
