//
//  DateHelpers.swift
//  Ollie-app
//

import Foundation

enum DateHelpers {
    // Format time as HH:mm
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    // Format date as YYYY-MM-DD for file names
    static func formatDateForFile(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    // Format date for display (e.g., "Woensdag 19 februari")
    static func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }

    // Check if date is today
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    // Get start of day for a date
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    // Get puppy age in weeks
    static func puppyAgeInWeeks(on date: Date = Date()) -> Int {
        let components = Calendar.current.dateComponents([.weekOfYear], from: Constants.birthDate, to: date)
        return components.weekOfYear ?? 0
    }

    // Get days since puppy came home
    static func daysSinceHome(on date: Date = Date()) -> Int {
        let components = Calendar.current.dateComponents([.day], from: Constants.startDate, to: date)
        return components.day ?? 0
    }
}
