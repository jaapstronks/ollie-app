//
//  Document.swift
//  OtisShared
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
            return Strings.Documents.passport
        case .chipRegistration:
            return Strings.Documents.chipRegistration
        case .insurance:
            return Strings.Documents.insurance
        case .pedigree:
            return Strings.Documents.pedigree
        case .vaccination:
            return Strings.Documents.vaccination
        case .medicalRecord:
            return Strings.Documents.medicalRecord
        case .registration:
            return Strings.Documents.registration
        case .trainingCertificate:
            return Strings.Documents.trainingCertificate
        case .other:
            return Strings.Documents.other
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
        return expiry > Date() && expiry <= Date.daysFromNow(30)
    }

    /// Days until expiry (nil if no expiry date, negative if expired)
    public var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        return expiry.startOfDay.daysSince(Date().startOfDay)
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
