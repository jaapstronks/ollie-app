//
//  CoreDataEventStore.swift
//  Ollie-app
//
//  Handles Core Data operations for puppy events
//  Replaces LocalEventFileStore with same public API
//

import Foundation
import CoreData
import OllieShared
import os

/// Handles Core Data operations for puppy events
/// Architecture: Same API as LocalEventFileStore for easy migration
final class CoreDataEventStore: @unchecked Sendable {

    // MARK: - Properties

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "CoreDataEventStore")

    /// In-memory cache for frequently accessed date ranges
    private var rangeCache: [String: (events: [PuppyEvent], timestamp: Date)] = [:]
    private let rangeCacheLock = NSLock()
    private let rangeCacheMaxAge: TimeInterval = 30 // Cache valid for 30 seconds

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

    /// Read events for a specific date
    func readEvents(for date: Date) -> [PuppyEvent] {
        let cdEvents = CDPuppyEvent.fetchEvents(for: date, in: viewContext)
        return cdEvents.compactMap { $0.toPuppyEvent() }.sorted { $0.time > $1.time }
    }

    /// Read all events from a date range (with caching for frequently accessed ranges)
    func readEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        let cacheKey = "\(startDate.dateString)_to_\(endDate.dateString)"

        // Check range cache first
        rangeCacheLock.lock()
        if let cached = rangeCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < rangeCacheMaxAge {
            rangeCacheLock.unlock()
            return cached.events
        }
        rangeCacheLock.unlock()

        // Fetch from Core Data
        let cdEvents = CDPuppyEvent.fetchEvents(from: startDate, to: endDate, in: viewContext)
        let events = cdEvents.compactMap { $0.toPuppyEvent() }.sorted { $0.time > $1.time }

        // Update range cache
        rangeCacheLock.lock()
        rangeCache[cacheKey] = (events: events, timestamp: Date())
        rangeCacheLock.unlock()

        return events
    }

    /// Async version of readEvents for date ranges - runs on background thread
    func readEventsAsync(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        let context = newBackgroundContext()
        return await context.perform {
            let cdEvents = CDPuppyEvent.fetchEvents(from: startDate, to: endDate, in: context)
            return cdEvents.compactMap { $0.toPuppyEvent() }.sorted { $0.time > $1.time }
        }
    }

    /// Read all events (for migration/export)
    func readAllEvents() -> [PuppyEvent] {
        let cdEvents = CDPuppyEvent.fetchAllEvents(in: viewContext)
        return cdEvents.compactMap { $0.toPuppyEvent() }
    }

    /// Fetch event by ID
    func fetchEvent(byId id: UUID) -> PuppyEvent? {
        guard let cdEvent = CDPuppyEvent.fetch(byId: id, in: viewContext) else {
            return nil
        }
        return cdEvent.toPuppyEvent()
    }

    /// Fetch events by type
    func fetchEvents(ofType type: EventType) -> [PuppyEvent] {
        let cdEvents = CDPuppyEvent.fetchEvents(ofType: type, in: viewContext)
        return cdEvents.compactMap { $0.toPuppyEvent() }
    }

    /// Fetch recent events (last N events)
    func fetchRecentEvents(limit: Int) -> [PuppyEvent] {
        let cdEvents = CDPuppyEvent.fetchRecentEvents(limit: limit, in: viewContext)
        return cdEvents.compactMap { $0.toPuppyEvent() }
    }

    // MARK: - Writing Events

    /// Save a single event
    func saveEvent(_ event: PuppyEvent) throws {
        let context = viewContext

        // Check if event already exists
        if let existing = CDPuppyEvent.fetch(byId: event.id, in: context) {
            existing.update(from: event)
        } else {
            _ = CDPuppyEvent.create(from: event, in: context)
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

    /// Save multiple events
    func saveEvents(_ events: [PuppyEvent]) throws {
        let context = viewContext

        for event in events {
            if let existing = CDPuppyEvent.fetch(byId: event.id, in: context) {
                existing.update(from: event)
            } else {
                _ = CDPuppyEvent.create(from: event, in: context)
            }
        }

        try persistenceController.save()

        // Invalidate all caches
        invalidateAllCaches()
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

    /// Invalidate cache for a specific date
    func invalidateCache(for date: Date) {
        rangeCacheLock.lock()
        // Remove all range caches that might include this date
        rangeCache.removeAll()
        rangeCacheLock.unlock()
    }

    /// Invalidate all caches
    func invalidateAllCaches() {
        rangeCacheLock.lock()
        rangeCache.removeAll()
        rangeCacheLock.unlock()
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

        for event in events {
            if let existing = CDPuppyEvent.fetch(byId: event.id, in: context) {
                // Only update if incoming event is newer
                if event.modifiedAt > (existing.modifiedAt ?? Date.distantPast) {
                    existing.update(from: event)
                }
            } else {
                _ = CDPuppyEvent.create(from: event, in: context)
            }
        }

        try persistenceController.save()
        invalidateAllCaches()
    }
}
