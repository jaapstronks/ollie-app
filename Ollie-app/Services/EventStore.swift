//
//  EventStore.swift
//  Ollie-app
//
//  Manages reading and writing puppy events with CloudKit sync and local cache
//  Orchestrates LocalEventFileStore and EventSyncCoordinator
//

import Combine
import Foundation
import OllieShared
import os

/// Manages reading and writing puppy events
/// Architecture: Local-first with CloudKit sync
/// - Saves locally first (instant, works offline)
/// - Syncs to CloudKit in background
/// - Subscribes to CloudKit changes for multi-device/multi-user sync
@MainActor
class EventStore: ObservableObject {
    @Published private(set) var events: [PuppyEvent] = []
    @Published private(set) var currentDate: Date = Date()
    @Published private(set) var isSyncing = false
    @Published private(set) var syncError: String?

    private let logger = Logger.ollie(category: "EventStore")

    /// Local file storage for events
    private let fileStore = LocalEventFileStore()

    /// CloudKit sync coordinator
    private let syncCoordinator = EventSyncCoordinator()

    /// File monitoring for App Intent changes
    private let fileMonitor = FileMonitoringService()

    private var cancellables = Set<AnyCancellable>()

    /// Background refresh task (stored for cancellation)
    private var cloudRefreshTask: Task<Void, Never>?

    init() {
        setupSyncCoordinatorBindings()
        setupFileMonitoring()
        setupWatchEventObserver()
        loadEvents(for: currentDate)

        // Set up sync coordinator callback
        syncCoordinator.onSyncCompleted = { [weak self] in
            await self?.refreshFromCloud()
        }

        // Initial sync on launch
        Task {
            let allLocalEvents = fileStore.readAllEvents()
            await syncCoordinator.initialSync(localEvents: allLocalEvents)
        }
    }

    // MARK: - Setup

    private func setupSyncCoordinatorBindings() {
        // Forward sync state from coordinator
        syncCoordinator.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSyncing)

