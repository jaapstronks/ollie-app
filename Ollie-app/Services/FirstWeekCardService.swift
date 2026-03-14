//
//  FirstWeekCardService.swift
//  Ollie-app
//
//  Manages first week card visibility and collapsed state.
//  Extracted from TimelineViewModel+Predictions for better separation of concerns.
//

import Foundation
import OtisShared

/// Service for managing first week card state
struct FirstWeekCardService {

    // MARK: - UserDefaults Keys

    private static let collapsedDateKey = UserPreferences.Key.firstWeekCardCollapsedDate.rawValue

    // MARK: - Visibility

    /// Whether the first week card should be shown
    /// Shows during days 1-7, dismissable for the day
    static func shouldShowCard(profile: PuppyProfile?, isShowingToday: Bool) -> Bool {
        guard let profile = profile else { return false }
        guard isShowingToday else { return false }

        // Only show during first week (days 1-7)
        guard profile.daysHome >= 1 && profile.daysHome <= 7 else { return false }

        return true
    }

    // MARK: - Collapsed State

    /// Whether the card is currently collapsed (for today)
    static var isCollapsed: Bool {
        isCollapsedToday
    }

    /// Check if card was collapsed today
    private static var isCollapsedToday: Bool {
        guard let collapsedDateString = UserDefaults.standard.string(forKey: collapsedDateKey) else {
            return false
        }

        // Parse the stored date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let collapsedDate = formatter.date(from: collapsedDateString) else {
            return false
        }

        // Check if it was collapsed today
        return Calendar.current.isDateInToday(collapsedDate)
    }

    /// Toggle the collapsed state
    static func toggleCollapsed() {
        if isCollapsedToday {
            // Expand: clear the date
            UserDefaults.standard.removeObject(forKey: collapsedDateKey)
        } else {
            // Collapse: store today's date
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let todayString = formatter.string(from: Date())
            UserDefaults.standard.set(todayString, forKey: collapsedDateKey)
        }
    }

    /// Collapse the card
    static func collapse() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let todayString = formatter.string(from: Date())
        UserDefaults.standard.set(todayString, forKey: collapsedDateKey)
    }

    /// Expand the card
    static func expand() {
        UserDefaults.standard.removeObject(forKey: collapsedDateKey)
    }

    // MARK: - Stats

    /// Calculate first week stats for the card
    /// PERFORMANCE: Prefer the overload with pre-fetched events to avoid blocking main thread
    @MainActor
    static func calculateStats(
        profile: PuppyProfile?,
        todayEvents: [PuppyEvent],
        eventStore: EventStore
    ) -> FirstWeekStats? {
        guard let profile = profile else { return nil }

        // Get yesterday's events
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.startOfDay(for: Date())
        let yesterdayEvents = eventStore.getEvents(from: startOfYesterday, to: endOfYesterday)

        // Get historical events (last 7 days for suppression logic)
        let sevenDaysAgo = Date().addingDays(-7)
        let historicalEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())

        return FirstWeekCalculations.calculateStats(
            profile: profile,
            todayEvents: todayEvents,
            yesterdayEvents: yesterdayEvents,
            historicalEvents: historicalEvents
        )
    }

    /// Calculate first week stats using pre-fetched events
    /// PERFORMANCE: Use this overload with cached events to avoid Core Data fetches
    static func calculateStats(
        profile: PuppyProfile?,
        todayEvents: [PuppyEvent],
        recentEvents: [PuppyEvent],  // Contains yesterday + today events
        weekEvents: [PuppyEvent]     // Contains 7 days of events
    ) -> FirstWeekStats? {
        guard let profile = profile else { return nil }

        // Filter yesterday's events from recent events
        let calendar = Calendar.current
        let yesterdayEvents = recentEvents.filter { calendar.isDateInYesterday($0.time) }

        return FirstWeekCalculations.calculateStats(
            profile: profile,
            todayEvents: todayEvents,
            yesterdayEvents: yesterdayEvents,
            historicalEvents: weekEvents
        )
    }
}
