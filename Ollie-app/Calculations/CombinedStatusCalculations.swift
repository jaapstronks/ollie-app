//
//  CombinedStatusCalculations.swift
//  Otis-app
//
//  Combined sleep + potty state machine for intelligent status card display
//  Prevents conflicting messages like "needs to pee NOW" while sleeping

import Foundation
import OtisShared

/// Combined state for sleep + potty status display
/// Determines which card(s) to show based on current conditions
enum CombinedSleepPottyState: Equatable {
    /// Puppy is awake - show normal separate cards
    case awake

    /// Sleeping, potty is not urgent - show only sleep card, hide potty card
    case sleepingPottyOkay(sleepingSince: Date, sleepDurationMin: Int)

    /// Sleeping, but potty is urgent/overdue - show combined card
    case sleepingPottyUrgent(
        sleepingSince: Date,
        sleepDurationMin: Int,
        pottyUrgency: PottyUrgency,
        minutesOverdue: Int?
    )

    /// Just woke up and potty was urgent while sleeping - show post-wake prompt
    case justWokeNeedsPotty(
        wokeAt: Date,
        minutesSinceWake: Int,
        pottyWasOverdueBy: Int?
    )

    /// User likely forgot to log overnight sleep - show assumed sleep card
    /// This replaces misleading "awake for X hours" messages in the morning
    case assumedOvernightSleep(
        suggestedSleepStart: Date,
        minutesSleeping: Int,
        lastEventTime: Date?
    )

    /// Unknown state - show nothing special
    case unknown

    /// Stale logging state - user hasn't logged events for a while during daytime
    /// Shows a "Start fresh" prompt instead of misleading status cards
    case staleLogging(
        hoursSinceLastEvent: Int,
        lastEventTime: Date?
    )

    /// First run state - user just completed onboarding and has no logged events yet
    /// Shows a friendly welcome prompt instead of misleading "missed meal" reminders
    case firstRun(puppyName: String)

    // MARK: - Computed Properties

    /// Whether the puppy is currently sleeping
    var isSleeping: Bool {
        switch self {
        case .sleepingPottyOkay, .sleepingPottyUrgent, .assumedOvernightSleep:
            return true
        default:
            return false
        }
    }

    /// Whether we should show the post-wake potty prompt
    var shouldShowPostWakePrompt: Bool {
        if case .justWokeNeedsPotty = self { return true }
        return false
    }

    /// Whether we should show the combined sleep+potty card
    var shouldShowCombinedCard: Bool {
        if case .sleepingPottyUrgent = self { return true }
        return false
    }

    /// Whether we should show the assumed overnight sleep card
    var shouldShowAssumedSleepCard: Bool {
        if case .assumedOvernightSleep = self { return true }
        return false
    }

    /// Whether we should show the stale logging banner
    var shouldShowStaleLoggingBanner: Bool {
        if case .staleLogging = self { return true }
        return false
    }

    /// Whether we should show the first run welcome card
    var shouldShowFirstRunCard: Bool {
        if case .firstRun = self { return true }
        return false
    }

    /// Whether we should show normal separate cards
    var shouldShowSeparateCards: Bool {
        if case .awake = self { return true }
        return false
    }

    /// Whether we should hide the standalone potty card
    var shouldHidePottyCard: Bool {
        switch self {
        case .sleepingPottyOkay, .sleepingPottyUrgent, .justWokeNeedsPotty, .assumedOvernightSleep, .staleLogging, .firstRun:
            return true
        default:
            return false
        }
    }

    /// Whether we should hide the standalone sleep card
    var shouldHideSleepCard: Bool {
        switch self {
        case .sleepingPottyUrgent, .assumedOvernightSleep, .staleLogging, .firstRun:
            return true
        default:
            return false
        }
    }
}

/// Potty urgency level captured at wake time (for post-wake tracking)
struct WakeTimePottyState: Equatable {
    let capturedAt: Date
    let wasOverdue: Bool
    let minutesOverdue: Int?
    let minutesSinceLast: Int?

    /// Duration in minutes to show the post-wake prompt
    static let postWakePromptDurationMinutes = 10

    /// Whether the post-wake prompt has expired
    var hasExpired: Bool {
        let minutesSinceWake = Date().minutesSince(capturedAt)
        return minutesSinceWake >= Self.postWakePromptDurationMinutes
    }
}

/// Calculations for combined sleep + potty state
struct CombinedStatusCalculations {

    // MARK: - Constants

