//
//  PuppyContextUtility.swift
//  Otis-app
//
//  Reusable utility for detecting puppy context (napping, stale logging, etc.)
//  Used by nudge cards to provide contextual messages like "While [name] naps..."
//

import Foundation
import OtisShared

/// Utility functions for detecting puppy context states
enum PuppyContextUtility {

    // MARK: - Nap Detection

    /// Check if the puppy is currently napping
    /// - Parameter sleepState: Current sleep state from SleepCalculations
    /// - Returns: true if currently sleeping
    static func isCurrentlyNapping(sleepState: SleepState) -> Bool {
        sleepState.isSleeping
    }

    /// Check if the user has established a pattern of logging naps
    /// Returns nil if insufficient data (< 3 nap sessions logged)
    /// - Parameter events: All historical events
    /// - Returns: true if active nap logging pattern, false if not, nil if insufficient data
    static func hasActiveNapLogging(events: [PuppyEvent]) -> Bool? {
        let calendar = Calendar.current

        // Count nap events (sleep events during daytime hours)
        let napEvents = events.filter { event in
            guard event.type == .slapen else { return false }
            let hour = calendar.component(.hour, from: event.time)
            // Consider daytime naps (6 AM - 10 PM)
            return hour >= 6 && hour < 22
        }

        // Need at least 3 nap sessions to establish a pattern
        guard napEvents.count >= 3 else { return nil }

        // Check if any naps were logged in the last 7 days
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentNaps = napEvents.filter { $0.time >= sevenDaysAgo }

        return !recentNaps.isEmpty
    }

    /// Check if logging has gone stale (4+ hours without events)
    /// Used to determine if contextual messages might be misleading
    /// - Parameter events: Today's events
    /// - Returns: true if 4+ hours since last event
    static func hasStaleLogging(events: [PuppyEvent]) -> Bool {
        // PERF: Use max(by:) O(n) instead of sorted().first O(n log n)
        guard let lastEvent = events.max(by: { $0.time < $1.time }) else {
            // No events today - consider stale
            return true
        }

        let hoursSinceLastEvent = Date().timeIntervalSince(lastEvent.time) / 3600
        return hoursSinceLastEvent >= 4
    }

    // MARK: - Combined Context Check

    /// Check if we should show the "While [name] naps..." context message
    /// Shows when:
    /// - Puppy is currently napping
    /// - User has active nap logging pattern (or we can't determine)
    /// - Logging isn't stale
    /// - Parameter sleepState: Current sleep state
    /// - Parameter events: Today's events
    /// - Returns: true if context message should be shown
    static func shouldShowNapContextMessage(
        sleepState: SleepState,
        events: [PuppyEvent]
    ) -> Bool {
        // Must be currently napping
        guard isCurrentlyNapping(sleepState: sleepState) else { return false }

        // Don't show if logging is stale (might not actually be napping)
        guard !hasStaleLogging(events: events) else { return false }

        // Show if user has active nap logging (or insufficient data to determine)
        let hasActivePattern = hasActiveNapLogging(events: events)
        return hasActivePattern ?? true
    }
}
