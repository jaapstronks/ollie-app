//
//  EventStore.swift
//  Ollie-app
//

import Foundation
import Combine

/// Manages reading and writing puppy events to JSONL files
@MainActor
class EventStore: ObservableObject {
    @Published private(set) var events: [PuppyEvent] = []
    @Published private(set) var currentDate: Date = Date()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

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

        loadEvents(for: currentDate)
    }

    // MARK: - Public Methods

    /// Load events for a specific date
    func loadEvents(for date: Date) {
        currentDate = date
        events = readEvents(for: date)
    }

    /// Add a new event
    func addEvent(_ event: PuppyEvent) {
        var newEvent = event
        if newEvent.id == UUID() {
            newEvent.id = UUID()
        }

        // Add to in-memory list
        events.append(newEvent)
        events.sort { $0.time < $1.time }

        // Persist to file
        saveEvents(for: currentDate)
    }

    /// Delete an event
    func deleteEvent(_ event: PuppyEvent) {
        events.removeAll { $0.id == event.id }
        saveEvents(for: currentDate)
    }

    /// Get all events for a date range
    func getEvents(from startDate: Date, to endDate: Date) -> [PuppyEvent] {
        var allEvents: [PuppyEvent] = []
        var current = startDate.startOfDay

        while current <= endDate {
            allEvents.append(contentsOf: readEvents(for: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }

        return allEvents.sorted { $0.time < $1.time }
    }

    /// Get the most recent event of a specific type
    func lastEvent(ofType type: EventType) -> PuppyEvent? {
        // Check today first
        if let event = events.filter({ $0.type == type }).last {
            return event
        }

        // Check previous days (up to 7 days back)
        var date = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        for _ in 0..<7 {
            let dayEvents = readEvents(for: date)
            if let event = dayEvents.filter({ $0.type == type }).last {
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

    // MARK: - Private Methods

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
        }
    }

    private func saveEvents(for date: Date) {
        ensureDataDirectoryExists()

        let eventsForDate = events.filter { Calendar.current.isDate($0.time, inSameDayAs: date) }
        let lines = eventsForDate.compactMap { event -> String? in
            guard let data = try? encoder.encode(event) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        let content = lines.joined(separator: "\n")
        let url = fileURL(for: date)

        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
