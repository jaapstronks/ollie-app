//
//  DateHelpers.swift
//  Ollie-app
//

import Foundation

extension Date {
    /// Format as YYYY-MM-DD for file names
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// Format as HH:mm for display
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// Format as full ISO 8601 with timezone
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }

    /// Parse from ISO 8601 string
    static func fromISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.date(from: string)
    }

    /// Start of the day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the day (23:59:59)
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }

    /// Check if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Relative day description in Dutch
    var relativeDayString: String {
        if isToday {
            return "Vandaag"
        } else if isYesterday {
            return "Gisteren"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            formatter.dateFormat = "EEEE d MMMM"
            return formatter.string(from: self).capitalized
        }
    }

    /// Minutes since another date
    func minutesSince(_ other: Date) -> Int {
        Int(timeIntervalSince(other) / 60)
    }
}

extension DateFormatter {
    /// Dutch locale date formatter
    static var dutch: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }
}
