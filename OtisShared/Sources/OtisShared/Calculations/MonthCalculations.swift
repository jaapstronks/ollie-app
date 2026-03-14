//
//  MonthCalculations.swift
//  OtisShared
//
//  Monthly recap calculations and stats aggregation

import Foundation

// MARK: - Month Summary Stats

/// Statistics for a monthly recap
public struct MonthSummaryStats: Identifiable, Sendable {
    public let id = UUID()
    public let month: Date
    public let puppyName: String
    public let totalWalks: Int
    public let totalWalkMinutes: Int
    public let totalPottyEvents: Int
    public let outdoorPottyCount: Int
    public let totalTrainingSessions: Int
    public let totalSocialEvents: Int
    public let photoCount: Int
    public let dayStats: [DayStats]

    public init(
        month: Date,
        puppyName: String,
        totalWalks: Int,
        totalWalkMinutes: Int,
        totalPottyEvents: Int,
        outdoorPottyCount: Int,
        totalTrainingSessions: Int,
        totalSocialEvents: Int,
        photoCount: Int,
        dayStats: [DayStats]
    ) {
        self.month = month
        self.puppyName = puppyName
        self.totalWalks = totalWalks
        self.totalWalkMinutes = totalWalkMinutes
        self.totalPottyEvents = totalPottyEvents
        self.outdoorPottyCount = outdoorPottyCount
        self.totalTrainingSessions = totalTrainingSessions
        self.totalSocialEvents = totalSocialEvents
        self.photoCount = photoCount
        self.dayStats = dayStats
    }

    // MARK: - Computed Properties

    /// Number of days with at least one walk
    public var daysWithWalks: Int {
        dayStats.filter { $0.walks > 0 }.count
    }

    /// Outdoor potty percentage (0-100)
    public var outdoorPottyPercentage: Int {
        guard totalPottyEvents > 0 else { return 0 }
        return Int(round(Double(outdoorPottyCount) / Double(totalPottyEvents) * 100))
    }

    /// Localized month name (e.g., "February 2026")
    public var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    /// Short month name (e.g., "Feb")
    public var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: month)
    }

    /// Formatted walk duration (e.g., "3.5 hours" or "45 min")
    public var formattedWalkDuration: String {
        if totalWalkMinutes >= 60 {
            let hours = Double(totalWalkMinutes) / 60.0
            let formatted = hours.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", hours)
                : String(format: "%.1f", hours)
            return "\(formatted)h"
        } else {
            return "\(totalWalkMinutes)m"
        }
    }

    /// Number of days in the month
    public var daysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)
        return range?.count ?? 30
    }

    /// Whether this month has meaningful data to show
    public var hasData: Bool {
        totalWalks > 0 || totalPottyEvents > 0 || totalTrainingSessions > 0 || totalSocialEvents > 0
    }
}

// MARK: - Month Calculations

/// Utility for calculating monthly statistics
public struct MonthCalculations {

    /// Calculate stats for a specific month
    /// - Parameters:
    ///   - month: Any date within the target month
    ///   - puppyName: Name of the puppy
    ///   - events: All events to analyze (will be filtered to the month)
    /// - Returns: MonthSummaryStats for the specified month
    public static func calculateMonthStats(
        month: Date,
        puppyName: String,
        events: [PuppyEvent]
    ) -> MonthSummaryStats {
        let calendar = Calendar.current

        // Get month boundaries
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return MonthSummaryStats(
                month: month,
                puppyName: puppyName,
                totalWalks: 0,
                totalWalkMinutes: 0,
                totalPottyEvents: 0,
                outdoorPottyCount: 0,
                totalTrainingSessions: 0,
                totalSocialEvents: 0,
                photoCount: 0,
                dayStats: []
            )
        }

        // Filter events to this month
        let monthEvents = events.filter { event in
            event.time >= startOfMonth && event.time <= endOfMonth.endOfDay
        }

        // Aggregate stats
        var totalWalks = 0
        var totalWalkMinutes = 0
        var totalPottyEvents = 0
        var outdoorPottyCount = 0
        var totalTrainingSessions = 0
        var totalSocialEvents = 0
        var photoCount = 0

        // Track per-day stats
        var eventsByDay: [Date: [PuppyEvent]] = [:]

        for event in monthEvents {
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

        // Build day stats for each day
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        var dayStats: [DayStats] = []

        for day in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEvents = eventsByDay[dayStart] ?? []

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

            dayStats.append(DayStats(
                date: date,
                outdoorPotty: outdoorPotty,
                indoorPotty: indoorPotty,
                meals: meals,
                walks: walks,
                sleepHours: 0, // Sleep calculation not needed for month recap
                trainingSessions: trainingSessions
            ))
        }

        return MonthSummaryStats(
            month: startOfMonth,
            puppyName: puppyName,
            totalWalks: totalWalks,
            totalWalkMinutes: totalWalkMinutes,
            totalPottyEvents: totalPottyEvents,
            outdoorPottyCount: outdoorPottyCount,
            totalTrainingSessions: totalTrainingSessions,
            totalSocialEvents: totalSocialEvents,
            photoCount: photoCount,
            dayStats: dayStats
        )
    }

    /// Get available months that have events
    /// - Parameter events: All events to analyze
    /// - Returns: Array of dates representing the start of each month with events, sorted descending
    public static func availableMonths(from events: [PuppyEvent]) -> [Date] {
        let calendar = Calendar.current
        var months = Set<Date>()

        for event in events {
            let components = calendar.dateComponents([.year, .month], from: event.time)
            if let monthStart = calendar.date(from: components) {
                months.insert(monthStart)
            }
        }

        return months.sorted(by: >)
    }

    /// Get events with photos for a specific month
    /// - Parameters:
    ///   - month: Any date within the target month
    ///   - events: All events to analyze
    /// - Returns: Events with photos, sorted by date descending
    public static func photoEvents(for month: Date, from events: [PuppyEvent]) -> [PuppyEvent] {
        let calendar = Calendar.current

        let components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }

        return events
            .filter { event in
                event.time >= startOfMonth &&
                event.time <= endOfMonth.endOfDay &&
                event.media.hasPhoto
            }
            .sorted { $0.time > $1.time }
    }
}

// MARK: - Date Helpers

extension Date {
    /// Start of the month for this date
    public var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of the month for this date
    public var endOfMonth: Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
    }

    /// Day of month (1-31)
    public var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Whether this date is near the end of the month (days 28-31)
    public var isNearEndOfMonth: Bool {
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: self)?.count ?? 30
        return dayOfMonth >= min(28, daysInMonth - 3)
    }

    /// Whether this date is at the start of the month (days 1-3)
    public var isStartOfMonth: Bool {
        dayOfMonth <= 3
    }

    /// Get the previous month
    public var previousMonth: Date {
        addingMonths(-1)
    }
}
