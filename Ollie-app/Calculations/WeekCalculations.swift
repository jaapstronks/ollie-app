//
//  WeekCalculations.swift
//  Ollie-app
//
//  Week overview calculations for the insights view

import Foundation

/// Statistics for a single day in the week overview
struct DayStats: Identifiable {
    let id = UUID()
    let date: Date
    let outdoorPotty: Int
    let indoorPotty: Int
    let meals: Int
    let walks: Int
    let sleepHours: Double
    let trainingSessions: Int

    /// Outdoor potty percentage (0-100)
    var outdoorPercentage: Int {
        let total = outdoorPotty + indoorPotty
        guard total > 0 else { return 0 }
        return Int(round(Double(outdoorPotty) / Double(total) * 100))
    }

    /// Short date label (e.g., "ma 17")
    var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "E d"  // "ma 17"
        return formatter.string(from: date).lowercased()
    }

    /// Whether this day is today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// Week calculation utilities
struct WeekCalculations {

    /// Calculate stats for the last 7 days
    /// - Parameter getEventsForDate: Closure that returns events for a specific date
    /// - Returns: Array of DayStats for the last 7 days (oldest first)
    static func calculateWeekStats(getEventsForDate: (Date) -> [PuppyEvent]) -> [DayStats] {
        let calendar = Calendar.current
        let today = Date()

        var stats: [DayStats] = []

        // Calculate for last 7 days (6 days ago through today)
        for daysAgo in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            // Get events for this day and the previous day (for overnight sleep)
            let events = getEventsForDate(date)
            let previousDate = calendar.date(byAdding: .day, value: -1, to: date)!
            let previousDayEvents = getEventsForDate(previousDate)

            // Count outdoor potty (plassen + poepen with location buiten)
            var outdoorPotty = 0
            var indoorPotty = 0
            var meals = 0
            var walks = 0
            var trainingSessions = 0

            for event in events {
                let isPotty = event.type == .plassen || event.type == .poepen

                if isPotty && event.location == .buiten {
                    outdoorPotty += 1
                } else if isPotty && event.location == .binnen {
                    indoorPotty += 1
                }

                if event.type == .eten {
                    meals += 1
                }

                if event.type == .uitlaten {
                    walks += 1
                }

                if event.type == .training {
                    trainingSessions += 1
                }
            }

            // Calculate sleep hours (combining current day events with previous day for overnight)
            let sleepMinutes = calculateDaySleepMinutes(
                date: date,
                todayEvents: events,
                previousDayEvents: previousDayEvents
            )
            let sleepHours = Double(sleepMinutes) / 60.0

            stats.append(DayStats(
                date: date,
                outdoorPotty: outdoorPotty,
                indoorPotty: indoorPotty,
                meals: meals,
                walks: walks,
                sleepHours: sleepHours,
                trainingSessions: trainingSessions
            ))
        }

        return stats
    }

    /// Calculate sleep minutes for a specific day
    /// Pairs slapen/bench events with ontwaken events, handles overnight sleep
    static func calculateDaySleepMinutes(
        date: Date,
        todayEvents: [PuppyEvent],
        previousDayEvents: [PuppyEvent]
    ) -> Int {
        let calendar = Calendar.current

        // Combine relevant events
        var sleepEvents: [PuppyEvent] = []
        for event in previousDayEvents {
            if isSleepEvent(event.type) || isWakeEvent(event.type) {
                sleepEvents.append(event)
            }
        }
        for event in todayEvents {
            if isSleepEvent(event.type) || isWakeEvent(event.type) {
                sleepEvents.append(event)
            }
        }

        // Sort by time
        sleepEvents.sort { $0.time < $1.time }

        var totalMinutes = 0
        var sleepStartTime: Date?

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        for event in sleepEvents {
            if isSleepEvent(event.type) {
                sleepStartTime = event.time
            } else if isWakeEvent(event.type), let start = sleepStartTime {
                // Calculate sleep duration that falls within this day
                let sleepEnd = event.time

                // Clip sleep period to this day's boundaries
                let effectiveStart = max(start, dayStart)
                let effectiveEnd = min(sleepEnd, dayEnd)

                if effectiveEnd > effectiveStart {
                    let minutes = Int(effectiveEnd.timeIntervalSince(effectiveStart) / 60)
                    totalMinutes += minutes
                }

                sleepStartTime = nil
            }
        }

        // If still sleeping at the end of the day (or now for today)
        if let start = sleepStartTime {
            let endTime: Date
            if calendar.isDateInToday(date) {
                endTime = Date()
            } else {
                endTime = dayEnd
            }

            let effectiveStart = max(start, dayStart)
            if endTime > effectiveStart {
                let minutes = Int(endTime.timeIntervalSince(effectiveStart) / 60)
                totalMinutes += minutes
            }
        }

        return totalMinutes
    }

    /// Check if event type indicates sleep start
    private static func isSleepEvent(_ type: EventType) -> Bool {
        type == .slapen || type == .bench
    }

    /// Check if event type indicates wake
    private static func isWakeEvent(_ type: EventType) -> Bool {
        type == .ontwaken
    }
}
