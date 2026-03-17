//
//  EventLoggingService.swift
//  Otis-app
//
//  Extracted from TimelineViewModel+Events.swift
//  Handles event CRUD operations and undo functionality
//

import Foundation
import OtisShared

// Note: EventLogRequest is defined in ActivityTrackingManager.swift

/// Handles event CRUD operations
/// Extracted from TimelineViewModel to improve testability and separation of concerns
@Observable
@MainActor
final class EventLoggingService {

    // MARK: - Dependencies

    @ObservationIgnored private let eventStore: EventStore
    @ObservationIgnored private let profileStore: ProfileStore
    @ObservationIgnored private let userIdentityStore: UserIdentityStore

    // MARK: - Undo State

    private(set) var lastDeletedEvent: PuppyEvent?

    // MARK: - Callbacks

    /// Called when events change (for syncing and refreshing UI)
    @ObservationIgnored var onEventsChanged: (() -> Void)?

    /// Called when a celebration should be triggered
    @ObservationIgnored var onCelebration: ((CelebrationPreset, String?) -> Void)?

    /// Called when notifications should be refreshed
    @ObservationIgnored var onRefreshNotifications: (() -> Void)?

    /// Called when potty log time should be recorded (for post-wake state)
    @ObservationIgnored var onRecordPottyLogTime: (() -> Void)?

    // MARK: - Init

