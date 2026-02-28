//
//  Document.swift
//  OllieShared
//
//  Model for storing dog documents (passport, insurance, vaccination records, etc.)

import Foundation

// MARK: - Attachment Type

/// Type of attachment for a document
public enum AttachmentType: String, Codable, CaseIterable, Sendable {
    case none
    case image
    case pdf
}

// MARK: - Document Type

/// Types of documents that can be stored
public enum DocumentType: String, Codable, CaseIterable, Sendable {
    case passport
    case chipRegistration
    case insurance
    case pedigree
    case vaccination
    case medicalRecord
    case registration
    case trainingCertificate
    case other

    /// SF Symbol icon for the document type
    public var icon: String {
        switch self {
        case .passport: return "book.closed.fill"
        case .chipRegistration: return "wave.3.right.circle.fill"
        case .insurance: return "shield.checkered"
        case .pedigree: return "scroll.fill"
        case .vaccination: return "syringe.fill"
        case .medicalRecord: return "cross.case.fill"
        case .registration: return "doc.badge.plus"
        case .trainingCertificate: return "rosette"
        case .other: return "doc.fill"
        }
    }

    /// Localized display name for the document type
    public var displayName: String {
        switch self {
        case .passport:
            return String(localized: "Passport", comment: "Document type: pet passport")
        case .chipRegistration:
            return String(localized: "Chip Registration", comment: "Document type: microchip registration")
        case .insurance:
            return String(localized: "Insurance", comment: "Document type: pet insurance")
        case .pedigree:
            return String(localized: "Pedigree", comment: "Document type: breed pedigree")
        case .vaccination:
            return String(localized: "Vaccination Record", comment: "Document type: vaccination record")
        case .medicalRecord:
            return String(localized: "Medical Record", comment: "Document type: medical record")
        case .registration:
            return String(localized: "Registration", comment: "Document type: official registration")
        case .trainingCertificate:
            return String(localized: "Training Certificate", comment: "Document type: training certificate")
        case .other:
            return String(localized: "Other", comment: "Document type: other document")
        }
    }
}

// MARK: - Document

/// A stored document (scan/photo) for the dog profile
/// Note: Image/PDF data is stored in Core Data and loaded separately via DocumentStore
public struct Document: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var type: DocumentType
    public var title: String?
    public var note: String?
    public var insuranceAgency: String?
    public var attachmentType: AttachmentType
    public var documentDate: Date?
    public var expiryDate: Date?
    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        type: DocumentType,
        title: String? = nil,
        note: String? = nil,
        insuranceAgency: String? = nil,
        attachmentType: AttachmentType = .none,
        documentDate: Date? = nil,
        expiryDate: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.note = note
        self.insuranceAgency = insuranceAgency
        self.attachmentType = attachmentType
        self.documentDate = documentDate
        self.expiryDate = expiryDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Attachment Computed Properties

    /// Whether the document has an image attachment
    public var hasImage: Bool {
        attachmentType == .image
    }

    /// Whether the document has a PDF attachment
    public var hasPDF: Bool {
        attachmentType == .pdf
    }

    /// Whether the document has any attachment
    public var hasAttachment: Bool {
        attachmentType != .none
    }

    // MARK: - Computed Properties

    /// Display title: custom title if set, otherwise document type name
    public var displayTitle: String {
        title ?? type.displayName
    }

    /// Whether the document has expired (past expiry date)
    public var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }

    /// Whether the document expires within 30 days
    public var expiresSoon: Bool {
        guard let expiry = expiryDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiry > Date() && expiry <= thirtyDaysFromNow
    }

    /// Days until expiry (nil if no expiry date, negative if expired)
    public var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: expiry)).day
    }
}

// MARK: - Hashable

extension Document {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.id == rhs.id
    }
}
