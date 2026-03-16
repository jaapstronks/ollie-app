//
//  CoreDataEventStore.swift
//  Otis-app
//
//  Handles Core Data operations for puppy events
//  Replaces LocalEventFileStore with same public API
//

import Foundation
import CoreData
import OtisShared
import os

/// Handles Core Data operations for puppy events
/// Architecture: Same API as LocalEventFileStore for easy migration
/// Supports profile-scoped queries for multi-puppy feature
final class CoreDataEventStore: @unchecked Sendable {

    // MARK: - Properties

    private let persistenceController: PersistenceController
    private let logger = Logger.otis(category: "CoreDataEventStore")
    private let fileManager = FileManager.default

    /// Documents directory for photo storage
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
    }

    /// Active profile for scoped queries (set by EventStore)
    /// When set, all read operations will filter by this profile
    var activeProfile: CDPuppyProfile?

    /// In-memory cache for frequently accessed date ranges
    private var rangeCache: [String: (events: [PuppyEvent], timestamp: Date)] = [:]
    private let rangeCacheLock = NSLock()
    /// PERFORMANCE: Increased from 30s to 120s - cache only invalidated when events change
    private let rangeCacheMaxAge: TimeInterval = 120 // Cache valid for 120 seconds

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Context Access

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    private func newBackgroundContext() -> NSManagedObjectContext {
        persistenceController.newBackgroundContext()
    }

    // MARK: - Reading Events

    /// Read events for a specific date (filtered by active profile if set)
    func readEvents(for date: Date) -> [PuppyEvent] {
        let cdEvents: [CDPuppyEvent]
        if let profile = activeProfile {
            cdEvents = CDPuppyEvent.fetchEvents(for: date, profile: profile, in: viewContext)
        } else {
            cdEvents = CDPuppyEvent.fetchEvents(for: date, in: viewContext)
        }
        return cdEvents.compactMap { $0.toPuppyEvent() }.sorted { $0.time > $1.time }
    }

    /// Read all events from a date range (with caching, filtered by active profile if set)
    func readEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        // Include profile ID in cache key for profile-scoped caching
        let profileSuffix = activeProfile?.id?.uuidString ?? "all"
        let cacheKey = "\(startDate.dateString)_to_\(endDate.dateString)_\(profileSuffix)"

        // Check range cache first
        rangeCacheLock.lock()
        if let cached = rangeCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < rangeCacheMaxAge {
            rangeCacheLock.unlock()
            return cached.events
        }
        rangeCacheLock.unlock()

        // Fetch from Core Data (profile-scoped if profile is set)
        let cdEvents: [CDPuppyEvent]
        if let profile = activeProfile {
            cdEvents = CDPuppyEvent.fetchEvents(from: startDate, to: endDate, profile: profile, in: viewContext)
        } else {
            cdEvents = CDPuppyEvent.fetchEvents(from: startDate, to: endDate, in: viewContext)
        }

        // PERFORMANCE: Photo extraction moved to lazy background processing
        // See processPhotoExtractionAsync() - called once on app launch instead of every fetch

        let events = cdEvents.compactMap { $0.toPuppyEvent() }.sorted { $0.time > $1.time }

        // Update range cache
        rangeCacheLock.lock()
        rangeCache[cacheKey] = (events: events, timestamp: Date())
        rangeCacheLock.unlock()

        return events
    }

    /// Async version of readEvents for date ranges - runs on background thread
    /// PERFORMANCE: Uses cache to avoid redundant Core Data fetches
    func readEventsAsync(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        // Include profile ID in cache key for profile-scoped caching
        let profileSuffix = activeProfile?.id?.uuidString ?? "all"
        let cacheKey = "\(startDate.dateString)_to_\(endDate.dateString)_\(profileSuffix)"

        // Check cache synchronously first
        if let cached = getCachedEvents(for: cacheKey) {
            return cached
        }

        // Fetch from Core Data on background thread
        let context = newBackgroundContext()
        let profileId = activeProfile?.id

        let events = await context.perform {
            let cdEvents: [CDPuppyEvent]
            if let profileId = profileId,
               let profile = CDPuppyProfile.fetch(byId: profileId, in: context) {
                cdEvents = CDPuppyEvent.fetchEvents(from: startDate, to: endDate, profile: profile, in: context)
            } else {
                cdEvents = CDPuppyEvent.fetchEvents(from: startDate, to: endDate, in: context)
            }
            return cdEvents.compactMap { $0.toPuppyEvent() }.sorted { $0.time > $1.time }
        }

        // Update cache synchronously
        setCachedEvents(events, for: cacheKey)

        return events
    }

    /// Get cached events (thread-safe, synchronous)
    private func getCachedEvents(for key: String) -> [PuppyEvent]? {
        rangeCacheLock.lock()
        defer { rangeCacheLock.unlock() }

        guard let cached = rangeCache[key],
              Date().timeIntervalSince(cached.timestamp) < rangeCacheMaxAge else {
            return nil
        }
        return cached.events
    }

    /// Set cached events (thread-safe, synchronous)
    private func setCachedEvents(_ events: [PuppyEvent], for key: String) {
        rangeCacheLock.lock()
        defer { rangeCacheLock.unlock() }
        rangeCache[key] = (events: events, timestamp: Date())
    }

    /// Read all events for the active profile (or all events if no profile set)
    func readAllEvents() -> [PuppyEvent] {
        let cdEvents: [CDPuppyEvent]
        if let profile = activeProfile {
            cdEvents = CDPuppyEvent.fetchAllEvents(for: profile, in: viewContext)
        } else {
            cdEvents = CDPuppyEvent.fetchAllEvents(in: viewContext)
        }
        // PERFORMANCE: Photo extraction moved to lazy background processing
        return cdEvents.compactMap { $0.toPuppyEvent() }
    }

    /// Fetch event by ID
    func fetchEvent(byId id: UUID) -> PuppyEvent? {
        guard let cdEvent = CDPuppyEvent.fetch(byId: id, in: viewContext) else {
            return nil
        }
        // PERFORMANCE: Lazy extract only when viewing this specific event's photo
        // This is acceptable since it's a single event, not a batch
        extractPhotoDataIfNeeded(from: cdEvent)
        return cdEvent.toPuppyEvent()
    }

    /// Get the date of the earliest logged event (for active profile if set)
    func getEarliestEventDate() -> Date? {
        if let profile = activeProfile {
            return CDPuppyEvent.fetchEarliestEvent(for: profile, in: viewContext)?.time
        }
        return CDPuppyEvent.fetchEarliestEvent(in: viewContext)?.time
    }

    /// Fetch events by type (for active profile if set)
    func fetchEvents(ofType type: EventType) -> [PuppyEvent] {
        let cdEvents: [CDPuppyEvent]
        if let profile = activeProfile {
            cdEvents = CDPuppyEvent.fetchEvents(ofType: type, profile: profile, in: viewContext)
        } else {
            cdEvents = CDPuppyEvent.fetchEvents(ofType: type, in: viewContext)
        }
        return cdEvents.compactMap { $0.toPuppyEvent() }
    }

    /// Fetch recent events (last N events, for active profile if set)
    func fetchRecentEvents(limit: Int) -> [PuppyEvent] {
        let cdEvents: [CDPuppyEvent]
        if let profile = activeProfile {
            cdEvents = CDPuppyEvent.fetchRecentEvents(limit: limit, profile: profile, in: viewContext)
        } else {
            cdEvents = CDPuppyEvent.fetchRecentEvents(limit: limit, in: viewContext)
        }
        // PERFORMANCE: Photo extraction moved to lazy background processing
        return cdEvents.compactMap { $0.toPuppyEvent() }
    }

    // MARK: - Photo Data Helpers

    /// Read photo data from local file system
    private func readPhotoData(from relativePath: String) -> Data? {
        let fullURL = documentsURL.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: fullURL.path) else { return nil }
        return try? Data(contentsOf: fullURL)
    }

    /// Write photo data to local file system (background-safe)
    private nonisolated func writePhotoData(_ data: Data, to relativePath: String, documentsURL: URL) {
        let fullURL = documentsURL.appendingPathComponent(relativePath)

        // Ensure directory exists
        let directory = fullURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        try? data.write(to: fullURL)
    }

    /// Check if a photo file exists locally (background-safe)
    private nonisolated func photoExists(at relativePath: String, documentsURL: URL) -> Bool {
        let fullURL = documentsURL.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: fullURL.path)
    }

    /// Extract embedded photo data to local file if needed (for photos synced from other users)
    /// Only used for single-event fetches where the overhead is acceptable
    private func extractPhotoDataIfNeeded(from cdEvent: CDPuppyEvent) {
        guard let photoPath = cdEvent.photo,
              let photoData = cdEvent.photoData,
              !photoExists(at: photoPath, documentsURL: documentsURL) else {
            return
        }

        writePhotoData(photoData, to: photoPath, documentsURL: documentsURL)
        logger.info("Extracted synced photo for event \(cdEvent.id?.uuidString ?? "unknown")")
    }

    /// Process synced photos in background - call once at app launch
    /// This extracts photo data from CloudKit-synced events to local files
    /// PERFORMANCE: Runs on background thread to avoid blocking main thread
    func processPhotoExtractionAsync() {
        let context = newBackgroundContext()
        let docsURL = self.documentsURL

        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            await context.perform {
                // Fetch only events that have photoData (synced from other users)
                let fetchRequest: NSFetchRequest<CDPuppyEvent> = CDPuppyEvent.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "photoData != nil AND photo != nil")

                guard let cdEvents = try? context.fetch(fetchRequest) else { return }

                var extractedCount = 0
                for cdEvent in cdEvents {
                    guard let photoPath = cdEvent.photo,
                          let photoData = cdEvent.photoData,
                          !self.photoExists(at: photoPath, documentsURL: docsURL) else {
                        continue
                    }

                    self.writePhotoData(photoData, to: photoPath, documentsURL: docsURL)
                    extractedCount += 1
                }

                if extractedCount > 0 {
                    self.logger.info("Background extracted \(extractedCount) synced photos")
                }
            }
        }
    }

    // MARK: - Writing Events

    /// Save a single event (links to active profile if set)
    func saveEvent(_ event: PuppyEvent) throws {
        let context = viewContext

        // Check if event already exists
        let cdEvent: CDPuppyEvent
        if let existing = CDPuppyEvent.fetch(byId: event.id, in: context) {
            existing.update(from: event)
            // Ensure profile link is maintained
            if existing.profile == nil, let profile = activeProfile {
                existing.profile = profile
            }
            cdEvent = existing
        } else {
            cdEvent = CDPuppyEvent.create(from: event, in: context)
            // Link to active profile
            if let profile = activeProfile {
                cdEvent.profile = profile

                // IMPORTANT: Assign the event to the same store as the profile
                // This prevents cross-zone references when the profile is shared
                if let store = profile.persistentStore {
                    context.assign(cdEvent, to: store)
                }
            }
        }

        // Embed photo data in Core Data for sharing between users
        // This ensures photos sync through the existing CKShare mechanism
        if let photoPath = event.photo, cdEvent.photoData == nil {
            if let photoData = readPhotoData(from: photoPath) {
                cdEvent.photoData = photoData
                logger.info("Embedded photo data (\(photoData.count) bytes) for event \(event.id)")
            }
        }

        try persistenceController.save()

        // Invalidate cache for this date
        invalidateCache(for: event.time)
    }

    /// Save a single event for a specific date (compatibility API)
    func saveEvent(_ event: PuppyEvent, for date: Date) {
        do {
            try saveEvent(event)
        } catch {
            logger.error("Failed to save event: \(error.localizedDescription)")
        }
    }

    /// Save multiple events (links to active profile if set)
    func saveEvents(_ events: [PuppyEvent]) throws {
        let context = viewContext

        // Get the store from the active profile once (for efficiency)
        let profileStore = activeProfile?.persistentStore

        for event in events {
            if let existing = CDPuppyEvent.fetch(byId: event.id, in: context) {
                existing.update(from: event)
                // Ensure profile link is maintained
                if existing.profile == nil, let profile = activeProfile {
                    existing.profile = profile
                }
            } else {
                let cdEvent = CDPuppyEvent.create(from: event, in: context)
                // Link to active profile
                if let profile = activeProfile {
                    cdEvent.profile = profile

                    // IMPORTANT: Assign the event to the same store as the profile
                    // This prevents cross-zone references when the profile is shared
                    if let store = profileStore {
                        context.assign(cdEvent, to: store)
                    }
                }
            }
        }

        try persistenceController.save()

        // Smart cache invalidation: only invalidate affected date ranges
        if let minDate = events.map(\.time).min(),
           let maxDate = events.map(\.time).max() {
            invalidateCache(from: minDate, to: maxDate)
        }
    }

    /// Save multiple events for a date (compatibility API)
    func saveEvents(_ events: [PuppyEvent], for date: Date) {
        do {
            try saveEvents(events)
        } catch {
            logger.error("Failed to save events: \(error.localizedDescription)")
        }
    }

    // MARK: - Deleting Events

    /// Delete an event by ID
    func deleteEvent(byId id: UUID) throws {
        let context = viewContext

        guard let cdEvent = CDPuppyEvent.fetch(byId: id, in: context) else {
            return // Event doesn't exist, nothing to delete
        }

        let eventDate = cdEvent.time ?? Date()
        context.delete(cdEvent)
        try persistenceController.save()

        // Invalidate cache for this date
        invalidateCache(for: eventDate)
    }

    /// Delete an event
    func deleteEvent(_ event: PuppyEvent) throws {
        try deleteEvent(byId: event.id)
    }

    /// Delete all events (use when switching to shared data)
    func deleteAllEvents() throws {
        let context = viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPuppyEvent.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try context.execute(deleteRequest)
        try context.save()

        invalidateAllCaches()
        logger.info("Deleted all events from Core Data")
    }

    // MARK: - Media File Handling

    /// Delete media files (photos, thumbnails) associated with an event
    /// Note: Media files are still stored in file system, not in Core Data
    func deleteMediaFiles(for event: PuppyEvent) {
        let fileManager = FileManager.default
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

    // MARK: - Cache Management

    /// Invalidate cache for a specific date (smart invalidation)
    /// Only removes cache entries whose date range includes the affected date
    func invalidateCache(for date: Date) {
        rangeCacheLock.lock()
        defer { rangeCacheLock.unlock() }

        let affectedDateString = date.dateString

        // Find and remove only cache entries that contain the affected date
        let keysToRemove = rangeCache.keys.filter { key in
            // Key format: "YYYY-MM-DD_to_YYYY-MM-DD"
            let parts = key.split(separator: "_")
            guard parts.count >= 3,
                  let startDateString = parts.first,
                  let endDateString = parts.last else {
                return true // Remove malformed keys
            }

            // Check if the affected date falls within this range
            let start = String(startDateString)
            let end = String(endDateString)

            // String comparison works for YYYY-MM-DD format
            return affectedDateString >= start && affectedDateString <= end
        }

        for key in keysToRemove {
            rangeCache.removeValue(forKey: key)
        }

        logger.debug("Invalidated \(keysToRemove.count) cache entries for date \(affectedDateString)")
    }

    /// Invalidate cache for a date range (smart invalidation)
    /// Removes cache entries that overlap with the given range
    func invalidateCache(from startDate: Date, to endDate: Date) {
        rangeCacheLock.lock()
        defer { rangeCacheLock.unlock() }

        let rangeStart = startDate.dateString
        let rangeEnd = endDate.dateString

        // Find cache entries that overlap with the given range
        let keysToRemove = rangeCache.keys.filter { key in
            let parts = key.split(separator: "_")
            guard parts.count >= 3,
                  let cacheStartString = parts.first,
                  let cacheEndString = parts.last else {
                return true
            }

            let cacheStart = String(cacheStartString)
            let cacheEnd = String(cacheEndString)

            // Check for overlap: ranges overlap if neither is completely before or after the other
            let noOverlap = cacheEnd < rangeStart || cacheStart > rangeEnd
            return !noOverlap
        }

        for key in keysToRemove {
            rangeCache.removeValue(forKey: key)
        }
    }

    /// Invalidate all caches
    func invalidateAllCaches() {
        rangeCacheLock.lock()
        rangeCache.removeAll()
        rangeCacheLock.unlock()
        logger.debug("Invalidated all caches")
    }

    /// Clean up expired cache entries (call periodically to prevent memory growth)
    func cleanupExpiredCaches() {
        rangeCacheLock.lock()
        defer { rangeCacheLock.unlock() }

        let now = Date()
        let expiredKeys = rangeCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) > rangeCacheMaxAge
        }.keys

        for key in expiredKeys {
            rangeCache.removeValue(forKey: key)
        }

        if !expiredKeys.isEmpty {
            logger.debug("Cleaned up \(expiredKeys.count) expired cache entries")
        }
    }

    // MARK: - Batch Operations

    /// Update events modified after a given date (for sync)
    func fetchEventsModified(after date: Date) -> [PuppyEvent] {
        let cdEvents = CDPuppyEvent.fetchEventsModified(after: date, in: viewContext)
        return cdEvents.compactMap { $0.toPuppyEvent() }
    }

    /// Merge events from CloudKit (used during sync)
    func mergeEvents(_ events: [PuppyEvent]) throws {
        let context = viewContext

        // Get the store from the active profile for new events
        let profileStore = activeProfile?.persistentStore

        for event in events {
            if let existing = CDPuppyEvent.fetch(byId: event.id, in: context) {
                // Only update if incoming event is newer
                if event.modifiedAt > (existing.modifiedAt ?? Date.distantPast) {
                    existing.update(from: event)
                }
            } else {
                let cdEvent = CDPuppyEvent.create(from: event, in: context)
                // Link to active profile and assign to correct store
                if let profile = activeProfile {
                    cdEvent.profile = profile
                    if let store = profileStore {
                        context.assign(cdEvent, to: store)
                    }
                }
            }
        }

        try persistenceController.save()

        // Smart cache invalidation: only invalidate affected date ranges
        if let minDate = events.map(\.time).min(),
           let maxDate = events.map(\.time).max() {
            invalidateCache(from: minDate, to: maxDate)
        }
    }
}
