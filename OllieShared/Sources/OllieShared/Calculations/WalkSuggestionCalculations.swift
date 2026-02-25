//
//  WalkSuggestionCalculations.swift
//  OllieShared
//
//  Smart walk scheduling that adapts based on actual walk times
//  Supports flexible mode (interval-based) and strict mode (fixed times)
//

import Foundation

/// Represents a smart walk suggestion
public struct WalkSuggestion: Sendable {
    public let suggestedTime: Date
    public let label: String
    public let isOverdue: Bool
    public let minutesSinceLastWalk: Int?
    public let minutesUntilSuggested: Int
    public let walksCompletedToday: Int
    public let targetWalksPerDay: Int
    public let scheduledWalkIndex: Int?  // Index in walkSchedule.walks (for strict mode)

    public init(
        suggestedTime: Date,
        label: String,
        isOverdue: Bool,
        minutesSinceLastWalk: Int?,
        minutesUntilSuggested: Int,
        walksCompletedToday: Int,
        targetWalksPerDay: Int,
        scheduledWalkIndex: Int? = nil
    ) {
        self.suggestedTime = suggestedTime
        self.label = label
        self.isOverdue = isOverdue
        self.minutesSinceLastWalk = minutesSinceLastWalk
        self.minutesUntilSuggested = minutesUntilSuggested
        self.walksCompletedToday = walksCompletedToday
        self.targetWalksPerDay = targetWalksPerDay
        self.scheduledWalkIndex = scheduledWalkIndex
    }

    /// Format suggested time as HH:mm string
    public var timeString: String {
        suggestedTime.timeString
    }

    /// Is the walk day complete (all scheduled walks done or past end time)?
    public var isDayComplete: Bool {
        walksCompletedToday >= targetWalksPerDay
    }
}

/// Calculations for smart walk suggestions
public struct WalkSuggestionCalculations {

    // MARK: - Public API

    /// Calculate the next smart walk suggestion
    /// - Parameters:
    ///   - events: Today's events (will be filtered for walks)
    ///   - walkSchedule: The configured walk schedule (provides target count and time slots)
    ///   - date: The date to calculate for (defaults to now)
    /// - Returns: A `WalkSuggestion` or nil if no more walks should be suggested today
    public static func calculateNextSuggestion(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date = Date()
    ) -> WalkSuggestion? {
        switch walkSchedule.mode {
        case .flexible:
            return calculateFlexibleSuggestion(events: events, walkSchedule: walkSchedule, date: date)
        case .strict:
            return calculateStrictSuggestion(events: events, walkSchedule: walkSchedule, date: date)
        }
    }

    /// Calculate all remaining walk suggestions for the day
    /// - Parameters:
    ///   - events: Today's events
    ///   - walkSchedule: The configured walk schedule
    ///   - date: The date to calculate for
    /// - Returns: Array of walk suggestions for the rest of the day
    public static func calculateRemainingSuggestions(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date = Date()
    ) -> [WalkSuggestion] {
        switch walkSchedule.mode {
        case .flexible:
            return calculateRemainingFlexible(events: events, walkSchedule: walkSchedule, date: date)
        case .strict:
            return calculateRemainingStrict(events: events, walkSchedule: walkSchedule, date: date)
        }
    }

    // MARK: - Flexible Mode (Interval-based)