        syncCoordinator.$syncError
            .receive(on: DispatchQueue.main)
            .assign(to: &$syncError)
    }

    private func setupFileMonitoring() {
        guard let dataDir = fileStore.dataDirectoryURL else { return }

        fileMonitor.onFileChange = { [weak self] in
            self?.handleFileSystemChange()
        }
        fileMonitor.startMonitoring(directoryURL: dataDir)
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

                // Invalidate cache and reload events for current date
                self.fileStore.invalidateCache(for: self.currentDate)
                self.loadEvents(for: self.currentDate)
            }
        }
    }

    // MARK: - Public Methods

    /// Load events for a specific date
    func loadEvents(for date: Date) {
        // Read events synchronously first
        let loadedEvents = fileStore.readEvents(for: date)

        // Cancel any existing cloud refresh task
        cloudRefreshTask?.cancel()

        // Defer published property updates to avoid "Publishing changes from within view updates"
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.currentDate = date
            self.events = loadedEvents

            // Then fetch from CloudKit in background
            self.cloudRefreshTask = Task {
                await self.refreshFromCloud()
            }
        }
    }

    /// Refresh current date's events from CloudKit
    func refreshFromCloud() async {
        guard syncCoordinator.isCloudAvailable else { return }
        guard !Task.isCancelled else { return }

        do {
            let cloudEvents = try await syncCoordinator.fetchEvents(for: currentDate)
            guard !Task.isCancelled else { return }

            // Clear cache for this date before merging
            fileStore.invalidateCache(for: currentDate)

            // Merge with local events
            let localEvents = fileStore.readEvents(for: currentDate)
            let mergedEvents = syncCoordinator.mergeEvents(local: localEvents, cloud: cloudEvents)

            // Update UI
            events = mergedEvents.sorted { $0.time > $1.time }

            // Persist merged result locally
            fileStore.saveEvents(mergedEvents, for: currentDate)
        } catch {
            logger.warning("Failed to refresh from cloud: \(error.localizedDescription)")
        }
    }

    /// Add a new event
    func addEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        var newEvent = event

        // Ensure unique ID
        if events.contains(where: { $0.id == newEvent.id }) {
            newEvent.id = UUID()
        }

        // Add to in-memory list
        events.append(newEvent)
        events.sort { $0.time > $1.time }

        // Persist to local file for the event's actual date (not currentDate)
        let eventDate = newEvent.time.startOfDay
        fileStore.saveEvent(newEvent, for: eventDate)

        // Update widgets
        updateWidgetData(profile: profile)

        // Sync to CloudKit in background
        Task {
            await syncCoordinator.saveToCloud(newEvent)
        }

        // Check if it's time to request a review (after successful event logging)
        ReviewService.shared.checkForUsageBasedReview()

        // Check for streak milestone review (for outdoor potty events)
        if newEvent.type == .plassen && newEvent.location == .buiten {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let allEvents = getEvents(from: thirtyDaysAgo, to: Date())
            let currentStreak = StreakCalculations.calculateCurrentStreak(events: allEvents)
            ReviewService.shared.checkForStreakMilestoneReview(currentStreak: currentStreak)
        }

        // Sync to Apple Watch
        WatchSyncService.shared.syncToWatch()
    }

    /// Delete an event
    func deleteEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        // Delete associated media files
        fileStore.deleteMediaFiles(for: event)

        // Remove from in-memory list
        events.removeAll { $0.id == event.id }

        // Persist locally
        let eventsForDate = events.filter { Calendar.current.isDate($0.time, inSameDayAs: currentDate) }
        fileStore.saveEvents(eventsForDate, for: currentDate)

        // Update widgets
        updateWidgetData(profile: profile)

        // Delete from CloudKit
        Task {
            await syncCoordinator.deleteFromCloud(event)
        }

        // Sync to Apple Watch
        WatchSyncService.shared.syncToWatch()
    }

    /// Update an existing event
    func updateEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            // Update modifiedAt timestamp
            let updatedEvent = event.withUpdatedTimestamp()
            events[index] = updatedEvent
            events.sort { $0.time > $1.time }

            let eventsForDate = events.filter { Calendar.current.isDate($0.time, inSameDayAs: currentDate) }
            fileStore.saveEvents(eventsForDate, for: currentDate)

            // Update widgets
            updateWidgetData(profile: profile)

            Task {
                await syncCoordinator.saveToCloud(updatedEvent)
            }

            // Sync to Apple Watch
            WatchSyncService.shared.syncToWatch()
        }
    }

    /// Get all events for a date range
    func getEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        fileStore.readEvents(from: startDate, to: endDate)
    }

    /// Get all events that have media (photos)
    func getEventsWithMedia(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        getEvents(from: startDate, to: endDate).filter { $0.photo != nil }
    }

    /// Get all events for a date range from CloudKit
    func getEventsFromCloud(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        guard syncCoordinator.isCloudAvailable else {
            return getEvents(from: startDate, to: endDate)
        }

        do {
            let cloudEvents = try await syncCoordinator.fetchEvents(from: startDate, to: endDate)
            let localEvents = getEvents(from: startDate, to: endDate)
            return syncCoordinator.mergeEvents(local: localEvents, cloud: cloudEvents)
        } catch {
            logger.warning("Failed to fetch from cloud: \(error.localizedDescription)")
            return getEvents(from: startDate, to: endDate)
        }
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
            let dayEvents = fileStore.readEvents(for: date)
            if let event = dayEvents.filter({ $0.type == type }).first {
                return event
            }
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        return nil
    }

    /// Check if data directory exists
    func dataDirectoryExists() -> Bool {
        fileStore.dataDirectoryExists()
    }

    /// Force a full sync with CloudKit
    func forceSync() async {
        await syncCoordinator.forceSync()
    }

    /// Retry pending cloud operations
    func retryPendingOperations() async {
        await syncCoordinator.retryPendingOperations()
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

    // MARK: - File Monitoring

    private func handleFileSystemChange() {
        logger.debug("Detected file system change, reloading events")

        // Invalidate cache for current date
        fileStore.invalidateCache(for: currentDate)

        // Reload events
        let reloadedEvents = fileStore.readEvents(for: currentDate)

        // Only update if different
        if reloadedEvents.map({ $0.id }) != events.map({ $0.id }) {
            events = reloadedEvents
            logger.info("Events updated from file system change")
        }
    }
}
