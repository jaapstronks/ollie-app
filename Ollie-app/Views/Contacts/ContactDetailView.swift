//
//  ContactDetailView.swift
//  Ollie-app
//
//  Detail view for viewing and editing a contact

import SwiftUI
import OllieShared

/// Detail view for a contact
struct ContactDetailView: View {
    let contact: DogContact
    @ObservedObject var contactStore: ContactStore
    var appointmentStore: AppointmentStore?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    // Appointments linked to this contact
    private var linkedAppointments: [DogAppointment] {
        appointmentStore?.appointments(linkedToContactId: contact.id) ?? []
    }

    private var upcomingAppointments: [DogAppointment] {
        linkedAppointments.filter { $0.isUpcoming || $0.isToday }
            .sorted { $0.startDate < $1.startDate }
    }

    private var pastAppointments: [DogAppointment] {
        linkedAppointments.filter { $0.isPast }
            .sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Contact actions
                if contact.hasContactInfo {
                    actionButtonsSection
                }

                // Details card
                detailsCard

                // Notes section
                if let notes = contact.notes, !notes.isEmpty {
                    notesCard(notes)
                }

                // Appointments section (only if we have appointment store)
                if appointmentStore != nil {
                    appointmentsSection
                }
            }
            .padding()
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label(Strings.Common.edit, systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(Strings.Common.delete, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditContactSheet(
                contactStore: contactStore,
                existingContact: contact
            )
        }
        .alert(
            Strings.Contacts.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation
        ) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Common.delete, role: .destructive) {
                contactStore.deleteContact(contact)
                dismiss()
            }
        } message: {
            Text(Strings.Contacts.deleteConfirmMessage)
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: contact.contactType.icon)
                .font(.system(size: 40))
                .foregroundColor(.ollieAccent)
                .frame(width: 80, height: 80)
                .background(Color.ollieAccent.opacity(0.1))
                .clipShape(Circle())

            Text(contact.contactType.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Action Buttons Section

    @ViewBuilder
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            if let phone = contact.phone, !phone.isEmpty {
                actionButton(
                    icon: "phone.fill",
                    label: Strings.Contacts.call,
                    color: .ollieSuccess
                ) {
                    callPhone(phone)
                }
            }

            if let email = contact.email, !email.isEmpty {
                actionButton(
                    icon: "envelope.fill",
                    label: Strings.Contacts.sendEmail,
                    color: .ollieInfo
                ) {
                    sendEmail(email)
                }
            }

            if let address = contact.address, !address.isEmpty {
                actionButton(
                    icon: "map.fill",
                    label: Strings.Contacts.openInMaps,
                    color: .ollieAccent
                ) {
                    openInMaps(address)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func actionButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Details Card

    @ViewBuilder
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let phone = contact.phone, !phone.isEmpty {
                detailRow(
                    icon: "phone.fill",
                    title: Strings.Contacts.phone,
                    value: phone
                )
            }

            if let email = contact.email, !email.isEmpty {
                if let phone = contact.phone, !phone.isEmpty {
                    Divider()
                }
                detailRow(
                    icon: "envelope.fill",
                    title: Strings.Contacts.email,
                    value: email
                )
            }

            if let address = contact.address, !address.isEmpty {
                let hasPhone = contact.phone.map { !$0.isEmpty } ?? false
                let hasEmail = contact.email.map { !$0.isEmpty } ?? false
                if hasPhone || hasEmail {
                    Divider()
                }
                detailRow(
                    icon: "mappin.circle.fill",
                    title: Strings.Contacts.address,
                    value: address
                )
            }

            // Show empty state if no contact info
            if !contact.hasContactInfo {
                HStack {
                    Spacer()
                    Text(Strings.Contacts.noContactsHint)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    @ViewBuilder
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.ollieAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }

    // MARK: - Appointments Section

    @ViewBuilder
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Next appointment
            if let nextAppointment = upcomingAppointments.first {
                VStack(alignment: .leading, spacing: 8) {
                    Label(Strings.Contacts.nextAppointment, systemImage: "calendar.badge.clock")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    appointmentRow(nextAppointment)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            }

            // Visit history
            if !pastAppointments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(Strings.Contacts.visitHistory, systemImage: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(pastAppointments.prefix(5)) { appointment in
                        if appointment.id != pastAppointments.first?.id {
                            Divider()
                        }
                        appointmentRow(appointment)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            }

            // Empty state when no appointments
            if upcomingAppointments.isEmpty && pastAppointments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text(Strings.Contacts.noAppointments)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            }
        }
    }

    @ViewBuilder
    private func appointmentRow(_ appointment: DogAppointment) -> some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: appointment.appointmentType.icon)
                .font(.title3)
                .foregroundStyle(Color(appointment.appointmentType.color))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(appointment.startDate, format: .dateTime.month(.abbreviated).day())
                    Text("·")
                    if appointment.isAllDay {
                        Text(Strings.Appointments.allDay)
                    } else {
                        Text(appointment.startDate, format: .dateTime.hour().minute())
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Completed checkmark for past appointments
            if appointment.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.ollieSuccess)
            }
        }
    }

    // MARK: - Notes Card

    @ViewBuilder
    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(Strings.Contacts.notes, systemImage: "note.text")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Actions

    private func callPhone(_ phone: String) {
        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleaned)") {
            openURL(url)
        }
    }

    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            openURL(url)
        }
    }

    private func openInMaps(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?address=\(encoded)") {
            openURL(url)
        }
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(
            contact: DogContact(
                name: "Dierenkliniek Utrecht",
                contactType: .vet,
                phone: "+31 30 123 4567",
                email: "info@dierenkliniek.nl",
                address: "Veterinairenstraat 1, 3512 AB Utrecht",
                notes: "Open ma-vr 8:00-18:00, za 9:00-12:00. Spoedlijn beschikbaar 24/7."
            ),
            contactStore: ContactStore()
        )
    }
}