    /// Calculate next suggestion in flexible mode (interval-based)
    private static func calculateFlexibleSuggestion(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date
    ) -> WalkSuggestion? {
        let calendar = Calendar.current
        let now = date

        // Filter to today's walk events
        let todayWalks = events.walks().filter { event in
            calendar.isDate(event.time, inSameDayAs: date)
        }.chronological()

        let walksCompletedToday = todayWalks.count
        let targetWalksPerDay = walkSchedule.walksPerDay

        // All walks done
        if walksCompletedToday >= targetWalksPerDay {
            return nil
        }

        // Check if we're past the end of walks time (24 means midnight, so never past)
        let currentHour = calendar.component(.hour, from: now)
        if walkSchedule.dayEndHour < 24 && currentHour >= walkSchedule.dayEndHour {
            return nil
        }

        let suggestedTime: Date
        let label: String
        let minutesSinceLastWalk: Int?

        if let lastWalk = todayWalks.last {
            // Calculate time since last walk
            let sinceLastWalk = Int(now.timeIntervalSince(lastWalk.time) / 60)
            minutesSinceLastWalk = sinceLastWalk

            // Next suggestion = last walk time + configured interval
            suggestedTime = lastWalk.time.addingTimeInterval(TimeInterval(walkSchedule.intervalMinutes * 60))

            // Use label from next scheduled walk slot if available
            if walksCompletedToday < walkSchedule.walks.count {
                label = walkSchedule.walks[walksCompletedToday].label
            } else if let closestSlot = walkSchedule.closestSlot(to: suggestedTime) {
                label = closestSlot.label
            } else {
                label = Strings.Walks.nextWalk
            }
        } else {
            // No walks today yet
            minutesSinceLastWalk = nil

            // Use first scheduled time or day start hour
            if let firstTimeStr = walkSchedule.firstWalkTime,
               let firstDate = parseTime(firstTimeStr, on: date) {
                if firstDate < now {
                    // First slot has passed - suggest now
                    suggestedTime = now
                } else {
                    suggestedTime = firstDate
                }
            } else {
                // Fallback: day start hour
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = walkSchedule.dayStartHour
                components.minute = 0
                let dayStart = calendar.date(from: components) ?? now
                suggestedTime = max(dayStart, now)
            }

            label = walkSchedule.walks.first?.label ?? Strings.Walks.morningWalk
        }

        // Cap at day end
        guard let cappedTime = capAtDayEnd(suggestedTime, walkSchedule: walkSchedule, date: date, now: now) else {
            return nil
        }

        let isOverdue = cappedTime < now
        let minutesUntilSuggested = Int(cappedTime.timeIntervalSince(now) / 60)

        return WalkSuggestion(
            suggestedTime: cappedTime,
            label: label,
            isOverdue: isOverdue,
            minutesSinceLastWalk: minutesSinceLastWalk,
            minutesUntilSuggested: minutesUntilSuggested,
            walksCompletedToday: walksCompletedToday,
            targetWalksPerDay: targetWalksPerDay,
            scheduledWalkIndex: walksCompletedToday < targetWalksPerDay ? walksCompletedToday : nil
        )
    }

    /// Calculate all remaining suggestions in flexible mode
    private static func calculateRemainingFlexible(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date
    ) -> [WalkSuggestion] {
        var suggestions: [WalkSuggestion] = []
        var simulatedEvents = events
        var currentTime = date

        // Generate suggestions until we hit the end of day or target count
        let maxIterations = walkSchedule.walksPerDay
        for _ in 0..<maxIterations {
            guard let suggestion = calculateFlexibleSuggestion(
                events: simulatedEvents,
                walkSchedule: walkSchedule,
                date: currentTime
            ) else {
                break
            }

            suggestions.append(suggestion)

            // Simulate this walk being completed
            let simulatedWalk = PuppyEvent(time: suggestion.suggestedTime, type: .uitlaten)
            simulatedEvents.append(simulatedWalk)
            currentTime = suggestion.suggestedTime.addingTimeInterval(60)
        }

        return suggestions
    }

    // MARK: - Strict Mode (Fixed Times)

