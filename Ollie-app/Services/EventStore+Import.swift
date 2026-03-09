//
//  EventStore+Import.swift
//  Ollie-app
//
//  App Group JSONL import for events logged via Siri/Shortcuts.
//

import Foundation
import OtisShared
import os

extension EventStore {

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
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    logger.warning("Could not delete imported intent file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
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
    func importEventsFromJSONL(at url: URL) -> Int {
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
}
