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
        // Defer to next run loop to avoid "Publishing changes from within view updates"
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentDate = date
            self.events = self.coreDataStore.readEvents(for: date)
        }
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
        // Check today first
        if let event = events.filter({ $0.type == type }).first {
            return event
        }

        // Check previous days (up to 7 days back)
        var date = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        for _ in 0..<7 {
            let dayEvents = coreDataStore.readEvents(for: date)
            if let event = dayEvents.filter({ $0.type == type }).first {
                return event
            }
            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
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
                try? fileManager.removeItem(at: fileURL)
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
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let allRecentEvents = getEvents(from: thirtyDaysAgo, to: Date())

        WidgetDataProvider.shared.update(
            events: events,
            allEvents: allRecentEvents,
            profile: profile
        )
    }
}
