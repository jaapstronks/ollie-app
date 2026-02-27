//
//  DogContact.swift
//  OllieShared
//
//  Model for storing dog-related contacts (vet, sitter, groomer, etc.)

import Foundation

/// A stored contact for the dog (vet, sitter, groomer, etc.)
public struct DogContact: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var contactType: ContactType
    public var phone: String?
    public var email: String?
    public var address: String?
    public var notes: String?
    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        name: String,
        contactType: ContactType,
        phone: String? = nil,
        email: String? = nil,
        address: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.contactType = contactType
        self.phone = phone
        self.email = email
        self.address = address
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// Whether the contact has any contact information (phone, email, or address)
    public var hasContactInfo: Bool {
        (phone != nil && !phone!.isEmpty) ||
        (email != nil && !email!.isEmpty) ||
        (address != nil && !address!.isEmpty)
    }
}

// MARK: - Hashable

extension DogContact {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: DogContact, rhs: DogContact) -> Bool {
        lhs.id == rhs.id
    }
}