    /// Default assumed bedtime (11 PM) if no historical data
    static let defaultBedtimeHour = 23

    /// Minimum hours "awake" to trigger assumed overnight sleep detection
    static let minAwakeHoursForOvernightAssumption = 6

    /// Morning window during which we check for assumed overnight sleep (5 AM - 11 AM)
    static let morningWindowStart = 5
    static let morningWindowEnd = 11

    /// Hours of no events during daytime to trigger stale logging state
    static let staleLoggingThresholdHours = 4

    /// Daytime window during which stale logging detection applies (7 AM - 11 PM)
    static let daytimeWindowStart = 7
    static let daytimeWindowEnd = 23

    // MARK: - Public Methods

    /// Calculate the combined state based on sleep and potty status
    /// - Parameters:
    ///   - sleepState: Current sleep state (sleeping, awake, unknown)
    ///   - pottyPrediction: Current potty prediction with urgency
    ///   - wakeTimePottyState: Captured potty state at wake time (if any)
    ///   - recentEvents: Events from today and yesterday (for overnight sleep detection)
    ///   - dismissedAssumedSleepDate: Date when assumed sleep was dismissed (if any)
    ///   - hasActiveCoverageGap: Whether there's an active coverage gap (tracking paused)
    ///   - dismissedStaleLoggingDate: Date when stale logging was dismissed (if any)
    /// - Returns: Combined state for display logic
    static func calculateCombinedState(
        sleepState: SleepState,
        pottyPrediction: PottyPrediction,
        wakeTimePottyState: WakeTimePottyState?,
        recentEvents: [PuppyEvent] = [],
        dismissedAssumedSleepDate: Date? = nil,
        hasActiveCoverageGap: Bool = false,
        dismissedStaleLoggingDate: Date? = nil
    ) -> CombinedSleepPottyState {

        // Check for post-wake state first (takes priority if just woke with urgent potty)
        if let wakeState = wakeTimePottyState,
           wakeState.wasOverdue,
           !wakeState.hasExpired,
           sleepState.isAwake {
            let minutesSinceWake = Date().minutesSince(wakeState.capturedAt)
            return .justWokeNeedsPotty(
                wokeAt: wakeState.capturedAt,
                minutesSinceWake: minutesSinceWake,
                pottyWasOverdueBy: wakeState.minutesOverdue
            )
        }

        // Check for stale logging (only if no active coverage gap)
        // This takes priority over misleading states like "awake for 10 hours"
        if !hasActiveCoverageGap,
           let staleState = checkForStaleLogging(
               recentEvents: recentEvents,
               dismissedDate: dismissedStaleLoggingDate
           ) {
            return staleState
        }

        switch sleepState {
        case .sleeping(let since, let durationMin):
            // Check if potty is urgent while sleeping
            if isPottyUrgent(pottyPrediction.urgency) {
                return .sleepingPottyUrgent(
                    sleepingSince: since,
                    sleepDurationMin: durationMin,
                    pottyUrgency: pottyPrediction.urgency,
                    minutesOverdue: minutesOverdue(from: pottyPrediction.urgency)
                )
            } else {
                return .sleepingPottyOkay(
                    sleepingSince: since,
                    sleepDurationMin: durationMin
                )
            }

        case .awake(let since, let durationMin):
            // Check if this looks like forgotten overnight sleep
            if let assumedState = checkForAssumedOvernightSleep(
                awakeSince: since,
                awakeDurationMin: durationMin,
                recentEvents: recentEvents,
                dismissedDate: dismissedAssumedSleepDate
            ) {
                return assumedState
            }
            return .awake

        case .unknown:
            // Also check for assumed overnight sleep when state is unknown
            // This can happen if no sleep events exist at all
            if let assumedState = checkForAssumedOvernightSleepFromEvents(
                recentEvents: recentEvents,
                dismissedDate: dismissedAssumedSleepDate
            ) {
                return assumedState
            }
            return .unknown
        }
    }

    /// Calculate combined state (legacy method without events - for backward compatibility)
    static func calculateCombinedState(
        sleepState: SleepState,
        pottyPrediction: PottyPrediction,
        wakeTimePottyState: WakeTimePottyState?
    ) -> CombinedSleepPottyState {
        return calculateCombinedState(
            sleepState: sleepState,
            pottyPrediction: pottyPrediction,
            wakeTimePottyState: wakeTimePottyState,
            recentEvents: [],
            dismissedAssumedSleepDate: nil
        )
    }

