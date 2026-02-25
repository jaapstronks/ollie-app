//
//  WatchIntentDataStore.swift
//  OllieWatch
//
//  Watch-specific data store for writing events to App Group
//  Similar to IntentDataStore but without WidgetKit dependency

import Foundation
import OllieShared
import os

/// Watch-specific data store for event logging
/// Writes to App Group container for main app to pick up
final class WatchIntentDataStore {
    static let shared = WatchIntentDataStore()

    static let suiteName = Constants.appGroupIdentifier
    static let dataDirectoryName = "data"

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger.ollieWatch(category: "WatchIntentDataStore")

    private init() {
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
    }

    // MARK: - App Group Container

    private var containerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.suiteName)
    }

    private var dataDirectoryURL: URL? {
        containerURL?.appendingPathComponent(Self.dataDirectoryName, isDirectory: true)
    }

    private func fileURL(for date: Date) -> URL? {
        dataDirectoryURL?.appendingPathComponent("\(date.dateString).jsonl")
    }

    // MARK: - Events

    /// Add an event to the App Group container
    func addEvent(_ event: PuppyEvent) throws {
        guard let dataDir = dataDirectoryURL else {
            throw WatchDataStoreError.containerNotAvailable
        }

        // Ensure data directory exists
        if !fileManager.fileExists(atPath: dataDir.path) {
            try fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }

        // Get file URL for event's date
        let eventDate = event.time.startOfDay
        guard let fileURL = self.fileURL(for: eventDate) else {
            throw WatchDataStoreError.containerNotAvailable
        }

        // Read existing events
        var existingEvents = readEvents(for: eventDate)

        // Check for duplicate ID
        if existingEvents.contains(where: { $0.id == event.id }) {
            var newEvent = event
            newEvent.id = UUID()
            existingEvents.append(newEvent)
        } else {
            existingEvents.append(event)
        }

        // Sort and write
        existingEvents.sort { $0.time > $1.time }
        let lines = existingEvents.compactMap { event -> String? in
            guard let data = try? encoder.encode(event) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        let content = lines.joined(separator: "\n")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        logger.info("Watch logged event: \(event.type.rawValue)")

        // Note: No WidgetCenter refresh here - widgets are iOS only
    }

    /// Read events for a specific date from App Group container
    func readEvents(for date: Date) -> [PuppyEvent] {
        guard let fileURL = self.fileURL(for: date),
              fileManager.fileExists(atPath: fileURL.path),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        return lines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(PuppyEvent.self, from: data)
        }.sorted { $0.time > $1.time }
    }

    /// Get the ongoing sleep event (if puppy is currently sleeping)
    func ongoingSleepEvent() -> PuppyEvent? {
        let today = Date()
        let todayEvents = readEvents(for: today)

        // Get all sleep/wake events sorted by time (most recent first)
        let sleepWakeEvents = todayEvents.ofTypes([.slapen, .ontwaken])

        // If the most recent sleep/wake event is a sleep, return it
        if let mostRecent = sleepWakeEvents.first, mostRecent.type == .slapen {
            return mostRecent
        }

        // Check yesterday too (in case puppy went to sleep last night)
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
            let yesterdayEvents = readEvents(for: yesterday)
            let yesterdaySleepWake = yesterdayEvents.ofTypes([.slapen, .ontwaken])
            if let mostRecent = yesterdaySleepWake.first, mostRecent.type == .slapen {
                return mostRecent
            }
        }

        return nil
    }
}

// MARK: - Errors

enum WatchDataStoreError: Error, LocalizedError {
    case containerNotAvailable

    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "App Group container not available"
        }
    }
}
