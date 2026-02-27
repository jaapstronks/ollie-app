//
//  ProfilePhotoStore.swift
//  Ollie-app
//
//  Manages storage of profile photos in the app's documents directory

import UIKit

/// Manages profile photo storage in the app's documents directory
final class ProfilePhotoStore {
    static let shared = ProfilePhotoStore()

    private let fileManager = FileManager.default
    private let directory: URL

    private init() {
        directory = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProfilePhotos", isDirectory: true)

        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Save an image and return the filename
    func save(image: UIImage) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ProfilePhotoError.imageConversionFailed
        }
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url)
        return filename
    }

    /// Load an image by filename
    func load(filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    /// Delete an image by filename
    func delete(filename: String) {
        let url = directory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }

    /// Get the full path for a filename
    func fullPath(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    enum ProfilePhotoError: Error {
        case imageConversionFailed
    }
}
