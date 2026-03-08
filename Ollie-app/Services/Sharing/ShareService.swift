//
//  ShareService.swift
//  Otis-app
//
//  Core sharing service for social media and general sharing
//

import SwiftUI
import UIKit
import Photos
import os
import Combine
import OtisShared

/// Main service for sharing content across platforms
@MainActor
final class ShareService: ObservableObject {

    // MARK: - Properties

    private let logger = Logger.otis(category: "ShareService")

    @Published var isSharing = false
    @Published var lastError: ShareError?

    // MARK: - Standard Share Sheet

    /// Present the standard iOS share sheet
    func share(
        image: UIImage,
        caption: String? = nil,
        from viewController: UIViewController
    ) {
        var items: [Any] = [image]
        if let caption = caption {
            items.append(caption)
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        activityVC.excludedActivityTypes = [
            .print,
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]

        // For iPad - configure popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
        logger.debug("Presented share sheet")
    }

    // MARK: - Instagram Stories

    /// Share directly to Instagram Stories
    /// - Parameters:
    ///   - backgroundImage: The main background image for the story
    ///   - stickerImage: Optional sticker overlay
    /// - Returns: Whether the share was successful
    func shareToInstagramStories(
        backgroundImage: UIImage,
        stickerImage: UIImage? = nil
    ) async -> Bool {
        guard isInstagramAvailable else {
            logger.warning("Instagram not available")
            lastError = .platformNotAvailable
            return false
        }

        guard let url = URL(string: "instagram-stories://share") else {
            return false
        }

        var pasteboardItems: [String: Any] = [:]

        if let imageData = backgroundImage.pngData() {
            pasteboardItems["com.instagram.sharedSticker.backgroundImage"] = imageData
        }

        if let sticker = stickerImage, let stickerData = sticker.pngData() {
            pasteboardItems["com.instagram.sharedSticker.stickerImage"] = stickerData
        }

        // App Store link for attribution
        pasteboardItems["com.instagram.sharedSticker.contentURL"] = "https://apps.apple.com/app/ollie-puppy-log/id6478116785"

        UIPasteboard.general.setItems(
            [pasteboardItems],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        logger.debug("Sharing to Instagram Stories")
        return await UIApplication.shared.open(url)
    }

    /// Share directly to Instagram feed (opens Instagram with image in clipboard)
    func shareToInstagramFeed(image: UIImage) async -> Bool {
        guard isInstagramAvailable else {
            logger.warning("Instagram not available")
            lastError = .platformNotAvailable
            return false
        }

        guard let url = URL(string: "instagram://app") else {
            return false
        }

        // Copy image to clipboard for manual paste
        UIPasteboard.general.image = image

        logger.debug("Opening Instagram for feed sharing (image in clipboard)")
        return await UIApplication.shared.open(url)
    }

    // MARK: - Facebook Stories

    /// Share directly to Facebook Stories
    /// - Parameter backgroundImage: The main background image for the story
    /// - Returns: Whether the share was successful
    func shareToFacebookStories(
        backgroundImage: UIImage
    ) async -> Bool {
        guard isFacebookAvailable else {
            logger.warning("Facebook not available")
            lastError = .platformNotAvailable
            return false
        }

        guard let url = URL(string: "facebook-stories://share") else {
            return false
        }

        var pasteboardItems: [String: Any] = [:]

        if let imageData = backgroundImage.pngData() {
            pasteboardItems["com.facebook.sharedSticker.backgroundImage"] = imageData
        }

        // Note: Facebook App ID should be configured in production
        // pasteboardItems["com.facebook.sharedSticker.appID"] = "YOUR_FACEBOOK_APP_ID"

        UIPasteboard.general.setItems(
            [pasteboardItems],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        logger.debug("Sharing to Facebook Stories")
        return await UIApplication.shared.open(url)
    }

    // MARK: - Save to Photos

    /// Save an image to the user's photo library
    /// - Parameter image: The image to save
    /// - Throws: ShareError if saving fails
    func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        switch status {
        case .authorized, .limited:
            break
        case .denied:
            throw ShareError.photoLibraryDenied
        case .restricted:
            throw ShareError.photoLibraryRestricted
        case .notDetermined:
            throw ShareError.photoLibraryDenied
        @unknown default:
            throw ShareError.photoLibraryDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            logger.debug("Saved image to photos")
        } catch {
            logger.error("Failed to save to photos: \(error.localizedDescription)")
            throw ShareError.unknown(error)
        }
    }

    // MARK: - Copy to Clipboard

    /// Copy an image to the clipboard
    func copyToClipboard(_ image: UIImage) {
        UIPasteboard.general.image = image
        logger.debug("Copied image to clipboard")
    }

    // MARK: - Platform Detection

    var isInstagramAvailable: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    var isInstagramAppAvailable: Bool {
        guard let url = URL(string: "instagram://app") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    var isFacebookAvailable: Bool {
        guard let url = URL(string: "facebook-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    var isWhatsAppAvailable: Bool {
        guard let url = URL(string: "whatsapp://app") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    var isTwitterAvailable: Bool {
        guard let url = URL(string: "twitter://app") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Get the root view controller for presenting share sheets
    @MainActor
    func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController.presentedViewController ?? rootViewController
    }
}
