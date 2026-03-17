//
//  CloudKitSceneDelegate.swift
//  Otis-app
//
//  Custom scene delegate that handles CloudKit shares when app is already running
//

import CloudKit
import OtisShared
import os
import UIKit

/// Custom scene delegate that handles CloudKit shares when app is already running
/// This is needed because SwiftUI's onOpenURL doesn't reliably receive CloudKit share URLs
class CloudKitSceneDelegate: UIResponder, UIWindowSceneDelegate {
    private let logger = Logger.otis(category: "SceneDelegate")

    // MARK: - Scene Connection

    /// Called when scene is about to connect - check for CloudKit share context
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        logger.info("🔗 SceneDelegate: scene willConnectTo session")

        // Check for CloudKit share metadata in connection options
        if let cloudKitMetadata = connectionOptions.cloudKitShareMetadata {
            logger.info("🔗 SceneDelegate: Found CloudKit share metadata in connection options!")
            logger.info("🔗   Container: \(cloudKitMetadata.containerIdentifier)")
            logger.info("🔗   Share URL: \(cloudKitMetadata.share.url?.absoluteString ?? "nil")")
            PendingShareMetadata.shared.metadata = cloudKitMetadata
        } else {
            logger.info("🔗 SceneDelegate: No CloudKit share metadata in connection options")
        }

        // Check for URLs in connection options
        for urlContext in connectionOptions.urlContexts {
            logger.info("🔗 SceneDelegate: URL context in connection: \(urlContext.url.absoluteString)")
            if urlContext.url.scheme?.hasPrefix("cloudkit") == true || urlContext.url.absoluteString.contains("icloud.com/share") {
                logger.info("🔗 SceneDelegate: Found CloudKit share URL in connection options")
                PendingShareMetadata.shared.pendingURL = urlContext.url
            }
        }
    }

    // MARK: - URL Handling

    /// Called when URLs are opened while the scene is already connected (app running)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        logger.info("🔗 SceneDelegate openURLContexts called with \(URLContexts.count) URL(s)")

        for context in URLContexts {
            let url = context.url
            logger.info("🔗 Scene received URL: \(url.absoluteString)")
            logger.info("🔗   Scheme: \(url.scheme ?? "nil")")

            if url.scheme?.hasPrefix("cloudkit") == true || url.absoluteString.contains("icloud.com/share") {
                logger.info("🔗 Processing CloudKit share URL from scene delegate")

                Task { @MainActor in
                    await CloudKitShareHandler.handleShareURL(url, profileStore: ProfileStoreProvider.shared.store)
                }
            }
        }
    }

    // MARK: - User Activity Handling

    /// Called when a user activity is continued (e.g., from Handoff or Universal Links)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        logger.info("🔗 SceneDelegate continue userActivity called")
        logger.info("🔗 Activity type: \(userActivity.activityType)")

        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            logger.info("🔗 Web URL from user activity: \(url.absoluteString)")

            if url.absoluteString.contains("icloud.com/share") {
                Task { @MainActor in
                    await CloudKitShareHandler.handleShareURL(url, profileStore: ProfileStoreProvider.shared.store)
                }
            }
        }
    }

    // MARK: - CloudKit Share Acceptance (App Already Running)

    /// Called when user accepts a CloudKit share while the app is ALREADY RUNNING
    /// This is the key method for handling shares without requiring app restart
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        logger.info("🔗 SceneDelegate: userDidAcceptCloudKitShareWith called (APP WAS RUNNING)")
        logger.info("🔗   Share URL: \(cloudKitShareMetadata.share.url?.absoluteString ?? "nil")")
        logger.info("🔗   Container: \(cloudKitShareMetadata.containerIdentifier)")
        logger.info("🔗   Owner: \(cloudKitShareMetadata.ownerIdentity.nameComponents?.formatted() ?? "unknown")")

        // Store the metadata and notify the app to process it
        // This ensures the correct ProfileStore instance is used
        PendingShareMetadata.shared.metadata = cloudKitShareMetadata

        // Post notification to trigger immediate processing
        NotificationCenter.default.post(name: .cloudKitShareReceived, object: cloudKitShareMetadata)
    }
}
