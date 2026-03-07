//
//  CloudKitSceneDelegate.swift
//  Otis-app
//
//  Custom scene delegate that handles CloudKit shares when app is already running
//

import OtisShared
import os
import UIKit

/// Custom scene delegate that handles CloudKit shares when app is already running
/// This is needed because SwiftUI's onOpenURL doesn't reliably receive CloudKit share URLs
class CloudKitSceneDelegate: UIResponder, UIWindowSceneDelegate {
    private let logger = Logger.otis(category: "SceneDelegate")

    // MARK: - URL Handling

    /// Called when URLs are opened while the scene is already connected (app running)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        logger.info("🔗 SceneDelegate openURLContexts called")

        for context in URLContexts {
            let url = context.url
            logger.info("🔗 Scene received URL: \(url.absoluteString)")

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
}
