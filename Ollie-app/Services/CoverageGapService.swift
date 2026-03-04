//
//  CoverageGapService.swift
//  Otis-app
//
//  Extracted from TimelineViewModel+CoverageGaps.swift
//  Handles coverage gap detection and catch-up functionality
//

import Foundation
import OtisShared

/// Handles coverage gap tracking and catch-up prompts
/// Extracted from TimelineViewModel to improve testability and separation of concerns
@MainActor
final class CoverageGapService {

    // MARK: - Dependencies

    private let eventStore: EventStore
    private let profileStore: ProfileStore

    // MARK: - Callbacks

    /// Called to present a sheet
    var onShowSheet: ((SheetCoordinator.ActiveSheet) -> Void)?

    /// Called when events change
    var onEventsChanged: (() -> Void)?

    /// Called to update an event (e.g., when ending coverage gap or updating sleep duration)
    var onUpdateEvent: ((PuppyEvent) -> Void)?

    /// Called to log a new event
    var onLogEvent: ((EventType, Date, EventLocation?, String?) -> Void)?

    // MARK: - Init

    init(eventStore: EventStore, profileStore: ProfileStore) {
        self.eventStore = eventStore
        self.profileStore = profileStore
    }

    // MARK: - Coverage Gap Queries

    /// Get active coverage gap (ongoing, not ended) from events
    func activeCoverageGap(events: [PuppyEvent]) -> PuppyEvent? {
        events.activeGaps().first
    }

    /// Get all coverage gaps from events
    func coverageGaps(events: [PuppyEvent]) -> [PuppyEvent] {
        events.coverageGaps()
    }

    // MARK: - Coverage Gap CRUD

    /// Start a new coverage gap
    func startCoverageGap(type: CoverageGapType, startTime: Date, location: String?, note: String?) {
        let gap = PuppyEvent.coverageGap(
            startTime: startTime,
            endTime: nil,
            gapType: type,
            location: location,
            note: note
        )
        eventStore.addEvent(gap)

        // Notify of changes
        onEventsChanged?()

        HapticFeedback.success()
    }

    /// End an active coverage gap
    func endCoverageGap(_ gap: PuppyEvent, endTime: Date, note: String?) {
        let updatedGap = gap.withEndTime(endTime, note: note)
        eventStore.updateEvent(updatedGap)

        // Notify of changes
        onEventsChanged?()

        HapticFeedback.success()
    }

    // MARK: - Gap Detection

    /// Check for and show gap detection prompt if needed
    /// Call this on app launch/foreground
    func checkForGapDetection(
        events: [PuppyEvent],
        sheetActive: Bool,
        puppyName: String
    ) {
        // Don't show if there's already an active gap
        guard activeCoverageGap(events: events) == nil else { return }

        // Don't show if a sheet is already active
        guard !sheetActive else { return }

        // Get the most recent event time (excluding coverage gaps)
        let lastEventTime = events
            .filter { $0.type != .coverageGap }
            .sorted { $0.time > $1.time }
            .first?.time

        // Check if we should prompt
        if GapDetectionService.shouldPromptForGap(lastEventTime: lastEventTime),
           let hours = GapDetectionService.hoursSinceLastEvent(lastEventTime: lastEventTime),
           let (suggestedStart, _) = GapDetectionService.suggestedGapRange(lastEventTime: lastEventTime) {
            onShowSheet?(.gapDetection(
                hours: hours,
                puppyName: puppyName,
                suggestedStartTime: suggestedStart
            ))
        }
    }

    // MARK: - Quick Catch-Up (3-16 hour gaps)

    /// Check for and show catch-up prompt if needed
    /// Call this on app launch/foreground for shorter gaps (3-16 hours)
    func checkForCatchUp(
        events: [PuppyEvent],
        recentEvents: [PuppyEvent],
        sheetActive: Bool,
        puppyName: String
    ) {
        // Don't show if there's already an active gap
        guard activeCoverageGap(events: events) == nil else { return }

        // Don't show if a sheet is already active
        guard !sheetActive else { return }

        // Get the most recent event time (excluding coverage gaps)
        let lastEventTime = events
            .filter { $0.type != .coverageGap }
            .sorted { $0.time > $1.time }
            .first?.time

        // Check if we should show catch-up (3-16 hour gap range)
        if CatchUpService.shouldShowCatchUp(lastEventTime: lastEventTime, hasActiveCoverageGap: false),
           let hours = CatchUpService.hoursSinceLastEvent(lastEventTime) {
            let context = CatchUpService.getCatchUpContext(
                events: recentEvents,
                profile: profileStore.profile
            )
            onShowSheet?(.catchUp(
                hours: hours,
                puppyName: puppyName,
                context: context
            ))
        }
    }

    /// Process catch-up result and log approximate events
    func processCatchUpResult(_ result: CatchUpResult, recentEvents: [PuppyEvent]) {
        // Log sleep/wake event based on current state
        if let isSleeping = result.isSleeping,
           let sinceTime = result.sleepAwakeSinceTime {
            if isSleeping {
                // Log that they fell asleep at the given time
                onLogEvent?(.slapen, sinceTime, nil, Strings.CatchUp.approximateNote)
            } else {
                // End the ongoing sleep by updating its duration (single-event model)
                if let sleepEvent = recentEvents
                    .filter({ $0.type == .slapen && $0.durationMin == nil })
                    .sorted(by: { $0.time > $1.time })
                    .first {
                    // Calculate duration and update sleep event
                    let durationMinutes = Int(sinceTime.timeIntervalSince(sleepEvent.time) / 60)
                    var updatedSleep = sleepEvent
                    updatedSleep.durationMin = max(1, durationMinutes)
                    if updatedSleep.note == nil {
                        updatedSleep.note = Strings.CatchUp.approximateNote
                    }
                    onUpdateEvent?(updatedSleep)
                }
            }
        }

        // Log potty event based on selection
        if let minutesAgo = result.lastPottyOption.minutesAgo {
            let pottyTime = Date().addingTimeInterval(-Double(minutesAgo) * 60)
            onLogEvent?(.plassen, pottyTime, .buiten, Strings.CatchUp.approximateNote)
        }

        // Log poop if user indicated yes
        if result.hasPoopedToday == true {
            // Log a poop event (approximate time, use current time)
            onLogEvent?(.poepen, Date(), .buiten, Strings.CatchUp.approximateNote)
        }

        // Note: We don't log meals here since we're just asking if they ate,
        // not when - the meal schedule will handle the next meal reminder

        HapticFeedback.success()
    }
}
