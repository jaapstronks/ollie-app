//
//  PerformanceDebug.swift
//  Otis-app
//
//  Toggles to help isolate performance issues.
//  Set flags to `true` to DISABLE features for testing.
//
//  HOW TO USE:
//  1. First, set `logObjectWillChange = true` to see which services trigger updates
//  2. Run the app and watch the console - identify which services fire frequently
//  3. Then set individual toggles to `true` one at a time:
//     - If the slowness disappears, you've found the culprit
//     - If not, revert to `false` and try the next toggle
//  4. Once identified, fix the root cause and revert all toggles to `false`
//
//  QUICK TEST ORDER (most likely culprits first):
//  1. disableObjectWillChangeForwarding - stops cascade updates
//  2. disableStatsRefresh - stops heavy stats calculations
//  3. disableHistoricalRefresh - stops background Core Data fetches
//  4. disablePredictions - stops prediction calculations
//  5. disableAINudges - stops AI network requests
//  6. disableSkeletons - stops shimmer animations
//  7. disablePhotoLoading - stops async image loading
//

import Foundation

/// Performance debugging toggles - disable features to isolate slowness
/// After identifying the culprit, revert all to `false`
enum PerformanceDebug {

    // MARK: - Feature Toggles (set to true to DISABLE)

    /// Disable AI nudge orchestrator (prevents AI requests and reordering)
    static let disableAINudges = false

    /// Disable AI cards entirely (morning briefing, potty analysis, etc.)
    static let disableAICards = false

    /// Disable skeleton/shimmer animations
    static let disableSkeletons = false

    /// Disable TimelineStatsCache refresh (uses stale data)
    static let disableStatsRefresh = false

    /// Disable EventDataProvider historical refresh (only today's events)
    static let disableHistoricalRefresh = false

    /// Disable prediction service refresh
    static let disablePredictions = false

    /// Disable objectWillChange forwarding from sub-services
    static let disableObjectWillChangeForwarding = false

    /// Disable photo loading in timeline
    static let disablePhotoLoading = false

    // MARK: - Logging

    /// Log when expensive operations occur
    static let logExpensiveOperations = false

    /// Log objectWillChange notifications
    static let logObjectWillChange = false
}
