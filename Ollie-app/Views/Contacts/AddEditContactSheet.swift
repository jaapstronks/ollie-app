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

    @State private var showingNameError = false

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
        }
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
