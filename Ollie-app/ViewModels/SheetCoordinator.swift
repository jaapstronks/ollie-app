//
//  SheetCoordinator.swift
//  Ollie-app
//
//  Centralized sheet presentation management for TimelineView
//

import Combine
import OllieShared
import SwiftUI

/// Manages sheet presentation state for the timeline view
@MainActor
final class SheetCoordinator: ObservableObject {

    // MARK: - Active Sheet Enum

    /// All possible sheet types that can be presented
    enum ActiveSheet: Equatable, Identifiable {
        case quickLog(EventType, suggestedTime: Date? = nil)
        case potty
        case allEvents
        case logEvent(EventType)
        case locationPicker(EventType)
        case mediaPicker(MediaPickerSource)
        case momentSourcePicker
        case logMoment
        case editEvent(PuppyEvent)
        case olliePlus  // Ollie+ subscription upsell sheet
        case subscriptionSuccess  // Shown after successful subscription
        case startActivity(ActivityType)
        case endActivity
        case endSleep(Date)
        // Additional sheets for settings and specialized logging
        case weightLog
        case trainingLog
        case socializationLog
        case settings
        case profileEdit
        case notificationSettings
        case walkLog
        case napLog(defaultDuration: Int)
        // Coverage gap sheets
        case startCoverageGap
        case endCoverageGap(PuppyEvent)
        case gapDetection(hours: Int, puppyName: String, suggestedStartTime: Date)
        // Catch-up sheet (for 3-16 hour gaps)
        case catchUp(hours: Int, puppyName: String, context: CatchUpContext)

        var id: String {
            switch self {
            case .quickLog(let type, _): return "quickLog-\(type.rawValue)"
            case .potty: return "potty"
            case .allEvents: return "allEvents"
            case .logEvent(let type): return "logEvent-\(type.rawValue)"
            case .locationPicker(let type): return "locationPicker-\(type.rawValue)"
            case .mediaPicker(let source): return "mediaPicker-\(source)"
            case .momentSourcePicker: return "momentSourcePicker"
            case .logMoment: return "logMoment"
            case .editEvent(let event): return "editEvent-\(event.id.uuidString)"
            case .olliePlus: return "olliePlus"
            case .subscriptionSuccess: return "subscriptionSuccess"
            case .startActivity(let type): return "startActivity-\(type.rawValue)"
            case .endActivity: return "endActivity"
            case .endSleep: return "endSleep"
            case .weightLog: return "weightLog"
            case .trainingLog: return "trainingLog"
            case .socializationLog: return "socializationLog"
            case .settings: return "settings"
            case .profileEdit: return "profileEdit"
            case .notificationSettings: return "notificationSettings"
            case .walkLog: return "walkLog"
            case .napLog: return "napLog"
            case .startCoverageGap: return "startCoverageGap"
            case .endCoverageGap(let gap): return "endCoverageGap-\(gap.id.uuidString)"
            case .gapDetection: return "gapDetection"
            case .catchUp: return "catchUp"
            }
        }
    }

    // MARK: - Published State

    /// Current active sheet (nil when no sheet is shown)
    @Published var activeSheet: ActiveSheet?

    /// Delete confirmation state (separate from sheets - uses confirmation dialog)
    @Published var showingDeleteConfirmation: Bool = false
    @Published var eventToDelete: PuppyEvent?

    /// Undo banner state (separate from sheets - uses overlay)
    @Published var showingUndoBanner: Bool = false
    @Published var lastDeletedEvent: PuppyEvent?

    /// Undo task for auto-dismiss
    private var undoTask: Task<Void, Never>?

    // MARK: - Sheet Data Accessors

    /// Current pending event type for quick log or log event sheets
    var pendingEventType: EventType? {
        guard let sheet = activeSheet else { return nil }
        switch sheet {
        case .quickLog(let type, _), .logEvent(let type), .locationPicker(let type):
            return type
        default:
            return nil
        }
    }

    /// Current media picker source
    var mediaPickerSource: MediaPickerSource {
        if case .mediaPicker(let source) = activeSheet {
            return source
        }
        return .camera
    }

    /// Whether media picker is showing (for fullScreenCover)
    var isShowingMediaPicker: Bool {
        if case .mediaPicker = activeSheet { return true }
        return false
    }

    // MARK: - Sheet Presentation

    /// Present a sheet, dismissing any currently active sheet
    func presentSheet(_ sheet: ActiveSheet) {
        activeSheet = sheet
    }

    /// Dismiss the current sheet
    func dismissSheet() {
        activeSheet = nil
    }

    /// Transition from one sheet to another with a delay
    /// Used for flows like AllEvents -> QuickLog
    func transitionToSheet(_ sheet: ActiveSheet) {
        dismissSheet()
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
            presentSheet(sheet)
        }
    }

    // MARK: - Delete Confirmation

    /// Request to delete an event (shows confirmation dialog)
    func requestDeleteEvent(_ event: PuppyEvent) {
        eventToDelete = event
        showingDeleteConfirmation = true
    }

    /// Clear delete confirmation state
    func clearDeleteConfirmation() {
        eventToDelete = nil
        showingDeleteConfirmation = false
    }

    // MARK: - Undo Banner

    /// Show undo banner for deleted event
    func showUndo(for event: PuppyEvent) {
        lastDeletedEvent = event
        showingUndoBanner = true

        // Auto-hide after configured timeout
        undoTask?.cancel()
        undoTask = Task {
            try? await Task.sleep(for: .seconds(Constants.undoBannerTimeoutSeconds))
            if !Task.isCancelled {
                dismissUndoBanner()
            }
        }
    }

    /// Dismiss undo banner
    func dismissUndoBanner() {
        undoTask?.cancel()
        undoTask = nil
        showingUndoBanner = false
        lastDeletedEvent = nil
    }

    /// Get the last deleted event for undo
    func popLastDeletedEvent() -> PuppyEvent? {
        let event = lastDeletedEvent
        dismissUndoBanner()
        return event
    }
}