    /// Calculate next suggestion in strict mode (fixed scheduled times)
    private static func calculateStrictSuggestion(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date
    ) -> WalkSuggestion? {
        let calendar = Calendar.current
        let now = date

        // Filter to today's walk events
        let todayWalks = events.walks().filter { event in
            calendar.isDate(event.time, inSameDayAs: date)
        }.chronological()

        let walksCompletedToday = todayWalks.count
        let targetWalksPerDay = walkSchedule.walksPerDay

        // All walks done
        if walksCompletedToday >= targetWalksPerDay {
            return nil
        }

        // Check if we're past the end of walks time (24 means midnight, so never past)
        let currentHour = calendar.component(.hour, from: now)
        if walkSchedule.dayEndHour < 24 && currentHour >= walkSchedule.dayEndHour {
            return nil
        }

        // Find the next scheduled walk that hasn't been completed
        // In strict mode, we use the scheduled times directly
        let nextWalkIndex = walksCompletedToday
        guard nextWalkIndex < walkSchedule.walks.count else {
            return nil
        }

        let nextScheduledWalk = walkSchedule.walks[nextWalkIndex]
        guard let scheduledTime = parseTime(nextScheduledWalk.targetTime, on: date) else {
            return nil
        }

        // Calculate minutes since last walk (for context)
        let minutesSinceLastWalk: Int?
        if let lastWalk = todayWalks.last {
            minutesSinceLastWalk = Int(now.timeIntervalSince(lastWalk.time) / 60)
        } else {
            minutesSinceLastWalk = nil
        }

        let isOverdue = scheduledTime < now
        let minutesUntilSuggested = Int(scheduledTime.timeIntervalSince(now) / 60)

        return WalkSuggestion(
            suggestedTime: scheduledTime,
            label: nextScheduledWalk.label,
            isOverdue: isOverdue,
            minutesSinceLastWalk: minutesSinceLastWalk,
            minutesUntilSuggested: minutesUntilSuggested,
            walksCompletedToday: walksCompletedToday,
            targetWalksPerDay: targetWalksPerDay,
            scheduledWalkIndex: nextWalkIndex
        )
    }

    /// Calculate all remaining suggestions in strict mode
    private static func calculateRemainingStrict(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date
    ) -> [WalkSuggestion] {
        let calendar = Calendar.current
        let now = date

        // Filter to today's walk events
        let todayWalks = events.walks().filter { event in
            calendar.isDate(event.time, inSameDayAs: date)
        }.chronological()

        let walksCompletedToday = todayWalks.count
        let targetWalksPerDay = walkSchedule.walksPerDay

        var suggestions: [WalkSuggestion] = []

        // Return all scheduled walks that haven't been completed
        for i in walksCompletedToday..<targetWalksPerDay {
            guard i < walkSchedule.walks.count else { break }

            let scheduledWalk = walkSchedule.walks[i]
            guard let scheduledTime = parseTime(scheduledWalk.targetTime, on: date) else { continue }

            // Calculate minutes since last walk (or last simulated walk)
            let minutesSinceLastWalk: Int?
            if let lastWalk = todayWalks.last {
                minutesSinceLastWalk = Int(now.timeIntervalSince(lastWalk.time) / 60)
            } else {
                minutesSinceLastWalk = nil
            }

            let isOverdue = scheduledTime < now
            let minutesUntilSuggested = Int(scheduledTime.timeIntervalSince(now) / 60)

            suggestions.append(WalkSuggestion(
                suggestedTime: scheduledTime,
                label: scheduledWalk.label,
                isOverdue: isOverdue,
                minutesSinceLastWalk: minutesSinceLastWalk,
                minutesUntilSuggested: minutesUntilSuggested,
                walksCompletedToday: walksCompletedToday + suggestions.count,
                targetWalksPerDay: targetWalksPerDay,
                scheduledWalkIndex: i
            ))
        }

        return suggestions
    }

    // MARK: - Helpers

    /// Parse a time string (e.g., "08:00") into a Date for the given day
    private static func parseTime(_ timeString: String, on date: Date) -> Date? {
        let parts = timeString.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute

        return Calendar.current.date(from: components)
    }

    /// Cap a suggested time at the day end hour, returning nil if past
    private static func capAtDayEnd(_ suggestedTime: Date, walkSchedule: WalkSchedule, date: Date, now: Date) -> Date? {
        // If day end is midnight (24), don't cap
        if walkSchedule.dayEndHour >= 24 {
            return suggestedTime
        }

        let calendar = Calendar.current
        let suggestedHour = calendar.component(.hour, from: suggestedTime)

        if suggestedHour >= walkSchedule.dayEndHour {
            // Set to day end hour
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = walkSchedule.dayEndHour
            components.minute = 0
            if let endTime = calendar.date(from: components), endTime > now {
                return endTime
            } else {
                return nil
            }
        }

        return suggestedTime
    }
}
