# TODO: Dog Contacts (MVP)

## Overview

Add a simple **Contacts** feature to store important dog-related contacts: vet, emergency vet, dog sitter, doggy daycare, groomer, trainer, etc.

This is an **MVP implementation** with manual entry only. Future enhancements may include "Import from iOS Contacts" functionality.

## Design Decisions

### Why Manual Entry (Not iOS Contacts Linking)

1. **Sharing works** - Family members who share the dog profile will see contacts even if they don't have them in their own iOS Contacts
2. **No permission prompts** - Contacts permission is a big ask for a puppy app
3. **CloudKit syncs automatically** - Core Data with CloudKit handles multi-device/multi-user sync
4. **Any user can add/edit** - Not dependent on one person's iOS Contacts

### Future Enhancement (Not MVP)

- "Import from Contacts" button using `CNContactPickerViewController`
- Copies selected fields into app's data model (not links)
- User picks which contact and which fields to import

## Architecture

### Data Layer

#### New Core Data Entity: `CDDogContact`

Add to `Ollie-app/Ollie.xcdatamodeld`:

```xml
Entity: CDDogContact
Attributes:
  - id: UUID
  - name: String
  - contactType: String          // maps to ContactType enum
  - phone: String?
  - email: String?
  - address: String?
  - notes: String?
  - createdAt: Date
  - updatedAt: Date

Relationships:
  - profile: CDPuppyProfile (inverse: contacts, to-one)
```

Add inverse relationship on `CDPuppyProfile`:
```
  - contacts: NSSet<CDDogContact> (inverse: profile, to-many, cascade delete)
```

#### OllieShared Model: `ContactType`

Add to `OllieShared/Sources/OllieShared/Models/`:

```swift
// ContactType.swift
import Foundation

public enum ContactType: String, CaseIterable, Codable, Identifiable, Sendable {
    case vet = "vet"
    case emergencyVet = "emergency_vet"
    case sitter = "sitter"
    case daycare = "daycare"
    case groomer = "groomer"
    case trainer = "trainer"
    case walker = "walker"
    case petStore = "pet_store"
    case breeder = "breeder"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vet: return String(localized: "contact.type.vet")
        case .emergencyVet: return String(localized: "contact.type.emergencyVet")
        case .sitter: return String(localized: "contact.type.sitter")
        case .daycare: return String(localized: "contact.type.daycare")
        case .groomer: return String(localized: "contact.type.groomer")
        case .trainer: return String(localized: "contact.type.trainer")
        case .walker: return String(localized: "contact.type.walker")
        case .petStore: return String(localized: "contact.type.petStore")
        case .breeder: return String(localized: "contact.type.breeder")
        case .other: return String(localized: "contact.type.other")
        }
    }

    public var systemImage: String {
        switch self {
        case .vet: return "stethoscope"
        case .emergencyVet: return "cross.case.fill"
        case .sitter: return "house.fill"
        case .daycare: return "building.2.fill"
        case .groomer: return "scissors"
        case .trainer: return "figure.walk.motion"
        case .walker: return "figure.walk"
        case .petStore: return "cart.fill"
        case .breeder: return "pawprint.fill"
        case .other: return "person.fill"
        }
    }
}
```

#### OllieShared Model: `DogContact`

```swift
// DogContact.swift
import Foundation

public struct DogContact: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var contactType: ContactType
    public var phone: String?
    public var email: String?
    public var address: String?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    public var hasContactInfo: Bool {
        phone != nil || email != nil
    }

    public init(
        id: UUID = UUID(),
        name: String,
        contactType: ContactType,
        phone: String? = nil,
        email: String? = nil,
        address: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.contactType = contactType
        self.phone = phone
        self.email = email
        self.address = address
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

### ViewModel

```swift
// ContactStore.swift
import Foundation
import CoreData
import SwiftUI

