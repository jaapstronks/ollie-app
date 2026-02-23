//
//  WalkSuggestionCalculations.swift
//  Ollie-app
//
//  Smart walk scheduling that adapts based on actual walk times
//

import Foundation

/// Represents a smart walk suggestion
struct WalkSuggestion {
    let suggestedTime: Date
    let label: String
    let isOverdue: Bool
    let minutesSinceLastWalk: Int?
    let minutesUntilSuggested: Int
    let walksCompletedToday: Int
    let targetWalksPerDay: Int

    /// Format suggested time as HH:mm string
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: suggestedTime)
    }

    /// Is the walk day complete (all scheduled walks done or past end time)?
    var isDayComplete: Bool {
        walksCompletedToday >= targetWalksPerDay
    }
}

/// Calculations for smart walk suggestions
struct WalkSuggestionCalculations {
    /// Default interval between walks (2 hours)
    static let defaultIntervalMinutes = 120

    /// Hour after which we stop suggesting walks (22:00)
    static let endOfWalksHour = 22

    /// Calculate the next smart walk suggestion
    /// - Parameters:
    ///   - events: Today's events (will be filtered for walks)
    ///   - walkSchedule: The configured walk schedule (provides target count and time slots)
    ///   - date: The date to calculate for (defaults to now)
    /// - Returns: A `WalkSuggestion` or nil if no more walks should be suggested today
    static func calculateNextSuggestion(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date = Date()
    ) -> WalkSuggestion? {
        let calendar = Calendar.current
        let now = date

        // Filter to today's walk events
        let todayWalks = events.filter { event in
            event.type == .uitlaten && calendar.isDate(event.time, inSameDayAs: date)
        }.sorted { $0.time < $1.time }

        let walksCompletedToday = todayWalks.count
        let targetWalksPerDay = walkSchedule.walks.count

        // Check if we're past the end of walks time (e.g., 22:00)
        let currentHour = calendar.component(.hour, from: now)
        if currentHour >= endOfWalksHour {
            return nil
        }

        // Calculate suggested time
        let suggestedTime: Date
        let label: String
        let minutesSinceLastWalk: Int?

        if let lastWalk = todayWalks.last {
            // Calculate time since last walk
            let sinceLastWalk = Int(now.timeIntervalSince(lastWalk.time) / 60)
            minutesSinceLastWalk = sinceLastWalk

            // Next suggestion = last walk time + 2 hours
            suggestedTime = lastWalk.time.addingTimeInterval(TimeInterval(defaultIntervalMinutes * 60))

            // Find the closest scheduled slot label for context
            if let closestSlot = walkSchedule.closestSlot(to: suggestedTime) {
                label = closestSlot.label
            } else {
                label = Strings.Walks.nextWalk
            }
        } else {
            // No walks today - suggest first scheduled slot
            minutesSinceLastWalk = nil

            if let firstTimeStr = walkSchedule.firstWalkTime,
               let firstDate = parseTime(firstTimeStr, on: date) {
                // If first slot has passed, calculate from now + a short buffer
                if firstDate < now {
                    // Suggest based on current time
                    suggestedTime = now.addingTimeInterval(15 * 60) // 15 min from now
                    if let closestSlot = walkSchedule.closestSlot(to: suggestedTime) {
                        label = closestSlot.label
                    } else {
                        label = Strings.Walks.morningWalk
                    }
                } else {
                    // First slot hasn't passed yet
                    suggestedTime = firstDate
                    label = walkSchedule.walks.first?.label ?? Strings.Walks.earlyMorning
                }
            } else {
                // Fallback: suggest 6:00 or now, whichever is later
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = 6
                components.minute = 0
                let sixAM = calendar.date(from: components) ?? now

                suggestedTime = max(sixAM, now.addingTimeInterval(15 * 60))
                label = Strings.Walks.earlyMorning
            }
        }

        // Cap suggested time at 22:00
        var cappedSuggestedTime = suggestedTime
        let suggestedHour = calendar.component(.hour, from: suggestedTime)
        if suggestedHour >= endOfWalksHour {
            // Set to 22:00 on the same day
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = endOfWalksHour
            components.minute = 0
            if let endTime = calendar.date(from: components), endTime > now {
                cappedSuggestedTime = endTime
            } else {
                // Past 22:00, no more walks
                return nil
            }
        }

        // Calculate if overdue
        let isOverdue = cappedSuggestedTime < now
        let minutesUntilSuggested = Int(cappedSuggestedTime.timeIntervalSince(now) / 60)

        return WalkSuggestion(
            suggestedTime: cappedSuggestedTime,
            label: label,
            isOverdue: isOverdue,
            minutesSinceLastWalk: minutesSinceLastWalk,
            minutesUntilSuggested: minutesUntilSuggested,
            walksCompletedToday: walksCompletedToday,
            targetWalksPerDay: targetWalksPerDay
        )
    }

    /// Calculate all remaining walk suggestions for the day
    /// - Parameters:
    ///   - events: Today's events
    ///   - walkSchedule: The configured walk schedule
    ///   - date: The date to calculate for
    /// - Returns: Array of walk suggestions for the rest of the day
    static func calculateRemainingSuggestions(
        events: [PuppyEvent],
        walkSchedule: WalkSchedule,
        date: Date = Date()
    ) -> [WalkSuggestion] {
        var suggestions: [WalkSuggestion] = []
        var simulatedEvents = events
        var currentTime = date

        // Generate suggestions until we hit the end of day or target count
        for _ in 0..<walkSchedule.walks.count {
            guard let suggestion = calculateNextSuggestion(
                events: simulatedEvents,
                walkSchedule: walkSchedule,
                date: currentTime
            ) else {
                break
            }

            suggestions.append(suggestion)

            // Simulate this walk being completed
            let simulatedWalk = PuppyEvent(
                time: suggestion.suggestedTime,
                type: .uitlaten
            )
            simulatedEvents.append(simulatedWalk)
            currentTime = suggestion.suggestedTime.addingTimeInterval(60) // Move time forward
        }

        return suggestions
    }

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
}
