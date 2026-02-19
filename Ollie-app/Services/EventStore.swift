//
//  EventStore.swift
//  Ollie-app
//

import Foundation

@MainActor
final class EventStore {
    static let shared = EventStore()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var dataDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("data", isDirectory: true)
    }

    private init() {
        // Ensure data directory exists
        try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }

    // Get file URL for a specific date
    private func fileURL(for date: Date) -> URL {
        let dateString = DateHelpers.formatDateForFile(date)
        return dataDirectory.appendingPathComponent("\(dateString).jsonl")
    }

    // Load events for a specific date
    func loadEvents(for date: Date) -> [PuppyEvent] {
        let url = fileURL(for: date)

        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        guard let data = fileManager.contents(atPath: url.path),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var events: [PuppyEvent] = []

        for line in lines {
            guard let lineData = line.data(using: .utf8) else { continue }
            if let event = try? decoder.decode(PuppyEvent.self, from: lineData) {
                events.append(event)
            }
        }

        // Sort by time
        return events.sorted { $0.time < $1.time }
    }

    // Save an event (append to file)
    func saveEvent(_ event: PuppyEvent) throws {
        let url = fileURL(for: event.time)

        // Encode event to JSON line
        let jsonData = try encoder.encode(event)
        guard var jsonString = String(data: jsonData, encoding: .utf8) else {
            throw EventStoreError.encodingFailed
        }
        jsonString += "\n"

        // Append to file
        if fileManager.fileExists(atPath: url.path) {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            if let data = jsonString.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            try jsonString.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // Get all dates that have events (for day navigation)
    func availableDates() -> [Date] {
        guard let files = try? fileManager.contentsOfDirectory(at: dataDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current

        return files.compactMap { url -> Date? in
            let filename = url.deletingPathExtension().lastPathComponent
            return formatter.date(from: filename)
        }.sorted()
    }
}

enum EventStoreError: Error {
    case encodingFailed
    case writeFailed
}