@MainActor
final class ContactStore: ObservableObject {
    @Published var contacts: [DogContact] = []

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchContacts()
    }

    func fetchContacts() {
        let request = CDDogContact.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDDogContact.contactType, ascending: true),
            NSSortDescriptor(keyPath: \CDDogContact.name, ascending: true)
        ]

        do {
            let results = try context.fetch(request)
            contacts = results.compactMap { $0.toDogContact() }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }

    func addContact(
        name: String,
        type: ContactType,
        phone: String?,
        email: String?,
        address: String?,
        notes: String?,
        profile: CDPuppyProfile
    ) throws {
        let entity = CDDogContact(context: context)
        entity.id = UUID()
        entity.name = name
        entity.contactType = type.rawValue
        entity.phone = phone?.isEmpty == true ? nil : phone
        entity.email = email?.isEmpty == true ? nil : email
        entity.address = address?.isEmpty == true ? nil : address
        entity.notes = notes?.isEmpty == true ? nil : notes
        entity.createdAt = Date()
        entity.updatedAt = Date()
        entity.profile = profile

        try context.save()
        fetchContacts()
    }

    func updateContact(_ contact: DogContact) throws {
        let request = CDDogContact.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)

        if let entity = try context.fetch(request).first {
            entity.name = contact.name
            entity.contactType = contact.contactType.rawValue
            entity.phone = contact.phone
            entity.email = contact.email
            entity.address = contact.address
            entity.notes = contact.notes
            entity.updatedAt = Date()

            try context.save()
            fetchContacts()
        }
    }

    func deleteContact(_ contact: DogContact) throws {
        let request = CDDogContact.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
        fetchContacts()
    }
}
```

## Views

### View Hierarchy

```
DogProfileSettingsView (existing)
  └── Section: "Contacts"
        ├── NavigationLink → ContactsView
        └── Count badge

ContactsView
  ├── List grouped by ContactType
  │     └── ContactRow (name, type icon, phone preview)
  ├── Empty state (ContentUnavailableView)
  ├── Toolbar: + button → AddContactSheet
  └── Swipe to delete

AddContactSheet / EditContactSheet
  ├── TextField: name (required)
  ├── Picker: ContactType
  ├── TextField: phone (optional, .phonePad keyboard)
  ├── TextField: email (optional, .emailAddress keyboard)
  ├── TextField: address (optional)
  ├── TextEditor: notes (optional)
  └── Save button

ContactDetailView
  ├── Contact info with tap-to-call/email/map buttons
  ├── Notes section
  ├── Edit button
  └── Delete button
```

### Key View: ContactsView

```swift
// ContactsView.swift
import SwiftUI
import OllieShared

struct ContactsView: View {
    @StateObject private var store: ContactStore
    @State private var showingAddSheet = false

    init(context: NSManagedObjectContext) {
        _store = StateObject(wrappedValue: ContactStore(context: context))
    }

