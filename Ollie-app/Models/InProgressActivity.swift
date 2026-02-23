//
//  InProgressActivity.swift
//  Ollie-app
//
//  Model for tracking an in-progress activity (walk or nap)

import Foundation

/// Types of activities that can be tracked in real-time
enum ActivityType: String, Codable {
    case walk
    case nap

    /// SF Symbol icon for this activity type
    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .nap: return "moon.zzz.fill"
        }
    }
}

/// Represents an activity currently in progress
struct InProgressActivity: Codable, Equatable {
    let type: ActivityType
    let startTime: Date
    let spotName: String?
    let sleepSessionId: UUID?  // Links nap start/end events

    init(type: ActivityType, startTime: Date, spotName: String? = nil, sleepSessionId: UUID? = nil) {
        self.type = type
        self.startTime = startTime
        self.spotName = spotName
        self.sleepSessionId = sleepSessionId
    }

    /// Duration in minutes since the activity started
    var durationMinutes: Int {
        Int(Date().timeIntervalSince(startTime) / 60)
    }

    /// Formatted duration string (e.g., "25 min" or "1u 15m")
    var durationFormatted: String {
        formatDuration(durationMinutes)
    }

    /// Alias for durationFormatted used by ActivityEndSheet
    var elapsedTimeFormatted: String {
        durationFormatted
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) uur"
            }
            return "\(hours)u \(mins)m"
        }
    }
}
