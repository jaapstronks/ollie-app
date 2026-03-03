//
//  PDFHelpers.swift
//  Otis-app
//
//  Shared utilities for PDF handling

import UIKit
import PDFKit

/// Helper utilities for PDF operations
enum PDFHelpers {

    /// Default thumbnail size
    static let defaultThumbnailSize: CGFloat = 200

    /// Generate a thumbnail from PDF data
    /// - Parameters:
    ///   - data: The PDF data
    ///   - size: The maximum dimension for the thumbnail (default 200)
    /// - Returns: A UIImage thumbnail of the first page, or nil if generation fails
    static func generateThumbnail(from data: Data, size: CGFloat = defaultThumbnailSize) -> UIImage? {
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

    /// Get the page count of a PDF
    /// - Parameter data: The PDF data
    /// - Returns: The number of pages, or 0 if the PDF couldn't be loaded
    static func pageCount(from data: Data) -> Int {
        PDFDocument(data: data)?.pageCount ?? 0
    }
}
