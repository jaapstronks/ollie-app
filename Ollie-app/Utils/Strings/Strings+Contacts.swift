//
//  Strings+Contacts.swift
//  Ollie-app
//
//  Contact storage strings

import Foundation

private let table = "Contacts"

extension Strings {

    // MARK: - Contacts
    enum Contacts {
        // View titles
        static let title = String(localized: "Contacts", table: table)
        static let addContact = String(localized: "Add Contact", table: table)
        static let editContact = String(localized: "Edit Contact", table: table)

        // Empty state
        static let noContacts = String(localized: "No Contacts", table: table)
        static let noContactsHint = String(localized: "Store your vet, groomer, sitter, and other important contacts here.", table: table)

        // Form fields
        static let contactType = String(localized: "Type", table: table)
        static let name = String(localized: "Name", table: table)
        static let namePlaceholder = String(localized: "Contact name", table: table)
        static let phone = String(localized: "Phone", table: table)
        static let phonePlaceholder = String(localized: "Phone number", table: table)
        static let email = String(localized: "Email", table: table)
        static let emailPlaceholder = String(localized: "Email address", table: table)
        static let address = String(localized: "Address", table: table)
        static let addressPlaceholder = String(localized: "Street address", table: table)
        static let notes = String(localized: "Notes", table: table)
        static let notesPlaceholder = String(localized: "Optional notes about this contact...", table: table)

        // Contact info section
        static let contactInfo = String(localized: "Contact Info", table: table)

        // Actions
        static let call = String(localized: "Call", table: table)
        static let sendEmail = String(localized: "Send Email", table: table)
        static let openInMaps = String(localized: "Open in Maps", table: table)

        // Delete confirmation
        static let deleteConfirmTitle = String(localized: "Delete Contact?", table: table)
        static let deleteConfirmMessage = String(localized: "This will permanently delete this contact.", table: table)

        // Validation
        static let nameRequired = String(localized: "Name is required", table: table)

        // Import from Contacts
        static let importFromContacts = String(localized: "Import from Contacts", table: table)
        static let importAction = String(localized: "Import", table: table)
        static let selectContact = String(localized: "Select a Contact", table: table)
        static let selectContactHint = String(localized: "Choose a contact from your address book to import their details.", table: table)
        static let chooseContact = String(localized: "Choose Contact", table: table)
        static let chooseAnotherContact = String(localized: "Choose Another Contact", table: table)
        static let nameAlwaysImported = String(localized: "The name will always be imported.", table: table)

        // Contact types (for picker)
        static let typeVet = String(localized: "Veterinarian", table: table)
        static let typeEmergencyVet = String(localized: "Emergency Vet", table: table)
        static let typeSitter = String(localized: "Pet Sitter", table: table)
        static let typeDaycare = String(localized: "Daycare", table: table)
        static let typeGroomer = String(localized: "Groomer", table: table)
        static let typeTrainer = String(localized: "Trainer", table: table)
        static let typeWalker = String(localized: "Dog Walker", table: table)
        static let typePetStore = String(localized: "Pet Store", table: table)
        static let typeBreeder = String(localized: "Breeder", table: table)
        static let typeOther = String(localized: "Other", table: table)

        // Location
        static let location = String(localized: "Location", table: table, comment: "Section header for contact location")
        static let locationSet = String(localized: "Location set", table: table, comment: "Indicates location is set")
        static let setOnMap = String(localized: "Set on map", table: table, comment: "Button to open location picker")
        static let removeLocation = String(localized: "Remove location", table: table, comment: "Button to remove location")
        static let locationFooter = String(localized: "Add a location to show this contact on the Places map.", table: table, comment: "Footer explaining location feature")

        // Appointments
        static let nextAppointment = String(localized: "Next appointment", table: table, comment: "Section header for upcoming appointment")
        static let visitHistory = String(localized: "Visit history", table: table, comment: "Section header for past appointments")
        static let noAppointments = String(localized: "No appointments scheduled", table: table, comment: "Empty state when no appointments")
        static let viewInCalendar = String(localized: "View in Calendar", table: table, comment: "Button to navigate to calendar")
    }
}
