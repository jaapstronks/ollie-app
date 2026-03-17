//
//  Date+AI.swift
//  Otis-app
//
//  Date extensions for AI nudge orchestration.
//

import Foundation
import OtisShared

extension Date {
    func millisecondsSince(_ start: Date) -> Int {
        Int(timeIntervalSince(start) * 1000)
    }

    func dayStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    func hourStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH"
        return formatter.string(from: self)
    }

    func windowStamp(hours: Int) -> String {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: self)
        let hour = calendar.component(.hour, from: self)
        let bucket = max(1, hours)
        let window = hour / bucket
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: day))-\(window)"
    }

    /// Parse a date string in YYYY-MM-DD format
    static func fromDateString(_ string: String) -> Date? {
        DateFormatters.dateOnly.date(from: string)
    }
}
