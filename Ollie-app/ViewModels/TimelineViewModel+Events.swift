//
//  TimelineViewModel+Events.swift
//  Ollie-app
//
//  Core event CRUD operations for TimelineViewModel.
//  Quick log methods are in TimelineViewModel+QuickLog.swift.
//  Sleep events are in TimelineViewModel+SleepEvents.swift.
//

import Foundation
import OtisShared
import SwiftUI

extension TimelineViewModel {

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
        napLocation: NapLocation? = nil,
        linkedContactID: UUID? = nil
    ) {
        // Get current user's household member ID for attribution
        let loggedBy = UserIdentityStore.shared.currentUserRecordID

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
            loggedBy: loggedBy,
            linkedContactID: linkedContactID
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
        let loggedBy = UserIdentityStore.shared.currentUserRecordID

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

    // MARK: - Private Helpers

    /// Common event persistence pattern: add event, sync UI, notify notifications
    /// This consolidates the repeated pattern of adding events and updating state
    func persistEvent(_ event: PuppyEvent) {
        eventStore.addEvent(event)
        syncEventsFromStore()
        notifyRefreshNotifications()
    }

    /// Persist event and provide success haptic feedback
    func persistEventWithFeedback(_ event: PuppyEvent) {
        persistEvent(event)
        HapticFeedback.success()
    }
}
