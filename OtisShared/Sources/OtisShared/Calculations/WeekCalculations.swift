//
//  WeekCalculations.swift
//  OtisShared
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

    // MARK: - Week Summary

    /// Calculate summary stats for a specific week
    /// - Parameters:
    ///   - weekStart: Start of the week (typically Monday or Sunday)
    ///   - puppyName: Name of the puppy
    ///   - events: All events to analyze (will be filtered to the week)
    /// - Returns: WeekSummaryStats for the specified week
    public static func calculateWeekSummary(
        weekStart: Date,
        puppyName: String,
        events: [PuppyEvent]
    ) -> WeekSummaryStats {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        // Filter events to this week
        let weekEvents = events.filter { event in
            event.time >= weekStart && event.time < calendar.date(byAdding: .day, value: 1, to: weekEnd)!
        }

        // Aggregate stats
        var totalWalks = 0
        var totalWalkMinutes = 0
        var totalPottyEvents = 0
        var outdoorPottyCount = 0
        var totalTrainingSessions = 0
        var totalSocialEvents = 0
        var photoCount = 0
        var totalSleepHours: Double = 0

        // Track per-day stats
        var eventsByDay: [Date: [PuppyEvent]] = [:]

        for event in weekEvents {
            let dayStart = calendar.startOfDay(for: event.time)
            eventsByDay[dayStart, default: []].append(event)

            switch event.type {
            case .uitlaten:
                totalWalks += 1
                totalWalkMinutes += event.durationMin ?? 0
            case .plassen, .poepen:
                totalPottyEvents += 1
                if event.location == .buiten {
                    outdoorPottyCount += 1
                }
            case .training:
                totalTrainingSessions += 1
            case .sociaal:
                totalSocialEvents += 1
            default:
                break
            }

            if event.media.hasPhoto {
                photoCount += 1
            }
        }

        // Build day stats for each day in the week
        var dayStats: [DayStats] = []

        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: day, to: weekStart) else { continue }
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
            totalSleepHours += sleepHours

            dayStats.append(DayStats(
                date: date,
                outdoorPotty: outdoorPotty,
                indoorPotty: indoorPotty,
                meals: meals,
                walks: walks,
                sleepHours: sleepHours,
                trainingSessions: trainingSessions
            ))
        }

        let avgSleepHours = dayStats.isEmpty ? 0 : totalSleepHours / Double(dayStats.count)

        return WeekSummaryStats(
            weekStart: weekStart,
            weekEnd: weekEnd,
            puppyName: puppyName,
            totalWalks: totalWalks,
            totalWalkMinutes: totalWalkMinutes,
            totalPottyEvents: totalPottyEvents,
            outdoorPottyCount: outdoorPottyCount,
            totalTrainingSessions: totalTrainingSessions,
            totalSocialEvents: totalSocialEvents,
            avgSleepHours: avgSleepHours,
            photoCount: photoCount,
            dayStats: dayStats
        )
    }

    /// Get the start of the current week (Monday)
    public static func currentWeekStart() -> Date {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        return calendar.date(from: components) ?? today
    }

    /// Get the start of the previous week
    public static func previousWeekStart() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart()) ?? Date()
    }

    /// Get events with photos for a specific week
    /// - Parameters:
    ///   - weekStart: Start of the week
    ///   - events: All events to analyze
    /// - Returns: Events with photos, sorted by date descending
    public static func photoEvents(for weekStart: Date, from events: [PuppyEvent]) -> [PuppyEvent] {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        return events
            .filter { event in
                event.time >= weekStart &&
                event.time < weekEnd &&
                event.media.hasPhoto
            }
            .sorted { $0.time > $1.time }
    }

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

        // Single pass: partition AND aggregate stats simultaneously
        // This avoids storing full PuppyEvent copies in the dictionary
        var statsByDay: [Date: (outdoor: Int, indoor: Int, meals: Int, walks: Int, training: Int)] = [:]
        var sleepEventsByDay: [Date: [(time: Date, type: EventType, durationMin: Int?)]] = [:]

        for event in events {
            let dayStart = calendar.startOfDay(for: event.time)

            // Aggregate counts directly (no copying full structs)
            var dayStat = statsByDay[dayStart] ?? (0, 0, 0, 0, 0)

            switch event.type {
            case .plassen, .poepen:
                if event.location == .buiten {
                    dayStat.outdoor += 1
                } else if event.location == .binnen {
                    dayStat.indoor += 1
                }
            case .eten:
                dayStat.meals += 1
            case .uitlaten:
                dayStat.walks += 1
            case .training:
                dayStat.training += 1
            case .slapen, .ontwaken:
                // Store minimal sleep data for sleep calculation
                sleepEventsByDay[dayStart, default: []].append((event.time, event.type, event.durationMin))
            default:
                break
            }

            statsByDay[dayStart] = dayStat
        }

        var stats: [DayStats] = []

        for daysAgo in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            let dayStart = calendar.startOfDay(for: date)
            let previousDayStart = calendar.date(byAdding: .day, value: -1, to: dayStart)!

            let dayStat = statsByDay[dayStart] ?? (0, 0, 0, 0, 0)

            // Calculate sleep using minimal data
            let sleepMinutes = calculateDaySleepMinutesOptimized(
                date: date,
                todaySleepEvents: sleepEventsByDay[dayStart] ?? [],
                previousDaySleepEvents: sleepEventsByDay[previousDayStart] ?? []
            )
            let sleepHours = Double(sleepMinutes) / 60.0

            stats.append(DayStats(
                date: date,
                outdoorPotty: dayStat.outdoor,
                indoorPotty: dayStat.indoor,
                meals: dayStat.meals,
                walks: dayStat.walks,
                sleepHours: sleepHours,
                trainingSessions: dayStat.training
            ))
        }

        return stats
    }

    /// Optimized sleep calculation using minimal event data
    private static func calculateDaySleepMinutesOptimized(
        date: Date,
        todaySleepEvents: [(time: Date, type: EventType, durationMin: Int?)],
        previousDaySleepEvents: [(time: Date, type: EventType, durationMin: Int?)]
    ) -> Int {
        let calendar = Calendar.current

        // Combine and sort sleep events
        var sleepEvents = previousDaySleepEvents + todaySleepEvents
        sleepEvents.sort { $0.time < $1.time }

        var totalMinutes = 0
        var sleepStartTime: Date?

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        for event in sleepEvents {
            if event.type == .slapen {
                sleepStartTime = event.time
            } else if event.type == .ontwaken, let start = sleepStartTime {
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
        type == .slapen
    }

    private static func isWakeEvent(_ type: EventType) -> Bool {
        type == .ontwaken
    }
}
