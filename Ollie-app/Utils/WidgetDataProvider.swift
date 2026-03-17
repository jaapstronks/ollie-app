//
//  WidgetDataProvider.swift
//  Otis-app
//
//  Shared data layer for widget communication via App Groups

import Foundation
import OtisShared
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
    let expectedWakeTime: Date?  // Predicted wake time based on average nap duration
    let averageNapDurationMin: Int?  // Average nap duration for predictions

    // MARK: - Meal Data
    let lastMealTime: Date?
    let nextScheduledMealTime: Date?  // Next meal target time today
    let mealsLoggedToday: Int
    let mealsExpectedToday: Int

    // MARK: - Walk Data
    let lastWalkTime: Date?
    let nextScheduledWalkTime: Date?  // Next walk target time today

    // MARK: - Latest Event Data
    let lastEventType: String?  // EventType.rawValue
    let lastEventTime: Date?
    let lastEventNote: String?
    let lastEventLocation: String?  // For potty events
    let lastEventHasMedia: Bool
    let lastEventThumbnailName: String?  // Filename of thumbnail in shared container

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
        expectedWakeTime = try container.decodeIfPresent(Date.self, forKey: .expectedWakeTime)
        averageNapDurationMin = try container.decodeIfPresent(Int.self, forKey: .averageNapDurationMin)
        lastMealTime = try container.decodeIfPresent(Date.self, forKey: .lastMealTime)
        nextScheduledMealTime = try container.decodeIfPresent(Date.self, forKey: .nextScheduledMealTime)
        mealsLoggedToday = try container.decode(Int.self, forKey: .mealsLoggedToday)
        mealsExpectedToday = try container.decode(Int.self, forKey: .mealsExpectedToday)
        lastWalkTime = try container.decodeIfPresent(Date.self, forKey: .lastWalkTime)
        nextScheduledWalkTime = try container.decodeIfPresent(Date.self, forKey: .nextScheduledWalkTime)
        lastEventType = try container.decodeIfPresent(String.self, forKey: .lastEventType)
        lastEventTime = try container.decodeIfPresent(Date.self, forKey: .lastEventTime)
        lastEventNote = try container.decodeIfPresent(String.self, forKey: .lastEventNote)
        lastEventLocation = try container.decodeIfPresent(String.self, forKey: .lastEventLocation)
        lastEventHasMedia = try container.decodeIfPresent(Bool.self, forKey: .lastEventHasMedia) ?? false
        lastEventThumbnailName = try container.decodeIfPresent(String.self, forKey: .lastEventThumbnailName)
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
        expectedWakeTime: Date? = nil,
        averageNapDurationMin: Int? = nil,
        lastMealTime: Date?,
        nextScheduledMealTime: Date?,
        mealsLoggedToday: Int,
        mealsExpectedToday: Int,
        lastWalkTime: Date?,
        nextScheduledWalkTime: Date?,
        lastEventType: String? = nil,
        lastEventTime: Date? = nil,
        lastEventNote: String? = nil,
        lastEventLocation: String? = nil,
        lastEventHasMedia: Bool = false,
        lastEventThumbnailName: String? = nil,
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
        self.expectedWakeTime = expectedWakeTime
        self.averageNapDurationMin = averageNapDurationMin
        self.lastMealTime = lastMealTime
        self.nextScheduledMealTime = nextScheduledMealTime
        self.mealsLoggedToday = mealsLoggedToday
        self.mealsExpectedToday = mealsExpectedToday
        self.lastWalkTime = lastWalkTime
        self.nextScheduledWalkTime = nextScheduledWalkTime
        self.lastEventType = lastEventType
        self.lastEventTime = lastEventTime
        self.lastEventNote = lastEventNote
        self.lastEventLocation = lastEventLocation
        self.lastEventHasMedia = lastEventHasMedia
        self.lastEventThumbnailName = lastEventThumbnailName
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
            expectedWakeTime: nil,
            averageNapDurationMin: 45,
            lastMealTime: Date().addingTimeInterval(-3 * 60 * 60),
            nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
            mealsLoggedToday: 2,
            mealsExpectedToday: 3,
            lastWalkTime: Date().addingTimeInterval(-2 * 60 * 60),
            nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
            lastEventType: "plassen",
            lastEventTime: Date().addingTimeInterval(-45 * 60),
            lastEventNote: nil,
            lastEventLocation: "buiten",
            lastEventHasMedia: false,
            lastEventThumbnailName: nil,
            puppyName: "--",
            lastUpdated: Date()
        )
    }
}

