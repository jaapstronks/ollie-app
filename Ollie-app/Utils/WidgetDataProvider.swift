//
//  WidgetDataProvider.swift
//  Ollie-app
//
//  Shared data layer for widget communication via App Groups

import Foundation
import OllieShared
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
    let lastWakeTime: Date?    // When puppy last woke up (for awake timer)

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

    // MARK: - Backwards-compatible decoding
    // Handles cached data that may be missing newer fields like lastWakeTime
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastPlasTime = try container.decodeIfPresent(Date.self, forKey: .lastPlasTime)
        lastPlasLocation = try container.decodeIfPresent(String.self, forKey: .lastPlasLocation)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        bestStreak = try container.decode(Int.self, forKey: .bestStreak)
        todayPottyCount = try container.decode(Int.self, forKey: .todayPottyCount)
        todayOutdoorCount = try container.decode(Int.self, forKey: .todayOutdoorCount)
        isCurrentlySleeping = try container.decode(Bool.self, forKey: .isCurrentlySleeping)
        sleepStartTime = try container.decodeIfPresent(Date.self, forKey: .sleepStartTime)
        lastWakeTime = try container.decodeIfPresent(Date.self, forKey: .lastWakeTime)
        lastMealTime = try container.decodeIfPresent(Date.self, forKey: .lastMealTime)
        nextScheduledMealTime = try container.decodeIfPresent(Date.self, forKey: .nextScheduledMealTime)
        mealsLoggedToday = try container.decode(Int.self, forKey: .mealsLoggedToday)
        mealsExpectedToday = try container.decode(Int.self, forKey: .mealsExpectedToday)
        lastWalkTime = try container.decodeIfPresent(Date.self, forKey: .lastWalkTime)
        nextScheduledWalkTime = try container.decodeIfPresent(Date.self, forKey: .nextScheduledWalkTime)
        puppyName = try container.decode(String.self, forKey: .puppyName)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }

    // Memberwise initializer for creating new instances
    init(
        lastPlasTime: Date?,
        lastPlasLocation: String?,
        currentStreak: Int,
        bestStreak: Int,
        todayPottyCount: Int,
        todayOutdoorCount: Int,
        isCurrentlySleeping: Bool,
        sleepStartTime: Date?,
        lastWakeTime: Date?,
        lastMealTime: Date?,
        nextScheduledMealTime: Date?,
        mealsLoggedToday: Int,
        mealsExpectedToday: Int,
        lastWalkTime: Date?,
        nextScheduledWalkTime: Date?,
        puppyName: String,
        lastUpdated: Date
    ) {
        self.lastPlasTime = lastPlasTime
        self.lastPlasLocation = lastPlasLocation
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.todayPottyCount = todayPottyCount
        self.todayOutdoorCount = todayOutdoorCount
        self.isCurrentlySleeping = isCurrentlySleeping
        self.sleepStartTime = sleepStartTime
        self.lastWakeTime = lastWakeTime
        self.lastMealTime = lastMealTime
        self.nextScheduledMealTime = nextScheduledMealTime
        self.mealsLoggedToday = mealsLoggedToday
        self.mealsExpectedToday = mealsExpectedToday
        self.lastWalkTime = lastWalkTime
        self.nextScheduledWalkTime = nextScheduledWalkTime
        self.puppyName = puppyName
        self.lastUpdated = lastUpdated
    }

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
            lastWakeTime: Date().addingTimeInterval(-90 * 60),
            lastMealTime: Date().addingTimeInterval(-3 * 60 * 60),
            nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
            mealsLoggedToday: 2,
            mealsExpectedToday: 3,
            lastWalkTime: Date().addingTimeInterval(-2 * 60 * 60),
            nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
            puppyName: "--",
            lastUpdated: Date()
        )
    }
}

/// Provides data to widgets via shared App Group UserDefaults
class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    static let suiteName = Constants.appGroupIdentifier
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
        var lastWakeTime: Date? = nil
        if case .sleeping(let since, _) = sleepState {
            sleepStartTime = since
        } else if case .awake(let since, _) = sleepState {
            lastWakeTime = since
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
            lastWakeTime: lastWakeTime,
            lastMealTime: lastMeal?.time,
            nextScheduledMealTime: nextMealTime,
            mealsLoggedToday: mealEvents.count,
            mealsExpectedToday: mealsExpected,
            lastWalkTime: lastWalk?.time,
            nextScheduledWalkTime: nextWalkTime,
            puppyName: profile?.name ?? "--",
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
        let currentMinutes = date.hour * 60 + date.minute

        // Parse all times and find the next one after current time
        var nextTime: Date? = nil
        var smallestFutureMinutes = Int.max

        for timeString in times {
            guard let (hour, minute) = timeString.parseTimeComponents() else { continue }

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

    // MARK: - Profile-Only Update

    /// Update just the puppy name in widget data
    /// Call this when profile is saved but no events have changed
    func updateProfileName(_ name: String) {
        // Read existing widget data and update name
        if let existing = read() {
            // Create new data with updated name
            let updated = WidgetData(
                lastPlasTime: existing.lastPlasTime,
                lastPlasLocation: existing.lastPlasLocation,
                currentStreak: existing.currentStreak,
                bestStreak: existing.bestStreak,
                todayPottyCount: existing.todayPottyCount,
                todayOutdoorCount: existing.todayOutdoorCount,
                isCurrentlySleeping: existing.isCurrentlySleeping,
                sleepStartTime: existing.sleepStartTime,
                lastWakeTime: existing.lastWakeTime,
                lastMealTime: existing.lastMealTime,
                nextScheduledMealTime: existing.nextScheduledMealTime,
                mealsLoggedToday: existing.mealsLoggedToday,
                mealsExpectedToday: existing.mealsExpectedToday,
                lastWalkTime: existing.lastWalkTime,
                nextScheduledWalkTime: existing.nextScheduledWalkTime,
                puppyName: name,
                lastUpdated: Date()
            )
            write(updated)
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            // No existing data - create minimal data with name
            let minimal = WidgetData(
                lastPlasTime: nil,
                lastPlasLocation: nil,
                currentStreak: 0,
                bestStreak: 0,
                todayPottyCount: 0,
                todayOutdoorCount: 0,
                isCurrentlySleeping: false,
                sleepStartTime: nil,
                lastWakeTime: nil,
                lastMealTime: nil,
                nextScheduledMealTime: nil,
                mealsLoggedToday: 0,
                mealsExpectedToday: 3,
                lastWalkTime: nil,
                nextScheduledWalkTime: nil,
                puppyName: name,
                lastUpdated: Date()
            )
            write(minimal)
            WidgetCenter.shared.reloadAllTimelines()
        }
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

