//
//  TimelineViewModel+QuickLog.swift
//  Ollie-app
//
//  Quick log, potty sheet, and media picker methods for TimelineViewModel.
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

    // MARK: - Behavior Incident Logging

    /// Log a behavior incident
    func logBehaviorIncident(
        category: BehaviorCategory,
        trigger: String?,
        intensity: BehaviorIntensity?,
        outcome: BehaviorOutcome?,
        context: BehaviorContext?,
        time: Date,
        note: String?
    ) {
        let loggedBy = UserIdentityStore.shared.currentUserRecordID

        var event = PuppyEvent.behaviorIncident(
            time: time,
            category: category,
            trigger: trigger,
            intensity: intensity,
            outcome: outcome,
            context: context,
            note: note
        )
        event.loggedBy = loggedBy

        persistEvent(event)
        HapticFeedback.success()
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
}