/// Provides data to widgets via shared App Group UserDefaults
final class WidgetDataProvider: @unchecked Sendable {
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

        // Calculate average nap duration and expected wake time
        let averageNapDuration = SleepCalculations.averageNapDuration(events: allEvents)
        var expectedWakeTime: Date? = nil
        if isCurrentlySleeping, let sleepStart = sleepStartTime {
            let napDuration = averageNapDuration ?? 45  // Default 45 min if no data
            expectedWakeTime = sleepStart.addingTimeInterval(Double(napDuration) * 60)
        }

        // MARK: Latest Moment Data (most recent event WITH media)
        // Find the most recent event that has a photo/video to display as the "moment"
        let lastMomentEvent = allEvents.reverseChronological().first { $0.media.hasMedia }
        let lastEventType = lastMomentEvent?.type.rawValue
        let lastEventTime = lastMomentEvent?.time
        let lastEventNote = lastMomentEvent?.note
        let lastEventLocation = lastMomentEvent?.location?.rawValue
        let lastEventHasMedia = lastMomentEvent?.media.hasMedia ?? false

        // Copy thumbnail to shared container for widget access
        let lastEventThumbnailName = copyThumbnailToSharedContainer(from: lastMomentEvent)

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
            expectedWakeTime: expectedWakeTime,
            averageNapDurationMin: averageNapDuration,
            lastMealTime: lastMeal?.time,
            nextScheduledMealTime: nextMealTime,
            mealsLoggedToday: mealEvents.count,
            mealsExpectedToday: mealsExpected,
            lastWalkTime: lastWalk?.time,
            nextScheduledWalkTime: nextWalkTime,
            lastEventType: lastEventType,
            lastEventTime: lastEventTime,
            lastEventNote: lastEventNote,
            lastEventLocation: lastEventLocation,
            lastEventHasMedia: lastEventHasMedia,
            lastEventThumbnailName: lastEventThumbnailName,
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
                expectedWakeTime: existing.expectedWakeTime,
                averageNapDurationMin: existing.averageNapDurationMin,
                lastMealTime: existing.lastMealTime,
                nextScheduledMealTime: existing.nextScheduledMealTime,
                mealsLoggedToday: existing.mealsLoggedToday,
                mealsExpectedToday: existing.mealsExpectedToday,
                lastWalkTime: existing.lastWalkTime,
                nextScheduledWalkTime: existing.nextScheduledWalkTime,
                lastEventType: existing.lastEventType,
                lastEventTime: existing.lastEventTime,
                lastEventNote: existing.lastEventNote,
                lastEventLocation: existing.lastEventLocation,
                lastEventHasMedia: existing.lastEventHasMedia,
                lastEventThumbnailName: existing.lastEventThumbnailName,
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
                expectedWakeTime: nil,
                averageNapDurationMin: nil,
                lastMealTime: nil,
                nextScheduledMealTime: nil,
                mealsLoggedToday: 0,
                mealsExpectedToday: 3,
                lastWalkTime: nil,
                nextScheduledWalkTime: nil,
                lastEventType: nil,
                lastEventTime: nil,
                lastEventNote: nil,
                lastEventLocation: nil,
                lastEventHasMedia: false,
                lastEventThumbnailName: nil,
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

    /// Copy thumbnail to shared App Group container for widget access
    /// Returns the filename if successful, nil otherwise
    private func copyThumbnailToSharedContainer(from event: PuppyEvent?) -> String? {
        guard let event = event,
              let thumbnailPath = event.thumbnailPath,
              !thumbnailPath.isEmpty else {
            return nil
        }

        let fileManager = FileManager.default

        // Get source URL (app documents directory)
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let sourceURL = documentsURL.appendingPathComponent(thumbnailPath)

        // Check if source file exists
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            return nil
        }

        // Get shared container URL
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) else {
            return nil
        }

        // Create widget thumbnails directory if needed
        let widgetThumbnailsDir = containerURL.appendingPathComponent("WidgetThumbnails", isDirectory: true)
        if !fileManager.fileExists(atPath: widgetThumbnailsDir.path) {
            try? fileManager.createDirectory(at: widgetThumbnailsDir, withIntermediateDirectories: true)
        }

        // Use event ID as filename to ensure uniqueness
        let thumbnailFilename = "\(event.id.uuidString).jpg"
        let destinationURL = widgetThumbnailsDir.appendingPathComponent(thumbnailFilename)

        // Copy file (replace if exists)
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return thumbnailFilename
        } catch {
            return nil
        }
    }
}

