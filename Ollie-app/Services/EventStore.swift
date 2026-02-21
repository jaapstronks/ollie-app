//
//  EventStore.swift
//  Ollie-app
//
//  Manages reading and writing puppy events with CloudKit sync and local cache
//

import Foundation
import Combine
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

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let cloudKit = CloudKitService.shared
    private let logger = Logger(subsystem: "nl.jaapstronks.Ollie", category: "EventStore")

    private var cancellables = Set<AnyCancellable>()
    private var pendingCloudSaves: [PuppyEvent] = []
    private var pendingCloudDeletes: [PuppyEvent] = []

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.iso8601String)
        }

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = Date.fromISO8601(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        setupCloudKitObservers()
        loadEvents(for: currentDate)

        // Initial sync on launch
        Task {
            await initialSync()
        }
    }

    // MARK: - Setup

    private func setupCloudKitObservers() {
        // Observe CloudKit sync state
        cloudKit.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSyncing)

        cloudKit.$syncError
            .receive(on: DispatchQueue.main)
            .assign(to: &$syncError)

        // Listen for sync completion to refresh local data
        NotificationCenter.default.publisher(for: .cloudKitSyncCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleSyncCompleted(notification)
            }
            .store(in: &cancellables)
    }

    private func initialSync() async {
        await cloudKit.setup()

        // Migrate local data to CloudKit if needed
        if cloudKit.isCloudAvailable && !cloudKit.isMigrationCompleted {
            await migrateLocalDataToCloudKit()
        }

        // Sync from cloud
        do {
            try await cloudKit.sync()
            await refreshFromCloud()
        } catch {
            logger.warning("Initial sync failed: \(error.localizedDescription)")
        }
    }

    private func handleSyncCompleted(_ notification: Notification) {
        // Refresh current date's events
        Task {
            await refreshFromCloud()
        }
    }

    // MARK: - Public Methods

    /// Load events for a specific date
    func loadEvents(for date: Date) {
        currentDate = date

        // Load from local cache first (instant)
        events = readEvents(for: date)

        // Then fetch from CloudKit in background
        Task {
            await refreshFromCloud()
        }
    }

    /// Refresh current date's events from CloudKit
    func refreshFromCloud() async {
        guard cloudKit.isCloudAvailable else { return }

        do {
            let cloudEvents = try await cloudKit.fetchEvents(for: currentDate)

            // Merge with local events
            let localEvents = readEvents(for: currentDate)
            let mergedEvents = mergeEvents(local: localEvents, cloud: cloudEvents)

            // Update UI
            events = mergedEvents.sorted { $0.time > $1.time }

            // Persist merged result locally
            saveEventsLocally(mergedEvents, for: currentDate)
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

        // Persist to local file (instant, works offline)
        saveEvents(for: currentDate)

        // Update widgets
        updateWidgetData(profile: profile)

        // Sync to CloudKit in background
        Task {
            await saveToCloud(newEvent)
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
    }

    /// Delete an event
    func deleteEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        // Delete associated media files
        deleteMediaFiles(for: event)

        // Remove from in-memory list
        events.removeAll { $0.id == event.id }

        // Persist locally
        saveEvents(for: currentDate)

        // Update widgets
        updateWidgetData(profile: profile)

        // Delete from CloudKit
        Task {
            await deleteFromCloud(event)
        }
    }

    /// Update an existing event
    func updateEvent(_ event: PuppyEvent, profile: PuppyProfile? = nil) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            events.sort { $0.time > $1.time }

            saveEvents(for: currentDate)

            // Update widgets
            updateWidgetData(profile: profile)

            Task {
                await saveToCloud(event)
            }
        }
    }

    /// Delete media files associated with an event
    private func deleteMediaFiles(for event: PuppyEvent) {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if let photoPath = event.photo {
            let photoURL = documentsURL.appendingPathComponent(photoPath)
            try? fileManager.removeItem(at: photoURL)
        }

        if let thumbnailPath = event.thumbnailPath {
            let thumbnailURL = documentsURL.appendingPathComponent(thumbnailPath)
            try? fileManager.removeItem(at: thumbnailURL)
        }
    }

    /// Get all events that have media (photos)
    func getEventsWithMedia(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        let allEvents = getEvents(from: startDate, to: endDate)
        return allEvents.filter { $0.photo != nil }
    }

    /// Get all events for a date range
    func getEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        var allEvents: [PuppyEvent] = []
        var current = startDate.startOfDay

        while current <= endDate {
            allEvents.append(contentsOf: readEvents(for: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }

        return allEvents.sorted { $0.time > $1.time }
    }

    /// Get all events for a date range from CloudKit
    func getEventsFromCloud(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        guard cloudKit.isCloudAvailable else {
            return getEvents(from: startDate, to: endDate)
        }

        do {
            let cloudEvents = try await cloudKit.fetchEvents(from: startDate, to: endDate)
            let localEvents = getEvents(from: startDate, to: endDate)
            return mergeEvents(local: localEvents, cloud: cloudEvents)
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
            let dayEvents = readEvents(for: date)
            if let event = dayEvents.filter({ $0.type == type }).first {
                return event
            }
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        return nil
    }

    /// Check if data directory exists
    func dataDirectoryExists() -> Bool {
        fileManager.fileExists(atPath: dataDirectoryURL.path)
    }

    /// Force a full sync with CloudKit
    func forceSync() async {
        guard cloudKit.isCloudAvailable else {
            syncError = "CloudKit niet beschikbaar"
            return
        }

        do {
            try await cloudKit.sync()
            await refreshFromCloud()
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Retry pending cloud operations
    func retryPendingOperations() async {
        // Retry saves
        for event in pendingCloudSaves {
            await saveToCloud(event)
        }

        // Retry deletes
        for event in pendingCloudDeletes {
            await deleteFromCloud(event)
        }
    }

    // MARK: - CloudKit Operations

    private func saveToCloud(_ event: PuppyEvent) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudSaves.append(event)
            return
        }

        do {
            try await cloudKit.saveEvent(event)
            pendingCloudSaves.removeAll { $0.id == event.id }
        } catch {
            logger.warning("Failed to save to cloud, will retry: \(error.localizedDescription)")
            if !pendingCloudSaves.contains(where: { $0.id == event.id }) {
                pendingCloudSaves.append(event)
            }
        }
    }

    private func deleteFromCloud(_ event: PuppyEvent) async {
        guard cloudKit.isCloudAvailable else {
            pendingCloudDeletes.append(event)
            return
        }

        do {
            try await cloudKit.deleteEvent(event)
            pendingCloudDeletes.removeAll { $0.id == event.id }
        } catch {
            logger.warning("Failed to delete from cloud: \(error.localizedDescription)")
            if !pendingCloudDeletes.contains(where: { $0.id == event.id }) {
                pendingCloudDeletes.append(event)
            }
        }
    }

    private func migrateLocalDataToCloudKit() async {
        logger.info("Starting local data migration to CloudKit")

        // Collect all local events
        var allLocalEvents: [PuppyEvent] = []

        // Read all JSONL files
        let url = dataDirectoryURL
        guard let files = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files where file.pathExtension == "jsonl" {
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

            for line in lines {
                guard let data = line.data(using: .utf8),
                      let event = try? decoder.decode(PuppyEvent.self, from: data) else { continue }
                allLocalEvents.append(event)
            }
        }

        guard !allLocalEvents.isEmpty else {
            logger.info("No local events to migrate")
            return
        }

        do {
            try await cloudKit.migrateLocalEvents(allLocalEvents)
            logger.info("Migration completed: \(allLocalEvents.count) events")
        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Widget Data

    /// Update shared widget data
    private func updateWidgetData(profile: PuppyProfile?) {
        // Get events from the last 30 days for streak calculations
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let allRecentEvents = getEvents(from: thirtyDaysAgo, to: Date())

        WidgetDataProvider.shared.update(
            events: events,
            allEvents: allRecentEvents,
            profile: profile
        )
    }

    // MARK: - Merging

    /// Merge local and cloud events, preferring cloud version for conflicts
    private func mergeEvents(local: [PuppyEvent], cloud: [PuppyEvent]) -> [PuppyEvent] {
        var merged: [UUID: PuppyEvent] = [:]

        // Add local events
        for event in local {
            merged[event.id] = event
        }

        // Overlay cloud events (cloud wins for conflicts)
        for event in cloud {
            merged[event.id] = event
        }

        return Array(merged.values)
    }

    // MARK: - Local Storage

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var dataDirectoryURL: URL {
        documentsURL.appendingPathComponent(Constants.dataDirectoryName, isDirectory: true)
    }

    private func fileURL(for date: Date) -> URL {
        dataDirectoryURL.appendingPathComponent("\(date.dateString).jsonl")
    }

    private func ensureDataDirectoryExists() {
        if !fileManager.fileExists(atPath: dataDirectoryURL.path) {
            try? fileManager.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private func readEvents(for date: Date) -> [PuppyEvent] {
        let url = fileURL(for: date)

        guard fileManager.fileExists(atPath: url.path),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        return lines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(PuppyEvent.self, from: data)
        }.sorted { $0.time > $1.time }
    }

    private func saveEvents(for date: Date) {
        let eventsForDate = events.filter { Calendar.current.isDate($0.time, inSameDayAs: date) }
        saveEventsLocally(eventsForDate, for: date)
    }

    private func saveEventsLocally(_ eventsToSave: [PuppyEvent], for date: Date) {
        ensureDataDirectoryExists()

        let eventsForDate = eventsToSave.filter { Calendar.current.isDate($0.time, inSameDayAs: date) }
        let lines = eventsForDate.compactMap { event -> String? in
            guard let data = try? encoder.encode(event) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        let content = lines.joined(separator: "\n")
        let url = fileURL(for: date)

        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
