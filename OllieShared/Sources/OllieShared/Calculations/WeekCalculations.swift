//
//  WeekCalculations.swift
//  OllieShared
//
//  Week overview calculations for the insights view

import Foundation

/// Statistics for a single day in the week overview
public struct DayStats: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let outdoorPotty: Int
    public let indoorPotty: Int
    public let meals: Int
    public let walks: Int
    public let sleepHours: Double
    public let trainingSessions: Int

    public init(date: Date, outdoorPotty: Int, indoorPotty: Int, meals: Int, walks: Int, sleepHours: Double, trainingSessions: Int) {
        self.date = date
        self.outdoorPotty = outdoorPotty
        self.indoorPotty = indoorPotty
        self.meals = meals
        self.walks = walks
        self.sleepHours = sleepHours
        self.trainingSessions = trainingSessions
    }

    /// Outdoor potty percentage (0-100)
    public var outdoorPercentage: Int {
        let total = outdoorPotty + indoorPotty
        guard total > 0 else { return 0 }
        return Int(round(Double(outdoorPotty) / Double(total) * 100))
    }

    /// Short date label
    public var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "E d"
        return formatter.string(from: date).lowercased()
    }

    /// Whether this day is today
    public var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// Week calculation utilities
public struct WeekCalculations {

    /// Calculate stats for the last 7 days (legacy - calls closure per day)
    public static func calculateWeekStats(getEventsForDate: (Date) -> [PuppyEvent]) -> [DayStats] {
        let calendar = Calendar.current
        let today = Date()

        var stats: [DayStats] = []

        for daysAgo in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            let events = getEventsForDate(date)
            let previousDate = calendar.date(byAdding: .day, value: -1, to: date)!
            let previousDayEvents = getEventsForDate(previousDate)

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

    /// Calculate stats for the last 7 days using a batch of events (optimized - single query)
    /// - Parameter events: All events from the past 8 days (7 days + 1 for sleep overlap)
    /// - Returns: Array of DayStats for the last 7 days
    public static func calculateWeekStatsBatch(from events: [PuppyEvent]) -> [DayStats] {
        let calendar = Calendar.current
        let today = Date()

        // Partition events by day (O(n) single pass)
        var eventsByDay: [Date: [PuppyEvent]] = [:]
        for event in events {
            let dayStart = calendar.startOfDay(for: event.time)
            eventsByDay[dayStart, default: []].append(event)
        }

        var stats: [DayStats] = []

        for daysAgo in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            let dayStart = calendar.startOfDay(for: date)
            let previousDayStart = calendar.date(byAdding: .day, value: -1, to: dayStart)!

            let dayEvents = eventsByDay[dayStart] ?? []
            let previousDayEvents = eventsByDay[previousDayStart] ?? []

            var outdoorPotty = 0
            var indoorPotty = 0
            var meals = 0
            var walks = 0
            var trainingSessions = 0

            for event in dayEvents {
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

            let sleepMinutes = calculateDaySleepMinutes(
                date: date,
                todayEvents: dayEvents,
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
    public static func calculateDaySleepMinutes(
        date: Date,
        todayEvents: [PuppyEvent],
        previousDayEvents: [PuppyEvent]
    ) -> Int {
        let calendar = Calendar.current

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

        sleepEvents.sort { $0.time < $1.time }

        var totalMinutes = 0
        var sleepStartTime: Date?

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        for event in sleepEvents {
            if isSleepEvent(event.type) {
                sleepStartTime = event.time
            } else if isWakeEvent(event.type), let start = sleepStartTime {
                let sleepEnd = event.time

                let effectiveStart = max(start, dayStart)
                let effectiveEnd = min(sleepEnd, dayEnd)

                if effectiveEnd > effectiveStart {
                    let minutes = Int(effectiveEnd.timeIntervalSince(effectiveStart) / 60)
                    totalMinutes += minutes
                }

                sleepStartTime = nil
            }
        }

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

    private static func isSleepEvent(_ type: EventType) -> Bool {
        type == .slapen || type == .bench
    }

    private static func isWakeEvent(_ type: EventType) -> Bool {
        type == .ontwaken
    }
}
