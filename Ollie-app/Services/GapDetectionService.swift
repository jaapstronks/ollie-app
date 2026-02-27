//
//  GapDetectionService.swift
//  Ollie-app
//
//  Service for detecting when a coverage gap should be prompted
//

import Foundation
import OllieShared

/// Service for detecting when to prompt for coverage gaps
struct GapDetectionService {

    /// Hours of no events before prompting about a coverage gap
    static let thresholdHours = 16

    /// Check if we should prompt the user about a potential coverage gap
    /// - Parameter lastEventTime: The time of the most recent event
    /// - Returns: True if enough time has passed to suggest a coverage gap
    static func shouldPromptForGap(lastEventTime: Date?) -> Bool {
        guard let lastEvent = lastEventTime else { return false }

        let hoursSinceLastEvent = Date().timeIntervalSince(lastEvent) / 3600
        return hoursSinceLastEvent >= Double(thresholdHours)
    }

    /// Calculate suggested time range for a coverage gap
    /// - Parameter lastEventTime: The time of the most recent event
    /// - Returns: Suggested start and end times for the gap
    static func suggestedGapRange(lastEventTime: Date?) -> (start: Date, end: Date)? {
        guard let lastEvent = lastEventTime else { return nil }

        // Start gap from the last event time
        // End gap at current time (user can adjust)
        return (start: lastEvent, end: Date())
    }

    /// Calculate hours since last event (for display)
    static func hoursSinceLastEvent(lastEventTime: Date?) -> Int? {
        guard let lastEvent = lastEventTime else { return nil }
        return Int(Date().timeIntervalSince(lastEvent) / 3600)
    }
}
