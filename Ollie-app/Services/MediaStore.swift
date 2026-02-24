//
//  MediaStore.swift
//  Ollie-app
//

import Foundation
import OllieShared
import UIKit
import Combine
import os

/// Manages saving, loading, and deleting photo media files
@MainActor
class MediaStore: ObservableObject {
    private let fileManager = FileManager.default
    private let logger = Logger.ollie(category: "MediaStore")

    // MARK: - Directory URLs

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var mediaDirectoryURL: URL {
        documentsURL.appendingPathComponent(Constants.mediaDirectoryName, isDirectory: true)
    }

    private var thumbnailDirectoryURL: URL {
        documentsURL.appendingPathComponent(Constants.thumbnailDirectoryName, isDirectory: true)
    }

    // MARK: - Security

    /// Validates that a relative path resolves to a location within the allowed directory
    /// Prevents path traversal attacks (e.g., "../../sensitive_file")
    private func isPathSafe(_ relativePath: String, within allowedDirectory: URL) -> Bool {
        let resolvedURL = documentsURL.appendingPathComponent(relativePath).standardized
        let allowedPath = allowedDirectory.standardized.path

        // Ensure the resolved path starts with the allowed directory path
        return resolvedURL.path.hasPrefix(allowedPath)
    }

    /// Validates that a path is within either the media or thumbnail directories
    private func isMediaPathSafe(_ relativePath: String) -> Bool {
        return isPathSafe(relativePath, within: mediaDirectoryURL) ||
               isPathSafe(relativePath, within: thumbnailDirectoryURL)
    }

    // MARK: - Public Methods

    /// Save a photo and generate thumbnail, returns the relative path to the saved photo
    func savePhoto(_ image: UIImage) -> (photoPath: String, thumbnailPath: String)? {
        ensureDirectoriesExist()

        let id = UUID().uuidString
        let photoFilename = "\(id).jpg"
        let thumbnailFilename = "\(id).jpg"

        // Resize photo to max size
        guard let resizedImage = resizeImage(image, maxSize: Constants.maxPhotoSize),
              let photoData = resizedImage.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        // Generate thumbnail
        guard let thumbnailImage = resizeImage(image, maxSize: Constants.thumbnailSize),
              let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }

        // Save photo
        let photoURL = mediaDirectoryURL.appendingPathComponent(photoFilename)
        let thumbnailURL = thumbnailDirectoryURL.appendingPathComponent(thumbnailFilename)

        do {
            try photoData.write(to: photoURL)
            try thumbnailData.write(to: thumbnailURL)

            // Return relative paths for storage in event JSON
            let photoRelativePath = "\(Constants.mediaDirectoryName)/\(photoFilename)"
            let thumbnailRelativePath = "\(Constants.thumbnailDirectoryName)/\(thumbnailFilename)"

            return (photoRelativePath, thumbnailRelativePath)
        } catch {
            logger.error("Error saving photo: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load a photo from relative path
    /// Returns nil if path is invalid or attempts path traversal
    func loadPhoto(relativePath: String) -> UIImage? {
        guard isMediaPathSafe(relativePath) else {
            logger.warning("Blocked potentially unsafe photo path: \(relativePath)")
            return nil
        }

        let url = documentsURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Load a thumbnail from relative path
    /// Returns nil if path is invalid or attempts path traversal
    func loadThumbnail(relativePath: String) -> UIImage? {
        guard isMediaPathSafe(relativePath) else {
            logger.warning("Blocked potentially unsafe thumbnail path: \(relativePath)")
            return nil
        }

        let url = documentsURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Delete photo and thumbnail files for an event
    /// Silently ignores paths that fail security validation
    func deleteMedia(photoPath: String?, thumbnailPath: String?) {
        if let photoPath = photoPath {
            guard isMediaPathSafe(photoPath) else {
                logger.warning("Blocked deletion of unsafe photo path: \(photoPath)")
                return
            }
            let photoURL = documentsURL.appendingPathComponent(photoPath)
            try? fileManager.removeItem(at: photoURL)
        }

        if let thumbnailPath = thumbnailPath {
            guard isMediaPathSafe(thumbnailPath) else {
                logger.warning("Blocked deletion of unsafe thumbnail path: \(thumbnailPath)")
                return
            }
            let thumbnailURL = documentsURL.appendingPathComponent(thumbnailPath)
            try? fileManager.removeItem(at: thumbnailURL)
        }
    }

    /// Get full URL for a relative path
    /// Returns nil if path fails security validation
    func fullURL(for relativePath: String) -> URL? {
        guard isMediaPathSafe(relativePath) else {
            logger.warning("Blocked unsafe path in fullURL: \(relativePath)")
            return nil
        }
        return documentsURL.appendingPathComponent(relativePath)
    }

    /// Check if a photo file exists locally
    func photoExists(for relativePath: String) -> Bool {
        guard let url = fullURL(for: relativePath) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Cloud Download Support

    /// Get the destination URL for downloading a photo from CloudKit
    /// Uses the same path as the original so the event's photo path remains valid
    func cloudDownloadURL(for eventId: UUID, originalPath: String) -> URL {
        ensureDirectoriesExist()
        return documentsURL.appendingPathComponent(originalPath)
    }

    /// Regenerate thumbnail for a downloaded photo
    func regenerateThumbnail(for eventId: UUID, photoURL: URL) async {
        guard let image = UIImage(contentsOfFile: photoURL.path) else {
            logger.warning("Could not load downloaded photo for thumbnail generation")
            return
        }

        guard let thumbnailImage = resizeImage(image, maxSize: Constants.thumbnailSize),
              let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) else {
            logger.warning("Could not generate thumbnail for downloaded photo")
            return
        }

        // Extract filename from photo path and use for thumbnail
        let filename = photoURL.deletingPathExtension().lastPathComponent + ".jpg"
        let thumbnailURL = thumbnailDirectoryURL.appendingPathComponent(filename)

        do {
            try thumbnailData.write(to: thumbnailURL)
            logger.info("Regenerated thumbnail for event \(eventId)")
        } catch {
            logger.error("Failed to save regenerated thumbnail: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func ensureDirectoriesExist() {
        if !fileManager.fileExists(atPath: mediaDirectoryURL.path) {
            try? fileManager.createDirectory(at: mediaDirectoryURL, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: thumbnailDirectoryURL.path) {
            try? fileManager.createDirectory(at: thumbnailDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        let maxDimension = max(size.width, size.height)

        if maxDimension <= maxSize {
            return image
        }

        let scale = maxSize / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