    /// Capture the potty state at wake time (for post-wake tracking)
    /// - Parameter pottyPrediction: Current potty prediction
    /// - Returns: Captured state if potty was urgent, nil otherwise
    static func captureWakeTimePottyState(
        pottyPrediction: PottyPrediction
    ) -> WakeTimePottyState? {
        let overdue = minutesOverdue(from: pottyPrediction.urgency)
        let isUrgent = isPottyUrgent(pottyPrediction.urgency)

        // Only capture if potty was soon or overdue
        guard isUrgent else { return nil }

        return WakeTimePottyState(
            capturedAt: Date(),
            wasOverdue: overdue != nil && overdue! > 0,
            minutesOverdue: overdue,
            minutesSinceLast: pottyPrediction.minutesSinceLast
        )
    }

    /// Check if the captured wake state should be cleared
    /// (e.g., potty was logged, or timeout expired)
    static func shouldClearWakeState(
        wakeState: WakeTimePottyState?,
        pottyWasLoggedSince: Date?
    ) -> Bool {
        guard let wakeState = wakeState else { return false }

        // Clear if expired
        if wakeState.hasExpired { return true }

        // Clear if potty was logged after wake
        if let logTime = pottyWasLoggedSince, logTime > wakeState.capturedAt {
            return true
        }

        return false
    }

    // MARK: - Private Helpers

    /// Check if potty urgency is at a level we consider "urgent"
    /// (soon, overdue, or post-accident)
    private static func isPottyUrgent(_ urgency: PottyUrgency) -> Bool {
        switch urgency {
        case .soon, .overdue, .postAccident:
            return true
        default:
            return false
        }
    }

    /// Extract minutes overdue from urgency (if applicable)
    private static func minutesOverdue(from urgency: PottyUrgency) -> Int? {
        switch urgency {
        case .overdue(let minutes):
            return minutes
        case .soon(let remaining) where remaining <= 0:
            return 0
        default:
            return nil
        }
    }

    // MARK: - Assumed Overnight Sleep Detection

    /// Check if "awake" state looks like the user forgot to log overnight sleep
    /// Returns nil if not applicable, otherwise returns the assumed sleep state
    private static func checkForAssumedOvernightSleep(
        awakeSince: Date,
        awakeDurationMin: Int,
        recentEvents: [PuppyEvent],
        dismissedDate: Date?
    ) -> CombinedSleepPottyState? {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Only check during morning window (5 AM - 11 AM)
        guard currentHour >= morningWindowStart && currentHour < morningWindowEnd else {
            return nil
        }

        // Only trigger if "awake" for unrealistically long time (> 6 hours overnight)
        let minAwakeMinutes = minAwakeHoursForOvernightAssumption * 60
        guard awakeDurationMin >= minAwakeMinutes else {
            return nil
        }

        // Check if user already dismissed this today
        if let dismissedDate = dismissedDate,
           calendar.isDateInToday(dismissedDate) {
            return nil
        }

        // Check if there was a sleep event logged overnight (after 9 PM yesterday or before now)
        let yesterday = now.addingDays(-1)
        let yesterdayAt9PM = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: yesterday)!

        let overnightSleepEvents = recentEvents.filter { event in
            let isSleepType = event.type == .slapen
            let isAfterYesterday9PM = event.time >= yesterdayAt9PM
            let isBeforeNow = event.time <= now
            return isSleepType && isAfterYesterday9PM && isBeforeNow
        }

        // If there's already an overnight sleep event, don't show assumed sleep
        if !overnightSleepEvents.isEmpty {
            return nil
        }

        // Calculate suggested sleep start time
        let suggestedSleepStart = calculateSuggestedBedtime(
            recentEvents: recentEvents,
            yesterday: yesterday
        )

        let minutesSleeping = Int(now.timeIntervalSince(suggestedSleepStart) / 60)

        // Find last event time for context
        let lastEventTime = recentEvents
            .filter { $0.time < now }
            .max(by: { $0.time < $1.time })?.time

