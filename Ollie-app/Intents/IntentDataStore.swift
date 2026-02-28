//
//  IntentDataStore.swift
//  Ollie-app
//
//  Lightweight shared data access for App Intents via App Group

import Foundation
import OllieShared
import WidgetKit
import os

/// Lightweight data store for App Intents
/// Uses App Group container for shared access with main app
final class IntentDataStore {
    static let shared = IntentDataStore()

    static let suiteName = Constants.appGroupIdentifier
    static let profileKey = "sharedProfile"
    static let dataDirectoryName = "data"

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger.ollie(category: "IntentDataStore")

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

    // MARK: - Profile

    /// Load the shared profile from App Group UserDefaults
    func loadProfile() -> SharedProfile? {
        guard let sharedDefaults = UserDefaults(suiteName: Self.suiteName),
              let data = sharedDefaults.data(forKey: Self.profileKey),
              let profile = try? JSONDecoder().decode(SharedProfile.self, from: data) else {
            return nil
        }
        return profile
    }

    /// Save a shared profile to App Group UserDefaults
    func saveProfile(_ profile: SharedProfile) {
        guard let sharedDefaults = UserDefaults(suiteName: Self.suiteName),
              let data = try? JSONEncoder().encode(profile) else {
            return
        }
        sharedDefaults.set(data, forKey: Self.profileKey)
    }

    // MARK: - Widget Data

    private static let widgetDataKey = "widgetData"

