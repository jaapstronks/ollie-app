//
//  ProfilePhotoStore.swift
//  Otis-app
//
//  Manages storage of profile photos in the app's documents directory
//  Also handles CloudKit sync for sharing profile photos with other users

import UIKit
import OtisShared
import os

/// Manages profile photo storage in the app's documents directory
/// Also handles CloudKit sync for sharing profile photos with other users
final class ProfilePhotoStore: @unchecked Sendable {
    static let shared = ProfilePhotoStore()

    private let fileManager = FileManager.default
    private let directory: URL
    private let logger = Logger.otis(category: "ProfilePhotoStore")

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

    /// Save an image for a specific profile and upload to CloudKit
    /// - Parameters:
    ///   - image: The image to save
    ///   - profileId: The profile ID this photo belongs to
    /// - Returns: The filename of the saved photo
    func save(image: UIImage, for profileId: UUID) async throws -> String {
        // Save locally first
        let filename = try save(image: image)

        // Upload to CloudKit in background
        Task { @MainActor in
            do {
                let localURL = fullPath(for: filename)
                _ = try await CloudKitService.shared.uploadProfilePhoto(
                    localURL: localURL,
                    profileId: profileId
                )
                logger.info("Profile photo uploaded to CloudKit for profile \(profileId)")
            } catch {
                // Log but don't fail - local save succeeded
                logger.warning("Failed to upload profile photo to CloudKit: \(error.localizedDescription)")
            }
        }

        return filename
    }

    /// Load an image by filename (synchronous - prefer loadAsync for UI)
    func load(filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    /// Load an image asynchronously (non-blocking)
    func loadAsync(filename: String) async -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        return await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: url.path)
        }.value
    }

    /// Load an image for a profile, downloading from CloudKit if needed
    /// - Parameters:
    ///   - filename: The filename to load
    ///   - profileId: The profile ID this photo belongs to (for CloudKit download)
    ///   - isSharedProfile: Whether this is a shared profile (requires downloading from owner's zone)
    /// - Returns: The loaded image, or nil if not found
    func loadAsync(filename: String, profileId: UUID, isSharedProfile: Bool = false) async -> UIImage? {
        let url = directory.appendingPathComponent(filename)

        // Check if file exists locally
        if fileManager.fileExists(atPath: url.path) {
            return await Task.detached(priority: .userInitiated) {
                UIImage(contentsOfFile: url.path)
            }.value
        }

        // Try to download from CloudKit
        logger.info("Profile photo not found locally, attempting CloudKit download for profile \(profileId)")
        do {
            let success = try await downloadFromCloudKit(profileId: profileId, to: url, isSharedProfile: isSharedProfile)
            if success {
                logger.info("Downloaded profile photo from CloudKit for profile \(profileId)")
                return await Task.detached(priority: .userInitiated) {
                    UIImage(contentsOfFile: url.path)
                }.value
            }
        } catch {
            logger.warning("Failed to download profile photo from CloudKit: \(error.localizedDescription)")
        }

        return nil
    }

    /// Download a profile photo from CloudKit
    /// - Parameters:
    ///   - profileId: The profile ID to download photo for
    ///   - destinationURL: Local URL to save the downloaded photo
    ///   - isSharedProfile: Whether this is a shared profile (requires downloading from owner's zone)
    /// - Returns: True if download succeeded
    @MainActor
    private func downloadFromCloudKit(profileId: UUID, to destinationURL: URL, isSharedProfile: Bool = false) async throws -> Bool {
        // For shared profiles, we need to use the owner's zone name to find the photo
        let ownerName: String? = isSharedProfile ? CloudKitService.shared.sharedZoneOwnerName : nil

        return try await CloudKitService.shared.downloadProfilePhoto(
            profileId: profileId,
            to: destinationURL,
            ownerName: ownerName
        )
    }

    /// Delete an image by filename
    func delete(filename: String) {
        let url = directory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }

    /// Delete an image by filename and also delete from CloudKit
    func delete(filename: String, profileId: UUID) {
        // Delete locally
        delete(filename: filename)

        // Delete from CloudKit in background
        Task { @MainActor in
            do {
                try await CloudKitService.shared.deleteProfilePhoto(profileId: profileId)
                logger.info("Profile photo deleted from CloudKit for profile \(profileId)")
            } catch {
                logger.warning("Failed to delete profile photo from CloudKit: \(error.localizedDescription)")
            }
        }
    }

    /// Get the full path for a filename
    func fullPath(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    /// Check if a profile photo exists locally
    func exists(filename: String) -> Bool {
        let url = directory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path)
    }

    /// Sync profile photo from CloudKit if it doesn't exist locally
    /// Call this when loading shared profiles
    /// - Parameters:
    ///   - filename: The filename to sync
    ///   - profileId: The profile ID this photo belongs to
    ///   - isSharedProfile: Whether this is a shared profile (requires downloading from owner's zone)
    func syncFromCloudKitIfNeeded(filename: String, profileId: UUID, isSharedProfile: Bool = false) async {
        guard !exists(filename: filename) else { return }

        let destinationURL = fullPath(for: filename)
        do {
            let success = try await downloadFromCloudKit(profileId: profileId, to: destinationURL, isSharedProfile: isSharedProfile)
            if success {
                logger.info("Synced profile photo from CloudKit for profile \(profileId)")
            }
        } catch {
            logger.warning("Failed to sync profile photo from CloudKit: \(error.localizedDescription)")
        }
    }

    enum ProfilePhotoError: Error {
        case imageConversionFailed
    }
}