    init(
        eventStore: EventStore,
        profileStore: ProfileStore,
        userIdentityStore: UserIdentityStore = .shared
    ) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.userIdentityStore = userIdentityStore
    }

    // MARK: - Attribution Helper

    /// Get the current user's CloudKit record ID for event attribution
    private var currentUserRecordID: String? {
        userIdentityStore.currentUserRecordID
    }

    // MARK: - Event CRUD

    /// Log a new event
    @discardableResult
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
    ) -> PuppyEvent {
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID

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
            onRecordPottyLogTime?()
        }

        // Check if this is the user's very first event (before adding)
        let isFirstEvent = eventStore.events.isEmpty && eventStore.getEvents(
            from: Date.distantPast,
            to: Date()
        ).isEmpty

        eventStore.addEvent(event)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()

        // Trigger celebration for first-ever event
        if isFirstEvent {
            onCelebration?(.milestone, nil)
        } else {
            // Trigger celebration based on event type
            triggerCelebrationForEvent(type: type, location: location)
        }

        return event
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
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID

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

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()

        // Celebrate completed walk
        onCelebration?(.training, nil)
    }

    /// Log a completed nap with start and end time (single-event model with durationMin)
    func logCompletedNap(startTime: Date, endTime: Date, note: String?, napLocation: NapLocation? = nil) {
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID
        let sessionId = UUID()

        // Calculate duration in minutes
        let durationMin = max(1, Int(endTime.timeIntervalSince(startTime) / 60))

        // Log single sleep event with duration
        let sleepEvent = PuppyEvent(
            time: startTime,
            type: .slapen,
            note: note,
            durationMin: durationMin,
            sleepSessionId: sessionId,
            napLocation: napLocation,
            loggedBy: loggedBy
        )
        eventStore.addEvent(sleepEvent)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()

        // Celebrate completed nap
        onCelebration?(.quickLog, nil)
    }

    /// Add a pre-built event (used for photo moments)
    func addEvent(_ event: PuppyEvent) {
        eventStore.addEvent(event)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()
    }

    /// Update an existing event
    func updateEvent(_ event: PuppyEvent) {
        eventStore.updateEvent(event)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()
    }

    /// Delete event with undo capability
    func deleteEventWithUndo(_ event: PuppyEvent) {
        // Actually delete
        eventStore.deleteEvent(event)

        // Save for undo
        lastDeletedEvent = event

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        HapticFeedback.warning()
    }

    /// Undo the last deletion
    /// Returns the restored event if successful
    func undoLastDelete() -> PuppyEvent? {
        guard let event = lastDeletedEvent else { return nil }

        eventStore.addEvent(event)
        lastDeletedEvent = nil

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        HapticFeedback.success()

        return event
    }

    /// Clear the last deleted event (e.g., when undo banner times out)
    func clearLastDeletedEvent() {
        lastDeletedEvent = nil
    }

    // MARK: - Potty Quick Log

    /// Log potty event(s) based on selection
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
    }

    // MARK: - Assumed Overnight Sleep

    /// Confirm the assumed overnight sleep with the given start time
    func confirmAssumedOvernightSleep(sleepStartTime: Date) {
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID
        let sessionId = UUID()

        // Log sleep event at the provided start time
        let sleepEvent = PuppyEvent(
            time: sleepStartTime,
            type: .slapen,
            sleepSessionId: sessionId,
            loggedBy: loggedBy
        )
        eventStore.addEvent(sleepEvent)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        HapticFeedback.success()
    }

    /// Log wake-up for the assumed overnight sleep
    func confirmAssumedOvernightSleepAndWakeUp(sleepStartTime: Date, wakeTime: Date = Date()) {
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID
        let sessionId = UUID()

        // Log sleep event at the start time
        let sleepEvent = PuppyEvent(
            time: sleepStartTime,
            type: .slapen,
            sleepSessionId: sessionId,
            loggedBy: loggedBy
        )
        eventStore.addEvent(sleepEvent)

        // Log wake event at the wake time
        let wakeEvent = PuppyEvent(
            time: wakeTime,
            type: .ontwaken,
            sleepSessionId: sessionId,
            loggedBy: loggedBy
        )
        eventStore.addEvent(wakeEvent)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        HapticFeedback.success()
    }

    // MARK: - Stale Logging

    /// Start fresh after a logging gap
    func startFreshAfterLoggingGap() {
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID
        let now = Date()

        // Log a wake event at the current time to establish a new baseline
        let wakeEvent = PuppyEvent(
            time: now,
            type: .ontwaken,
            loggedBy: loggedBy
        )
        eventStore.addEvent(wakeEvent)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        HapticFeedback.success()
    }

    // MARK: - First Run

    /// Handle "puppy is sleeping" response from first run welcome
    func firstRunPuppyIsSleeping() {
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID
        let now = Date()

        // Log a sleep event at the current time
        let sleepEvent = PuppyEvent(
            time: now,
            type: .slapen,
            loggedBy: loggedBy
        )
        eventStore.addEvent(sleepEvent)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        HapticFeedback.success()
    }

    /// Handle "puppy is awake" response from first run welcome
    func firstRunPuppyIsAwake() {
        // Get current user's CloudKit record ID for attribution
        let loggedBy = currentUserRecordID
        let now = Date()

        // Log a wake event at the current time
        let wakeEvent = PuppyEvent(
            time: now,
            type: .ontwaken,
            loggedBy: loggedBy
        )
        eventStore.addEvent(wakeEvent)

        // Notify of changes
        onEventsChanged?()
        onRefreshNotifications?()

        HapticFeedback.success()
    }

    // MARK: - Private Helpers

    /// Trigger appropriate celebration for an event type
    private func triggerCelebrationForEvent(type: EventType, location: EventLocation?) {
        switch type {
        case .plassen, .poepen:
            // Outdoor potty gets a celebration
            if location == .buiten {
                onCelebration?(.pottySuccess, nil)
            }
        case .eten:
            // Meal logged - subtle celebration
            onCelebration?(.quickLog, nil)
        case .uitlaten:
            // Walk logged
            onCelebration?(.training, nil)
        case .training:
            // Training session - celebrate!
            onCelebration?(.training, nil)
        case .sociaal:
            // Socialization - celebrate!
            onCelebration?(.training, nil)
        default:
            // Other events don't trigger celebrations
            break
        }
    }
}
