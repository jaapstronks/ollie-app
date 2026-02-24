//
//  WatchWidgetDataReader.swift
//  OllieWatchWidgets
//
//  Reads widget data from App Group shared container for watch complications

import Foundation

/// Widget data shared between app and widgets via App Groups
/// Mirrors the iOS WidgetData structure
struct WatchWidgetData: Codable {
    // MARK: - Potty Data
    let lastPlasTime: Date?
    let lastPlasLocation: String?  // "buiten" or "binnen"
    let currentStreak: Int
    let bestStreak: Int
    let todayPottyCount: Int
    let todayOutdoorCount: Int

    // MARK: - Sleep Data
    let isCurrentlySleeping: Bool
    let sleepStartTime: Date?
    let lastWakeTime: Date?  // When puppy last woke up (for awake timer)

    // MARK: - Meal Data
    let lastMealTime: Date?
    let nextScheduledMealTime: Date?
    let mealsLoggedToday: Int
    let mealsExpectedToday: Int

    // MARK: - Walk Data
    let lastWalkTime: Date?
    let nextScheduledWalkTime: Date?

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

    static var placeholder: WatchWidgetData {
        WatchWidgetData(
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
            puppyName: "Puppy",
            lastUpdated: Date()
        )
    }
}

/// Reads widget data from shared App Group UserDefaults
struct WatchWidgetDataReader {
    // Matches Constants.appGroupIdentifier from OllieShared
    static let suiteName = "group.jaapstronks.Ollie"
    static let dataKey = "widgetData"

    static func read() -> WatchWidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName),
              let data = sharedDefaults.data(forKey: dataKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(WatchWidgetData.self, from: data)
    }
}
