//
//  Ollie_appApp.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import CloudKit
import UserNotifications
import TipKit
import os

@main
struct OllieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var profileStore = ProfileStore()
    @StateObject private var eventStore = EventStore()
    @StateObject private var dataImporter = DataImporter()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var spotStore = SpotStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var medicationStore = MedicationStore()
    @StateObject private var socializationStore = SocializationStore()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var cloudKit = CloudKitService.shared

    init() {
        // Initialize crash reporting first (before any other code that might crash)
        CrashReporter.start()

        UserPreferences.registerDefaults()

        // Configure TipKit for contextual tips
        configureTips()

        // Install seed data for development
        #if DEBUG
        SeedData.installSeedDataIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileStore)
                .environmentObject(eventStore)
                .environmentObject(dataImporter)
                .environmentObject(weatherService)
                .environmentObject(notificationService)
                .environmentObject(spotStore)
                .environmentObject(locationManager)
                .environmentObject(medicationStore)
                .environmentObject(socializationStore)
                .environmentObject(subscriptionManager)
                .environmentObject(cloudKit)
                .task {
                    // Wire up location manager to weather service
                    weatherService.setLocationManager(locationManager)

                    // Request location authorization for weather forecasts
                    if !locationManager.authorizationDetermined {
                        locationManager.requestAuthorization()
                    }

                    // Check subscription status on app launch
                    await subscriptionManager.checkSubscriptionStatus()
                    await subscriptionManager.loadProducts()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Sync when app comes to foreground
                    Task {
                        await eventStore.forceSync()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Track app usage for review prompt timing
                    ReviewService.shared.recordAppActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    // Clear image cache on memory warning
                    ImageCache.shared.handleMemoryWarning()
                }
        }
    }
}

// MARK: - App Delegate for CloudKit Remote Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger.ollie(category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register for remote notifications (required for CloudKit silent push)
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // CloudKit uses this automatically
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
        // Handle CloudKit silent push notification
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            completionHandler(.noData)
            return
        }

        if notification.notificationType == .recordZone {
            // CloudKit zone changed - sync in background
            Task { @MainActor in
                do {
                    try await CloudKitService.shared.sync()
                    completionHandler(.newData)
                } catch {
                    logger.error("Background sync failed: \(error.localizedDescription)")
                    completionHandler(.failed)
                }
            }
        } else {
            completionHandler(.noData)
        }
    }

    // MARK: - CloudKit Share Acceptance

    /// Handle CloudKit share acceptance when user taps share link
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            do {
                try await CloudKitService.shared.acceptShare(cloudKitShareMetadata)
                logger.info("Successfully accepted CloudKit share")
            } catch {
                logger.error("Failed to accept share: \(error.localizedDescription)")
            }
        }
    }
}
