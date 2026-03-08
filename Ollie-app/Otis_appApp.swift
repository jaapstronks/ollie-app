//
//  Otis_appApp.swift
//  Otis-app
//

import CloudKit
import CoreData
import OtisShared
import os
import SwiftUI
import TipKit
import UserNotifications

@main
struct OtisApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Core Data persistence controller (must be initialized first)
    let persistenceController = PersistenceController.shared

    // MARK: - State Objects

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
    @StateObject private var skillProgressStore = SkillProgressStore()
    @StateObject private var regressionLogStore = RegressionLogStore()
    @StateObject private var routineStore = RoutineStore()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var atmosphereProvider = AtmosphereProvider()
    @StateObject private var foodRecallService = FoodRecallService()
    @ObservedObject private var cloudKit = CloudKitService.shared
    @State private var toastManager = ToastManager()

    // MARK: - Initialization

    init() {
        CrashReporter.start()
        OtisAnalytics.shared.trackAppLaunch()
        UserPreferences.registerDefaults()
        AINudgeRollout.registerDefaults()
        configureTips()

        // Install seed data for UI testing or development
        if SeedData.isUITesting {
            SeedData.installSeedDataIfNeeded()
        }
        #if DEBUG
        if !SeedData.isUITesting {
            SeedData.installSeedDataIfNeeded()
        }
        #endif
    }

    // MARK: - Body

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
                .environmentObject(skillProgressStore)
                .environmentObject(cloudKit)
                .environmentObject(atmosphereProvider)
                .environmentObject(foodRecallService)
                .environmentObject(routineStore)
                .toastContainer()
                .environment(toastManager)
                .task { await performInitialSetup() }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleForegroundEntry()
                }
                .onReceive(NotificationCenter.default.publisher(for: .shareAccessRevoked)) { _ in
                    handleShareAccessRevoked()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    ReviewService.shared.recordAppActive()
                    Analytics.trackDay2ReturnIfEligible(profileId: profileStore.profile?.id)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    ImageCache.shared.handleMemoryWarning()
                }
                .onOpenURL { url in
                    handleOpenURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    handleUserActivity(userActivity)
                }
        }
    }
}

// MARK: - Setup & Lifecycle

private extension OtisApp {

    func performInitialSetup() async {
        let logger = Logger.otis(category: "App")

        // Make ProfileStore available to SceneDelegate for CloudKit share handling
        ProfileStoreProvider.shared.store = profileStore

        // Run Core Data migration
        do {
            try await CoreDataMigrationCoordinator.shared.migrateIfNeeded(using: persistenceController)
        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
        }

        // Wire up dependencies
        eventStore.setProfileStore(profileStore)
        weatherService.setLocationManager(locationManager)
        atmosphereProvider.setWeatherService(weatherService)

        // Check subscription status
        await subscriptionManager.checkSubscriptionStatus()
        await subscriptionManager.loadProducts()

        // Setup CloudKit and perform initial syncs
        await CloudKitService.shared.setup()
        await UserIdentityStore.shared.setup()
        await profileStore.initialSync()
        await spotStore.initialSync()
        await medicationStore.initialSync()
        await milestoneStore.initialSync()

        // Process any pending CloudKit share
        await CloudKitShareHandler.processPendingShare(profileStore: profileStore)

        // Refresh participant info from CloudKit shares (for partner activity cards)
        await ParticipantResolver.shared.refreshFromCloudKit()

        // Perform initial photo sync - upload any pending photos
        let recentEvents = await eventStore.getEventsAsync(from: Date.daysAgo(30), to: Date())
        PhotoSyncService.shared.performInitialSync(events: recentEvents)

        // Seed default milestones
        milestoneStore.seedDefaultMilestonesIfNeeded()

        // Wire up remaining stores
        documentStore.setProfileStore(profileStore)
        documentStore.migrateOrphanedDocuments()
        appointmentStore.setProfileStore(profileStore)
        appointmentStore.migrateOrphanedAppointments()
        weightStore.setProfileStore(profileStore)
        await CoreDataMigrationCoordinator.shared.migrateWeightEventsIfNeeded(using: persistenceController)
        weightStore.migrateOrphanedMeasurements()
        routineStore.setProfileStore(profileStore)
        routineStore.migrateOrphanedItems()

        // Sync to Apple Watch
        WatchSyncService.shared.syncToWatch()

        // Check for food recalls
        await foodRecallService.checkForRecalls()

        // Wire up AI services with all data providers
        AI.setup(
            skillProgressStore: skillProgressStore,
            regressionLogStore: regressionLogStore,
            socializationStore: socializationStore,
            sentimentStore: SentimentStore.shared,
            profileStore: profileStore
        )
    }

    func handleForegroundEntry() {
        // Import events logged via Siri/Shortcuts while app was in background
        eventStore.importPendingIntentEvents(profile: profileStore.profile)

        // Retry failed photo uploads
        PhotoSyncService.shared.retryFailedUploads()

        Task {
            await CloudKitShareHandler.processPendingShare(profileStore: profileStore)
            await eventStore.forceSync()
            await profileStore.forceSync()
            await spotStore.forceSync()
            await medicationStore.forceSync()
            await CloudKitService.shared.checkShareAccessStatus()
            await ParticipantResolver.shared.refreshFromCloudKit()
        }

        WatchSyncService.shared.syncToWatch()
    }

    @MainActor
    func handleShareAccessRevoked() {
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

    func handleOpenURL(_ url: URL) {
        let logger = Logger.otis(category: "App")
        logger.info("🔗 onOpenURL called: \(url.absoluteString)")
        logger.info("🔗 URL scheme: \(url.scheme ?? "nil")")

        let isCloudKitScheme = url.scheme?.hasPrefix("cloudkit") == true
        let isICloudShareURL = url.absoluteString.contains("icloud.com/share")

        if isCloudKitScheme || isICloudShareURL {
            logger.info("🔗 Detected CloudKit share URL, fetching metadata...")
            Task {
                await CloudKitShareHandler.handleShareURL(url, profileStore: profileStore)
            }
        }
    }

    func handleUserActivity(_ userActivity: NSUserActivity) {
        let logger = Logger.otis(category: "App")
        logger.info("🔗 onContinueUserActivity for web browsing")

        guard let url = userActivity.webpageURL else {
            logger.info("🔗 No webpage URL in activity")
            return
        }

        logger.info("🔗 Web URL: \(url.absoluteString)")

        if url.absoluteString.contains("icloud.com/share") {
            logger.info("🔗 Detected iCloud share URL from user activity")
            Task {
                await CloudKitShareHandler.handleShareURL(url, profileStore: profileStore)
            }
        }
    }
}
