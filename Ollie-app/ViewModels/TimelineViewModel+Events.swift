//
//  TimelineViewModel+Events.swift
//  Otis-app
//
//  Event CRUD operations for TimelineViewModel
//

import Foundation
import OtisShared
import SwiftUI

extension TimelineViewModel {
    // MARK: - Quick Log

    func quickLog(type: EventType, suggestedTime: Date? = nil) {
        // Core logging is always free - no paywall check needed

        // Special handling for medications
        if type == .medicatie {
            // Show medication log sheet for selection
            sheetCoordinator.presentSheet(.medicationLog)
            return
        }

        // V2: All events now go through QuickLogSheet for time adjustment
        // Pass suggested time for overdue items (e.g., scheduled meal time)
        sheetCoordinator.presentSheet(.quickLog(type, suggestedTime: suggestedTime))
    }

    /// Quick log with immediate location (used by FAB quick actions)
    func quickLogWithLocation(type: EventType, location: EventLocation) {
        // Core logging is always free - no paywall check needed
        // Log immediately with the provided location
        logEvent(type: type, location: location)
        HapticFeedback.success()
    }

    /// Log event with time, location, and note from QuickLogSheet
    func logFromQuickSheet(time: Date, location: EventLocation?, note: String?) {
        guard let type = pendingEventType else { return }
        logEvent(type: type, time: time, location: location, note: note)
        sheetCoordinator.dismissSheet()
    }

    func cancelQuickLogSheet() {
        sheetCoordinator.dismissSheet()
    }

    // Legacy: kept for backwards compatibility
    func logWithLocation(location: EventLocation) {
        guard let type = pendingEventType else { return }
        logEvent(type: type, location: location)
        sheetCoordinator.dismissSheet()
    }

    func cancelLocationPicker() {
        sheetCoordinator.dismissSheet()
    }

    func openLogSheet(for type: EventType) {
        sheetCoordinator.presentSheet(.logEvent(type))
    }

    func showAllEvents() {
        // Core logging is always free - no paywall check needed
        sheetCoordinator.presentSheet(.allEvents)
    }

    // MARK: - Potty Quick Log (V3: combined plassen/poepen)

    func showPottySheet() {
        // Core logging is always free - no paywall check needed
        sheetCoordinator.presentSheet(.potty())
    }

    func cancelPottySheet() {
        sheetCoordinator.dismissSheet()
    }

    func logPottyEvent(selection: PottySelection, time: Date, location: EventLocation, note: String?) {
        switch selection {
        case .plassen:
            logEvent(type: .plassen, time: time, location: location, note: note)
        case .poepen:
            logEvent(type: .poepen, time: time, location: location, note: note)
        case .beide:
            // Log both events at the same time
            logEvent(type: .plassen, time: time, location: location, note: note)
            logEvent(type: .poepen, time: time, location: location, note: note)
        }

        // Note: Celebration is triggered in logEvent() based on event type
        sheetCoordinator.dismissSheet()
    }

    // MARK: - Quick Log Context

    var quickLogContext: QuickLogContext {
        QuickLogContext(
            sleepState: currentSleepState,
            mealSchedule: profileStore.profile?.mealSchedule,
            todayEvents: events
        )
    }

    // MARK: - Photo Moment Capture

    func openCamera() {
        // Photo/video attachments require Otis+
        guard subscriptionManager.hasAccess(to: .photoVideoAttachments) else {
            sheetCoordinator.presentSheet(.otisPlus)
            return
        }
        sheetCoordinator.presentSheet(.mediaPicker(.camera))
    }

    func openPhotoLibrary() {
        // Photo/video attachments require Otis+
        guard subscriptionManager.hasAccess(to: .photoVideoAttachments) else {
            sheetCoordinator.presentSheet(.otisPlus)
            return
        }
        sheetCoordinator.presentSheet(.mediaPicker(.library))
    }

    func dismissMediaPicker() {
        sheetCoordinator.dismissSheet()
    }

    func showLogMomentSheet() {
        sheetCoordinator.presentSheet(.logMoment)
    }

    func dismissLogMomentSheet() {
        sheetCoordinator.dismissSheet()
    }

    // MARK: - Event CRUD

