//
//  WidgetDataProvider.swift
//  Ollie-app
//
//  Shared data layer for widget communication via App Groups

import Foundation
import WidgetKit

/// Data structure for widget display
struct WidgetData: Codable {
    // MARK: - Potty Data
    let lastPlasTime: Date?
    let lastPlasLocation: String?  // "buiten" or "binnen"
    let currentStreak: Int
    let bestStreak: Int
    let todayPottyCount: Int
    let todayOutdoorCount: Int

    // MARK: - Sleep Data
    let isCurrentlySleeping: Bool
    let sleepStartTime: Date?  // When current sleep started (if sleeping)

    // MARK: - Meal Data
    let lastMealTime: Date?
    let nextScheduledMealTime: Date?  // Next meal target time today
    let mealsLoggedToday: Int
    let mealsExpectedToday: Int

    // MARK: - Walk Data
    let lastWalkTime: Date?
    let nextScheduledWalkTime: Date?  // Next walk target time today

    // MARK: - Meta
    let puppyName: String
    let lastUpdated: Date

    static var placeholder: WidgetData {
        WidgetData(
            lastPlasTime: Date().addingTimeInterval(-45 * 60),
            lastPlasLocation: "buiten",
            currentStreak: 3,
            bestStreak: 12,
            todayPottyCount: 4,
            todayOutdoorCount: 3,
            isCurrentlySleeping: false,
            sleepStartTime: nil,
            lastMealTime: Date().addingTimeInterval(-3 * 60 * 60),
            nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
            mealsLoggedToday: 2,
            mealsExpectedToday: 3,
            lastWalkTime: Date().addingTimeInterval(-2 * 60 * 60),
            nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
            puppyName: "Puppy",
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
        let now = Date()
        let today = now.startOfDay
        let todayEvents = events.onDate(today)

        // MARK: Potty Data
        let pottyEvents = todayEvents.pee()
        let outdoorPotty = pottyEvents.outdoor()
        let lastPlas = allEvents.pee().reverseChronological().first
        let streakInfo = StreakCalculations.getStreakInfo(events: allEvents)

        // MARK: Sleep Data
        let sleepState = SleepCalculations.currentSleepState(events: allEvents)
        let isCurrentlySleeping = sleepState.isSleeping
        var sleepStartTime: Date? = nil
        if case .sleeping(let since, _) = sleepState {
            sleepStartTime = since
        }

        // MARK: Meal Data
        let mealEvents = todayEvents.filter { $0.type == .eten }
        let lastMeal = allEvents.filter { $0.type == .eten }.reverseChronological().first
        let mealsExpected = profile?.mealSchedule.mealsPerDay ?? 3
        let nextMealTime = Self.nextScheduledTime(
            from: profile?.mealSchedule.portions.compactMap { $0.targetTime } ?? [],
            after: now
        )

        // MARK: Walk Data
        let lastWalk = allEvents.filter { $0.type == .uitlaten }.reverseChronological().first
        let nextWalkTime = Self.nextScheduledTime(
            from: profile?.walkSchedule.walks.map { $0.targetTime } ?? [],
            after: now
        )

        let widgetData = WidgetData(
            lastPlasTime: lastPlas?.time,
            lastPlasLocation: lastPlas?.location?.rawValue,
            currentStreak: streakInfo.currentStreak,
            bestStreak: streakInfo.bestStreak,
            todayPottyCount: pottyEvents.count,
            todayOutdoorCount: outdoorPotty.count,
            isCurrentlySleeping: isCurrentlySleeping,
            sleepStartTime: sleepStartTime,
            lastMealTime: lastMeal?.time,
            nextScheduledMealTime: nextMealTime,
            mealsLoggedToday: mealEvents.count,
            mealsExpectedToday: mealsExpected,
            lastWalkTime: lastWalk?.time,
            nextScheduledWalkTime: nextWalkTime,
            puppyName: profile?.name ?? "Puppy",
            lastUpdated: now
        )

        write(widgetData)

        // Notify widgets to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Schedule Helpers

    /// Find the next scheduled time from a list of "HH:mm" strings
    private static func nextScheduledTime(from times: [String], after date: Date) -> Date? {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        let currentMinutes = currentHour * 60 + currentMinute

        // Parse all times and find the next one after current time
        var nextTime: Date? = nil
        var smallestFutureMinutes = Int.max

        for timeString in times {
            let parts = timeString.split(separator: ":")
            guard parts.count >= 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]) else { continue }

            let scheduleMinutes = hour * 60 + minute

            // If this time is in the future today
            if scheduleMinutes > currentMinutes && scheduleMinutes < smallestFutureMinutes {
                smallestFutureMinutes = scheduleMinutes
                nextTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
            }
        }

        return nextTime
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

