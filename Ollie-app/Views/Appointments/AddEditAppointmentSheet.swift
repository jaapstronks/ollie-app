//
//  AddEditAppointmentSheet.swift
//  Otis-app
//
//  Sheet for adding or editing an appointment

import SwiftUI
import OtisShared

/// Sheet for adding or editing an appointment
struct AddEditAppointmentSheet: View {
    var appointmentStore: AppointmentStore
    @Environment(ContactStore.self) var contactStore
    var existingAppointment: DogAppointment?
    var prefill: AppointmentPrefill?

    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var appointmentType: AppointmentType = .vetCheckup
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600) // 1 hour later
    @State private var isAllDay: Bool = false
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var reminderMinutesBefore: Int = 60

    // Linking
    @State private var linkedContactID: UUID?
    @State private var linkedGroomingType: GroomingType?

    // Validation
    @State private var showingTitleError = false

    private var isEditing: Bool {
        existingAppointment != nil
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type section
                Section(Strings.Appointments.appointmentType) {
                    Picker(Strings.Appointments.appointmentType, selection: $appointmentType) {
                        ForEach(AppointmentType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: appointmentType) { _, newType in
                        // Auto-fill title based on type if empty
                        if title.isEmpty {
                            title = newType.displayName
                        }
                        // Suggest contact if available
                        suggestContact(for: newType)
                        // Clear grooming type if not a grooming appointment
                        if newType != .grooming {
                            linkedGroomingType = nil
                        }
                    }

                    // Grooming type picker (only for grooming appointments)
                    if appointmentType == .grooming {
                        Picker(Strings.Grooming.title, selection: $linkedGroomingType) {
                            Text(Strings.Appointments.appointmentType)
                                .tag(nil as GroomingType?)
                            ForEach(GroomingType.allCases, id: \.self) { type in
                                Label(type.label, systemImage: type.icon)
                                    .tag(type as GroomingType?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: linkedGroomingType) { _, newType in
                            // Update title to reflect specific grooming type
                            if let groomingType = newType {
                                title = groomingType.label
                            }
                        }
                    }
                }

                // Title section
                Section {
                    TextField(Strings.Appointments.titlePlaceholder, text: $title)
                } header: {
                    Text(Strings.Appointments.appointmentTitle)
                } footer: {
                    if showingTitleError && title.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(Strings.Contacts.nameRequired)
                            .foregroundStyle(.red)
                    }
                }

                // Date & Time section
                Section(Strings.Appointments.date) {
                    Toggle(Strings.Appointments.allDay, isOn: $isAllDay)

                    if isAllDay {
                        DatePicker(
                            Strings.Appointments.date,
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        .onChange(of: startDate) { _, newDate in
                            // Set end date to end of same day
                            let calendar = Calendar.current
                            if let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: newDate) {
                                endDate = endOfDay
                            }
                        }
                    } else {
                        DatePicker(
                            Strings.Appointments.startTime,
                            selection: $startDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .onChange(of: startDate) { _, newDate in
                            // Keep end date at least 30 minutes after start
                            if endDate <= newDate {
                                endDate = newDate.addingTimeInterval(3600)
                            }
                        }

                        DatePicker(
                            Strings.Appointments.endTime,
                            selection: $endDate,
                            in: startDate...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                // Location section
                Section(Strings.Appointments.location) {
                    TextField(Strings.Appointments.locationPlaceholder, text: $location)
                        .textContentType(.fullStreetAddress)
                }

                // Contact linking
                Section(Strings.Appointments.linkedContact) {
                    contactPicker
                }

                // Reminder section
                Section(Strings.Appointments.reminder) {
                    Picker(Strings.Appointments.reminder, selection: $reminderMinutesBefore) {
                        ForEach(DogAppointment.reminderOptions, id: \.minutes) { option in
                            Text(option.label).tag(option.minutes)
                        }
                    }
                    .labelsHidden()
                }

                // Notes section
                Section(Strings.Appointments.notes) {
                    TextField(Strings.Appointments.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? Strings.Appointments.editAppointment : Strings.Appointments.addAppointment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveAppointment()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadExistingAppointment()
            }
        }
    }

    // MARK: - Contact Picker

    @ViewBuilder
    private var contactPicker: some View {
        let suggestedContacts = contactsForAppointmentType(appointmentType)

        if suggestedContacts.isEmpty {
            Text(Strings.Appointments.noContact)
                .foregroundStyle(.secondary)
        } else {
            Picker(Strings.Appointments.linkedContact, selection: $linkedContactID) {
                Text(Strings.Appointments.noContact).tag(nil as UUID?)

                ForEach(suggestedContacts) { contact in
                    Label(contact.name, systemImage: contact.contactType.icon)
                        .tag(contact.id as UUID?)
                }
            }
            .labelsHidden()
        }
    }

    /// Get contacts that match the appointment type
    private func contactsForAppointmentType(_ type: AppointmentType) -> [DogContact] {
        guard let suggestedType = type.suggestedContactType else {
            return contactStore.contacts
        }

        // Get contacts of suggested type, plus all others
        let primaryContacts = contactStore.contacts(ofType: suggestedType)
        let otherContacts = contactStore.contacts.filter { $0.contactType != suggestedType }

        return primaryContacts + otherContacts
    }

    /// Suggest a contact when appointment type changes
    private func suggestContact(for type: AppointmentType) {
        guard linkedContactID == nil,
              let suggestedType = type.suggestedContactType else {
            return
        }

        // Auto-select if there's exactly one contact of the suggested type
        let matchingContacts = contactStore.contacts(ofType: suggestedType)
        if matchingContacts.count == 1 {
            linkedContactID = matchingContacts.first?.id
        }
    }

    // MARK: - Load Existing Appointment

    private func loadExistingAppointment() {
        // Load prefill data first (for nudge-initiated appointments)
        if let prefill = prefill {
            appointmentType = prefill.appointmentType
            title = prefill.title
            notes = prefill.notes ?? ""

            if let suggestedDate = prefill.suggestedDate {
                startDate = suggestedDate
                endDate = suggestedDate.addingTimeInterval(3600) // 1 hour later
            }

            // Suggest contact for the appointment type
            suggestContact(for: prefill.appointmentType)
            return
        }

        // Load existing appointment data (for editing)
        guard let appointment = existingAppointment else { return }

        appointmentType = appointment.appointmentType
        title = appointment.title
        startDate = appointment.startDate
        endDate = appointment.endDate
        isAllDay = appointment.isAllDay
        location = appointment.location ?? ""
        notes = appointment.notes ?? ""
        reminderMinutesBefore = appointment.reminderMinutesBefore
        linkedContactID = appointment.linkedContactID
        linkedGroomingType = appointment.linkedGroomingType
    }

    // MARK: - Save

    private func saveAppointment() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)

        guard !trimmedTitle.isEmpty else {
            showingTitleError = true
            return
        }

        // For all-day events, set times to start/end of day
        var actualStartDate = startDate
        var actualEndDate = endDate

        if isAllDay {
            let calendar = Calendar.current
            actualStartDate = calendar.startOfDay(for: startDate)
            if let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startDate) {
                actualEndDate = endOfDay
            }
        }

        // Determine linkedMilestoneID from prefill or existing appointment
        let milestoneID = prefill?.linkedMilestoneID ?? existingAppointment?.linkedMilestoneID

        let appointment = DogAppointment(
            id: existingAppointment?.id ?? UUID(),
            title: trimmedTitle,
            appointmentType: appointmentType,
            startDate: actualStartDate,
            endDate: actualEndDate,
            isAllDay: isAllDay,
            location: location.nilIfBlank,
            notes: notes.nilIfBlank,
            reminderMinutesBefore: reminderMinutesBefore,
            recurrence: nil, // TODO: Add recurrence editor for premium
            linkedMilestoneID: milestoneID,
            linkedContactID: linkedContactID,
            linkedGroomingType: appointmentType == .grooming ? linkedGroomingType : nil,
            calendarEventID: existingAppointment?.calendarEventID,
            isCompleted: existingAppointment?.isCompleted ?? false,
            completionNotes: existingAppointment?.completionNotes,
            createdAt: existingAppointment?.createdAt ?? Date(),
            modifiedAt: Date()
        )

        if isEditing {
            appointmentStore.updateAppointment(appointment)
        } else {
            appointmentStore.addAppointment(appointment)
        }

        dismiss()
    }
}

#Preview {
    AddEditAppointmentSheet(appointmentStore: AppointmentStore())
        .environment(ContactStore())
}
