//
//  EventStore.swift
//  Otis-app
//
//  Manages reading and writing puppy events with Core Data and automatic CloudKit sync.
//  Observer setup is in EventStore+Observers.swift.
//  Import logic is in EventStore+Import.swift.
//  Widget updates are in EventStore+Widgets.swift.
//

import Combine
import Foundation
import CoreData
import OtisShared
import os

/// Manages reading and writing puppy events
/// Architecture: Core Data with NSPersistentCloudKitContainer for automatic CloudKit sync
@Observable
@MainActor
class EventStore {
    // Note: setter is internal (not private) to allow EventStore+Observers extension to update
    var events: [PuppyEvent] = []
    var currentDate: Date = Date()
    private(set) var isSyncing = false
    private(set) var syncError: String?

    @ObservationIgnored let logger = Logger.otis(category: "EventStore")

    /// Core Data event store
    @ObservationIgnored let coreDataStore: CoreDataEventStore

    /// Media store for photo operations
    @ObservationIgnored private let mediaStore = MediaStore()

    /// Reference to profile store for profile-scoped queries
    @ObservationIgnored weak var profileStoreRef: ProfileStore?

    /// Reference to daily aggregate service for cache invalidation
    @ObservationIgnored weak var dailyAggregateServiceRef: DailyAggregateService?

    @ObservationIgnored var cancellables = Set<AnyCancellable>()

    /// Feature flag for FRC-based timeline updates (vs full reload)
    @ObservationIgnored let useFetchedResultsController: Bool = true

    /// Timeline fetch controller for incremental updates
    @ObservationIgnored lazy var timelineFetchController: TimelineFetchController = {
        let controller = TimelineFetchController(
            context: PersistenceController.shared.viewContext
        )
        controller.onContentChange = { [weak self] in
            self?.handleFetchedResultsChange()
        }
        return controller
    }()

    init(persistenceController: PersistenceController = .shared) {
        self.coreDataStore = CoreDataEventStore(persistenceController: persistenceController)

        setupAllObservers()
        loadEvents(for: currentDate)

        // PERFORMANCE: Extract synced photos in background (runs once at launch)
        // This replaces synchronous extraction that was blocking every event fetch
        coreDataStore.processPhotoExtractionAsync()
    }

    /// Set the profile store reference for profile-scoped queries
    func setProfileStore(_ profileStore: ProfileStore) {
        self.profileStoreRef = profileStore
        updateActiveProfile()
    }

    /// Set the daily aggregate service reference for cache invalidation
    func setDailyAggregateService(_ service: DailyAggregateService) {
        self.dailyAggregateServiceRef = service
    }

    /// Update the active profile on the Core Data store
    func updateActiveProfile() {
        coreDataStore.activeProfile = profileStoreRef?.getActiveCDProfile()
    }

