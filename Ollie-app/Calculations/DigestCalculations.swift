//
//  DigestCalculations.swift
//  Ollie-app
//
//  Daily digest calculations for timeline summary

import Foundation

/// Daily digest summary
struct DailyDigest: Equatable {
    /// Day number since coming home (e.g., "Dag 5 thuis")
    let dayNumber: Int?

    /// Summary parts for display (e.g., ["5x buiten (100%)", "3 maaltijden"])
    let parts: [String]

    /// Whether there's any data to show
    var hasData: Bool {
        !parts.isEmpty
    }

    /// Empty digest for days with no events
    static var empty: DailyDigest {
        DailyDigest(dayNumber: nil, parts: [])
    }
}

/// Digest calculation utilities
struct DigestCalculations {

    // MARK: - Public Methods

    /// Generate a daily digest from events and profile
    /// - Parameters:
    ///   - events: Events for the day
    ///   - profile: Puppy profile (optional, for day number)
    ///   - date: The date being displayed
    /// - Returns: Daily digest with summary parts
    static func generateDigest(
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
        let pottyEvents = events.filter { $0.type == .plassen }
        guard !pottyEvents.isEmpty else { return nil }

        let outdoorCount = pottyEvents.filter { $0.location == .buiten }.count
        let totalCount = pottyEvents.count

        if totalCount == 0 {
            return nil
        }

        let percentage = (outdoorCount * 100) / totalCount

        if outdoorCount == totalCount {
            return "\(totalCount)x plassen (100% buiten)"
        } else {
            return "\(totalCount)x plassen (\(percentage)% buiten)"
        }
    }

    /// Generate poop summary
    private static func generatePoopSummary(events: [PuppyEvent]) -> String? {
        let poopEvents = events.filter { $0.type == .poepen }
        guard !poopEvents.isEmpty else { return nil }

        let outdoorCount = poopEvents.filter { $0.location == .buiten }.count
        let totalCount = poopEvents.count

        if outdoorCount == totalCount && totalCount > 0 {
            return "\(totalCount)x poepen (100% buiten)"
        } else if totalCount > 0 {
            let percentage = (outdoorCount * 100) / totalCount
            return "\(totalCount)x poepen (\(percentage)% buiten)"
        }

        return nil
    }

    /// Generate meal summary
    private static func generateMealSummary(events: [PuppyEvent]) -> String? {
        let mealCount = events.filter { $0.type == .eten }.count
        guard mealCount > 0 else { return nil }

        if mealCount == 1 {
            return "1 maaltijd"
        } else {
            return "\(mealCount) maaltijden"
        }
    }

    /// Generate sleep summary
    private static func generateSleepSummary(events: [PuppyEvent]) -> String? {
        let totalMinutes = SleepCalculations.totalSleepToday(events: events)
        guard totalMinutes > 0 else { return nil }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes) min geslapen"
        } else if minutes == 0 {
            return "\(hours) uur geslapen"
        } else {
            return "\(hours)u\(minutes)m geslapen"
        }
    }

    /// Generate walk summary
    private static func generateWalkSummary(events: [PuppyEvent]) -> String? {
        let walkCount = events.filter { $0.type == .uitlaten }.count
        guard walkCount > 0 else { return nil }

        if walkCount == 1 {
            return "1 wandeling"
        } else {
            return "\(walkCount) wandelingen"
        }
    }
}
