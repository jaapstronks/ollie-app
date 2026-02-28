//
//  ContactsView.swift
//  Ollie-app
//
//  Main view for managing dog contacts

import SwiftUI
import OllieShared

/// Main view for listing and managing contacts
struct ContactsView: View {
    @ObservedObject var contactStore: ContactStore
    var appointmentStore: AppointmentStore?

    @State private var showingAddSheet = false
    @State private var showingImportSheet = false
    @State private var contactToDelete: DogContact?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if contactStore.contacts.isEmpty {
                emptyState
            } else {
                contactList
            }
        }
        .navigationTitle(Strings.Contacts.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label(Strings.Contacts.addContact, systemImage: "plus")
                    }

                    Button {
                        showingImportSheet = true
                    } label: {
                        Label(Strings.Contacts.importFromContacts, systemImage: "person.crop.circle.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditContactSheet(contactStore: contactStore)
        }
        .sheet(isPresented: $showingImportSheet) {
            ContactImportSheet(contactStore: contactStore)
        }
        .alert(
            Strings.Contacts.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation,
            presenting: contactToDelete
        ) { contact in
            Button(Strings.Common.cancel, role: .cancel) {
                contactToDelete = nil
            }
            Button(Strings.Common.delete, role: .destructive) {
                contactStore.deleteContact(contact)
                contactToDelete = nil
            }
        } message: { _ in
            Text(Strings.Contacts.deleteConfirmMessage)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView {
            Label(Strings.Contacts.noContacts, systemImage: "person.crop.circle")
        } description: {
            Text(Strings.Contacts.noContactsHint)
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Text(Strings.Contacts.addContact)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Contact List

    @ViewBuilder
    private var contactList: some View {
        List {
            // Group by contact type
            ForEach(groupedContactTypes, id: \.self) { type in
                Section(type.displayName) {
                    ForEach(contactsForType(type)) { contact in
                        NavigationLink {
                            ContactDetailView(
                                contact: contact,
                                contactStore: contactStore,
                                appointmentStore: appointmentStore
                            )
                        } label: {
                            ContactRow(contact: contact)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                contactToDelete = contact
                                showingDeleteConfirmation = true
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helpers

    /// Contact types that have at least one contact, sorted by display name
    private var groupedContactTypes: [ContactType] {
        let typesWithContacts = Set(contactStore.contacts.map { $0.contactType })
        return ContactType.allCases.filter { typesWithContacts.contains($0) }
    }

    /// Contacts for a specific type, sorted by name
    private func contactsForType(_ type: ContactType) -> [DogContact] {
        contactStore.contacts
            .filter { $0.contactType == type }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

#Preview {
    NavigationStack {
        ContactsView(contactStore: ContactStore())
    }
}
