//
//  TimelineGridCalculator.swift
//  Ollie-app
//
//  Helper for calculating Y positions and heights in the 24-hour timeline grid

import Foundation

/// Calculator for positioning items in a 24-hour vertical timeline grid
/// Timeline is inverted: future at top (00:00), past at bottom (24:00)
struct TimelineGridCalculator {

    // MARK: - Configuration

    /// Height per hour in points
    let hourHeight: CGFloat

    /// Start of the day (00:00:00)
    let dayStart: Date

    /// End of the day (23:59:59)
    let dayEnd: Date

    // MARK: - Init

    init(for date: Date, hourHeight: CGFloat = LayoutConstants.timelineHourHeight) {
        self.hourHeight = hourHeight
        let calendar = Calendar.current
        self.dayStart = calendar.startOfDay(for: date)
        self.dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)?.addingTimeInterval(-1) ?? dayStart
    }

    // MARK: - Calculated Properties

    /// Total grid height (24 hours)
    var totalHeight: CGFloat {
        24 * hourHeight
    }

    // MARK: - Position Calculations

    /// Y position for a given time (inverted: 00:00 at top, 24:00 at bottom)
    /// - Parameter time: The time to calculate position for
    /// - Returns: Y offset from top of grid
    func yPosition(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let hour = CGFloat(components.hour ?? 0)
        let minute = CGFloat(components.minute ?? 0)

        // Position from top: hours + fraction of hour
        return (hour + minute / 60.0) * hourHeight
    }

    /// Height for a duration block between two times
    /// - Parameters:
    ///   - start: Start time
    ///   - end: End time
    /// - Returns: Height in points
    func blockHeight(from start: Date, to end: Date) -> CGFloat {
        let duration = end.timeIntervalSince(start)
        let hours = duration / 3600.0
        return CGFloat(hours) * hourHeight
    }

    /// Y position for a specific hour (0-23)
    func yPosition(forHour hour: Int) -> CGFloat {
        CGFloat(hour) * hourHeight
    }

    /// Whether a time is within the current day
    func isWithinDay(_ time: Date) -> Bool {
        time >= dayStart && time <= dayEnd
    }

    /// Clamp a time to the current day bounds
    func clampToDay(_ time: Date) -> Date {
        if time < dayStart { return dayStart }
        if time > dayEnd { return dayEnd }
        return time
    }
}
