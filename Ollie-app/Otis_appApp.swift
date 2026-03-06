//
//  Otis_appApp.swift
//  Otis-app
//

import SwiftUI
import OtisShared
import CloudKit
import CoreData
import UserNotifications
import TipKit
import os

// MARK: - CloudKit Share URL Handler

@MainActor
private final class ShareAcceptanceRegistry {
    static let shared = ShareAcceptanceRegistry()
    private var inFlightKeys = Set<String>()

    func beginIfNeeded(for metadata: CKShare.Metadata) -> Bool {
        let key = keyForMetadata(metadata)
        guard !inFlightKeys.contains(key) else { return false }
        inFlightKeys.insert(key)
        return true
    }

    func end(for metadata: CKShare.Metadata) {
        inFlightKeys.remove(keyForMetadata(metadata))
    }

    private func keyForMetadata(_ metadata: CKShare.Metadata) -> String {
        let recordID = metadata.share.recordID
        return "\(recordID.zoneID.ownerName)|\(recordID.zoneID.zoneName)|\(recordID.recordName)"
    }
}

@MainActor
private func sharedProfileIDSnapshot() -> Set<UUID> {
    guard let sharedStore = PersistenceController.shared.getSharedStore() else { return [] }
    let profiles = CDPuppyProfile.fetchAllProfiles(in: PersistenceController.shared.viewContext, from: sharedStore)
    return Set(profiles.compactMap(\.id))
}

@MainActor
private func waitForSharedProfileName(
    previousSharedProfileIDs: Set<UUID>,
    timeoutSeconds: TimeInterval = 30
) async -> String? {
    guard let sharedStore = PersistenceController.shared.getSharedStore() else { return nil }
    let deadline = Date().addingTimeInterval(timeoutSeconds)

    while Date() <= deadline {
        let profiles = CDPuppyProfile.fetchAllProfiles(in: PersistenceController.shared.viewContext, from: sharedStore)
        let newlyAdded = profiles.filter { profile in
            guard let id = profile.id else { return false }
            return !previousSharedProfileIDs.contains(id)
        }

        if let newest = newlyAdded.max(by: { ($0.modifiedAt ?? .distantPast) < ($1.modifiedAt ?? .distantPast) }),
           let name = newest.name,
           !name.isEmpty {
            return name
        }

        try? await Task.sleep(for: .seconds(1))
    }

    return nil
}

/// Handle CloudKit share URL by fetching metadata and accepting
@MainActor
func handleCloudKitShareURL(_ url: URL, profileStore: ProfileStore) async {
    let logger = Logger.otis(category: "ShareHandler")
    logger.info("🔗 handleCloudKitShareURL called with: \(url.absoluteString)")

    let container = CKContainer(identifier: "iCloud.nl.jaapstronks.Otis")

    // Fetch share metadata from the URL
    let operation = CKFetchShareMetadataOperation(shareURLs: [url])
    operation.perShareMetadataResultBlock = { url, result in
        switch result {
        case .success(let metadata):
            logger.info("✅ Got share metadata for URL")
            let ownerName = metadata.ownerIdentity.nameComponents?.formatted() ?? "someone"
            logger.info("🔗 Owner: \(ownerName)")
            logger.info("🔗 Container: \(metadata.containerIdentifier)")

            Task { @MainActor in
                // Check if user has existing profile - show conflict warning
                if profileStore.hasExistingPrivateProfile() {
                    let existingName = profileStore.profile?.name ?? ""
                    showExistingProfileWarning(
                        existingName: existingName,
                        ownerName: ownerName,
                        metadata: metadata,
                        profileStore: profileStore,
                        logger: logger
                    )
                } else {
                    // No conflict - accept share directly
                    await acceptShareInvitation(metadata: metadata, profileStore: profileStore, logger: logger)
                }
            }

        case .failure(let error):
            logger.error("❌ Failed to fetch share metadata: \(error.localizedDescription)")

            Task { @MainActor in
                let errorAlert = UIAlertController(
                    title: Strings.CloudSharing.shareError,
                    message: "\(Strings.CloudSharing.couldNotFetchShareInfo): \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: Strings.Common.ok, style: .default))
                presentAlert(errorAlert)
            }
        }
    }

    operation.qualityOfService = .userInitiated
    container.add(operation)
}

/// Show warning when user has existing profile and is accepting a share
@MainActor
private func showExistingProfileWarning(
    existingName: String,
    ownerName: String,
    metadata: CKShare.Metadata,
    profileStore: ProfileStore,
    logger: Logger
) {
    // With multi-puppy support, we no longer need to replace the existing profile
    // The shared profile will be ADDED to the user's profile list
    let message = existingName.isEmpty
        ? Strings.CloudSharing.addSharedProfileMessageGeneric(ownerName: ownerName)
        : Strings.CloudSharing.addSharedProfileMessage(existingName: existingName, sharedOwner: ownerName)

    let alert = UIAlertController(
        title: Strings.CloudSharing.addSharedProfileTitle,
        message: message,
        preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: Strings.Common.cancel, style: .cancel))
    alert.addAction(UIAlertAction(title: Strings.CloudSharing.acceptShare, style: .default) { _ in
        Task { @MainActor in
            // No longer deleting private profile - multi-puppy support allows both
            await acceptShareInvitation(metadata: metadata, profileStore: profileStore, logger: logger)
        }
    })

    presentAlert(alert)
}

