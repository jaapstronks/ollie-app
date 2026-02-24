//
//  LocalEventFileStore.swift
//  Ollie-app
//
//  Handles local file I/O for puppy events using JSONL format
//  Extracted from EventStore to separate file operations from sync coordination
//

import Foundation
import OllieShared
import os

/// Handles local file I/O for puppy events using JSONL format
/// Architecture: Synchronous operations for instant local persistence
@MainActor
final class LocalEventFileStore {
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger.ollie(category: "LocalEventFileStore")

    /// Event cache for reducing disk I/O
    private let eventCache = EventCache()

    /// App Group migration helper
    private lazy var migrator: AppGroupMigrator = {
        AppGroupMigrator(decoder: decoder, encoder: encoder)
    }()

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

        // Migrate local data to App Group if needed
        migrator.migrateIfNeeded()
    }

    // MARK: - Public Properties

    var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Primary data directory - uses App Group container via migrator
    var dataDirectoryURL: URL? {
        migrator.dataDirectoryURL
    }

    /// Check if data directory exists
    func dataDirectoryExists() -> Bool {
        guard let url = dataDirectoryURL else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Reading

    /// Read events for a specific date from disk (with caching)
    func readEvents(for date: Date) -> [PuppyEvent] {
        // Check cache first (fast path)
        if let cached = eventCache.get(for: date) {
            return cached
        }

        // Read from disk
        guard let url = fileURL(for: date),
              fileManager.fileExists(atPath: url.path),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            // Cache empty result to avoid repeated disk checks
            eventCache.set([], for: date)
            return []
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        let events: [PuppyEvent] = lines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(PuppyEvent.self, from: data)
        }.sorted { $0.time > $1.time }

        // Cache result
        eventCache.set(events, for: date)

        return events
    }

    /// Read all events from a date range
    func readEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        var allEvents: [PuppyEvent] = []
        var current = startDate.startOfDay

        while current <= endDate {
            allEvents.append(contentsOf: readEvents(for: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }

        return allEvents.sorted { $0.time > $1.time }
    }

    /// Read all JSONL files and return all events (for migration)
    func readAllEvents() -> [PuppyEvent] {
        var allLocalEvents: [PuppyEvent] = []

        guard let url = dataDirectoryURL,
              let files = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return []
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

        return allLocalEvents
    }

    // MARK: - Writing

    /// Save a single event to the appropriate date file
    func saveEvent(_ event: PuppyEvent, for date: Date) {
        ensureDataDirectoryExists()

        // Read existing events for this date
        var existingEvents = readEvents(for: date)

        // Replace if event with same ID exists, otherwise append
        if let index = existingEvents.firstIndex(where: { $0.id == event.id }) {
            existingEvents[index] = event
        } else {
            existingEvents.append(event)
        }

        // Sort and save
        existingEvents.sort { $0.time > $1.time }
        saveEvents(existingEvents, for: date)
    }

    /// Save multiple events for a date
    func saveEvents(_ events: [PuppyEvent], for date: Date) {
        ensureDataDirectoryExists()

        let eventsForDate = events.filter { Calendar.current.isDate($0.time, inSameDayAs: date) }
        let lines = eventsForDate.compactMap { event -> String? in
            guard let data = try? encoder.encode(event) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        let content = lines.joined(separator: "\n")
        guard let url = fileURL(for: date) else { return }

        try? content.write(to: url, atomically: true, encoding: .utf8)

        // Invalidate cache for this date since we just wrote new data
        eventCache.invalidate(for: date)
    }

    // MARK: - Deleting

    /// Delete media files (photos, thumbnails) associated with an event
    func deleteMediaFiles(for event: PuppyEvent) {
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
        eventCache.invalidate(for: date)
    }

    // MARK: - Private Helpers

    func fileURL(for date: Date) -> URL? {
        dataDirectoryURL?.appendingPathComponent("\(date.dateString).jsonl")
    }

    private func ensureDataDirectoryExists() {
        guard let url = dataDirectoryURL else { return }
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
