//
//  CDDocument+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between Document and CDDocument

import CoreData
import OllieShared
import UIKit
import PDFKit

extension CDDocument {

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from Document struct (does not update image/PDF data)
    func update(from document: Document) {
        self.id = document.id
        self.type = document.type.rawValue
        self.title = document.title
        self.note = document.note
        self.insuranceAgency = document.insuranceAgency
        self.attachmentType = document.attachmentType.rawValue
        self.documentDate = document.documentDate
        self.expiryDate = document.expiryDate
        self.createdAt = document.createdAt
        self.modifiedAt = Date()
    }

    /// Create a new CDDocument from a Document struct
    static func create(from document: Document, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDDocument {
        let cdDocument = CDDocument(context: context)
        cdDocument.update(from: document)
        cdDocument.profile = profile
        return cdDocument
    }

    // MARK: - Convert to Swift Struct

    /// Convert to Document struct
    func toDocument() -> Document? {
        guard let id = self.id,
              let typeString = self.type,
              let type = DocumentType(rawValue: typeString),
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        // Determine attachment type from stored value or infer from data
        let attachment: AttachmentType
        if let attachmentTypeString = self.attachmentType,
           let storedType = AttachmentType(rawValue: attachmentTypeString) {
            attachment = storedType
        } else if self.pdfData != nil {
            attachment = .pdf
        } else if self.imageData != nil {
            attachment = .image
        } else {
            attachment = .none
        }

        return Document(
            id: id,
            type: type,
            title: self.title,
            note: self.note,
            insuranceAgency: self.insuranceAgency,
            attachmentType: attachment,
            documentDate: self.documentDate,
            expiryDate: self.expiryDate,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }

    // MARK: - Image Handling

    /// JPEG compression quality for full-size images
    private static let imageCompressionQuality: CGFloat = 0.85

    /// JPEG compression quality for thumbnails
    private static let thumbnailCompressionQuality: CGFloat = 0.80

    /// Thumbnail size (square)
    private static let thumbnailSize: CGFloat = 200

    /// Set image data from UIImage (generates thumbnail automatically)
    func setImage(_ image: UIImage?) {
        guard let image = image else {
            self.imageData = nil
            self.thumbnailData = nil
            self.attachmentType = AttachmentType.none.rawValue
            return
        }

        // Save full-size image
        self.imageData = image.jpegData(compressionQuality: Self.imageCompressionQuality)
        self.attachmentType = AttachmentType.image.rawValue

        // Generate and save thumbnail
        let thumbnail = Self.generateThumbnail(from: image, size: Self.thumbnailSize)
        self.thumbnailData = thumbnail.jpegData(compressionQuality: Self.thumbnailCompressionQuality)
    }

    /// Get full-size image
    func getImage() -> UIImage? {
        guard let data = self.imageData else { return nil }
        return UIImage(data: data)
    }

    /// Get thumbnail image
    func getThumbnail() -> UIImage? {
        guard let data = self.thumbnailData else { return nil }
        return UIImage(data: data)
    }

    /// Generate a square thumbnail from an image
    private static func generateThumbnail(from image: UIImage, size: CGFloat) -> UIImage {
        let targetSize = CGSize(width: size, height: size)

        // Calculate crop rect for center square
        let originalSize = image.size
        let minDimension = min(originalSize.width, originalSize.height)
        let cropRect = CGRect(
            x: (originalSize.width - minDimension) / 2,
            y: (originalSize.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )

        // Crop to square
        guard let cgImage = image.cgImage,
              let croppedImage = cgImage.cropping(to: cropRect) else {
            // Fallback: just resize
            return resizeImage(image, to: targetSize)
        }

        // Resize the cropped square image
        let squareImage = UIImage(cgImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
        return resizeImage(squareImage, to: targetSize)
    }

    /// Resize an image to the specified size
    private static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }

    // MARK: - PDF Handling

    /// Set PDF data (generates thumbnail from first page automatically)
    func setPDF(_ data: Data?) {
        guard let data = data else {
            self.pdfData = nil
            self.thumbnailData = nil
            self.attachmentType = AttachmentType.none.rawValue
            return
        }

        self.pdfData = data
        self.attachmentType = AttachmentType.pdf.rawValue

        // Generate thumbnail from first page
        if let thumbnail = Self.generatePDFThumbnail(from: data, size: Self.thumbnailSize) {
            self.thumbnailData = thumbnail.jpegData(compressionQuality: Self.thumbnailCompressionQuality)
        }
    }

    /// Get PDF data
    func getPDFData() -> Data? {
        return self.pdfData
    }

    /// Generate a thumbnail from a PDF's first page
    private static func generatePDFThumbnail(from data: Data, size: CGFloat) -> UIImage? {
        guard let pdfDocument = PDFDocument(data: data),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = size / max(pageRect.width, pageRect.height)
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let thumbnail = renderer.image { context in
            // Fill with white background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: scaledSize))

            // Draw PDF page
            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }

        return thumbnail
    }

    /// Clear all attachment data (image and PDF)
    func clearAttachment() {
        self.imageData = nil
        self.pdfData = nil
        self.thumbnailData = nil
        self.attachmentType = AttachmentType.none.rawValue
    }
}

// MARK: - Fetch Request Helpers

extension CDDocument {

    /// Fetch all documents for a profile, sorted by creation date (newest first)
    static func fetchDocuments(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDDocument] {
        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.createdAt, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch documents by type for a profile
    static func fetchDocuments(type: DocumentType, for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDDocument] {
        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.predicate = NSPredicate(format: "profile == %@ AND type == %@", profile, type.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.createdAt, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch document by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDDocument? {
        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Count documents for a profile
    static func countDocuments(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        return (try? context.count(for: request)) ?? 0
    }

    /// Fetch documents with expiry dates for a profile
    static func fetchDocumentsWithExpiry(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDDocument] {
        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.predicate = NSPredicate(format: "profile == %@ AND expiryDate != nil", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.expiryDate, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch expired documents for a profile
    static func fetchExpiredDocuments(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDDocument] {
        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.predicate = NSPredicate(format: "profile == %@ AND expiryDate != nil AND expiryDate < %@", profile, Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.expiryDate, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Fetch documents expiring within a number of days for a profile
    static func fetchExpiringDocuments(withinDays days: Int, for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDDocument] {
        let now = Date()
        guard let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now) else {
            return []
        }

        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.predicate = NSPredicate(
            format: "profile == %@ AND expiryDate != nil AND expiryDate >= %@ AND expiryDate <= %@",
            profile,
            now as NSDate,
            futureDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.expiryDate, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Legacy/Migration Support

    /// Fetch all documents (regardless of profile) - for migration only
    static func fetchAllDocumentsForMigration(in context: NSManagedObjectContext) -> [CDDocument] {
        let request = NSFetchRequest<CDDocument>(entityName: "CDDocument")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.createdAt, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}