    /// Read widget data from App Group UserDefaults (synced by main app)
    func loadWidgetData() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: Self.suiteName),
              let data = sharedDefaults.data(forKey: Self.widgetDataKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetData.self, from: data)
    }

    /// Update widget data with a newly logged event
    /// This allows status intents to immediately see events logged via Siri/Shortcuts
    func updateWidgetData(with event: PuppyEvent) {
        guard var widgetData = loadWidgetData() else {
            logger.debug("No existing widget data to update")
            return
        }

        // Create updated widget data based on the event type
        switch event.type {
        case .plassen:
            widgetData = WidgetData(
                lastPlasTime: event.time,
                lastPlasLocation: event.location?.rawValue,
                currentStreak: event.location == .buiten ? widgetData.currentStreak + 1 : 0,
                bestStreak: widgetData.bestStreak,
                todayPottyCount: widgetData.todayPottyCount + 1,
                todayOutdoorCount: event.location == .buiten ? widgetData.todayOutdoorCount + 1 : widgetData.todayOutdoorCount,
                isCurrentlySleeping: widgetData.isCurrentlySleeping,
                sleepStartTime: widgetData.sleepStartTime,
                lastWakeTime: widgetData.lastWakeTime,
                lastMealTime: widgetData.lastMealTime,
                nextScheduledMealTime: widgetData.nextScheduledMealTime,
                mealsLoggedToday: widgetData.mealsLoggedToday,
                mealsExpectedToday: widgetData.mealsExpectedToday,
                lastWalkTime: widgetData.lastWalkTime,
                nextScheduledWalkTime: widgetData.nextScheduledWalkTime,
                puppyName: widgetData.puppyName,
                lastUpdated: Date()
            )

        case .slapen:
            widgetData = WidgetData(
                lastPlasTime: widgetData.lastPlasTime,
                lastPlasLocation: widgetData.lastPlasLocation,
                currentStreak: widgetData.currentStreak,
                bestStreak: widgetData.bestStreak,
                todayPottyCount: widgetData.todayPottyCount,
                todayOutdoorCount: widgetData.todayOutdoorCount,
                isCurrentlySleeping: true,
                sleepStartTime: event.time,
                lastWakeTime: widgetData.lastWakeTime,
                lastMealTime: widgetData.lastMealTime,
                nextScheduledMealTime: widgetData.nextScheduledMealTime,
                mealsLoggedToday: widgetData.mealsLoggedToday,
                mealsExpectedToday: widgetData.mealsExpectedToday,
                lastWalkTime: widgetData.lastWalkTime,
                nextScheduledWalkTime: widgetData.nextScheduledWalkTime,
                puppyName: widgetData.puppyName,
                lastUpdated: Date()
            )

        case .ontwaken:
            widgetData = WidgetData(
                lastPlasTime: widgetData.lastPlasTime,
                lastPlasLocation: widgetData.lastPlasLocation,
                currentStreak: widgetData.currentStreak,
                bestStreak: widgetData.bestStreak,
                todayPottyCount: widgetData.todayPottyCount,
                todayOutdoorCount: widgetData.todayOutdoorCount,
                isCurrentlySleeping: false,
                sleepStartTime: nil,
                lastWakeTime: event.time,
                lastMealTime: widgetData.lastMealTime,
                nextScheduledMealTime: widgetData.nextScheduledMealTime,
                mealsLoggedToday: widgetData.mealsLoggedToday,
                mealsExpectedToday: widgetData.mealsExpectedToday,
                lastWalkTime: widgetData.lastWalkTime,
                nextScheduledWalkTime: widgetData.nextScheduledWalkTime,
                puppyName: widgetData.puppyName,
                lastUpdated: Date()
            )

        case .eten:
            widgetData = WidgetData(
                lastPlasTime: widgetData.lastPlasTime,
                lastPlasLocation: widgetData.lastPlasLocation,
                currentStreak: widgetData.currentStreak,
                bestStreak: widgetData.bestStreak,
                todayPottyCount: widgetData.todayPottyCount,
                todayOutdoorCount: widgetData.todayOutdoorCount,
                isCurrentlySleeping: widgetData.isCurrentlySleeping,
                sleepStartTime: widgetData.sleepStartTime,
                lastWakeTime: widgetData.lastWakeTime,
                lastMealTime: event.time,
                nextScheduledMealTime: widgetData.nextScheduledMealTime,
                mealsLoggedToday: widgetData.mealsLoggedToday + 1,
                mealsExpectedToday: widgetData.mealsExpectedToday,
                lastWalkTime: widgetData.lastWalkTime,
                nextScheduledWalkTime: widgetData.nextScheduledWalkTime,
                puppyName: widgetData.puppyName,
                lastUpdated: Date()
            )

        case .uitlaten:
            widgetData = WidgetData(
                lastPlasTime: widgetData.lastPlasTime,
                lastPlasLocation: widgetData.lastPlasLocation,
                currentStreak: widgetData.currentStreak,
                bestStreak: widgetData.bestStreak,
                todayPottyCount: widgetData.todayPottyCount,
                todayOutdoorCount: widgetData.todayOutdoorCount,
                isCurrentlySleeping: widgetData.isCurrentlySleeping,
                sleepStartTime: widgetData.sleepStartTime,
                lastWakeTime: widgetData.lastWakeTime,
                lastMealTime: widgetData.lastMealTime,
                nextScheduledMealTime: widgetData.nextScheduledMealTime,
                mealsLoggedToday: widgetData.mealsLoggedToday,
                mealsExpectedToday: widgetData.mealsExpectedToday,
                lastWalkTime: event.time,
                nextScheduledWalkTime: widgetData.nextScheduledWalkTime,
                puppyName: widgetData.puppyName,
                lastUpdated: Date()
            )

        default:
            // No widget data update needed for other event types
            return
        }

        // Save updated widget data
        saveWidgetData(widgetData)
    }

    /// Save widget data to App Group UserDefaults
    private func saveWidgetData(_ widgetData: WidgetData) {
        guard let sharedDefaults = UserDefaults(suiteName: Self.suiteName) else {
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(widgetData) {
            sharedDefaults.set(data, forKey: Self.widgetDataKey)
        }
    }

    // MARK: - Events

    /// Add an event via Siri/Shortcuts
    /// Events are saved to the App Group container for the main app to pick up
    func addEvent(_ event: PuppyEvent) throws {
        guard let dataDir = dataDirectoryURL else {
            throw IntentDataStoreError.containerNotAvailable
        }

        // Ensure data directory exists
        if !fileManager.fileExists(atPath: dataDir.path) {
            try fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }

        // Get file URL for event's date
        let eventDate = event.time.startOfDay
        guard let fileURL = self.fileURL(for: eventDate) else {
            throw IntentDataStoreError.containerNotAvailable
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

        logger.info("Intent logged event: \(event.type.rawValue)")

        // Update widget data so status intents immediately reflect the new event
        updateWidgetData(with: event)

        // Notify widgets to refresh
        WidgetCenter.shared.reloadAllTimelines()
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

    /// Get the most recent event of a specific type
    func lastEvent(ofType type: EventType) -> PuppyEvent? {
        let today = Date()

        // Check today first
        let todayEvents = readEvents(for: today)
        if let event = todayEvents.ofType(type).first {
            return event
        }

        // Check previous days (up to 7 days back)
        var date = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        for _ in 0..<7 {
            let dayEvents = readEvents(for: date)
            if let event = dayEvents.ofType(type).first {
                return event
            }
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        return nil
    }

    /// Check if puppy is currently sleeping (has a sleep event without matching wake up)
    func isCurrentlySleeping() -> Bool {
        return ongoingSleepEvent() != nil
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

enum IntentDataStoreError: Error, LocalizedError {
    case containerNotAvailable
    case profileNotFound
    case loggingDisabled

    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "App Group container not available"
        case .profileNotFound:
            return "Please set up your puppy profile first"
        case .loggingDisabled:
            return "Your free trial has ended. Please upgrade to continue logging."
        }
    }
}
