//
//  AppDelegate.swift
//  Otis-app
//
//  UIApplicationDelegate for handling remote notifications and scene configuration
//

import CloudKit
import CoreData
import OtisShared
import os
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger.otis(category: "AppDelegate")

    // MARK: - App Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize WatchConnectivity session as early as possible (Apple best practice)
        _ = WatchSyncService.shared

        // Set up notification delegate for handling notification actions
        UNUserNotificationCenter.current().delegate = self

        // Register notification categories for moments (like actions)
        Task { @MainActor in
            MomentsNotificationHandler.shared.registerNotificationCategories()
        }

        // Register for remote notifications (required for CloudKit silent push)
        application.registerForRemoteNotifications()
        return true
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        logger.info("Registered for remote notifications")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            completionHandler(.noData)
            return
        }

        if notification.notificationType == .recordZone {
            NotificationCenter.default.post(name: .NSPersistentStoreRemoteChange, object: nil)
            logger.info("Received CloudKit remote change notification")
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }

    // MARK: - Scene Configuration

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        logger.info("🔗 Scene configuration requested")

        // Check if this scene connection has CloudKit share context
        if let cloudKitMetadata = options.cloudKitShareMetadata {
            logger.info("🔗 Scene has CloudKit share metadata!")
            logger.info("🔗 Container: \(cloudKitMetadata.containerIdentifier)")
            PendingShareMetadata.shared.metadata = cloudKitMetadata
        }

        // Check URL contexts for share URLs
        for urlContext in options.urlContexts {
            let url = urlContext.url
            logger.info("🔗 Scene URL context: \(url.absoluteString)")

            if url.scheme?.hasPrefix("cloudkit") == true || url.absoluteString.contains("icloud.com/share") {
                logger.info("🔗 Scene has CloudKit share URL")
                PendingShareMetadata.shared.pendingURL = url
            }
        }

        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = CloudKitSceneDelegate.self
        return config
    }

    // MARK: - CloudKit Share Acceptance

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        logger.info("🔗 userDidAcceptCloudKitShareWith called!")
        logger.info("🔗 Share URL: \(cloudKitShareMetadata.share.url?.absoluteString ?? "nil")")
        logger.info("🔗 Container ID: \(cloudKitShareMetadata.containerIdentifier)")
        logger.info("🔗 Zone ID: \(cloudKitShareMetadata.share.recordID.zoneID.zoneName)")
        logger.info("🔗 Owner: \(cloudKitShareMetadata.share.recordID.zoneID.ownerName)")

        Task { @MainActor in
            await CloudKitShareHandler.acceptShareInvitation(
                metadata: cloudKitShareMetadata,
                profileStore: nil
            )
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Handle notification responses (actions and taps)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            // Try to handle moment notification actions
            let handled = await MomentsNotificationHandler.shared.handleNotificationResponse(response)

            if !handled {
                logger.debug("Notification response not handled: \(response.notification.request.identifier)")
            }

            completionHandler()
        }
    }

    /// Handle notifications while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification banner even when app is in foreground
        // This is useful for moment notifications from other household members
        completionHandler([.banner, .sound, .badge])
    }
}