    func logEvent(
        type: EventType,
        time: Date = Date(),
        location: EventLocation? = nil,
        note: String? = nil,
        who: String? = nil,
        exercise: String? = nil,
        result: String? = nil,
        durationMin: Int? = nil,
        sleepSessionId: UUID? = nil,
        napLocation: NapLocation? = nil
    ) {
        // Get current user's household member ID for attribution
        let loggedBy = profileStore.currentUserMemberId

        // Note: sleepSessionId is auto-generated for sleep events in PuppyEvent init
        let event = PuppyEvent(
            time: time,
            type: type,
            location: location,
            note: note,
            who: who,
            exercise: exercise,
            result: result,
            durationMin: durationMin,
            sleepSessionId: sleepSessionId,
            napLocation: napLocation,
            loggedBy: loggedBy
        )

        // Track potty event time for post-wake state clearing
        if type == .plassen || type == .poepen {
            recordPottyLogTime()
        }

        // Check if this is the user's very first event (before adding)
        let isFirstEvent = events.isEmpty && eventStore.getEvents(
            from: Date.distantPast,
            to: Date()
        ).isEmpty

        eventStore.addEvent(event)

        // Immediately sync events from EventStore to ensure status cards update
        syncEventsFromStore()

        notifyRefreshNotifications()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()

        // Debug override: force a visible celebration for every event log.
        if triggerForcedCelebrationIfEnabled() {
            return
        }

        // Trigger celebration for first-ever event
        if isFirstEvent {
            triggerCelebration(.milestone)
        } else {
            // Trigger celebration based on event type
            triggerCelebrationForEvent(type: type, location: location)
        }
    }

    /// Trigger appropriate celebration for an event type
    private func triggerCelebrationForEvent(type: EventType, location: EventLocation?) {
        switch type {
        case .plassen, .poepen:
            // Outdoor potty gets a celebration with streak count
            if location == .buiten {
                // Get current streak count for the celebration headline
                let currentStreak = streakInfo.currentStreak
                triggerCelebration(.pottySuccess, streakCount: currentStreak)
            }
        case .eten:
            // Meal logged - subtle celebration
            triggerCelebration(.quickLog)
        case .uitlaten:
            // Walk logged
            triggerCelebration(.training)
        case .training:
            // Training session - celebrate!
            triggerCelebration(.training)
        case .sociaal:
            // Socialization - celebrate!
            triggerCelebration(.training)
        default:
            // Other events don't trigger celebrations
            break
        }
    }

