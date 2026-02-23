//
//  DigestCalculations.swift
//  OllieShared
//
//  Daily digest calculations for timeline summary

import Foundation

/// Daily digest summary
public struct DailyDigest: Equatable, Sendable {
    /// Day number since coming home (e.g., "Day 5 home")
    public let dayNumber: Int?

    /// Summary parts for display (e.g., ["5x outside (100%)", "3 meals"])
    public let parts: [String]

    public init(dayNumber: Int?, parts: [String]) {
        self.dayNumber = dayNumber
        self.parts = parts
    }

    /// Whether there's any data to show
    public var hasData: Bool {
        !parts.isEmpty
    }

    /// Empty digest for days with no events
    public static var empty: DailyDigest {
        DailyDigest(dayNumber: nil, parts: [])
    }
}

/// Digest calculation utilities
public struct DigestCalculations {

    // MARK: - Public Methods

    /// Generate a daily digest from events and profile
    /// - Parameters:
    ///   - events: Events for the day
    ///   - profile: Puppy profile (optional, for day number)
    ///   - date: The date being displayed
    /// - Returns: Daily digest with summary parts
    public static func generateDigest(
        events: [PuppyEvent],
        profile: PuppyProfile?,
        date: Date = Date()
    ) -> DailyDigest {
        var parts: [String] = []

        // Calculate day number if we have profile
        let dayNumber: Int?
        if let profile = profile {
            dayNumber = calculateDayNumber(homeDate: profile.homeDate, targetDate: date)
        } else {
            dayNumber = nil
        }

        // Potty summary with outdoor percentage
        let pottySummary = generatePottySummary(events: events)
        if let summary = pottySummary {
            parts.append(summary)
        }

        // Poop summary
        let poopSummary = generatePoopSummary(events: events)
        if let summary = poopSummary {
            parts.append(summary)
        }

        // Meal count
        let mealSummary = generateMealSummary(events: events)
        if let summary = mealSummary {
            parts.append(summary)
        }

        // Sleep summary
        let sleepSummary = generateSleepSummary(events: events)
        if let summary = sleepSummary {
            parts.append(summary)
        }

        // Walk count
        let walkSummary = generateWalkSummary(events: events)
        if let summary = walkSummary {
            parts.append(summary)
        }

        return DailyDigest(dayNumber: dayNumber, parts: parts)
    }

    // MARK: - Private Helpers

    /// Calculate day number since coming home
    private static func calculateDayNumber(homeDate: Date, targetDate: Date) -> Int? {
        let calendar = Calendar.current
        let homeStart = calendar.startOfDay(for: homeDate)
        let targetStart = calendar.startOfDay(for: targetDate)

        let components = calendar.dateComponents([.day], from: homeStart, to: targetStart)

        guard let days = components.day, days >= 0 else {
            return nil
        }

        // Day 1 is the first day home
        return days + 1
    }

    /// Generate potty summary with outdoor percentage
    private static func generatePottySummary(events: [PuppyEvent]) -> String? {
        let pottyEvents = events.pee()
        guard !pottyEvents.isEmpty else { return nil }

        let outdoorCount = pottyEvents.outdoor().count
        let totalCount = pottyEvents.count

        if totalCount == 0 {
            return nil
        }

        let percentage = (outdoorCount * 100) / totalCount
        return Strings.Digest.peeCount(totalCount, percentage: percentage)
    }

    /// Generate poop summary
    private static func generatePoopSummary(events: [PuppyEvent]) -> String? {
        let poopEvents = events.poop()
        guard !poopEvents.isEmpty else { return nil }

        let outdoorCount = poopEvents.outdoor().count
        let totalCount = poopEvents.count

        guard totalCount > 0 else { return nil }

        let percentage = (outdoorCount * 100) / totalCount
        return Strings.Digest.poopCount(totalCount, percentage: percentage)
    }

    /// Generate meal summary
    private static func generateMealSummary(events: [PuppyEvent]) -> String? {
        let mealCount = events.meals().count
        guard mealCount > 0 else { return nil }
        return Strings.Digest.mealCount(mealCount)
    }

    /// Generate sleep summary
    private static func generateSleepSummary(events: [PuppyEvent]) -> String? {
        let totalMinutes = SleepCalculations.totalSleepToday(events: events)
        guard totalMinutes > 0 else { return nil }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return Strings.Digest.sleepMinutes(minutes)
        } else if minutes == 0 {
            return Strings.Digest.sleepHours(hours)
        } else {
            return Strings.Digest.sleepHoursMinutes(hours: hours, minutes: minutes)
        }
    }

    /// Generate walk summary
    private static func generateWalkSummary(events: [PuppyEvent]) -> String? {
        let walkCount = events.walks().count
        guard walkCount > 0 else { return nil }
        return Strings.Digest.walkCount(walkCount)
    }
}
