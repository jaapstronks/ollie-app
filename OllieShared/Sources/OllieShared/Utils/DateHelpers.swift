//
//  DateHelpers.swift
//  OllieShared
//
//  Centralized date formatting and date manipulation utilities.
//  Uses static cached formatters to avoid repeated allocations.

import Foundation

// MARK: - Centralized DateFormatters

/// Cached date formatters for performance
/// DateFormatter is expensive to create, so we cache instances
public enum DateFormatters {
    /// Format: yyyy-MM-dd (for file names)
    public static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Format: HH:mm (24-hour time)
    public static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Format: HH:00 (hour only, for weather forecasts)
    public static let hourOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Format: EEEE d MMMM (Dutch locale, full day name)
    public static let dutchFullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter
    }()

    /// Format: E d MMM (Dutch locale, short)
    public static let dutchShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "E d MMM"
        return formatter
    }()

    /// Format: d MMM yyyy (Dutch locale)
    public static let dutchMediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    /// Format: HH:mm (Dutch locale)
    public static let dutchTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// ISO 8601 with timezone
    public static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// ISO 8601 with fractional seconds
    public static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone, .withFractionalSeconds]
        return formatter
    }()
}

// MARK: - Cached Calendar

/// Cached calendar instance for performance
/// Using a shared instance avoids repeated Calendar.current lookups
public enum AppCalendar {
    public static let current = Calendar.current
}

// MARK: - Date Extensions

extension Date {
    /// Format as YYYY-MM-DD for file names
    public var dateString: String {
        DateFormatters.dateOnly.string(from: self)
    }

    /// Format as HH:mm for display
    public var timeString: String {
        DateFormatters.timeOnly.string(from: self)
    }

    /// Format as HH:00 for display (hour only)
    public var hourString: String {
        DateFormatters.hourOnly.string(from: self)
    }

    /// Format as full ISO 8601 with timezone
    public var iso8601String: String {
        DateFormatters.iso8601.string(from: self)
    }

    /// Parse from ISO 8601 string
    public static func fromISO8601(_ string: String) -> Date? {
        // Try with fractional seconds first
        if let date = DateFormatters.iso8601WithFractional.date(from: string) {
            return date
        }
        // Try without fractional seconds
        return DateFormatters.iso8601.date(from: string)
    }

    // MARK: - Day Boundaries

    /// Start of the day (midnight)
    public var startOfDay: Date {
        AppCalendar.current.startOfDay(for: self)
    }

    /// End of the day (23:59:59)
    public var endOfDay: Date {
        addingDays(1).startOfDay.addingTimeInterval(-1)
    }

    // MARK: - Date Comparisons

    /// Check if this date is today
    public var isToday: Bool {
        AppCalendar.current.isDateInToday(self)
    }

    /// Check if this date is yesterday
    public var isYesterday: Bool {
        AppCalendar.current.isDateInYesterday(self)
    }

    /// Check if this date is tomorrow
    public var isTomorrow: Bool {
        AppCalendar.current.isDateInTomorrow(self)
    }

    /// Check if this date is in the same day as another date
    public func isSameDay(as other: Date) -> Bool {
        AppCalendar.current.isDate(self, inSameDayAs: other)
    }

    // MARK: - Date Arithmetic

    /// Add days to date
    public func addingDays(_ days: Int) -> Date {
        AppCalendar.current.date(byAdding: .day, value: days, to: self)!
    }

    /// Add weeks to date
    public func addingWeeks(_ weeks: Int) -> Date {
        AppCalendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
    }

    /// Add hours to date
    public func addingHours(_ hours: Int) -> Date {
        AppCalendar.current.date(byAdding: .hour, value: hours, to: self)!
    }