    /// Log a walk event with optional spot information and potty events
    func logWalkEvent(
        time: Date = Date(),
        durationMin: Int? = nil,
        didPee: Bool = false,
        didPoop: Bool = false,
        spot: WalkSpot? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        note: String? = nil
    ) {
        // Get current user's household member ID for attribution
        let loggedBy = profileStore.currentUserMemberId

        var walkEvent = PuppyEvent.walk(
            time: time,
            durationMin: durationMin,
            note: note,
            spot: spot,
            latitude: latitude,
            longitude: longitude
        )
        walkEvent.loggedBy = loggedBy

        eventStore.addEvent(walkEvent)

        // Log potty events linked to this walk
        if didPee {
            var peeEvent = PuppyEvent.potty(
                type: .plassen,
                time: time,
                location: .buiten,
                parentWalkId: walkEvent.id
            )
            peeEvent.loggedBy = loggedBy
            eventStore.addEvent(peeEvent)
        }

        if didPoop {
            var poopEvent = PuppyEvent.potty(
                type: .poepen,
                time: time,
                location: .buiten,
                parentWalkId: walkEvent.id
            )
            poopEvent.loggedBy = loggedBy
            eventStore.addEvent(poopEvent)
        }

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        notifyRefreshNotifications()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()

        if !triggerForcedCelebrationIfEnabled() {
            // Celebrate completed walk
            triggerCelebration(.training)
        }
    }

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
            loggedBy: profileStore.currentUserMemberId
        )
        persistEvent(sleepEvent)
        FeedbackManager.logEvent()

        if !triggerForcedCelebrationIfEnabled() {
            triggerCelebration(.quickLog)
        }
    }

    /// Add a pre-built event (used for photo moments)
    func addEvent(_ event: PuppyEvent) {
        persistEvent(event)
        _ = triggerForcedCelebrationIfEnabled()
    }

    /// Update an existing event
    func updateEvent(_ event: PuppyEvent) {
        eventStore.updateEvent(event)

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        // Force refresh stats to ensure week view updates immediately
        notifyForceRefreshStats()
        notifyRefreshNotifications()

        // Sync activity manager if this is the current nap's sleep event
        // This ensures the banner shows the correct start time after editing
        if event.type == .slapen,
           let sessionId = event.sleepSessionId,
           activityManager.currentActivity?.sleepSessionId == sessionId {
            activityManager.updateActivityStartTime(to: event.time)
        }
    }

    /// Show edit sheet for an event
    func editEvent(_ event: PuppyEvent) {
        sheetCoordinator.presentSheet(.editEvent(event))
    }

    // MARK: - Delete with Confirmation

    /// Request to delete an event (shows confirmation)
    func requestDeleteEvent(_ event: PuppyEvent) {
        sheetCoordinator.requestDeleteEvent(event)
    }

    /// Confirm deletion after user approval
    func confirmDeleteEvent() {
        guard let event = sheetCoordinator.eventToDelete else { return }
        deleteEventWithUndo(event)
        sheetCoordinator.clearDeleteConfirmation()
    }

    /// Cancel deletion
    func cancelDeleteEvent() {
        sheetCoordinator.clearDeleteConfirmation()
    }

    /// Binding for delete confirmation dialog
    var showingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { self.sheetCoordinator.showingDeleteConfirmation },
            set: { self.sheetCoordinator.showingDeleteConfirmation = $0 }
        )
    }

    /// Delete event with undo capability
    func deleteEventWithUndo(_ event: PuppyEvent) {
        // If deleting the currently active nap's sleep event, clear the activity
        if event.type == .slapen,
           let activity = currentActivity,
           activity.type == .nap,
           event.sleepSessionId == activity.sleepSessionId {
            currentActivity = nil
        }

        // Actually delete
        eventStore.deleteEvent(event)

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        // Force refresh stats to ensure week view updates immediately
        notifyForceRefreshStats()
        notifyRefreshNotifications()

        HapticFeedback.warning()

        // Show undo banner
        sheetCoordinator.showUndo(for: event)
    }

    /// Direct delete (from swipe, no confirmation needed but with undo)
    func deleteEvent(_ event: PuppyEvent) {
        deleteEventWithUndo(event)
    }

    /// Undo the last deletion
    func undoDelete() {
        guard let event = sheetCoordinator.popLastDeletedEvent() else { return }
        persistEventWithFeedback(event)
        notifyForceRefreshStats()
    }

    /// Dismiss the undo banner
    func dismissUndoBanner() {
        sheetCoordinator.dismissUndoBanner()
    }

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
            loggedBy: profileStore.currentUserMemberId
        )
        persistEventWithFeedback(sleepEvent)
        dismissedAssumedSleepDate = Date()
        _ = triggerForcedCelebrationIfEnabled()
    }

    /// Log wake-up for the assumed overnight sleep
    /// This confirms the sleep and logs the wake event at the current time (or specified time)
    func confirmAssumedOvernightSleepAndWakeUp(sleepStartTime: Date, wakeTime: Date = Date()) {
        let loggedBy = profileStore.currentUserMemberId
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
            loggedBy: profileStore.currentUserMemberId
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
            loggedBy: profileStore.currentUserMemberId
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
            loggedBy: profileStore.currentUserMemberId
        )
        persistEventWithFeedback(wakeEvent)
        dismissFirstRunWelcome()
        _ = triggerForcedCelebrationIfEnabled()
    }

    /// Force a full celebration for every event log when the setting is enabled.
    @discardableResult
    private func triggerForcedCelebrationIfEnabled() -> Bool {
        let shouldForceCelebrate = UserDefaults.standard.bool(
            forKey: UserPreferences.Key.forceCelebrateEveryLog.rawValue
        )
        guard shouldForceCelebrate else { return false }
        triggerCelebration(.milestone)
        return true
    }

    /// Dismiss the first run welcome permanently
    private func dismissFirstRunWelcome() {
        dismissedFirstRunWelcome = true
        UserDefaults.standard.set(true, forKey: "dismissedFirstRunWelcome")
    }

    // MARK: - Private Helpers

    /// Common event persistence pattern: add event, sync UI, notify notifications
    /// This consolidates the repeated pattern of adding events and updating state
    private func persistEvent(_ event: PuppyEvent) {
        eventStore.addEvent(event)
        syncEventsFromStore()
        notifyRefreshNotifications()
    }

    /// Persist event and provide success haptic feedback
    private func persistEventWithFeedback(_ event: PuppyEvent) {
        persistEvent(event)
        HapticFeedback.success()
    }
}
