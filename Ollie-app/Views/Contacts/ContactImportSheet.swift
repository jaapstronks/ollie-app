//
//  ContactImportSheet.swift
//  Ollie-app
//
//  Sheet for importing a contact from the iOS Contacts app

import SwiftUI
import ContactsUI
import OllieShared

/// Data extracted from a CNContact for import
struct ImportedContactData {
    var name: String
    var phones: [String]
    var emails: [String]
    var addresses: [String]

    var hasPhone: Bool { !phones.isEmpty }
    var hasEmail: Bool { !emails.isEmpty }
    var hasAddress: Bool { !addresses.isEmpty }

    /// Check if the contact has any importable data
    var isEmpty: Bool {
        name.isEmpty && phones.isEmpty && emails.isEmpty && addresses.isEmpty
    }
}

/// Sheet for importing a contact from the iOS Address Book
struct ContactImportSheet: View {
    @ObservedObject var contactStore: ContactStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingContactPicker = false
    @State private var importedData: ImportedContactData?
    @State private var selectedContactType: ContactType = .other

    // Field selection
    @State private var selectedPhone: String?
    @State private var selectedEmail: String?
    @State private var selectedAddress: String?

    var body: some View {
        NavigationStack {
            Group {
                if let data = importedData {
                    fieldSelectionView(data: data)
                } else {
                    selectContactPrompt
                }
            }
            .navigationTitle(Strings.Contacts.importFromContacts)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                if importedData != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Strings.Contacts.importAction) {
                            importContact()
                        }
                        .disabled(importedData?.name.isEmpty ?? true)
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPicker { contact in
                    if let contact = contact {
                        importedData = extractContactData(from: contact)
                        // Pre-select first values
                        selectedPhone = importedData?.phones.first
                        selectedEmail = importedData?.emails.first
                        selectedAddress = importedData?.addresses.first
                    }
                }
            }
            .onAppear {
                // Automatically show contact picker when sheet appears
                showingContactPicker = true
            }
        }
    }

    // MARK: - Select Contact Prompt

    @ViewBuilder
    private var selectContactPrompt: some View {
        ContentUnavailableView {
            Label(Strings.Contacts.selectContact, systemImage: "person.crop.circle.badge.plus")
        } description: {
            Text(Strings.Contacts.selectContactHint)
        } actions: {
            Button {
                showingContactPicker = true
            } label: {
                Text(Strings.Contacts.chooseContact)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Field Selection View

    @ViewBuilder
    private func fieldSelectionView(data: ImportedContactData) -> some View {
        Form {
            // Name section (always shown)
            Section {
                HStack {
                    Label(data.name, systemImage: "person.fill")
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }
            } header: {
                Text(Strings.Contacts.name)
            } footer: {
                Text(Strings.Contacts.nameAlwaysImported)
            }

            // Contact type picker
            Section(Strings.Contacts.contactType) {
                Picker(Strings.Contacts.contactType, selection: $selectedContactType) {
                    ForEach(ContactType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Phone selection
            if data.hasPhone {
                Section(Strings.Contacts.phone) {
                    ForEach(data.phones, id: \.self) { phone in
                        Button {
                            selectedPhone = selectedPhone == phone ? nil : phone
                        } label: {
                            HStack {
                                Label(phone, systemImage: "phone.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedPhone == phone {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }

            // Email selection
            if data.hasEmail {
                Section(Strings.Contacts.email) {
                    ForEach(data.emails, id: \.self) { email in
                        Button {
                            selectedEmail = selectedEmail == email ? nil : email
                        } label: {
                            HStack {
                                Label(email, systemImage: "envelope.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedEmail == email {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }

            // Address selection
            if data.hasAddress {
                Section(Strings.Contacts.address) {
                    ForEach(data.addresses, id: \.self) { address in
                        Button {
                            selectedAddress = selectedAddress == address ? nil : address
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Label {
                                        Text(address)
                                            .multilineTextAlignment(.leading)
                                    } icon: {
                                        Image(systemName: "mappin.and.ellipse")
                                    }
                                }
                                .foregroundStyle(.primary)
                                Spacer()
                                if selectedAddress == address {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }

            // Change contact button
            Section {
                Button {
                    showingContactPicker = true
                } label: {
                    Label(Strings.Contacts.chooseAnotherContact, systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }

    // MARK: - Extract Contact Data

    private func extractContactData(from contact: CNContact) -> ImportedContactData {
        // Build name from components
        let name: String
        if !contact.organizationName.isEmpty {
            name = contact.organizationName
        } else {
            let formatter = CNContactFormatter()
            formatter.style = .fullName
            name = formatter.string(from: contact) ?? ""
        }

        // Extract all phone numbers
        let phones = contact.phoneNumbers.map { phoneNumber in
            phoneNumber.value.stringValue
        }

        // Extract all email addresses
        let emails = contact.emailAddresses.map { email in
            email.value as String
        }

        // Extract all addresses
        let addresses = contact.postalAddresses.map { address in
            CNPostalAddressFormatter.string(from: address.value, style: .mailingAddress)
        }

        return ImportedContactData(
            name: name,
            phones: phones,
            emails: emails,
            addresses: addresses
        )
    }

    // MARK: - Import Contact

    private func importContact() {
        guard let data = importedData, !data.name.isEmpty else { return }

        let contact = DogContact(
            name: data.name,
            contactType: selectedContactType,
            phone: selectedPhone,
            email: selectedEmail,
            address: selectedAddress
        )

        contactStore.addContact(contact)
        dismiss()
    }
}

// MARK: - Contact Picker (UIKit Wrapper)

/// UIViewControllerRepresentable wrapper for CNContactPickerViewController
struct ContactPicker: UIViewControllerRepresentable {
    var onSelectContact: (CNContact?) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectContact: onSelectContact)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var onSelectContact: (CNContact?) -> Void

        init(onSelectContact: @escaping (CNContact?) -> Void) {
            self.onSelectContact = onSelectContact
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onSelectContact(contact)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onSelectContact(nil)
        }
    }
}

#Preview {
    ContactImportSheet(contactStore: ContactStore())
}
