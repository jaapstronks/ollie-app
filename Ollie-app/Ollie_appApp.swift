//
//  Ollie_appApp.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import CloudKit
import CoreData
import UserNotifications
import TipKit
import os

// MARK: - CloudKit Share URL Handler

/// Handle CloudKit share URL by fetching metadata and accepting
@MainActor
func handleCloudKitShareURL(_ url: URL) async {
    let logger = Logger.ollie(category: "ShareHandler")
    logger.info("🔗 handleCloudKitShareURL called with: \(url.absoluteString)")

    let container = CKContainer(identifier: "iCloud.nl.jaapstronks.Ollie")

    // Fetch share metadata from the URL
    let operation = CKFetchShareMetadataOperation(shareURLs: [url])
    operation.perShareMetadataResultBlock = { url, result in
        switch result {
        case .success(let metadata):
            logger.info("✅ Got share metadata for URL")
            logger.info("🔗 Owner: \(metadata.ownerIdentity.nameComponents?.formatted() ?? "unknown")")
            logger.info("🔗 Container: \(metadata.containerIdentifier)")

            // Accept the share
            Task { @MainActor in
                // Show accepting alert
                let acceptingAlert = UIAlertController(
                    title: "Accepting Share...",
                    message: "Connecting to shared data",
                    preferredStyle: .alert
                )
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.rootViewController?
                    .present(acceptingAlert, animated: true)

                do {
                    try await CloudKitService.shared.acceptShare(metadata)

                    // Dismiss and show success
                    acceptingAlert.dismiss(animated: true) {
                        let successAlert = UIAlertController(
                            title: "Share Accepted!",
                            message: "You now have access to shared data. The app will reload.",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            // Notify stores to refresh their data
                            NotificationCenter.default.post(name: .cloudKitShareAccepted, object: nil)
                        })
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.windows.first?.rootViewController?
                            .present(successAlert, animated: true)
                    }

                    logger.info("✅ Share accepted successfully!")
                } catch {
                    logger.error("❌ Failed to accept share: \(error.localizedDescription)")

                    acceptingAlert.dismiss(animated: true) {
                        let errorAlert = UIAlertController(
                            title: "Share Failed",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.windows.first?.rootViewController?
                            .present(errorAlert, animated: true)
                    }
                }
            }

        case .failure(let error):
            logger.error("❌ Failed to fetch share metadata: \(error.localizedDescription)")

            Task { @MainActor in
                let errorAlert = UIAlertController(
                    title: "Share Error",
                    message: "Could not fetch share information: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.rootViewController?
                    .present(errorAlert, animated: true)
            }
        }
    }

    operation.qualityOfService = .userInitiated
    container.add(operation)
}

@main
struct OllieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Core Data persistence controller (must be initialized first)
    let persistenceController = PersistenceController.shared

    @StateObject private var profileStore = ProfileStore()
    @StateObject private var eventStore = EventStore()
    @StateObject private var dataImporter = DataImporter()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var spotStore = SpotStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var medicationStore = MedicationStore()
    @StateObject private var socializationStore = SocializationStore()
    @StateObject private var milestoneStore = MilestoneStore()
    @StateObject private var documentStore = DocumentStore()
    @StateObject private var contactStore = ContactStore()
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
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(profileStore)
                .environmentObject(eventStore)
                .environmentObject(dataImporter)
                .environmentObject(weatherService)
                .environmentObject(notificationService)
                .environmentObject(spotStore)
                .environmentObject(locationManager)
                .environmentObject(medicationStore)
                .environmentObject(socializationStore)
                .environmentObject(milestoneStore)
                .environmentObject(documentStore)
                .environmentObject(contactStore)
                .environmentObject(subscriptionManager)
                .environmentObject(cloudKit)
                .task {
                    // Run Core Data migration from JSONL files (one-time, on first launch after update)
                    do {
                        try await CoreDataMigrationCoordinator.shared.migrateIfNeeded(using: persistenceController)
                    } catch {
                        Logger.ollie(category: "App").error("Migration failed: \(error.localizedDescription)")
                    }

                    // Wire up location manager to weather service
                    weatherService.setLocationManager(locationManager)

                    // Request location authorization for weather forecasts
                    if !locationManager.authorizationDetermined {
                        locationManager.requestAuthorization()
                    }

                    // Check subscription status on app launch
                    await subscriptionManager.checkSubscriptionStatus()
                    await subscriptionManager.loadProducts()

                    // Setup CloudKit service and check availability
                    await CloudKitService.shared.setup()

                    // Initial CloudKit sync for profile, spots, and medications
                    await profileStore.initialSync()
                    await spotStore.initialSync()
                    await medicationStore.initialSync()

                    // Seed default milestones if this is a fresh install
                    milestoneStore.seedDefaultMilestonesIfNeeded()

                    // Wire up DocumentStore with ProfileStore and migrate any orphaned documents
                    documentStore.setProfileStore(profileStore)
                    documentStore.migrateOrphanedDocuments()

                    // Initial sync to Apple Watch
                    WatchSyncService.shared.syncToWatch()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Sync when app comes to foreground
                    Task {
                        await eventStore.forceSync()
                        await profileStore.forceSync()
                        await spotStore.forceSync()
                        await medicationStore.forceSync()

                        // Check if participant access was revoked
                        await CloudKitService.shared.checkShareAccessStatus()
                    }
                    // Sync data to Apple Watch
                    WatchSyncService.shared.syncToWatch()
                }
                .onReceive(NotificationCenter.default.publisher(for: .shareAccessRevoked)) { _ in
                    // Handle share access revocation
                    Task { @MainActor in
                        let alert = UIAlertController(
                            title: "Share Access Removed",
                            message: "You no longer have access to the shared puppy data. The owner may have stopped sharing.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.windows.first?.rootViewController?
                            .present(alert, animated: true)
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
                // Handle CloudKit share URLs directly (since userDidAcceptCloudKitShareWith isn't reliable in SwiftUI)
                .onOpenURL { url in
                    Logger.ollie(category: "App").info("🔗 onOpenURL called: \(url.absoluteString)")

                    // Check if this is a CloudKit share URL
                    if url.absoluteString.contains("icloud.com/share") || url.scheme == "cloudkit" {
                        Logger.ollie(category: "App").info("🔗 Detected CloudKit share URL, fetching metadata...")

                        Task {
                            await handleCloudKitShareURL(url)
                        }
                    }
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
        // Initialize WatchConnectivity session as early as possible (Apple best practice)
        // This ensures WCSession is ready before any sync attempts
        _ = WatchSyncService.shared

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
        // NSPersistentCloudKitContainer handles sync automatically
        // We just need to process persistent history for local cache updates
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            completionHandler(.noData)
            return
        }

        if notification.notificationType == .recordZone {
            // CloudKit zone changed - NSPersistentCloudKitContainer handles sync automatically
            // Post notification so stores can refresh their local caches
            NotificationCenter.default.post(name: .NSPersistentStoreRemoteChange, object: nil)
            logger.info("Received CloudKit remote change notification")
            completionHandler(.newData)
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
        logger.info("🔗 userDidAcceptCloudKitShareWith called!")
        logger.info("🔗 Share URL: \(cloudKitShareMetadata.share.url?.absoluteString ?? "nil")")
        logger.info("🔗 Container ID: \(cloudKitShareMetadata.containerIdentifier)")
        logger.info("🔗 Zone ID: \(cloudKitShareMetadata.share.recordID.zoneID.zoneName)")
        logger.info("🔗 Owner: \(cloudKitShareMetadata.share.recordID.zoneID.ownerName)")

        Task { @MainActor in
            do {
                logger.info("🔗 Calling acceptShare...")
                try await CloudKitService.shared.acceptShare(cloudKitShareMetadata)
                logger.info("✅ Successfully accepted CloudKit share")

                // NSPersistentCloudKitContainer handles sync automatically after share acceptance
                // Notify stores to refresh their local data
                NotificationCenter.default.post(name: .cloudKitShareAccepted, object: nil)
                logger.info("✅ Share accepted, automatic sync will update data")

                // Show success alert
                let successAlert = UIAlertController(
                    title: "Share Accepted!",
                    message: "You now have access to shared data.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.rootViewController?
                    .present(successAlert, animated: true)

            } catch {
                logger.error("❌ Failed to accept share: \(error.localizedDescription)")
                logger.error("❌ Error details: \(error)")

                let errorAlert = UIAlertController(
                    title: "Share Failed",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.rootViewController?
                    .present(errorAlert, animated: true)
            }
        }
    }
}
