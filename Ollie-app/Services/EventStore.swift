//
//  EventStore.swift
//  Otis-app
//
//  Manages reading and writing puppy events with Core Data and automatic CloudKit sync
//

import Combine
import Foundation
import CoreData
import OtisShared
import os

/// Manages reading and writing puppy events
/// Architecture: Core Data with NSPersistentCloudKitContainer for automatic CloudKit sync
@MainActor
class EventStore: ObservableObject {
    @Published private(set) var events: [PuppyEvent] = []
    @Published private(set) var currentDate: Date = Date()
    @Published private(set) var isSyncing = false
    @Published private(set) var syncError: String?

    private let logger = Logger.otis(category: "EventStore")

    /// Core Data event store
    private let coreDataStore: CoreDataEventStore

    /// Media store for photo operations
    private let mediaStore = MediaStore()

    /// Reference to profile store for profile-scoped queries
    private weak var profileStoreRef: ProfileStore?

    private var cancellables = Set<AnyCancellable>()

    /// NSFetchedResultsController for reactive updates
    private var fetchedResultsController: NSFetchedResultsController<CDPuppyEvent>?

    init(persistenceController: PersistenceController = .shared) {
        self.coreDataStore = CoreDataEventStore(persistenceController: persistenceController)

        setupRemoteChangeObserver()
        setupWatchEventObserver()
        setupProfileChangeObserver()
        setupPhotoSyncObserver()
        setupNotificationActionObserver()
        loadEvents(for: currentDate)
    }

    /// Set the profile store reference for profile-scoped queries
    func setProfileStore(_ profileStore: ProfileStore) {
        self.profileStoreRef = profileStore
        updateActiveProfile()
    }

    /// Update the active profile on the Core Data store
    private func updateActiveProfile() {
        coreDataStore.activeProfile = profileStoreRef?.getActiveCDProfile()
    }

    // MARK: - Setup

    private func setupRemoteChangeObserver() {
        // Listen for Core Data remote changes (CloudKit sync)
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)

