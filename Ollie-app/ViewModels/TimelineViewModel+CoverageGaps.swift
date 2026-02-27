//
//  TimelineViewModel+CoverageGaps.swift
//  Ollie-app
//
//  Coverage gap and catch-up functionality for TimelineViewModel
//

import Foundation
import OllieShared

extension TimelineViewModel {
    // MARK: - Coverage Gaps

    /// Active coverage gap (ongoing, not ended)
    var activeCoverageGap: PuppyEvent? {
        events.activeGaps().first
    }

    /// All coverage gaps in the current view
    var coverageGaps: [PuppyEvent] {
        events.coverageGaps()
    }

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

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        HapticFeedback.success()
    }

    /// End an active coverage gap
    func endCoverageGap(_ gap: PuppyEvent, endTime: Date, note: String?) {
        let updatedGap = gap.withEndTime(endTime, note: note)
        eventStore.updateEvent(updatedGap)

        // Immediately sync for instant UI updates
        syncEventsFromStore()

        HapticFeedback.success()
    }

    /// Show start coverage gap sheet
    func showStartCoverageGapSheet() {
        sheetCoordinator.presentSheet(.startCoverageGap)
    }

    /// Show end coverage gap sheet
    func showEndCoverageGapSheet(for gap: PuppyEvent) {
        sheetCoordinator.presentSheet(.endCoverageGap(gap))
    }

    /// Check for and show gap detection prompt if needed
    /// Call this on app launch/foreground
    func checkForGapDetection() {
        // Don't show if there's already an active gap
        guard activeCoverageGap == nil else { return }

        // Don't show if a sheet is already active
        guard sheetCoordinator.activeSheet == nil else { return }

        // Get the most recent event time (excluding coverage gaps)
        let lastEventTime = events
            .filter { $0.type != .coverageGap }
            .sorted { $0.time > $1.time }
            .first?.time

        // Check if we should prompt
        if GapDetectionService.shouldPromptForGap(lastEventTime: lastEventTime),
           let hours = GapDetectionService.hoursSinceLastEvent(lastEventTime: lastEventTime),
           let (suggestedStart, _) = GapDetectionService.suggestedGapRange(lastEventTime: lastEventTime) {
            sheetCoordinator.presentSheet(.gapDetection(
                hours: hours,
                puppyName: puppyName,
                suggestedStartTime: suggestedStart
            ))
        }
    }

    // MARK: - Quick Catch-Up (3-16 hour gaps)

    /// Check for and show catch-up prompt if needed
    /// Call this on app launch/foreground for shorter gaps (3-16 hours)
    func checkForCatchUp() {
        // Don't show if there's already an active gap
        guard activeCoverageGap == nil else { return }

        // Don't show if a sheet is already active
        guard sheetCoordinator.activeSheet == nil else { return }

        // Get the most recent event time (excluding coverage gaps)
        let lastEventTime = events
            .filter { $0.type != .coverageGap }
            .sorted { $0.time > $1.time }
            .first?.time

        // Check if we should show catch-up (3-16 hour gap range)
        if CatchUpService.shouldShowCatchUp(lastEventTime: lastEventTime, hasActiveCoverageGap: false),
           let hours = CatchUpService.hoursSinceLastEvent(lastEventTime) {
            let context = CatchUpService.getCatchUpContext(
                events: getRecentEvents(),
                profile: profileStore.profile
            )
            sheetCoordinator.presentSheet(.catchUp(
                hours: hours,
                puppyName: puppyName,
                context: context
            ))
        }
    }

    /// Process catch-up result and log approximate events
    func processCatchUpResult(_ result: CatchUpResult) {
        // Log sleep/wake event based on current state
        if let isSleeping = result.isSleeping,
           let sinceTime = result.sleepAwakeSinceTime {
            if isSleeping {
                // Log that they fell asleep at the given time
                logEvent(type: .slapen, time: sinceTime, note: Strings.CatchUp.approximateNote)
            } else {
                // Log that they woke up at the given time
                // Try to find an ongoing sleep session to link it to
                let recentEvents = getRecentEvents()
                let sleepSessionId = SleepSession.ongoingSleepSessionId(from: recentEvents)
                logEvent(type: .ontwaken, time: sinceTime, note: Strings.CatchUp.approximateNote, sleepSessionId: sleepSessionId)
            }
        }

        // Log potty event based on selection
        if let minutesAgo = result.lastPottyOption.minutesAgo {
            let pottyTime = Date().addingTimeInterval(-Double(minutesAgo) * 60)
            logEvent(type: .plassen, time: pottyTime, location: .buiten, note: Strings.CatchUp.approximateNote)
        }

        // Log poop if user indicated yes
        if result.hasPoopedToday == true {
            // Log a poop event (approximate time, use current time)
            logEvent(type: .poepen, time: Date(), location: .buiten, note: Strings.CatchUp.approximateNote)
        }

        // Note: We don't log meals here since we're just asking if they ate,
        // not when - the meal schedule will handle the next meal reminder

        HapticFeedback.success()
    }
}
