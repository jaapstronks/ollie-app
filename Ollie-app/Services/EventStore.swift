//
//  EventStore.swift
//  Ollie-app
//
//  Manages reading and writing puppy events with Core Data and automatic CloudKit sync
//

import Combine
import Foundation
import CoreData
import OllieShared
import os

/// Manages reading and writing puppy events
/// Architecture: Core Data with NSPersistentCloudKitContainer for automatic CloudKit sync
@MainActor
class EventStore: ObservableObject {
    @Published private(set) var events: [PuppyEvent] = []
    @Published private(set) var currentDate: Date = Date()
    @Published private(set) var isSyncing = false
    @Published private(set) var syncError: String?

    private let logger = Logger.ollie(category: "EventStore")

    /// Core Data event store
    private let coreDataStore: CoreDataEventStore

    /// Media store for photo operations
    private let mediaStore = MediaStore()

    private var cancellables = Set<AnyCancellable>()

    /// NSFetchedResultsController for reactive updates
    private var fetchedResultsController: NSFetchedResultsController<CDPuppyEvent>?

    init(persistenceController: PersistenceController = .shared) {
        self.coreDataStore = CoreDataEventStore(persistenceController: persistenceController)

        setupRemoteChangeObserver()
        setupWatchEventObserver()
        loadEvents(for: currentDate)
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

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change")
        coreDataStore.invalidateCache(for: currentDate)
        loadEvents(for: currentDate)
    }

    private func handleShareAccepted() {
        logger.info("Share accepted - reloading data from shared store")
        coreDataStore.invalidateAllCaches()
        loadEvents(for: currentDate)
    }

    // MARK: - Public Methods

    /// Load events for a specific date
    func loadEvents(for date: Date) {
        currentDate = date
        events = coreDataStore.readEvents(for: date)
    }

    /// Refresh events (re-read from Core Data)
    func refreshFromCloud() async {
        // With NSPersistentCloudKitContainer, CloudKit sync is automatic
        // Just invalidate cache and reload
        coreDataStore.invalidateCache(for: currentDate)
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

            // Update widgets
            updateWidgetData(profile: profile)

            // Sync to Apple Watch
            WatchSyncService.shared.syncToWatch()

            // Check if it's time to request a review
            ReviewService.shared.checkForUsageBasedReview()

            // Check for streak milestone review (for outdoor potty events)
            if newEvent.type == .plassen && newEvent.location == .buiten {
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let allEvents = getEvents(from: thirtyDaysAgo, to: Date())
                let currentStreak = StreakCalculations.calculateCurrentStreak(events: allEvents)
                ReviewService.shared.checkForStreakMilestoneReview(currentStreak: currentStreak)
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

    /// Get all events for a date range
    func getEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        coreDataStore.readEvents(from: startDate, to: endDate)
    }

    /// Get all events that have media (photos)
    func getEventsWithMedia(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        getEvents(from: startDate, to: endDate).filter { $0.photo != nil }
    }

    /// Get all events for a date range (async version)
    func getEventsFromCloud(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        // With Core Data + CloudKit, local and cloud are automatically synced
        await coreDataStore.readEventsAsync(from: startDate, to: endDate)
    }

    /// Get the most recent event of a specific type
    func lastEvent(ofType type: EventType) -> PuppyEvent? {
        // Check today first
        if let event = events.filter({ $0.type == type }).first {
            return event
        }

        // Check previous days (up to 7 days back)
        var date = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        for _ in 0..<7 {
            let dayEvents = coreDataStore.readEvents(for: date)
            if let event = dayEvents.filter({ $0.type == type }).first {
                return event
            }
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        return nil
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

    // MARK: - Widget Data

    private func updateWidgetData(profile: PuppyProfile?) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let allRecentEvents = getEvents(from: thirtyDaysAgo, to: Date())

        WidgetDataProvider.shared.update(
            events: events,
            allEvents: allRecentEvents,
            profile: profile
        )
    }
}
