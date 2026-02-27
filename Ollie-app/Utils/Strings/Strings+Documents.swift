//
//  Strings+Documents.swift
//  Ollie-app
//
//  Document storage strings

import Foundation

private let table = "Documents"

extension Strings {

    // MARK: - Documents
    enum Documents {
        // View titles
        static let title = String(localized: "Documents", table: table)
        static let addDocument = String(localized: "Add Document", table: table)
        static let editDocument = String(localized: "Edit Document", table: table)

        // Empty state
        static let noDocuments = String(localized: "No Documents", table: table)
        static let noDocumentsHint = String(localized: "Store scans of your dog's important documents here.", table: table)

        // Form fields
        static let documentType = String(localized: "Type", table: table)
        static let customTitle = String(localized: "Title", table: table)
        static let customTitlePlaceholder = String(localized: "Optional custom title", table: table)
        static let documentDate = String(localized: "Document Date", table: table)
        static let expiryDate = String(localized: "Expiry Date", table: table)
        static let hasExpiry = String(localized: "Has Expiry Date", table: table)
        static let notes = String(localized: "Notes", table: table)
        static let notesPlaceholder = String(localized: "Optional notes about this document...", table: table)
        static let photo = String(localized: "Photo", table: table)

        // Expiry status
        static let expired = String(localized: "Expired", table: table)
        static let expiresSoon = String(localized: "Expires Soon", table: table)

        static func expiresIn(_ days: Int) -> String {
            if days == 1 {
                return String(localized: "Expires in 1 day", table: table)
            } else {
                return String(localized: "Expires in \(days) days", table: table)
            }
        }

        static func expiredDaysAgo(_ days: Int) -> String {
            if days == 1 {
                return String(localized: "Expired 1 day ago", table: table)
            } else {
                return String(localized: "Expired \(days) days ago", table: table)
            }
        }

        // Document types (for picker)
        static let typePassport = String(localized: "Passport", table: table)
        static let typeChipRegistration = String(localized: "Chip Registration", table: table)
        static let typeInsurance = String(localized: "Insurance", table: table)
        static let typePedigree = String(localized: "Pedigree", table: table)
        static let typeVaccination = String(localized: "Vaccination Record", table: table)
        static let typeMedicalRecord = String(localized: "Medical Record", table: table)
        static let typeRegistration = String(localized: "Registration", table: table)
        static let typeTrainingCertificate = String(localized: "Training Certificate", table: table)
        static let typeOther = String(localized: "Other", table: table)

        // Hints
        static let titleHint = String(localized: "Leave empty to use the document type as title", table: table)

        // Actions
        static let viewFullSize = String(localized: "View Full Size", table: table)
        static let share = String(localized: "Share", table: table)

        // Delete confirmation
        static let deleteConfirmTitle = String(localized: "Delete Document?", table: table)
        static let deleteConfirmMessage = String(localized: "This will permanently delete this document and its photo.", table: table)
    }
}
