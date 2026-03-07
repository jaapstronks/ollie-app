//
//  TrialTouchpoint.swift
//  Otis-app
//
//  Defines strategic touchpoints during the 14-day trial

import Foundation

/// Strategic touchpoints for trial engagement
/// Each touchpoint represents a day in the trial where we show specific content
enum TrialTouchpoint: Int, CaseIterable, Codable {
    /// Day 1: Show first AI insight to demonstrate value
    case day1FirstInsight = 1

    /// Day 3: Engagement notification to bring user back
    case day3Notification = 3

    /// Day 7: Value summary showing what they've accomplished
    case day7ValueSummary = 7

    /// Day 12: Warning that trial is ending soon
    case day12Warning = 12

    /// Day 14: Final conversion opportunity
    case day14Conversion = 14

    /// The day of the trial this touchpoint occurs
    var day: Int {
        rawValue
    }

    /// Whether this touchpoint should show a notification
    var showsNotification: Bool {
        switch self {
        case .day3Notification, .day12Warning:
            return true
        default:
            return false
        }
    }

    /// Whether this touchpoint shows an in-app card
    var showsInAppCard: Bool {
        switch self {
        case .day1FirstInsight, .day7ValueSummary, .day12Warning, .day14Conversion:
            return true
        case .day3Notification:
            return false
        }
    }
}
