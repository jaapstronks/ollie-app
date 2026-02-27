//
//  AppointmentDetailView.swift
//  Ollie-app
//
//  Detail view for an appointment with actions

import SwiftUI
import OllieShared

/// Detail view for displaying and managing an appointment
struct AppointmentDetailView: View {
    let appointment: DogAppointment
    @ObservedObject var appointmentStore: AppointmentStore
    @EnvironmentObject var contactStore: ContactStore

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCompletionSheet = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Header section with type and status
            Section {
                HStack {
                    Image(systemName: appointment.appointmentType.icon)
                        .font(.title2)
                        .foregroundColor(.ollieAccent)
                        .frame(width: 44, height: 44)
                        .background(Color.ollieAccent.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.appointmentType.displayName)
                            .font(.headline)

                        if appointment.isCompleted {
                            Label(Strings.Appointments.completed, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if appointment.isPast {
                            Text(Strings.Appointments.past)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if appointment.isRecurring {
                        Image(systemName: "repeat")
                            .foregroundColor(.secondary)
                    }

                    if appointment.isSyncedToCalendar {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.ollieAccent)
                    }
                }
            }

            // Date & Time section
            Section(Strings.Appointments.date) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(appointment.dateString)
                }

                if !appointment.isAllDay {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(appointment.timeRangeString)
                    }
                } else {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(Strings.Appointments.allDay)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Location section
            if let location = appointment.location, !location.isEmpty {
                Section(Strings.Appointments.location) {
                    Button {
                        openMaps(location)
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.ollieAccent)
                            Text(location)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Linked contact section
            if let contactId = appointment.linkedContactID,
               let contact = contactStore.contact(withId: contactId) {
                Section(Strings.Appointments.linkedContact) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Contact header
                        HStack {
                            Image(systemName: contact.contactType.icon)
                                .foregroundColor(.ollieAccent)
                            Text(contact.name)
                                .font(.headline)
                        }

                        // Quick actions
                        if let phone = contact.phone, !phone.isEmpty {
                            Button {
                                callPhone(phone)
                            } label: {
                                Label(phone, systemImage: "phone.fill")
                            }
                        }

                        if let email = contact.email, !email.isEmpty {
                            Button {
                                sendEmail(email)
                            } label: {
                                Label(email, systemImage: "envelope.fill")
                            }
                        }
                    }
                }
            }

            // Notes section
            if let notes = appointment.notes, !notes.isEmpty {
                Section(Strings.Appointments.notes) {
                    Text(notes)
                        .foregroundColor(.secondary)
                }
            }

            // Completion notes (for completed appointments)
            if appointment.isCompleted, let completionNotes = appointment.completionNotes, !completionNotes.isEmpty {
                Section(Strings.Appointments.completionNotes) {
                    Text(completionNotes)
                        .foregroundColor(.secondary)
                }
            }

            // Actions section
            Section {
                // Mark complete (for past, uncompleted appointments)
                if appointment.isPast && !appointment.isCompleted {
                    Button {
                        showingCompletionSheet = true
                    } label: {
                        Label(Strings.Appointments.markComplete, systemImage: "checkmark.circle")
                    }
                }

                // Delete
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label(Strings.Common.delete, systemImage: "trash")
                }
            }
        }
        .navigationTitle(appointment.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(Strings.Common.edit) {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditAppointmentSheet(
                appointmentStore: appointmentStore,
                existingAppointment: appointment
            )
        }
        .sheet(isPresented: $showingCompletionSheet) {
            CompletionSheet(
                appointment: appointment,
                appointmentStore: appointmentStore
            )
        }
        .alert(
            Strings.Appointments.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation
        ) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Common.delete, role: .destructive) {
                appointmentStore.deleteAppointment(appointment)
                dismiss()
            }
        } message: {
            Text(Strings.Appointments.deleteConfirmMessage)
        }
    }

    // MARK: - Actions

    private func callPhone(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel:\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }

    private func openMaps(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Completion Sheet

/// Sheet for marking an appointment as completed with optional notes
private struct CompletionSheet: View {
    let appointment: DogAppointment
    @ObservedObject var appointmentStore: AppointmentStore

    @Environment(\.dismiss) private var dismiss
    @State private var completionNotes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(appointment.title)
                        .font(.headline)
                    Text(appointment.dateString)
                        .foregroundColor(.secondary)
                }

                Section(Strings.Appointments.completionNotes) {
                    TextField(
                        Strings.Appointments.completionNotesPlaceholder,
                        text: $completionNotes,
                        axis: .vertical
                    )
                    .lineLimit(4...8)
                }
            }
            .navigationTitle(Strings.Appointments.markComplete)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        appointmentStore.completeAppointment(
                            appointment,
                            notes: completionNotes.isEmpty ? nil : completionNotes
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppointmentDetailView(
            appointment: DogAppointment(
                title: "Annual Checkup",
                appointmentType: .vetCheckup,
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                location: "Dierenkliniek Utrecht, Hoofdstraat 1",
                notes: "Bring vaccination booklet"
            ),
            appointmentStore: AppointmentStore()
        )
        .environmentObject(ContactStore())
    }
}