        // Listen for share acceptance to reload data
        NotificationCenter.default.publisher(for: .cloudKitShareAccepted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleShareAccepted()
            }
            .store(in: &cancellables)
    }

    private func setupWatchEventObserver() {
        NotificationCenter.default.addObserver(
            forName: .watchEventReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            Task { @MainActor in
                self.logger.info("Received event from Apple Watch, reloading...")
                self.coreDataStore.invalidateCache(for: self.currentDate)
                self.loadEvents(for: self.currentDate)
            }
        }
    }

    private func setupProfileChangeObserver() {
        // Listen for active profile changes to reload events
        NotificationCenter.default.publisher(for: .activeProfileChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleProfileChange()
            }
            .store(in: &cancellables)
    }

    private func setupPhotoSyncObserver() {
        // Listen for photo upload completion to update event flags
        NotificationCenter.default.publisher(for: .photoUploadCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID else { return }
                self?.markPhotoAsSynced(eventId: eventId)
            }
            .store(in: &cancellables)

        // Listen for photo upload retry requests
        NotificationCenter.default.publisher(for: .photoUploadRetryRequested)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID,
                      let self = self else { return }
                // Fetch the event and retry upload
                if let event = self.coreDataStore.fetchEvent(byId: eventId) {
                    PhotoSyncService.shared.retryUpload(for: event)
                }
            }
            .store(in: &cancellables)
    }

    private func setupNotificationActionObserver() {
        // Handle like action from moment notification
        NotificationCenter.default.publisher(for: .likeMomentFromNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID,
                      let self = self else { return }
                self.handleLikeFromNotification(eventId: eventId)
            }
            .store(in: &cancellables)
    }

    /// Handle like action triggered from a notification
    private func handleLikeFromNotification(eventId: UUID) {
        // Fetch the event from Core Data
        guard let event = coreDataStore.fetchEvent(byId: eventId) else {
            logger.warning("Could not find event \(eventId) for notification like action")
            return
        }

        // Toggle the like
        if let updatedEvent = toggleLike(on: event) {
            logger.info("Liked event \(eventId) from notification: liked=\(updatedEvent.isLikedBy(UserIdentityStore.shared.currentUserRecordID ?? ""))")
        }
    }

    private func handleProfileChange() {
        logger.info("Active profile changed - updating event store")
        updateActiveProfile()
        coreDataStore.invalidateAllCaches()
        loadEvents(for: currentDate)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change")

        // Get current events before cache invalidation for comparison
        let previousEventIds = Set(events.map { $0.id })

        // Invalidate ALL caches, not just current date
        // Sleep state calculations need recent events from multiple days
        coreDataStore.invalidateAllCaches()
        loadEvents(for: currentDate)

        // Check for new moments from other users and send notifications
        Task {
            await checkForNewMomentsAndNotify(previousEventIds: previousEventIds)
        }
    }

    /// Check for new moment events from CloudKit sync and send notifications
    private func checkForNewMomentsAndNotify(previousEventIds: Set<UUID>) async {
        guard let profile = profileStoreRef?.profile else { return }

        // Get recent events (last 24 hours) to check for new moments
        let recentEvents = getEvents(from: Date.daysAgo(1), to: Date())

        // Find new events that weren't in our previous set
        let newEvents = recentEvents.filter { !previousEventIds.contains($0.id) }

        guard !newEvents.isEmpty else { return }

        // Send notifications for new moments from other users
        await MomentsNotificationHandler.shared.handleRemoteChanges(
            newEvents: newEvents,
            currentUserRecordID: UserIdentityStore.shared.currentUserRecordID,
            puppyName: profile.name,
            settings: profile.notificationSettings
        )
    }

    private func handleShareAccepted() {
        logger.info("Share accepted - reloading data from shared store")
        coreDataStore.invalidateAllCaches()
        loadEvents(for: currentDate)
    }

    // MARK: - Public Methods

    /// Load events for a specific date
    func loadEvents(for date: Date) {
        // Defer to next run loop to avoid "Publishing changes from within view updates"
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentDate = date
            self.events = self.coreDataStore.readEvents(for: date)
        }
    }

    /// Refresh events (re-read from Core Data)
    /// Call this when app returns to foreground to ensure fresh data
    func refreshFromCloud() async {
        // With NSPersistentCloudKitContainer, CloudKit sync is automatic
        // Invalidate ALL caches to ensure sleep state uses fresh data
        coreDataStore.invalidateAllCaches()
        loadEvents(for: currentDate)
    }

    /// Synchronously refresh all data - use when app comes to foreground
    func refreshOnForeground() {
        logger.debug("App returned to foreground - refreshing all data")
        coreDataStore.invalidateAllCaches()
        loadEvents(for: currentDate)
    }

    /// Add a new event
    func addEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        var newEvent = event

        // Ensure unique ID
        if events.contains(where: { $0.id == newEvent.id }) {
            newEvent.id = UUID()
        }

        do {
            try coreDataStore.saveEvent(newEvent)

            // Add to in-memory list
            events.append(newEvent)
            events.sort { $0.time > $1.time }

            // Track analytics
            OtisAnalytics.shared.trackEventLogged(
                type: newEvent.type.rawValue,
                hasLocation: newEvent.location != nil,
                hasNote: newEvent.note != nil,
                hasPhoto: newEvent.photo != nil
            )
            Analytics.trackFirstEventLogged(
                profileId: profileStoreRef?.profile?.id,
                eventType: newEvent.type.rawValue,
                hasLocation: newEvent.location != nil,
                hasNote: newEvent.note != nil,
                hasPhoto: newEvent.photo != nil
            )

            // Update widgets
            updateWidgetData(profile: profile)

            // Sync to Apple Watch
            WatchSyncService.shared.syncToWatch()

            // Check if it's time to request a review
            ReviewService.shared.checkForUsageBasedReview()

            // Check for streak milestone review (for outdoor potty events)
            if newEvent.type == .plassen && newEvent.location == .buiten {
                let allEvents = getEvents(from: Date.daysAgo(30), to: Date())
                let currentStreak = StreakCalculations.calculateCurrentStreak(events: allEvents)
                ReviewService.shared.checkForStreakMilestoneReview(currentStreak: currentStreak)
            }

            // Upload photo to CloudKit if present
            if newEvent.photo != nil {
                PhotoSyncService.shared.uploadPhoto(for: newEvent)
            }

            // Send webhook if configured
            if let webhookConfig = profile?.webhookConfig,
               webhookConfig.shouldSendWebhook(for: newEvent.type) {
                Task {
                    await WebhookService.shared.sendEventWebhook(
                        newEvent,
                        config: webhookConfig,
                        puppyName: profile?.name
                    )
                }
            }
        } catch {
            logger.error("Failed to save event: \(error.localizedDescription)")
            syncError = error.localizedDescription
        }
    }

    /// Delete an event
    func deleteEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        // Delete associated media files
        coreDataStore.deleteMediaFiles(for: event)

        // Delete cloud photo if synced
        if event.cloudPhotoSynced == true {
            Task {
                await PhotoSyncService.shared.deletePhoto(for: event)
            }
        }

        do {
            try coreDataStore.deleteEvent(event)

            // Remove from in-memory list
            events.removeAll { $0.id == event.id }

            // Update widgets
            updateWidgetData(profile: profile)

            // Sync to Apple Watch
            WatchSyncService.shared.syncToWatch()
        } catch {
            logger.error("Failed to delete event: \(error.localizedDescription)")
            syncError = error.localizedDescription
        }
    }

    /// Mark a photo as synced to CloudKit
    /// Called by PhotoSyncService after successful upload
    func markPhotoAsSynced(eventId: UUID) {
        guard var event = events.first(where: { $0.id == eventId }) else {
            // Event might be on a different day, fetch from store
            if let storedEvent = coreDataStore.fetchEvent(byId: eventId) {
                var mutableEvent = storedEvent
                mutableEvent.cloudPhotoSynced = true
                do {
                    try coreDataStore.saveEvent(mutableEvent)
                    logger.info("Marked photo as synced for event \(eventId)")
                } catch {
                    logger.error("Failed to mark photo as synced: \(error.localizedDescription)")
                }
            }
            return
        }

        event.cloudPhotoSynced = true
        do {
            try coreDataStore.saveEvent(event)
            // Update in-memory list
            if let index = events.firstIndex(where: { $0.id == eventId }) {
                events[index] = event
            }
            logger.info("Marked photo as synced for event \(eventId)")
        } catch {
            logger.error("Failed to mark photo as synced: \(error.localizedDescription)")
        }
    }

    /// Update an existing event
    func updateEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        let updatedEvent = event.withUpdatedTimestamp()

        do {
            try coreDataStore.saveEvent(updatedEvent)

            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = updatedEvent
                events.sort { $0.time > $1.time }
            }

            // Update widgets
            updateWidgetData(profile: profile)

            // Sync to Apple Watch
            WatchSyncService.shared.syncToWatch()
        } catch {
            logger.error("Failed to update event: \(error.localizedDescription)")
            syncError = error.localizedDescription
        }
    }

    /// Toggle like on an event from the current user
    /// - Parameter event: The event to like/unlike
    /// - Returns: The updated event, or nil if current user is not available
    @discardableResult
    func toggleLike(on event: PuppyEvent) -> PuppyEvent? {
        guard let currentUserRecordID = UserIdentityStore.shared.currentUserRecordID else {
            logger.warning("Cannot toggle like - no current user record ID")
            return nil
        }

        let updatedEvent = event.withLikeToggled(by: currentUserRecordID)

        do {
            try coreDataStore.saveEvent(updatedEvent)

            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = updatedEvent
            }

            // Track analytics
            let isNowLiked = updatedEvent.isLikedBy(currentUserRecordID)
            Analytics.track(isNowLiked ? .eventLiked : .eventUnliked)

            logger.debug("Toggled like on event \(event.id.uuidString): now \(isNowLiked ? "liked" : "unliked")")
            return updatedEvent
        } catch {
            logger.error("Failed to toggle like: \(error.localizedDescription)")
            syncError = error.localizedDescription
            return nil
        }
    }

    /// Get all events for a date range (sync - uses cache, good for small ranges)
    func getEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        coreDataStore.readEvents(from: startDate, to: endDate)
    }

    /// Get all events for a date range (async - runs on background thread, better for large ranges)
    func getEventsAsync(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        await coreDataStore.readEventsAsync(from: startDate, to: endDate)
    }

    /// Get all events that have media (photos)
    func getEventsWithMedia(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        getEvents(from: startDate, to: endDate).filter { $0.photo != nil }
    }

    /// Get all events that have media (async version)
    func getEventsWithMediaAsync(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        await getEventsAsync(from: startDate, to: endDate).filter { $0.photo != nil }
    }

    /// Get all events for a date range (async version) - alias for backward compatibility
    func getEventsFromCloud(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        // With Core Data + CloudKit, local and cloud are automatically synced
        await coreDataStore.readEventsAsync(from: startDate, to: endDate)
    }

    /// Get the most recent event of a specific type
    func lastEvent(ofType type: EventType) -> PuppyEvent? {
        // Check today's in-memory events first (most common case, O(n) where n is small)
        if let event = events.first(where: { $0.type == type }) {
            return event
        }

        // Single query for 8-day range instead of 7 separate day queries
        // Events are sorted by time descending, so first match is most recent
        let eightDaysAgo = currentDate.addingDays(-8)
        let startOfToday = currentDate.startOfDay
        let historicalEvents = coreDataStore.readEvents(from: eightDaysAgo, to: startOfToday)

        return historicalEvents.first(where: { $0.type == type })
    }

    /// Check if Core Data has any events
    func dataDirectoryExists() -> Bool {
        // With Core Data, this always returns true
        return true
    }

    /// Force a refresh (no-op with automatic CloudKit sync)
    func forceSync() async {
        // With NSPersistentCloudKitContainer, sync is automatic
        // Just reload current data
        await refreshFromCloud()
    }

    /// Delete all local events (use when switching to shared data)
    func deleteAllLocalEvents() {
        logger.info("Deleting all local events for share acceptance")
        events = []
        do {
            try coreDataStore.deleteAllEvents()
        } catch {
            logger.error("Failed to delete all events: \(error.localizedDescription)")
        }
    }

    /// Retry pending operations (no-op with automatic CloudKit sync)
    func retryPendingOperations() async {
        // With NSPersistentCloudKitContainer, retries are automatic
    }

    /// Get the date of the earliest logged event
    func getEarliestEventDate() -> Date? {
        coreDataStore.getEarliestEventDate()
    }

    // MARK: - App Group Event Import

    /// Import events logged via Siri/Shortcuts from the App Group JSONL files
    /// Call this when the app becomes active to pick up events logged externally
    func importPendingIntentEvents(profile: PuppyProfile? = nil) {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) else {
            logger.debug("App Group container not available")
            return
        }

        let dataDir = containerURL.appendingPathComponent("data", isDirectory: true)
        guard fileManager.fileExists(atPath: dataDir.path) else {
            logger.debug("No intent data directory found")
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(at: dataDir, includingPropertiesForKeys: nil)
            let jsonlFiles = files.filter { $0.pathExtension == "jsonl" }

            guard !jsonlFiles.isEmpty else {
                return
            }

            logger.info("Found \(jsonlFiles.count) JSONL files from intents to import")

            var importedCount = 0
            for fileURL in jsonlFiles {
                let importedEvents = importEventsFromJSONL(at: fileURL)
                importedCount += importedEvents

                // Delete the file after successful import
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    logger.warning("Could not delete imported intent file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }

            if importedCount > 0 {
                logger.info("Imported \(importedCount) events from Siri/Shortcuts")
                // Reload events to show imported data
                loadEvents(for: currentDate)
                // Update widgets
                updateWidgetData(profile: profile)
                // Sync to watch
                WatchSyncService.shared.syncToWatch()
            }
        } catch {
            logger.error("Failed to scan intent data directory: \(error.localizedDescription)")
        }
    }

    /// Import events from a single JSONL file
    private func importEventsFromJSONL(at url: URL) -> Int {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return 0
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = Date.fromISO8601(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var importedCount = 0

        for line in lines {
            guard let data = line.data(using: .utf8),
                  let event = try? decoder.decode(PuppyEvent.self, from: data) else {
                continue
            }

            // Check if event already exists (by ID)
            let existingEvents = coreDataStore.readEvents(for: event.time.startOfDay)
            if existingEvents.contains(where: { $0.id == event.id }) {
                logger.debug("Skipping duplicate event: \(event.id)")
                continue
            }

            do {
                try coreDataStore.saveEvent(event)
                importedCount += 1
            } catch {
                logger.error("Failed to import event: \(error.localizedDescription)")
            }
        }

        return importedCount
    }

    // MARK: - Widget Data

    private func updateWidgetData(profile: PuppyProfile?) {
        let allRecentEvents = getEvents(from: Date.daysAgo(30), to: Date())

        WidgetDataProvider.shared.update(
            events: events,
            allEvents: allRecentEvents,
            profile: profile
        )
    }
}
