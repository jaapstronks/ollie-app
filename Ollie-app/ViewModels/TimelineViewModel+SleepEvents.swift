//
//  TimelineViewModel+SleepEvents.swift
//  Ollie-app
//
//  Sleep-related event methods: overnight sleep, naps, first run, stale logging.
//

import Foundation
import OtisShared

extension TimelineViewModel {

    // MARK: - Assumed Overnight Sleep

    /// Dismiss the assumed overnight sleep card for today
    func dismissAssumedOvernightSleep() {
        dismissedAssumedSleepDate = Date()
        HapticFeedback.selection()
    }

    /// Confirm the assumed overnight sleep with the given start time
    /// This logs a sleep event at the suggested/adjusted start time
    func confirmAssumedOvernightSleep(sleepStartTime: Date) {
        let sleepEvent = PuppyEvent(
            time: sleepStartTime,
            type: .slapen,
            sleepSessionId: UUID(),
            loggedBy: UserIdentityStore.shared.currentUserRecordID
        )
        persistEventWithFeedback(sleepEvent)
        dismissedAssumedSleepDate = Date()
        _ = triggerForcedCelebrationIfEnabled()
    }

    /// Log wake-up for the assumed overnight sleep
    /// This confirms the sleep and logs the wake event at the current time (or specified time)
    func confirmAssumedOvernightSleepAndWakeUp(sleepStartTime: Date, wakeTime: Date = Date()) {
        let loggedBy = UserIdentityStore.shared.currentUserRecordID
        let sessionId = UUID()

        let sleepEvent = PuppyEvent(
            time: sleepStartTime,
            type: .slapen,
            sleepSessionId: sessionId,
            loggedBy: loggedBy
        )
        let wakeEvent = PuppyEvent(
            time: wakeTime,
            type: .ontwaken,
            sleepSessionId: sessionId,
            loggedBy: loggedBy
        )

        // Persist both events (only sync once at the end)
        eventStore.addEvent(sleepEvent)
        eventStore.addEvent(wakeEvent)
        syncEventsFromStore()
        notifyRefreshNotifications()

        dismissedAssumedSleepDate = Date()
        captureWakeTimePottyState()
        HapticFeedback.success()
        _ = triggerForcedCelebrationIfEnabled()
    }

    // MARK: - Stale Logging

    /// Dismiss the stale logging banner for today
    func dismissStaleLogging() {
        dismissedStaleLoggingDate = Date()
        HapticFeedback.selection()
    }

    /// Start fresh after a logging gap
    /// This dismisses the stale state and logs a wake event to establish a new baseline
    func startFreshAfterLoggingGap() {
        let now = Date()
        let wakeEvent = PuppyEvent(
            time: now,
            type: .ontwaken,
            loggedBy: UserIdentityStore.shared.currentUserRecordID
        )
        persistEventWithFeedback(wakeEvent)
        dismissedStaleLoggingDate = now
        _ = triggerForcedCelebrationIfEnabled()
    }

    // MARK: - First Run Welcome

    /// Handle "puppy is sleeping" response from first run welcome
    /// Logs a sleep event to establish a baseline
    func firstRunPuppyIsSleeping() {
        let sleepEvent = PuppyEvent(
            time: Date(),
            type: .slapen,
            loggedBy: UserIdentityStore.shared.currentUserRecordID
        )
        persistEventWithFeedback(sleepEvent)
        dismissFirstRunWelcome()
        _ = triggerForcedCelebrationIfEnabled()
    }

    /// Handle "puppy is awake" response from first run welcome
    /// Logs a wake event to establish a baseline
    func firstRunPuppyIsAwake() {
        let wakeEvent = PuppyEvent(
            time: Date(),
            type: .ontwaken,
            loggedBy: UserIdentityStore.shared.currentUserRecordID
        )
        persistEventWithFeedback(wakeEvent)
        dismissFirstRunWelcome()
        _ = triggerForcedCelebrationIfEnabled()
    }

    /// Dismiss the first run welcome permanently
    func dismissFirstRunWelcome() {
        dismissedFirstRunWelcome = true
        UserDefaults.standard.set(true, forKey: "dismissedFirstRunWelcome")
    }

    // MARK: - Nap Logging

    /// Log a completed nap with start and end time (single-event model with durationMin)
    func logCompletedNap(startTime: Date, endTime: Date, note: String?, napLocation: NapLocation? = nil) {
        let durationMin = max(1, endTime.minutesSince(startTime))
        let sleepEvent = PuppyEvent(
            time: startTime,
            type: .slapen,
            note: note,
            durationMin: durationMin,
            sleepSessionId: UUID(),
            napLocation: napLocation,
            loggedBy: UserIdentityStore.shared.currentUserRecordID
        )
        persistEvent(sleepEvent)
        FeedbackManager.logEvent()

        if !triggerForcedCelebrationIfEnabled() {
            triggerCelebration(.quickLog)
        }
    }

    // MARK: - Private Helpers

    /// Force a full celebration for every event log when the setting is enabled.
    @discardableResult
    func triggerForcedCelebrationIfEnabled() -> Bool {
        let shouldForceCelebrate = UserDefaults.standard.bool(
            forKey: UserPreferences.Key.forceCelebrateEveryLog.rawValue
        )
        guard shouldForceCelebrate else { return false }
        triggerCelebration(.milestone)
        return true
    }
}