        return .assumedOvernightSleep(
            suggestedSleepStart: suggestedSleepStart,
            minutesSleeping: minutesSleeping,
            lastEventTime: lastEventTime
        )
    }

    /// Check for assumed overnight sleep when SleepState is .unknown
    /// (no sleep events exist at all)
    private static func checkForAssumedOvernightSleepFromEvents(
        recentEvents: [PuppyEvent],
        dismissedDate: Date?
    ) -> CombinedSleepPottyState? {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Only check during morning window
        guard currentHour >= morningWindowStart && currentHour < morningWindowEnd else {
            return nil
        }

        // Check if user already dismissed this today
        if let dismissedDate = dismissedDate,
           calendar.isDateInToday(dismissedDate) {
            return nil
        }

        // If there are events from the previous day but no sleep logged,
        // suggest overnight sleep
        let yesterday = now.addingDays(-1)
        let startOfYesterday = calendar.startOfDay(for: yesterday)

        let yesterdayEvents = recentEvents.filter { event in
            event.time >= startOfYesterday && event.time < calendar.startOfDay(for: now)
        }

        // Only trigger if there were events yesterday but no sleep today
        guard !yesterdayEvents.isEmpty else {
            return nil
        }

        let suggestedSleepStart = calculateSuggestedBedtime(
            recentEvents: recentEvents,
            yesterday: yesterday
        )

        let minutesSleeping = Int(now.timeIntervalSince(suggestedSleepStart) / 60)

        let lastEventTime = yesterdayEvents
            .max(by: { $0.time < $1.time })?.time

        return .assumedOvernightSleep(
            suggestedSleepStart: suggestedSleepStart,
            minutesSleeping: minutesSleeping,
            lastEventTime: lastEventTime
        )
    }

    /// Calculate suggested bedtime based on events and defaults
    /// - Returns suggested sleep start time (previous night)
    private static func calculateSuggestedBedtime(
        recentEvents: [PuppyEvent],
        yesterday: Date
    ) -> Date {
        let calendar = Calendar.current

        // Find the last significant event from yesterday evening (after 8 PM)
        let yesterdayAt8PM = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!
        let endOfYesterday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!

        let eveningEvents = recentEvents.filter { event in
            // Only consider activity events (potty, meal, walk) - not sleep/wake
            let isActivityType = [EventType.plassen, .poepen, .eten, .uitlaten, .tuin].contains(event.type)
            return isActivityType && event.time >= yesterdayAt8PM && event.time <= endOfYesterday
        }

        // If there's a late evening event, assume sleep started shortly after
        if let lastEveningEvent = eveningEvents.max(by: { $0.time < $1.time }) {
            let eventHour = calendar.component(.hour, from: lastEveningEvent.time)

            // If event was after 11 PM, assume sleep at 23:59
            if eventHour >= 23 {
                return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: yesterday)!
            }

            // Otherwise, assume sleep ~15-30 minutes after last activity
            return lastEveningEvent.time.addingTimeInterval(20 * 60)
        }

        // Default: assume sleep at 11 PM
        return calendar.date(bySettingHour: defaultBedtimeHour, minute: 0, second: 0, of: yesterday)!
    }

    // MARK: - Stale Logging Detection

    /// Check if logging has gone stale (too long without events during daytime)
    /// Returns nil if not applicable, otherwise returns the stale logging state
    private static func checkForStaleLogging(
        recentEvents: [PuppyEvent],
        dismissedDate: Date?
    ) -> CombinedSleepPottyState? {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Only check during daytime hours (7 AM - 11 PM)
        guard currentHour >= daytimeWindowStart && currentHour < daytimeWindowEnd else {
            return nil
        }

        // Check if user already dismissed stale logging today
        if let dismissedDate = dismissedDate,
           calendar.isDateInToday(dismissedDate) {
            return nil
        }

        // Find the last event (excluding coverage gaps)
        let lastEvent = recentEvents
            .filter { $0.type != .coverageGap }
            .max(by: { $0.time < $1.time })

        guard let lastEventTime = lastEvent?.time else {
            // No events at all - could be a new user, don't show stale banner
            return nil
        }

        // Calculate hours since last event
        let hoursSinceLastEvent = Int(now.timeIntervalSince(lastEventTime) / 3600)

        // Only trigger if enough time has passed
        guard hoursSinceLastEvent >= staleLoggingThresholdHours else {
            return nil
        }

        // Don't trigger if last event was overnight (sleeping)
        // Morning window handles this case with assumed overnight sleep
        let lastEventHour = calendar.component(.hour, from: lastEventTime)
        let isLastEventOvernight = lastEventHour >= 21 || lastEventHour < morningWindowStart
        if isLastEventOvernight && currentHour < morningWindowEnd {
            // This should be handled by assumed overnight sleep detection instead
            return nil
        }

        return .staleLogging(
            hoursSinceLastEvent: hoursSinceLastEvent,
            lastEventTime: lastEventTime
        )
    }

}
