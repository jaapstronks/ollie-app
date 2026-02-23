//
//  WidgetDataProvider.swift
//  Ollie-app
//
//  Shared data layer for widget communication via App Groups

import Foundation
import WidgetKit

/// Data structure for widget display
struct WidgetData: Codable {
    let lastPlasTime: Date?
    let lastPlasLocation: String?  // "buiten" or "binnen"
    let currentStreak: Int
    let bestStreak: Int
    let puppyName: String
    let todayPottyCount: Int
    let todayOutdoorCount: Int
    let lastUpdated: Date

    static var placeholder: WidgetData {
        WidgetData(
            lastPlasTime: nil,
            lastPlasLocation: nil,
            currentStreak: 0,
            bestStreak: 0,
            puppyName: "Puppy",
            todayPottyCount: 0,
            todayOutdoorCount: 0,
            lastUpdated: Date()
        )
    }
}

/// Provides data to widgets via shared App Group UserDefaults
class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    static let suiteName = "group.jaapstronks.Ollie"
    static let dataKey = "widgetData"

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public Methods

    /// Update widget data from current events and profile
    /// Call this after any event changes (add/delete/update)
    func update(events: [PuppyEvent], allEvents: [PuppyEvent], profile: PuppyProfile?) {
        let today = Date().startOfDay
        let todayEvents = events.filter { Calendar.current.isDate($0.time, inSameDayAs: today) }

        // Get potty events
        let pottyEvents = todayEvents.filter { $0.type == .plassen }
        let outdoorPotty = pottyEvents.filter { $0.location == .buiten }

        // Find last plas event (across all loaded events, not just today)
        let lastPlas = allEvents
            .filter { $0.type == .plassen }
            .sorted { $0.time > $1.time }
            .first

        // Calculate streaks from all events
        let streakInfo = StreakCalculations.getStreakInfo(events: allEvents)

        let widgetData = WidgetData(
            lastPlasTime: lastPlas?.time,
            lastPlasLocation: lastPlas?.location?.rawValue,
            currentStreak: streakInfo.currentStreak,
            bestStreak: streakInfo.bestStreak,
            puppyName: profile?.name ?? "Puppy",
            todayPottyCount: pottyEvents.count,
            todayOutdoorCount: outdoorPotty.count,
            lastUpdated: Date()
        )

        write(widgetData)

        // Notify widgets to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Read widget data (used by widget extension)
    func read() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: Self.suiteName),
              let data = sharedDefaults.data(forKey: Self.dataKey),
              let widgetData = try? decoder.decode(WidgetData.self, from: data) else {
            return nil
        }
        return widgetData
    }

    // MARK: - Private Methods

    private func write(_ widgetData: WidgetData) {
        guard let sharedDefaults = UserDefaults(suiteName: Self.suiteName),
              let data = try? encoder.encode(widgetData) else {
            return
        }
        sharedDefaults.set(data, forKey: Self.dataKey)
    }
}