    /// Add minutes to date
    public func addingMinutes(_ minutes: Int) -> Date {
        AppCalendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    /// Days since another date
    public func daysSince(_ other: Date) -> Int {
        AppCalendar.current.dateComponents([.day], from: other, to: self).day ?? 0
    }

    /// Weeks since another date
    public func weeksSince(_ other: Date) -> Int {
        AppCalendar.current.dateComponents([.weekOfYear], from: other, to: self).weekOfYear ?? 0
    }

    // MARK: - Date Components

    /// Hour component (0-23)
    public var hour: Int {
        AppCalendar.current.component(.hour, from: self)
    }

    /// Minute component (0-59)
    public var minute: Int {
        AppCalendar.current.component(.minute, from: self)
    }

    /// Day of week (1 = Sunday, 7 = Saturday)
    public var weekday: Int {
        AppCalendar.current.component(.weekday, from: self)
    }

    // MARK: - Time Intervals

    /// Minutes since another date
    public func minutesSince(_ other: Date) -> Int {
        Int(timeIntervalSince(other) / 60)
    }

    /// Hours since another date (fractional)
    public func hoursSince(_ other: Date) -> Double {
        timeIntervalSince(other) / 3600
    }

    // MARK: - Display Formatting

    /// Relative day description (localized)
    public var relativeDayString: String {
        if isToday {
            return Strings.Common.today
        } else if isYesterday {
            return Strings.Common.yesterday
        } else {
            return DateFormatters.dutchFullDate.string(from: self).capitalized
        }
    }

    /// Short date string (E d MMM)
    public var shortDateString: String {
        DateFormatters.dutchShortDate.string(from: self)
    }

    /// Medium date string (d MMM yyyy)
    public var mediumDateString: String {
        DateFormatters.dutchMediumDate.string(from: self)
    }
}

// MARK: - DateFormatter Extensions

extension DateFormatter {
    /// Dutch locale date formatter (convenience for custom formats)
    public static var dutch: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }
}

// MARK: - Duration Formatting

/// Style options for duration formatting
public enum DurationFormatStyle {
    /// Compact format for widgets: "5m", "1h 30m", "--" for zero
    case compact
    /// Full format for app UI: "5 min", "1u 30m"
    case full
}

/// Centralized duration formatting to avoid duplication
public enum DurationFormatter {
    /// Format a duration in minutes for display
    /// - Parameters:
    ///   - minutes: Duration in minutes
    ///   - style: Format style (.compact for widgets, .full for app)
    ///   - showZeroAsEmpty: If true, returns "--" for zero (useful for widgets)
    /// - Returns: Formatted duration string
    public static func format(_ minutes: Int, style: DurationFormatStyle = .full, showZeroAsEmpty: Bool = false) -> String {
        if minutes == 0 && showZeroAsEmpty {
            return "--"
        }

        let hours = minutes / 60
        let mins = minutes % 60

        switch style {
        case .compact:
            if minutes < 60 {
                return "\(minutes)m"
            } else if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }

        case .full:
            if minutes < 60 {
                return "\(minutes) \(Strings.Common.minutes)"
            } else if mins == 0 {
                return "\(hours) \(Strings.Common.hours)"
            } else {
                return "\(hours)u \(mins)m"
            }
        }
    }
}

// Convenience extension for Int
extension Int {
    /// Format this integer as a duration in minutes
    public func formatAsDuration(style: DurationFormatStyle = .full, showZeroAsEmpty: Bool = false) -> String {
        DurationFormatter.format(self, style: style, showZeroAsEmpty: showZeroAsEmpty)
    }
}

// MARK: - Time Parsing Helpers

extension String {
    /// Parse a time string like "08:00" or "14:30" into hour and minute components
    /// - Returns: Tuple of (hour, minute) or nil if parsing fails
    public func parseTimeComponents() -> (hour: Int, minute: Int)? {
        let parts = self.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return (hour, minute)
    }
}

extension Date {
    /// Create a Date from a time string (e.g., "08:00") on a given date
    /// - Parameters:
    ///   - timeString: Time string in "HH:mm" format
    ///   - date: The date to apply the time to (defaults to today)
    /// - Returns: A Date with the specified time on the given date, or nil if parsing fails
    public static func fromTimeString(_ timeString: String, on date: Date = Date()) -> Date? {
        guard let (hour, minute) = timeString.parseTimeComponents() else { return nil }
        var components = AppCalendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return AppCalendar.current.date(from: components)
    }

    /// Create a Date from hour and minute components (without a reference date)
    /// Useful for time pickers where only the time matters
    /// - Parameters:
    ///   - hour: Hour (0-23)
    ///   - minute: Minute (0-59)
    /// - Returns: A Date with the specified time components
    public static func fromTimeComponents(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return AppCalendar.current.date(from: components) ?? Date()
    }
}
