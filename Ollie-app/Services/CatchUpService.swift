//
//  CatchUpService.swift
//  Ollie-app
//
//  Service for detecting when user needs to catch up after a logging gap
//

import Foundation
import OllieShared

/// Service for detecting catch-up scenarios and providing smart defaults
struct CatchUpService {

    /// Minimum hours of gap before showing catch-up prompt
    static let minimumGapHours = 3

    /// Maximum hours before switching to coverage gap prompt instead
    static let maximumGapHours = 16

    /// Check if we should show the catch-up prompt
    /// - Parameters:
    ///   - lastEventTime: Time of the most recent event
    ///   - hasActiveCoverageGap: Whether there's an active coverage gap
    /// - Returns: True if catch-up should be shown
    static func shouldShowCatchUp(lastEventTime: Date?, hasActiveCoverageGap: Bool) -> Bool {
        // Don't show if there's an active coverage gap
        guard !hasActiveCoverageGap else { return false }

        guard let lastEvent = lastEventTime else { return false }

        let hoursSinceLastEvent = Date().timeIntervalSince(lastEvent) / 3600

        // Show catch-up for 3-16 hour gaps (after 16h, coverage gap prompt takes over)
        return hoursSinceLastEvent >= Double(minimumGapHours) &&
               hoursSinceLastEvent < Double(maximumGapHours)
    }

    /// Get hours since last event (for display)
    static func hoursSinceLastEvent(_ lastEventTime: Date?) -> Int? {
        guard let lastEvent = lastEventTime else { return nil }
        return Int(Date().timeIntervalSince(lastEvent) / 3600)
    }

    /// Get contextual info for catch-up UI
    static func getCatchUpContext(
        events: [PuppyEvent],
        profile: PuppyProfile?
    ) -> CatchUpContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // Find last events of each type
        let lastPotty = events.filter { $0.type == .plassen && $0.location == .buiten }.max(by: { $0.time < $1.time })
        let lastMeal = events.filter { $0.type == .eten }.max(by: { $0.time < $1.time })
        let lastPoop = events.filter { $0.type == .poepen }.max(by: { $0.time < $1.time })

        // Determine if it's likely nap time based on hour
        let isTypicalNapTime = (hour >= 12 && hour <= 15) || (hour >= 19 && hour <= 21)

        // Check if poop already logged today
        let hasPoopedToday = lastPoop.map { calendar.isDateInToday($0.time) } ?? false

        // Get last meal time for display
        let lastMealTime = lastMeal?.time
        let lastMealDescription: String?
        if let mealTime = lastMealTime {
            if calendar.isDateInToday(mealTime) {
                lastMealDescription = mealTime.timeString
            } else {
                lastMealDescription = "yesterday"
            }
        } else {
            lastMealDescription = nil
        }

        // Suggest sleep state based on time and patterns
        let suggestedSleepState: Bool? = isTypicalNapTime ? true : nil

        // Default time for "since" slider (2 hours ago, but not before last event)
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)
        let lastEventTime = events.max(by: { $0.time < $1.time })?.time ?? twoHoursAgo
        let defaultSinceTime = max(twoHoursAgo, lastEventTime.addingTimeInterval(300)) // At least 5 min after last event

        return CatchUpContext(
            lastEventTime: lastEventTime,
            lastPottyTime: lastPotty?.time,
            lastMealTime: lastMealTime,
            lastMealDescription: lastMealDescription,
            hasPoopedToday: hasPoopedToday,
            suggestedSleepState: suggestedSleepState,
            defaultSinceTime: defaultSinceTime,
            isTypicalNapTime: isTypicalNapTime
        )
    }
}

/// Context for the catch-up UI
struct CatchUpContext: Equatable {
    let lastEventTime: Date
    let lastPottyTime: Date?
    let lastMealTime: Date?
    let lastMealDescription: String?
    let hasPoopedToday: Bool
    let suggestedSleepState: Bool?
    let defaultSinceTime: Date
    let isTypicalNapTime: Bool
}
