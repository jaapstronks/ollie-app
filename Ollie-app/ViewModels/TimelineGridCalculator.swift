//
//  TimelineGridCalculator.swift
//  Otis-app
//
//  Helper for calculating Y positions and heights in the 24-hour timeline grid

import SwiftUI

/// Calculator for positioning items in a 24-hour vertical timeline grid
/// Timeline is INVERTED: recent times at top (small y), midnight at bottom (large y)
/// This allows the most recent events to appear first when scrolling
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

    /// Y position for a given time (INVERTED: later times have smaller y, earlier times have larger y)
    /// - 23:59 → y ≈ 0 (top of grid)
    /// - 00:00 → y = 24 * hourHeight (bottom of grid)
    /// - Parameter time: The time to calculate position for
    /// - Returns: Y offset from top of grid
    func yPosition(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let hour = CGFloat(components.hour ?? 0)
        let minute = CGFloat(components.minute ?? 0)

        // INVERTED: subtract from 24 so later times are at top
        let timeInHours = hour + minute / 60.0
        return (24.0 - timeInHours) * hourHeight
    }

    /// Height for a duration block between two times
    /// - Parameters:
    ///   - start: Start time
    ///   - end: End time
    /// - Returns: Height in points (always positive)
    func blockHeight(from start: Date, to end: Date) -> CGFloat {
        let duration = abs(end.timeIntervalSince(start))
        let hours = duration / 3600.0
        return CGFloat(hours) * hourHeight
    }

    /// Y position for a specific hour (0-23)
    /// INVERTED: hour 23 is near top, hour 0 is at bottom
    func yPosition(forHour hour: Int) -> CGFloat {
        CGFloat(24 - hour) * hourHeight
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