/// Accept the share invitation and reload profile
@MainActor
private func acceptShareInvitation(
    metadata: CKShare.Metadata,
    profileStore: ProfileStore?,
    logger: Logger
) async {
    guard ShareAcceptanceRegistry.shared.beginIfNeeded(for: metadata) else {
        logger.info("Share acceptance already in progress for this invitation")
        return
    }
    defer { ShareAcceptanceRegistry.shared.end(for: metadata) }

    // Show accepting alert
    let acceptingAlert = UIAlertController(
        title: Strings.CloudSharing.acceptingShare,
        message: Strings.CloudSharing.connectingToSharedData,
        preferredStyle: .alert
    )
    presentAlert(acceptingAlert)

    do {
        let previousSharedProfileIDs = profileStore?.currentSharedProfileIDs() ?? sharedProfileIDSnapshot()

        // Accept via PersistenceController so the shared data is routed into the shared store
        // This is required for NSPersistentCloudKitContainer's two-store architecture
        try await PersistenceController.shared.acceptShareInvitation(from: metadata)

        // Update CloudKit service state
        CloudKitService.shared.markAsParticipant()

        // Notify stores to refresh their data and skip onboarding
        NotificationCenter.default.post(name: .cloudKitShareAccepted, object: nil)

        // Wait for shared profile import before showing "dog added" confirmation.
        // Acceptance and data import are separate phases in CloudKit sharing.
        let importedSharedDogName: String?
        if let profileStore {
            importedSharedDogName = await profileStore.awaitNewlySharedProfile(
                previousSharedProfileIDs: previousSharedProfileIDs,
                timeoutSeconds: 30
            )?.name
        } else {
            importedSharedDogName = await waitForSharedProfileName(
                previousSharedProfileIDs: previousSharedProfileIDs,
                timeoutSeconds: 30
            )
        }

        acceptingAlert.dismiss(animated: true) {
            let successAlert = UIAlertController(
                title: importedSharedDogName == nil ? Strings.CloudSharing.shareAccepted : Strings.CloudSharing.sharedDogReadyTitle,
                message: importedSharedDogName.map { Strings.CloudSharing.sharedDogReadyMessage(name: $0) } ?? Strings.CloudSharing.shareAcceptedSyncingMessage,
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: Strings.Common.ok, style: .default))
            presentAlert(successAlert)
        }

        logger.info("✅ Share accepted successfully")
    } catch {
        logger.error("❌ Failed to accept share: \(error.localizedDescription)")

        acceptingAlert.dismiss(animated: true) {
            let errorAlert = UIAlertController(
                title: Strings.CloudSharing.shareFailed,
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: Strings.Common.ok, style: .default))
            presentAlert(errorAlert)
        }
    }
}

/// Helper to present alerts on the current window
@MainActor
private func presentAlert(_ alert: UIAlertController) {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows.first?.rootViewController?
        .present(alert, animated: true)
}

