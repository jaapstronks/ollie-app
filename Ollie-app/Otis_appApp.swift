//
//  Otis_appApp.swift
//  Otis-app
//

import CloudKit
import CoreData
import OtisShared
import os
import Sentry
import SwiftUI
import TipKit
import UserNotifications

@main
struct OtisApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Core Data persistence controller (must be initialized first)
    let persistenceController = PersistenceController.shared

    // MARK: - State Objects

    @State private var profileStore = ProfileStore()
    @State private var eventStore = EventStore()
    @State private var dataImporter = DataImporter()
    @State private var weatherService = WeatherService()
    @State private var notificationService = NotificationService()
    @State private var spotStore = SpotStore()
    @State private var locationManager = LocationManager()
    @State private var medicationStore = MedicationStore()
    @State private var socializationStore = SocializationStore()
    @State private var milestoneStore = MilestoneStore()
    @State private var documentStore = DocumentStore()
    @State private var contactStore = ContactStore()
    @State private var appointmentStore = AppointmentStore()
    @State private var weightStore = WeightStore()
    @State private var skillProgressStore = SkillProgressStore()
    @State private var regressionLogStore = RegressionLogStore()
    @State private var routineStore = RoutineStore()
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var atmosphereProvider = AtmosphereProvider()
    @State private var foodRecallService = FoodRecallService()
    @State private var unitPreferences = UnitPreferences.shared
    @State private var trainingMasteryStore = TrainingMasteryStore.shared
    @State private var walkTrackingService = WalkTrackingService()
    private var cloudKit = CloudKitService.shared
    private let dailyAggregateService = DailyAggregateService.shared
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
                .environment(profileStore)
                .environment(eventStore)
                .environment(dataImporter)
                .environment(weatherService)
                .environment(notificationService)
                .environment(spotStore)
                .environment(locationManager)
                .environment(medicationStore)
                .environment(socializationStore)
                .environment(milestoneStore)
                .environment(documentStore)
                .environment(contactStore)
                .environment(appointmentStore)
                .environment(weightStore)
                .environment(subscriptionManager)
                .environment(skillProgressStore)
                .environment(cloudKit)
                .environment(atmosphereProvider)
                .environment(foodRecallService)
                .environment(routineStore)
                .environment(unitPreferences)
                .environment(trainingMasteryStore)
                .environment(walkTrackingService)
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

        // Start app launch transaction for Sentry performance monitoring
        let launchTransaction = CrashReporter.startTransaction(name: "App Launch", operation: "app.launch")

        // ============================================================
        // PHASE 1: Critical path - minimum needed to show UI (target: <500ms)
        // ============================================================

        // Make ProfileStore available to SceneDelegate for CloudKit share handling
        ProfileStoreProvider.shared.store = profileStore

        // Run Core Data migration (fast - typically <1ms)
        let migrationSpan = launchTransaction?.startChild(operation: "db.migrate", description: "Core Data Migration")
        do {
            try await CoreDataMigrationCoordinator.shared.migrateIfNeeded(using: persistenceController)
        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
        }
        migrationSpan?.finish()

        // Wire up dependencies (synchronous, fast)
        let wireupSpan = launchTransaction?.startChild(operation: "app.wireup", description: "Wire Dependencies")
        eventStore.setProfileStore(profileStore)
        eventStore.setDailyAggregateService(dailyAggregateService)
        weatherService.setLocationManager(locationManager)
        atmosphereProvider.setWeatherService(weatherService)
        documentStore.setProfileStore(profileStore)
        appointmentStore.setProfileStore(profileStore)
        weightStore.setProfileStore(profileStore)
        routineStore.setProfileStore(profileStore)
        skillProgressStore.configureProfileStore(profileStore)
        milestoneStore.configureProfileStore(profileStore)
        UserIdentityStore.shared.configureProfileStore(profileStore)
        wireupSpan?.finish()

        // Seed default milestones (local operation, fast)
        milestoneStore.seedDefaultMilestonesIfNeeded()

        // Wire up AI services (synchronous setup, fast)
        AI.setup(
            skillProgressStore: skillProgressStore,
            regressionLogStore: regressionLogStore,
            socializationStore: socializationStore,
            sentimentStore: SentimentStore.shared,
            profileStore: profileStore
        )

        // Finish the critical launch transaction - UI is now interactive
        launchTransaction?.finish()

        // ============================================================
        // PHASE 2: Background tasks - run in parallel, don't block UI
        // ============================================================

        // Track background work separately (UI is already interactive at this point)
        CrashReporter.addBreadcrumb(category: "app.launch", message: "Starting background sync tasks")

        // Capture stores for background tasks (avoid capturing self in sendable closures)
        let subManager = subscriptionManager
        let profStore = profileStore
        let sptStore = spotStore
        let medStore = medicationStore
        let milStore = milestoneStore
        let docStore = documentStore
        let apptStore = appointmentStore
        let wgtStore = weightStore
        let rtStore = routineStore
        let evtStore = eventStore
        let recallService = foodRecallService
        let persistence = persistenceController
        let aggregateService = dailyAggregateService

        // Run slow network operations in parallel using async let
        // These run concurrently, reducing total time from ~4.3s to ~2s (max of the parallel tasks)
        async let subscriptionTask: Void = {
            await subManager.checkSubscriptionStatus()
            await subManager.loadProducts()
        }()

        async let cloudKitTask: Void = {
            await CloudKitService.shared.setup()
            await UserIdentityStore.shared.setup()
            await profStore.initialSync()
        }()

        async let secondarySyncTask: Void = {
            // Small delay to let CloudKit setup complete first
            try? await Task.sleep(for: .milliseconds(100))
            await sptStore.initialSync()
            await medStore.initialSync()
            await milStore.initialSync()
        }()

        // Wait for parallel tasks to complete
        _ = await (subscriptionTask, cloudKitTask, secondarySyncTask)

        // Process pending share (depends on CloudKit being set up)
        await CloudKitShareHandler.processPendingShare(profileStore: profStore)

        // Refresh participants (depends on CloudKit being set up)
        await ParticipantResolver.shared.refreshFromCloudKit()

        CrashReporter.addBreadcrumb(category: "app.launch", message: "Background sync tasks completed")

        // ============================================================
        // PHASE 3: Deferred tasks - low priority, run after UI stable
        // ============================================================

        Task { @MainActor in
            // Run migrations (one-time operations)
            docStore.migrateOrphanedDocuments()
            apptStore.migrateOrphanedAppointments()
            await CoreDataMigrationCoordinator.shared.migrateWeightEventsIfNeeded(using: persistence)
            wgtStore.migrateOrphanedMeasurements()
            rtStore.migrateOrphanedItems()
        }

        Task { @MainActor in
            // Sync to Apple Watch
            WatchSyncService.shared.syncToWatch()

            // Check for food recalls
            await recallService.checkForRecalls()

            // Photo sync (already delayed)
            try? await Task.sleep(for: .seconds(2))
            let recentEvents = await evtStore.getEventsAsync(from: Date.daysAgo(30), to: Date())
            PhotoSyncService.shared.performInitialSync(events: recentEvents)

            // Pre-populate daily aggregates (uses same events fetch)
            if let profileId = profStore.profile?.id {
                await aggregateService.prepopulate(
                    days: 30,
                    profileId: profileId,
                    events: recentEvents
                )
            }
        }
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
