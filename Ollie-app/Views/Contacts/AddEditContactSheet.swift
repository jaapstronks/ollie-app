//
//  AddEditContactSheet.swift
//  Ollie-app
//
//  Sheet for adding or editing a contact

import SwiftUI
import OllieShared

/// Sheet for adding or editing a contact
struct AddEditContactSheet: View {
    @ObservedObject var contactStore: ContactStore
    var existingContact: DogContact?

    @Environment(\.dismiss) private var dismiss

    @State private var contactType: ContactType = .vet
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    @State private var latitude: Double?
    @State private var longitude: Double?

    @State private var showingNameError = false
    @State private var showingLocationPicker = false

    private var isEditing: Bool {
        existingContact != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type section
                Section(Strings.Contacts.contactType) {
                    Picker(Strings.Contacts.contactType, selection: $contactType) {
                        ForEach(ContactType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                // Name section
                Section {
                    TextField(Strings.Contacts.namePlaceholder, text: $name)
                        .textContentType(.organizationName)
                } header: {
                    Text(Strings.Contacts.name)
                } footer: {
                    if showingNameError && name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(Strings.Contacts.nameRequired)
                            .foregroundColor(.red)
                    }
                }

                // Contact info section
                Section(Strings.Contacts.contactInfo) {
                    TextField(Strings.Contacts.phonePlaceholder, text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)

                    TextField(Strings.Contacts.emailPlaceholder, text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    TextField(Strings.Contacts.addressPlaceholder, text: $address)
                        .textContentType(.fullStreetAddress)
                }

                // Notes section
                Section(Strings.Contacts.notes) {
                    TextField(Strings.Contacts.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Location section
                Section {
                    if hasLocation {
                        // Show current location
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Color.ollieAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Strings.Contacts.locationSet)
                                    .font(.subheadline)
                                Text(locationString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                showingLocationPicker = true
                            } label: {
                                Text(Strings.Common.edit)
                                    .font(.subheadline)
                            }
                        }

                        Button(role: .destructive) {
                            latitude = nil
                            longitude = nil
                        } label: {
                            Label(Strings.Contacts.removeLocation, systemImage: "trash")
                        }
                    } else {
                        // No location set
                        Button {
                            showingLocationPicker = true
                        } label: {
                            Label(Strings.Contacts.setOnMap, systemImage: "mappin.and.ellipse")
                        }
                    }
                } header: {
                    Text(Strings.Contacts.location)
                } footer: {
                    Text(Strings.Contacts.locationFooter)
                }
            }
            .navigationTitle(isEditing ? Strings.Contacts.editContact : Strings.Contacts.addContact)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveContact()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadExistingContact()
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerMapView(
                    selectedLatitude: $latitude,
                    selectedLongitude: $longitude,
                    address: address.isEmpty ? nil : address,
                    onConfirm: {}
                )
            }
        }
    }

    // MARK: - Location Helpers

    private var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    private var locationString: String {
        guard let lat = latitude, let lon = longitude else { return "" }
        return String(format: "%.5f, %.5f", lat, lon)
    }

    // MARK: - Load Existing Contact

    private func loadExistingContact() {
        guard let contact = existingContact else { return }

        contactType = contact.contactType
        name = contact.name
        phone = contact.phone ?? ""
        email = contact.email ?? ""
        address = contact.address ?? ""
        notes = contact.notes ?? ""
        latitude = contact.latitude
        longitude = contact.longitude
    }

    // MARK: - Save

    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            showingNameError = true
            return
        }

        let contact = DogContact(
            id: existingContact?.id ?? UUID(),
            name: trimmedName,
            contactType: contactType,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            address: address.isEmpty ? nil : address,
            notes: notes.isEmpty ? nil : notes,
            latitude: latitude,
            longitude: longitude,
            createdAt: existingContact?.createdAt ?? Date(),
            modifiedAt: Date()
        )

        if isEditing {
            contactStore.updateContact(contact)
        } else {
            contactStore.addContact(contact)
        }

        dismiss()
    }
}

#Preview {
    AddEditContactSheet(contactStore: ContactStore())
}
