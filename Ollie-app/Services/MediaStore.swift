//
//  MediaStore.swift
//  Ollie-app
//

import Foundation
import UIKit
import Combine

/// Manages saving, loading, and deleting photo media files
@MainActor
class MediaStore: ObservableObject {
    private let fileManager = FileManager.default

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
            print("Error saving photo: \(error)")
            return nil
        }
    }

    /// Load a photo from relative path
    func loadPhoto(relativePath: String) -> UIImage? {
        let url = documentsURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Load a thumbnail from relative path
    func loadThumbnail(relativePath: String) -> UIImage? {
        let url = documentsURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Delete photo and thumbnail files for an event
    func deleteMedia(photoPath: String?, thumbnailPath: String?) {
        if let photoPath = photoPath {
            let photoURL = documentsURL.appendingPathComponent(photoPath)
            try? fileManager.removeItem(at: photoURL)
        }

        if let thumbnailPath = thumbnailPath {
            let thumbnailURL = documentsURL.appendingPathComponent(thumbnailPath)
            try? fileManager.removeItem(at: thumbnailURL)
        }
    }

    /// Get full URL for a relative path
    func fullURL(for relativePath: String) -> URL {
        documentsURL.appendingPathComponent(relativePath)
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
