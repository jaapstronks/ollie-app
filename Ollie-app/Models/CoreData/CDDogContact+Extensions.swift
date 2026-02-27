//
//  CDDogContact+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between DogContact and CDDogContact

import CoreData
import OllieShared

extension CDDogContact {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from DogContact struct
    func update(from contact: DogContact) {
        self.id = contact.id
        self.name = contact.name
        self.contactType = contact.contactType.rawValue
        self.phone = contact.phone
        self.email = contact.email
        self.address = contact.address
        self.notes = contact.notes
        self.createdAt = contact.createdAt
        self.modifiedAt = Date()
    }

    /// Create a new CDDogContact from a DogContact struct
    static func create(from contact: DogContact, in context: NSManagedObjectContext) -> CDDogContact {
        let cdContact = CDDogContact(context: context)
        cdContact.update(from: contact)
        return cdContact
    }

    // MARK: - Convert to Swift Struct

    /// Convert to DogContact struct
    func toContact() -> DogContact? {
        guard let id = self.id,
              let name = self.name,
              let typeString = self.contactType,
              let contactType = ContactType(rawValue: typeString),
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        return DogContact(
            id: id,
            name: name,
            contactType: contactType,
            phone: self.phone,
            email: self.email,
            address: self.address,
            notes: self.notes,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDDogContact {

    /// Fetch all contacts sorted by creation date (newest first)
    static func fetchAllContacts(in context: NSManagedObjectContext) -> [CDDogContact] {
        let request = NSFetchRequest<CDDogContact>(entityName: "CDDogContact")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDogContact.createdAt, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch contacts by type
    static func fetchContacts(type: ContactType, in context: NSManagedObjectContext) -> [CDDogContact] {
        let request = NSFetchRequest<CDDogContact>(entityName: "CDDogContact")
        request.predicate = NSPredicate(format: "contactType == %@", type.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDogContact.createdAt, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch contact by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDDogContact? {
        let request = NSFetchRequest<CDDogContact>(entityName: "CDDogContact")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Count all contacts
    static func countContacts(in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDDogContact>(entityName: "CDDogContact")
        return (try? context.count(for: request)) ?? 0
    }
}
