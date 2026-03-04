//
//  ContactsView.swift
//  Otis-app
//
//  Main view for managing dog contacts

import SwiftUI
import OtisShared

/// Main view for listing and managing contacts
struct ContactsView: View {
    @ObservedObject var contactStore: ContactStore
    var appointmentStore: AppointmentStore?

    @State private var showingAddSheet = false
    @State private var contactToDelete: DogContact?
    @State private var showingDeleteConfirmation = false

    // First-visit tip tracking
    @AppStorage("hasSeenContactsTip") private var hasSeenContactsTip = false

    var body: some View {
        Group {
            if contactStore.contacts.isEmpty {
                emptyStateWithTip
            } else {
                contactListWithTip
            }
        }
        .navigationTitle(Strings.Contacts.title)
        .sheet(isPresented: $showingAddSheet) {
            AddEditContactSheet(contactStore: contactStore)
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

    // MARK: - Empty State with Tip

    @ViewBuilder
    private var emptyStateWithTip: some View {
        ScrollView {
            VStack(spacing: 20) {
                // First-visit tip (shows once, then dismissed)
                if !hasSeenContactsTip {
                    FeatureTipCard(
                        tip: .scheduleContacts,
                        onAction: {
                            showingAddSheet = true
                            hasSeenContactsTip = true
                        },
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                hasSeenContactsTip = true
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top)
                }

                // Empty state (always shows when empty)
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
                .padding(.top, hasSeenContactsTip ? 60 : 0)
            }
        }
    }

    // MARK: - Contact List with Tip

    @ViewBuilder
    private var contactListWithTip: some View {
        List {
            // First-visit tip at top of list
            if !hasSeenContactsTip {
                Section {
                    FeatureTipCard(
                        tip: .scheduleContacts,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                hasSeenContactsTip = true
                            }
                        }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            // Contact groups
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
