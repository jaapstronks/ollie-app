//
//  WatchDataProvider.swift
//  OllieWatch
//
//  Provides read access to shared data from App Group container

import Foundation
import Combine
import OllieShared
import os

/// Provides read access to shared data from App Group container
@MainActor
final class WatchDataProvider: ObservableObject {
    static let shared = WatchDataProvider()

    @Published var lastPeeTime: Date?
    @Published var lastPoopTime: Date?
    @Published var currentStreak: Int = 0
    @Published var isSleeping: Bool = false
    @Published var sleepStartTime: Date?
    @Published var puppyName: String = "Puppy"
    @Published var canLogEvents: Bool = true

    private let suiteName = Constants.appGroupIdentifier
    private let dataDirectoryName = "data"
    private let profileKey = "sharedProfile"
    private let fileManager = FileManager.default
    private let logger = Logger.ollieWatch(category: "WatchDataProvider")
    private let decoder: JSONDecoder

    private init() {
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

    // MARK: - Container Access

    private var containerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    private var dataDirectoryURL: URL? {
        containerURL?.appendingPathComponent(dataDirectoryName, isDirectory: true)
    }

    private func fileURL(for date: Date) -> URL? {
        dataDirectoryURL?.appendingPathComponent("\(date.dateString).jsonl")
    }

    // MARK: - Public Methods

    /// Refresh all data from App Group
    func refresh() {
        loadProfile()
        loadRecentEvents()
    }

    /// Format time since last pee for display
    func timeSinceLastPee() -> String {
        guard let lastPee = lastPeeTime else {
            return "--"
        }
        return formatTimeSince(lastPee)
    }

    /// Get urgency color based on time since last pee
    func urgencyLevel() -> UrgencyLevel {
        guard let lastPee = lastPeeTime else {
            return .unknown
        }

        let minutes = Int(Date().timeIntervalSince(lastPee) / 60)

        if minutes < 60 {
            return .good
        } else if minutes < 120 {
            return .attention
        } else if minutes < 180 {
            return .warning
        } else {
            return .urgent
        }
    }

    // MARK: - Private Methods

    private func loadProfile() {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName),
              let data = sharedDefaults.data(forKey: profileKey) else {
            logger.info("No shared profile found")
            return
        }

        do {
            let profile = try JSONDecoder().decode(SharedProfile.self, from: data)
            puppyName = profile.name
            canLogEvents = profile.canLogEvents
        } catch {
            logger.error("Failed to decode profile: \(error.localizedDescription)")
        }
    }

    private func loadRecentEvents() {
        let today = Date()
        var allEvents: [PuppyEvent] = []

        // Load today's events
        allEvents.append(contentsOf: readEvents(for: today))

        // Load up to 7 days back for streak calculation
        for dayOffset in 1...7 {
            if let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) {
                allEvents.append(contentsOf: readEvents(for: date))
            }
        }

        // Update published properties
        updateLastPeeTime(from: allEvents)
        updateLastPoopTime(from: allEvents)
        updateStreak(from: allEvents)
        updateSleepState(from: allEvents)
    }

    private func readEvents(for date: Date) -> [PuppyEvent] {
        guard let fileURL = self.fileURL(for: date),
              fileManager.fileExists(atPath: fileURL.path),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        return lines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(PuppyEvent.self, from: data)
        }
    }

    private func updateLastPeeTime(from events: [PuppyEvent]) {
        lastPeeTime = events
            .pee()
            .reverseChronological()
            .first?
            .time
    }

    private func updateLastPoopTime(from events: [PuppyEvent]) {
        lastPoopTime = events
            .poop()
            .reverseChronological()
            .first?
            .time
    }

    private func updateStreak(from events: [PuppyEvent]) {
        currentStreak = StreakCalculations.calculateCurrentStreak(events: events)
    }

    private func updateSleepState(from events: [PuppyEvent]) {
        let sleepState = SleepCalculations.currentSleepState(events: events)

        switch sleepState {
        case .sleeping(let since, _):
            isSleeping = true
            sleepStartTime = since
        case .awake, .unknown:
            isSleeping = false
            sleepStartTime = nil
        }
    }

    private func formatTimeSince(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)

        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)u"
            }
            return "\(hours)u \(mins)m"
        }
    }
}

// MARK: - Urgency Level

enum UrgencyLevel {
    case good
    case attention
    case warning
    case urgent
    case unknown
}

// MARK: - Shared Profile (matches iOS app)

struct SharedProfile: Codable {
    let name: String
    let isPremiumUnlocked: Bool
    let freeDaysRemaining: Int

    var canLogEvents: Bool {
        isPremiumUnlocked || freeDaysRemaining > 0
    }
}
