//
//  TimelineViewModel+Sheets.swift
//  Ollie-app
//
//  Extension containing sheet presentation helpers
//  Extracted from TimelineViewModel to improve code organization
//

import Foundation
import OllieShared
import SwiftUI

// MARK: - Sheet Presentation Helpers

extension TimelineViewModel {

    /// Present a sheet
    func presentSheet(_ sheet: SheetCoordinator.ActiveSheet) {
        sheetCoordinator.presentSheet(sheet)
    }

    /// Dismiss current sheet
    func dismissSheet() {
        sheetCoordinator.dismissSheet()
    }

    /// Whether any sheet is currently presented
    var hasActiveSheet: Bool {
        sheetCoordinator.activeSheet != nil
    }
}

// MARK: - Premium Sheet Helpers

extension TimelineViewModel {

    /// Show the Ollie+ subscription sheet
    func showOlliePlusSheet() {
        sheetCoordinator.presentSheet(.olliePlus)
    }

    /// Check if user can access a premium feature, showing paywall if not
    /// Returns true if access is granted
    func checkPremiumAccess(for feature: PremiumFeature) -> Bool {
        if subscriptionManager.hasAccess(to: feature) {
            return true
        }
        showOlliePlusSheet()
        return false
    }
}

// MARK: - Event Sheet Helpers

extension TimelineViewModel {

    /// Show edit sheet for event by ID
    func editEventById(_ eventId: UUID) {
        guard let event = events.first(where: { $0.id == eventId }) else { return }
        editEvent(event)
    }

    /// Show the weight log sheet
    func showWeightLogSheet() {
        sheetCoordinator.presentSheet(.weightLog)
    }

    /// Show the training log sheet
    func showTrainingLogSheet() {
        sheetCoordinator.presentSheet(.trainingLog)
    }

    /// Show the socialization log sheet
    func showSocializationLogSheet() {
        sheetCoordinator.presentSheet(.socializationLog)
    }
}

// MARK: - Settings Sheet Helpers

extension TimelineViewModel {

    /// Show the settings sheet
    func showSettingsSheet() {
        sheetCoordinator.presentSheet(.settings)
    }

    /// Show the profile edit sheet
    func showProfileEditSheet() {
        sheetCoordinator.presentSheet(.profileEdit)
    }

    /// Show the notifications settings sheet
    func showNotificationSettingsSheet() {
        sheetCoordinator.presentSheet(.notificationSettings)
    }
}

// MARK: - Sheet State Bindings

extension TimelineViewModel {

    /// Binding for showing all events sheet
    var showingAllEventsBinding: Binding<Bool> {
        Binding(
            get: {
                if case .allEvents = self.sheetCoordinator.activeSheet {
                    return true
                }
                return false
            },
            set: { newValue in
                if !newValue {
                    self.dismissSheet()
                }
            }
        )
    }

    /// Binding for showing Ollie+ sheet
    var showingOlliePlusBinding: Binding<Bool> {
        Binding(
            get: {
                if case .olliePlus = self.sheetCoordinator.activeSheet {
                    return true
                }
                return false
            },
            set: { newValue in
                if !newValue {
                    self.dismissSheet()
                }
            }
        )
    }
}
