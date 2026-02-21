//
//  SheetCoordinator.swift
//  Ollie-app
//
//  Centralized sheet presentation management for TimelineView
//

import Combine
import SwiftUI

/// Manages sheet presentation state for the timeline view
@MainActor
final class SheetCoordinator: ObservableObject {

    // MARK: - Active Sheet Enum

    /// All possible sheet types that can be presented
    enum ActiveSheet: Equatable {
        case none
        case quickLog(EventType)
        case potty
        case allEvents
        case logEvent(EventType)
        case locationPicker(EventType)
        case mediaPicker(MediaPickerSource)
        case logMoment
        case upgradePrompt
        case purchaseSuccess
    }

    // MARK: - Published State

    /// Current active sheet
    @Published private(set) var activeSheet: ActiveSheet = .none

    /// Delete confirmation state (separate from sheets - uses confirmation dialog)
    @Published var showingDeleteConfirmation: Bool = false
    @Published var eventToDelete: PuppyEvent?

    /// Undo banner state (separate from sheets - uses overlay)
    @Published var showingUndoBanner: Bool = false
    @Published var lastDeletedEvent: PuppyEvent?

    /// Undo task for auto-dismiss
    private var undoTask: Task<Void, Never>?

    // MARK: - Computed Bindings for SwiftUI Sheets

    /// Binding for PottyQuickLogSheet
    var isShowingPotty: Binding<Bool> {
        Binding(
            get: { self.activeSheet == .potty },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for AllEventsSheet
    var isShowingAllEvents: Binding<Bool> {
        Binding(
            get: { self.activeSheet == .allEvents },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for QuickLogSheet
    var isShowingQuickLog: Binding<Bool> {
        Binding(
            get: {
                if case .quickLog = self.activeSheet { return true }
                return false
            },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for LogEventSheet
    var isShowingLogSheet: Binding<Bool> {
        Binding(
            get: {
                if case .logEvent = self.activeSheet { return true }
                return false
            },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for LocationPickerSheet
    var isShowingLocationPicker: Binding<Bool> {
        Binding(
            get: {
                if case .locationPicker = self.activeSheet { return true }
                return false
            },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for MediaPicker fullscreen cover
    var isShowingMediaPicker: Binding<Bool> {
        Binding(
            get: {
                if case .mediaPicker = self.activeSheet { return true }
                return false
            },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for LogMomentSheet
    var isShowingLogMoment: Binding<Bool> {
        Binding(
            get: { self.activeSheet == .logMoment },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for upgrade prompt
    var isShowingUpgradePrompt: Binding<Bool> {
        Binding(
            get: { self.activeSheet == .upgradePrompt },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    /// Binding for purchase success
    var isShowingPurchaseSuccess: Binding<Bool> {
        Binding(
            get: { self.activeSheet == .purchaseSuccess },
            set: { if !$0 { self.dismissSheet() } }
        )
    }

    // MARK: - Sheet Data Accessors

    /// Current pending event type for quick log or log event sheets
    var pendingEventType: EventType? {
        switch activeSheet {
        case .quickLog(let type), .logEvent(let type), .locationPicker(let type):
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

    // MARK: - Sheet Presentation

    /// Present a sheet, dismissing any currently active sheet
    func presentSheet(_ sheet: ActiveSheet) {
        activeSheet = sheet
    }

    /// Dismiss the current sheet
    func dismissSheet() {
        activeSheet = .none
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