    var body: some View {
        Group {
            if store.contacts.isEmpty {
                ContentUnavailableView(
                    Strings.Contacts.emptyTitle,
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text(Strings.Contacts.emptyDescription)
                )
            } else {
                List {
                    ForEach(groupedContacts, id: \.key) { type, contacts in
                        Section(type.displayName) {
                            ForEach(contacts) { contact in
                                NavigationLink(value: contact) {
                                    ContactRow(contact: contact)
                                }
                            }
                            .onDelete { indexSet in
                                deleteContacts(contacts: contacts, at: indexSet)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Strings.Contacts.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContactSheet(store: store)
        }
        .navigationDestination(for: DogContact.self) { contact in
            ContactDetailView(contact: contact, store: store)
        }
    }

    private var groupedContacts: [(key: ContactType, value: [DogContact])] {
        Dictionary(grouping: store.contacts) { $0.contactType }
            .sorted { $0.key.displayName < $1.key.displayName }
    }

    private func deleteContacts(contacts: [DogContact], at offsets: IndexSet) {
        for index in offsets {
            try? store.deleteContact(contacts[index])
        }
    }
}
```

### ContactRow

```swift
// ContactRow.swift
import SwiftUI
import OllieShared

struct ContactRow: View {
    let contact: DogContact

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: contact.contactType.systemImage)
                .font(.title3)
                .foregroundStyle(.ollieAccent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.body)

                if let phone = contact.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

### ContactDetailView with Action Buttons

```swift
// ContactDetailView.swift
import SwiftUI
import OllieShared

struct ContactDetailView: View {
    let contact: DogContact
    @ObservedObject var store: ContactStore
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Contact type header
            Section {
                Label(contact.contactType.displayName, systemImage: contact.contactType.systemImage)
                    .font(.headline)
            }

            // Quick actions
            if contact.hasContactInfo {
                Section {
                    if let phone = contact.phone {
                        Button {
                            callPhone(phone)
                        } label: {
                            Label(phone, systemImage: "phone.fill")
                        }
                    }

                    if let email = contact.email {
                        Button {
                            sendEmail(email)
                        } label: {
                            Label(email, systemImage: "envelope.fill")
                        }
                    }

                    if let address = contact.address {
                        Button {
                            openMaps(address)
                        } label: {
                            Label(address, systemImage: "map.fill")
                        }
                    }
                }
            }

            // Notes
            if let notes = contact.notes, !notes.isEmpty {
                Section(Strings.Contacts.notes) {
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }

            // Delete
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label(Strings.Common.delete, systemImage: "trash")
                }
            }
        }
        .navigationTitle(contact.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(Strings.Common.edit) {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditContactSheet(contact: contact, store: store)
        }
        .alert(Strings.Contacts.deleteConfirmTitle, isPresented: $showingDeleteAlert) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Common.delete, role: .destructive) {
                try? store.deleteContact(contact)
            }
        } message: {
            Text(Strings.Contacts.deleteConfirmMessage)
        }
    }

    private func callPhone(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
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
```

## File List

### New Files

| File | Location |
|------|----------|
| `ContactType.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `DogContact.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `ContactStore.swift` | `Ollie-app/ViewModels/` |
| `ContactsView.swift` | `Ollie-app/Views/Contacts/` |
| `AddContactSheet.swift` | `Ollie-app/Views/Contacts/` |
| `EditContactSheet.swift` | `Ollie-app/Views/Contacts/` |
| `ContactDetailView.swift` | `Ollie-app/Views/Contacts/` |
| `ContactRow.swift` | `Ollie-app/Views/Contacts/` |

### Modified Files

| File | Change |
|------|--------|
| `Ollie-app/Ollie.xcdatamodeld` | Add `CDDogContact` entity + relationship on `CDPuppyProfile` |
| `Ollie-app/Views/Settings/DogProfileSettingsView.swift` | Add "Contacts" section with NavigationLink |
| `OllieShared/Sources/OllieShared/Utils/Strings.swift` | Add `Strings.Contacts.*` constants |
| `Ollie-app/Localizable.xcstrings` | Add all contact-related keys (en + nl) |

## Localization Keys

Add to `Strings.swift`:

```swift
public enum Contacts {
    public static let title = String(localized: "contacts.title")
    public static let emptyTitle = String(localized: "contacts.empty.title")
    public static let emptyDescription = String(localized: "contacts.empty.description")
    public static let addTitle = String(localized: "contacts.add.title")
    public static let editTitle = String(localized: "contacts.edit.title")
    public static let name = String(localized: "contacts.name")
    public static let type = String(localized: "contacts.type")
    public static let phone = String(localized: "contacts.phone")
    public static let email = String(localized: "contacts.email")
    public static let address = String(localized: "contacts.address")
    public static let notes = String(localized: "contacts.notes")
    public static let deleteConfirmTitle = String(localized: "contacts.delete.title")
    public static let deleteConfirmMessage = String(localized: "contacts.delete.message")
}
```

Translations (en / nl):

```
contacts.title = "Contacts" / "Contacten"
contacts.empty.title = "No Contacts" / "Geen contacten"
contacts.empty.description = "Add important contacts like your vet, dog sitter, or groomer." / "Voeg belangrijke contacten toe zoals je dierenarts, oppas of trimmer."
contacts.add.title = "Add Contact" / "Contact toevoegen"
contacts.edit.title = "Edit Contact" / "Contact bewerken"
contacts.name = "Name" / "Naam"
contacts.type = "Type" / "Type"
contacts.phone = "Phone" / "Telefoon"
contacts.email = "Email" / "E-mail"
contacts.address = "Address" / "Adres"
contacts.notes = "Notes" / "Notities"
contacts.delete.title = "Delete Contact?" / "Contact verwijderen?"
contacts.delete.message = "This cannot be undone." / "Dit kan niet ongedaan worden gemaakt."
contact.type.vet = "Veterinarian" / "Dierenarts"
contact.type.emergencyVet = "Emergency Vet" / "Spoeddierenarts"
contact.type.sitter = "Dog Sitter" / "Hondenoppas"
contact.type.daycare = "Doggy Daycare" / "Hondenopvang"
contact.type.groomer = "Groomer" / "Trimmer"
contact.type.trainer = "Trainer" / "Trainer"
contact.type.walker = "Dog Walker" / "Hondenuitlaatservice"
contact.type.petStore = "Pet Store" / "Dierenwinkel"
contact.type.breeder = "Breeder" / "Fokker"
contact.type.other = "Other" / "Overig"
```

## Implementation Order

1. **Core Data model** - Add `CDDogContact` entity and relationship to `CDPuppyProfile`
2. **OllieShared models** - `ContactType` enum + `DogContact` struct
3. **ContactStore** - ViewModel with CRUD operations
4. **ContactRow** - List row component
5. **ContactsView** - Main list view with empty state
6. **AddContactSheet** - Creation form
7. **EditContactSheet** - Edit form (similar to add)
8. **ContactDetailView** - Detail view with call/email/map actions
9. **Integration** - Add section to `DogProfileSettingsView`
10. **Localization** - Add all string keys

## Future Considerations

- **Import from iOS Contacts** - `CNContactPickerViewController` to copy contact data
- **Contact sharing** - Share contact card via Messages/AirDrop
- **Favorite contacts** - Pin important contacts to top
- **Quick dial widget** - Widget with emergency vet button