@main
struct OtisApp: App {
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
    @StateObject private var appointmentStore = AppointmentStore()
    @StateObject private var weightStore = WeightStore()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var atmosphereProvider = AtmosphereProvider()
    @StateObject private var foodRecallService = FoodRecallService()
    @ObservedObject private var cloudKit = CloudKitService.shared
    @State private var toastManager = ToastManager()

    init() {
        // Initialize crash reporting first (before any other code that might crash)
        CrashReporter.start()

        // Track app launch for analytics
        OtisAnalytics.shared.trackAppLaunch()

        UserPreferences.registerDefaults()
        AINudgeRollout.registerDefaults()

        // Configure TipKit for contextual tips
        configureTips()

        // Install seed data for UI testing (screenshot automation) - always runs regardless of build config
        if SeedData.isUITesting {
            SeedData.installSeedDataIfNeeded()
        }
        #if DEBUG
        // Install seed data for development (when not UI testing)
        if !SeedData.isUITesting {
            SeedData.installSeedDataIfNeeded()
        }
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
                .environmentObject(appointmentStore)
                .environmentObject(weightStore)
                .environmentObject(subscriptionManager)
                .environmentObject(cloudKit)
                .environmentObject(atmosphereProvider)
                .environmentObject(foodRecallService)
                .toastContainer()
                .environment(toastManager)
                .task {
                    // Run Core Data migration from JSONL files (one-time, on first launch after update)
                    do {
                        try await CoreDataMigrationCoordinator.shared.migrateIfNeeded(using: persistenceController)
                    } catch {
                        Logger.otis(category: "App").error("Migration failed: \(error.localizedDescription)")
                    }

                    // Wire up event store with profile store for profile-scoped queries
                    eventStore.setProfileStore(profileStore)

                    // Wire up location manager to weather service
                    weatherService.setLocationManager(locationManager)

                    // Wire up atmosphere provider to weather service
                    atmosphereProvider.setWeatherService(weatherService)

                    // Note: Location authorization is now requested during onboarding
                    // No automatic request here - the user can enable location from Settings if skipped

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

                    // Wire up AppointmentStore with ProfileStore and migrate any orphaned appointments
                    appointmentStore.setProfileStore(profileStore)
                    appointmentStore.migrateOrphanedAppointments()

                    // Wire up WeightStore with ProfileStore and run migration
                    weightStore.setProfileStore(profileStore)
                    await CoreDataMigrationCoordinator.shared.migrateWeightEventsIfNeeded(using: persistenceController)
                    weightStore.migrateOrphanedMeasurements()

                    // Initial sync to Apple Watch
                    WatchSyncService.shared.syncToWatch()

                    // Check for food recalls if enabled
                    await foodRecallService.checkForRecalls()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Import any events logged via Siri/Shortcuts while app was in background
                    eventStore.importPendingIntentEvents(profile: profileStore.profile)

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
                    Analytics.trackDay2ReturnIfEligible(profileId: profileStore.profile?.id)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    // Clear image cache on memory warning
                    ImageCache.shared.handleMemoryWarning()
                }
                // Handle CloudKit share URLs directly (since userDidAcceptCloudKitShareWith isn't reliable in SwiftUI)
                .onOpenURL { url in
                    Logger.otis(category: "App").info("🔗 onOpenURL called: \(url.absoluteString)")
                    Logger.otis(category: "App").info("🔗 URL scheme: \(url.scheme ?? "nil")")

                    // Check if this is a CloudKit share URL
                    // CloudKit share URLs come as: cloudkit-{containerID}:// or https://www.icloud.com/share/...
                    let isCloudKitScheme = url.scheme?.hasPrefix("cloudkit") == true
                    let isICloudShareURL = url.absoluteString.contains("icloud.com/share")

                    if isCloudKitScheme || isICloudShareURL {
                        Logger.otis(category: "App").info("🔗 Detected CloudKit share URL, fetching metadata...")

                        Task {
                            await handleCloudKitShareURL(url, profileStore: profileStore)
                        }
                    }
                }
        }
    }
}

// MARK: - App Delegate for CloudKit Remote Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger.otis(category: "AppDelegate")

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
    /// This is the system callback for CloudKit share URLs - it provides pre-fetched metadata
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
            await acceptShareInvitation(
                metadata: cloudKitShareMetadata,
                profileStore: nil,
                logger: logger
            )
        }
    }
}
