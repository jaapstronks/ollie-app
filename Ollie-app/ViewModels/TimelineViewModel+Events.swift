//
//  TimelineViewModel+Events.swift
//  Ollie-app
//
//  Event CRUD operations for TimelineViewModel
//

import Foundation
import OllieShared
import SwiftUI

extension TimelineViewModel {
    // MARK: - Quick Log

    func quickLog(type: EventType, suggestedTime: Date? = nil) {
        // Core logging is always free - no paywall check needed
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
        sheetCoordinator.presentSheet(.potty)
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

        // Check for outdoor pee streak celebration (plassen or beide with buiten)
        if (selection == .plassen || selection == .beide) && location == .buiten {
            checkAndTriggerPottyStreakCelebration()
        }

        sheetCoordinator.dismissSheet()
    }

    /// Check if the user has achieved a same-day outdoor pee streak worth celebrating
    /// Triggers celebration if 3+ outdoor pees today with NO indoor pees
    private func checkAndTriggerPottyStreakCelebration() {
        let calendar = Calendar.current

        // Get today's pee events from the current events array (just synced)
        let todayPeeEvents = events.filter { event in
            event.type == .plassen && calendar.isDateInToday(event.time)
        }

        // Count outdoor and indoor pees today
        let outdoorCount = todayPeeEvents.filter { $0.location == .buiten }.count
        let indoorCount = todayPeeEvents.filter { $0.location == .binnen }.count

        // Celebrate if 3+ outdoor pees AND no indoor pees today
        if outdoorCount >= 3 && indoorCount == 0 {
            // Trigger the potty success celebration animation
            triggerCelebration(.pottySuccess)

            // Show celebration banner with message
            let message = Strings.Celebration.outdoorStreakToday(
                count: outdoorCount,
                puppyName: puppyName
            )
            sheetCoordinator.showCelebration(message: message)
        }
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
        // Photo/video attachments require Ollie+
        guard subscriptionManager.hasAccess(to: .photoVideoAttachments) else {
            sheetCoordinator.presentSheet(.olliePlus)
            return
        }
        sheetCoordinator.presentSheet(.mediaPicker(.camera))
    }

    func openPhotoLibrary() {
        // Photo/video attachments require Ollie+
        guard subscriptionManager.hasAccess(to: .photoVideoAttachments) else {
            sheetCoordinator.presentSheet(.olliePlus)
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
        sleepSessionId: UUID? = nil
    ) {
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
            sleepSessionId: sleepSessionId
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

        // Trigger celebration for first-ever event
        if isFirstEvent {
            triggerCelebration(.milestone)
        }
    }

    /// Trigger a celebration animation
    func triggerCelebration(_ style: CelebrationPreset) {
        celebrationStyle = style
        showCelebration = true
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
        let walkEvent = PuppyEvent.walk(
            time: time,
            durationMin: durationMin,
            note: note,
            spot: spot,
            latitude: latitude,
            longitude: longitude
        )

        eventStore.addEvent(walkEvent)

        // Log potty events linked to this walk
        if didPee {
            let peeEvent = PuppyEvent.potty(
                type: .plassen,
                time: time,
                location: .buiten,
                parentWalkId: walkEvent.id
            )
            eventStore.addEvent(peeEvent)
        }

        if didPoop {
            let poopEvent = PuppyEvent.potty(
                type: .poepen,
                time: time,
                location: .buiten,
                parentWalkId: walkEvent.id
            )
            eventStore.addEvent(poopEvent)
        }

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        notifyRefreshNotifications()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()
    }

    /// Log a completed nap with start and end time (creates both sleep and wake events)
    func logCompletedNap(startTime: Date, endTime: Date, note: String?) {
        let sessionId = UUID()

        // Log sleep event at start time
        let sleepEvent = PuppyEvent(
            time: startTime,
            type: .slapen,
            note: note,
            sleepSessionId: sessionId
        )
        eventStore.addEvent(sleepEvent)

        // Log wake event at end time
        let wakeEvent = PuppyEvent(
            time: endTime,
            type: .ontwaken,
            sleepSessionId: sessionId
        )
        eventStore.addEvent(wakeEvent)

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        notifyRefreshNotifications()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()
    }

    /// Add a pre-built event (used for photo moments)
    func addEvent(_ event: PuppyEvent) {
        eventStore.addEvent(event)

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        notifyRefreshNotifications()
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
        eventStore.addEvent(event)

        // Immediately sync for instant UI updates
        syncEventsFromStore()
        // Force refresh stats to ensure week view updates immediately
        notifyForceRefreshStats()
        notifyRefreshNotifications()
        HapticFeedback.success()
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
        let sessionId = UUID()

        // Log sleep event at the provided start time
        let sleepEvent = PuppyEvent(
            time: sleepStartTime,
            type: .slapen,
            sleepSessionId: sessionId
        )
        eventStore.addEvent(sleepEvent)

        // Clear the dismissed date (no longer needed)
        dismissedAssumedSleepDate = Date()

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        notifyRefreshNotifications()

        HapticFeedback.success()
    }

    /// Log wake-up for the assumed overnight sleep
    /// This confirms the sleep and logs the wake event at the current time (or specified time)
    func confirmAssumedOvernightSleepAndWakeUp(sleepStartTime: Date, wakeTime: Date = Date()) {
        let sessionId = UUID()

        // Log sleep event at the start time
        let sleepEvent = PuppyEvent(
            time: sleepStartTime,
            type: .slapen,
            sleepSessionId: sessionId
        )
        eventStore.addEvent(sleepEvent)

        // Log wake event at the wake time
        let wakeEvent = PuppyEvent(
            time: wakeTime,
            type: .ontwaken,
            sleepSessionId: sessionId
        )
        eventStore.addEvent(wakeEvent)

        // Clear the dismissed date
        dismissedAssumedSleepDate = Date()

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        notifyRefreshNotifications()

        // Capture potty state at wake time for post-wake tracking
        captureWakeTimePottyState()

        HapticFeedback.success()
    }
}
