//
//  EXIFExtractor.swift
//  Ollie-app
//

import Foundation
import OllieShared
import ImageIO
import UIKit
import CoreLocation

/// Extracts EXIF metadata (date and GPS) from photos
struct EXIFExtractor {

    struct PhotoMetadata {
        var date: Date?
        var latitude: Double?
        var longitude: Double?
    }

    /// Extract metadata from image data
    static func extractMetadata(from imageData: Data) -> PhotoMetadata {
        var metadata = PhotoMetadata()

        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return metadata
        }

        // Extract date from EXIF
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                metadata.date = parseEXIFDate(dateString)
            } else if let dateString = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String {
                metadata.date = parseEXIFDate(dateString)
            }
        }

        // Fallback to TIFF date if no EXIF date
        if metadata.date == nil,
           let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateString = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
            metadata.date = parseEXIFDate(dateString)
        }

        // Extract GPS coordinates
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String {
                metadata.latitude = latRef == "S" ? -lat : lat
            }

            if let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
                metadata.longitude = lonRef == "W" ? -lon : lon
            }
        }

        return metadata
    }

    /// Extract metadata from UIImage (note: UIImage may lose EXIF data)
    static func extractMetadata(from image: UIImage) -> PhotoMetadata {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return PhotoMetadata()
        }
        return extractMetadata(from: data)
    }

    // MARK: - Private

    private static func parseEXIFDate(_ string: String) -> Date? {
        // EXIF date format: "2024:03:15 14:30:00"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Try local timezone first (most cameras use local time)
        formatter.timeZone = TimeZone.current
        if let date = formatter.date(from: string) {
            return date
        }

        // Fallback: try UTC
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)
    }
}
