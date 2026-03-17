//
//  DateHelpers.swift
//  OtisShared
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
    nonisolated(unsafe) public static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// ISO 8601 with fractional seconds
    nonisolated(unsafe) public static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone, .withFractionalSeconds]
        return formatter
    }()

    /// Localized medium date (e.g., "Mar 8, 2026" in en_US, "8 mrt 2026" in nl_NL)
    /// Uses system locale for proper localization
    public static let localizedMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
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

    /// Check if this date is within the last N days (from now)
    public func isWithinLastDays(_ days: Int) -> Bool {
        self >= Date.daysAgo(days)
    }

    /// Check if this date falls within a specific date range (inclusive)
    public func isBetween(_ start: Date, and end: Date) -> Bool {
        self >= start && self < end
    }

    /// Check if this date is within the "this week" window (last 7 days)
    public var isThisWeek: Bool {
        isWithinLastDays(7)
    }

    /// Check if this date is within the "last week" window (7-14 days ago)
    public var isLastWeek: Bool {
        isBetween(Date.daysAgo(14), and: Date.daysAgo(7))
    }

    /// Check if this date is within the "this month" window (last 30 days)
    public var isThisMonth: Bool {
        isWithinLastDays(30)
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

    /// Add months to date
    public func addingMonths(_ months: Int) -> Date {
        AppCalendar.current.date(byAdding: .month, value: months, to: self)!
    }

    /// Add years to date
    public func addingYears(_ years: Int) -> Date {
        AppCalendar.current.date(byAdding: .year, value: years, to: self)!
    }

    /// Add hours to date
    public func addingHours(_ hours: Int) -> Date {
        AppCalendar.current.date(byAdding: .hour, value: hours, to: self)!
    }

    /// Add minutes to date
    public func addingMinutes(_ minutes: Int) -> Date {
        AppCalendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    // MARK: - Convenience Past/Future Dates

    /// Get a date N days ago from now
    public static func daysAgo(_ days: Int) -> Date {
        Date().addingDays(-days)
    }

    /// Get a date N weeks ago from now
    public static func weeksAgo(_ weeks: Int) -> Date {
        Date().addingWeeks(-weeks)
    }

    /// Get a date N months ago from now
    public static func monthsAgo(_ months: Int) -> Date {
        Date().addingMonths(-months)
    }

    /// Get a date N days from now
    public static func daysFromNow(_ days: Int) -> Date {
        Date().addingDays(days)
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

    /// Milliseconds since another date
    public func millisecondsSince(_ other: Date) -> Int {
        Int(timeIntervalSince(other) * 1000)
    }

    /// Hours since another date (fractional)
    public func hoursSince(_ other: Date) -> Double {
        timeIntervalSince(other) / 3600
    }

    // MARK: - Caching Stamps

    /// Format as YYYY-MM-DD for cache keys and budget tracking
    public func dayStamp() -> String {
        dateString
    }

    /// Format as YYYY-MM-DD-HH for hourly cache keys
    public func hourStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// Format as YYYY-MM-DD-W where W is the window bucket for cache keys
    /// Groups hours into buckets (e.g., hours=6 creates 4 buckets per day: 0, 1, 2, 3)
    public func windowStamp(hours: Int) -> String {
        let hour = AppCalendar.current.component(.hour, from: self)
        let bucket = max(1, hours)
        let window = hour / bucket
        return "\(dateString)-\(window)"
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

    // MARK: - Localized Display Formatting

    /// Format as localized medium date (e.g., "Mar 8, 2026" or "8 mrt 2026")
    /// Uses system locale for proper localization
    public func formattedMedium() -> String {
        DateFormatters.localizedMedium.string(from: self)
    }

    /// Format as relative time (e.g., "2h ago", "yesterday")
    /// - Parameter style: The units style for the formatter (default: .abbreviated)
    public func relativeFormatted(style: RelativeDateTimeFormatter.UnitsStyle = .abbreviated) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = style
        return formatter.localizedString(for: self, relativeTo: Date())
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
    /// Natural language for notifications: "an hour", "45 minutes", "an hour and a half"
    case naturalLanguage
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

        case .naturalLanguage:
            return formatNaturalLanguage(minutes)
        }
    }

    /// Format minutes as natural language (e.g., "an hour", "45 minutes", "an hour and a half")
    private static func formatNaturalLanguage(_ minutes: Int) -> String {
        switch minutes {
        case 0..<2:
            return Strings.Duration.aMoment
        case 2..<5:
            return Strings.Duration.aFewMinutes
        case 25...35:
            return Strings.Duration.halfAnHour
        case 55...65:
            return Strings.Duration.anHour
        case 85...95:
            return Strings.Duration.anHourAndAHalf
        case 115...125:
            return Strings.Duration.twoHours
        default:
            // For other values, use numeric format with "minutes" or "hours"
            if minutes < 60 {
                return Strings.Duration.minutesNatural(minutes)
            } else {
                let hours = minutes / 60
                let remainingMins = minutes % 60
                if remainingMins < 10 {
                    return Strings.Duration.aboutHours(hours)
                } else if remainingMins >= 25 && remainingMins <= 35 {
                    return Strings.Duration.hoursAndAHalf(hours)
                } else {
                    return Strings.Duration.aboutHours(hours)
                }
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