    /// Trigger aggregate recompute for the date of an event
    /// Called after add/update/delete operations
    private func triggerAggregateRecompute(for date: Date) {
        guard let profileId = profileStoreRef?.profile?.id else { return }

        Task {
            // Get events for the affected day (and surrounding days for sleep calculation)
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: date)
            let rangeStart = calendar.date(byAdding: .day, value: -1, to: dayStart)!
            let rangeEnd = calendar.date(byAdding: .day, value: 2, to: dayStart)!
            let events = await getEventsAsync(from: rangeStart, to: rangeEnd)

            await dailyAggregateServiceRef?.recompute(
                date: date,
                profileId: profileId,
                events: events
            )
        }
    }

    // MARK: - Load & Refresh

    /// Load events for a specific date
    func loadEvents(for date: Date) {
        // Defer mutations to the next run loop tick to avoid
        // "Publishing changes from within view updates" when called during
        // a SwiftUI body evaluation.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentDate = date

            if self.useFetchedResultsController {
                self.timelineFetchController.configure(
                    for: date,
                    profile: self.profileStoreRef?.getActiveCDProfile()
                )
                do {
                    try self.timelineFetchController.performFetch()
                    self.events = self.timelineFetchController.fetchedEvents
                } catch {
                    self.logger.error("FRC fetch failed: \(error)")
                    self.events = self.coreDataStore.readEvents(for: date)
                }
            } else {
                self.events = self.coreDataStore.readEvents(for: date)
            }

            self.notifyEventsDidChange()
        }
    }

    /// Handle changes detected by the NSFetchedResultsController
    func handleFetchedResultsChange() {
        guard useFetchedResultsController else { return }

        let newEvents = timelineFetchController.fetchedEvents
        let previousIds = Set(events.map { $0.id })
        let newIds = Set(newEvents.map { $0.id })

        // Skip update if nothing actually changed (same IDs and same count)
        guard newIds != previousIds || newEvents.count != events.count else {
            logger.debug("FRC change but no actual differences")
            return
        }

        logger.info("FRC: \(newIds.subtracting(previousIds).count) new, \(previousIds.subtracting(newIds).count) removed")
        events = newEvents
        notifyEventsDidChange()
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

    // MARK: - CRUD Operations

    /// Add a new event
    func addEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        var newEvent = event

        // Ensure unique ID
        if events.contains(where: { $0.id == newEvent.id }) {
            newEvent.id = UUID()
        }

        do {
            try coreDataStore.saveEvent(newEvent)

            // Add to in-memory list (only if FRC is disabled)
            // When FRC is enabled, the FRC callback fires synchronously during save
            // and already updates the events array - appending here would create duplicates
            if !useFetchedResultsController {
                events.append(newEvent)
                events.sort { $0.time > $1.time }
            }

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

            // Recompute daily aggregate for this event's date
            triggerAggregateRecompute(for: newEvent.time)

            // Check if it's time to request a review
            ReviewService.shared.checkForUsageBasedReview()

            // Check for streak milestone review (for outdoor potty events)
            // Run async to avoid blocking main thread with 30-day event fetch
            if newEvent.type == .plassen && newEvent.location == .buiten {
                Task {
                    let allEvents = await getEventsAsync(from: Date.daysAgo(30), to: Date())
                    let currentStreak = StreakCalculations.calculateCurrentStreak(events: allEvents)
                    ReviewService.shared.checkForStreakMilestoneReview(currentStreak: currentStreak)
                }
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

            // Notify observers of event changes
            notifyEventsDidChange()
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

            // Recompute daily aggregate for this event's date
            triggerAggregateRecompute(for: event.time)

            // Notify observers of event changes
            notifyEventsDidChange()
        } catch {
            logger.error("Failed to delete event: \(error.localizedDescription)")
            syncError = error.localizedDescription
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

            // Recompute daily aggregate for this event's date
            triggerAggregateRecompute(for: updatedEvent.time)

            // Notify observers of event changes
            notifyEventsDidChange()
        } catch {
            logger.error("Failed to update event: \(error.localizedDescription)")
            syncError = error.localizedDescription
        }
    }

    // MARK: - Photo Sync

    /// Mark a photo as synced to CloudKit
    /// Called by PhotoSyncService after successful upload
    /// - Parameters:
    ///   - eventId: The event ID
    ///   - ownerName: The CloudKit zone owner who uploaded the photo (needed for partner downloads)
    func markPhotoAsSynced(eventId: UUID, ownerName: String?) {
        guard var event = events.first(where: { $0.id == eventId }) else {
            // Event might be on a different day, fetch from store
            if let storedEvent = coreDataStore.fetchEvent(byId: eventId) {
                var mutableEvent = storedEvent
                mutableEvent.cloudPhotoSynced = true
                mutableEvent.cloudPhotoOwner = ownerName
                do {
                    try coreDataStore.saveEvent(mutableEvent)
                    logger.info("Marked photo as synced for event \(eventId), owner: \(ownerName ?? "unknown")")
                } catch {
                    logger.error("Failed to mark photo as synced: \(error.localizedDescription)")
                }
            }
            return
        }

        event.cloudPhotoSynced = true
        event.cloudPhotoOwner = ownerName
        do {
            try coreDataStore.saveEvent(event)
            // Update in-memory list
            if let index = events.firstIndex(where: { $0.id == eventId }) {
                events[index] = event
            }
            logger.info("Marked photo as synced for event \(eventId), owner: \(ownerName ?? "unknown")")
        } catch {
            logger.error("Failed to mark photo as synced: \(error.localizedDescription)")
        }
    }

    /// Set the photo owner for an event (migration for existing photos)
    /// Called during migration to backfill cloudPhotoOwner for photos uploaded before owner tracking
    func setPhotoOwner(eventId: UUID, ownerName: String) {
        // Try in-memory first
        if var event = events.first(where: { $0.id == eventId }) {
            // Only update if not already set
            guard event.cloudPhotoOwner == nil else { return }

            event.cloudPhotoOwner = ownerName
            do {
                try coreDataStore.saveEvent(event)
                if let index = events.firstIndex(where: { $0.id == eventId }) {
                    events[index] = event
                }
                logger.debug("Migrated photo owner for event \(eventId)")
            } catch {
                logger.error("Failed to migrate photo owner: \(error.localizedDescription)")
            }
            return
        }

        // Event might be on a different day, fetch from store
        if let storedEvent = coreDataStore.fetchEvent(byId: eventId) {
            guard storedEvent.cloudPhotoOwner == nil else { return }

            var mutableEvent = storedEvent
            mutableEvent.cloudPhotoOwner = ownerName
            do {
                try coreDataStore.saveEvent(mutableEvent)
                logger.debug("Migrated photo owner for event \(eventId)")
            } catch {
                logger.error("Failed to migrate photo owner: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Like Operations

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

            // Notify observers of event changes
            notifyEventsDidChange()

            return updatedEvent
        } catch {
            logger.error("Failed to toggle like: \(error.localizedDescription)")
            syncError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Query Operations

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

    /// Get the date of the earliest logged event
    func getEarliestEventDate() -> Date? {
        coreDataStore.getEarliestEventDate()
    }

    // MARK: - Utility Methods

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
            notifyEventsDidChange()
        } catch {
            logger.error("Failed to delete all events: \(error.localizedDescription)")
        }
    }

    /// Retry pending operations (no-op with automatic CloudKit sync)
    func retryPendingOperations() async {
        // With NSPersistentCloudKitContainer, retries are automatic
    }

    /// Post notification when events change
    /// Used by EventDataProvider and other observers since @Observable doesn't support Combine
    func notifyEventsDidChange() {
        NotificationCenter.default.post(name: .eventsDidChange, object: self)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let eventsDidChange = Notification.Name("eventsDidChange")
}
