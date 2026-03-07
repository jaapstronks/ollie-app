//
//  SheetContent+Events.swift
//  Otis-app
//
//  Sheet content builders for event-related sheets
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    // MARK: - Event Sheets

    @MainActor @ViewBuilder
    func buildEventContent(context: SheetContentContext) -> some View {
        switch self {
        case .potty(let preselected):
            PottyQuickLogSheet(
                onSave: context.viewModel.logPottyEvent,
                onCancel: context.viewModel.cancelPottySheet,
                preselected: preselected
            )

        case .allEvents:
            AllEventsSheet(
                onSelect: { type in
                    handleEventTypeSelection(type, context: context)
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        case .quickLog(let type, let suggestedTime):
            QuickLogSheet(
                eventType: type,
                onSave: context.viewModel.logFromQuickSheet,
                onCancel: context.viewModel.cancelQuickLogSheet,
                suggestedTime: suggestedTime,
                spotStore: type == .uitlaten ? context.spotStore : nil,
                locationManager: type == .uitlaten ? context.locationManager : nil,
                onSaveWalk: type == .uitlaten ? { time, spot, lat, lon, note in
                    context.viewModel.logWalkEvent(time: time, spot: spot, latitude: lat, longitude: lon, note: note)
                    context.sheetCoordinator.dismissSheet()
                } : nil
            )

        case .logEvent(let type):
            LogEventSheet(eventType: type) { note, who, exercise, result, durationMin in
                context.viewModel.logEvent(
                    type: type,
                    note: note,
                    who: who,
                    exercise: exercise,
                    result: result,
                    durationMin: durationMin
                )
                context.sheetCoordinator.dismissSheet()
            }

        case .locationPicker(let type):
            LocationPickerSheet(
                eventType: type,
                onSelect: context.viewModel.logWithLocation,
                onCancel: context.viewModel.cancelLocationPicker
            )

        case .editEvent(let event):
            EditEventSheet(
                event: event,
                onSave: { updatedEvent in
                    context.viewModel.updateEvent(updatedEvent)
                    context.sheetCoordinator.dismissSheet()
                },
                onDelete: {
                    context.viewModel.deleteEvent(event)
                    context.sheetCoordinator.dismissSheet()
                },
                householdMembers: context.profile?.householdMembers
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Event Type Selection Handler

    @MainActor
    private func handleEventTypeSelection(_ type: EventType, context: SheetContentContext) {
        switch type {
        case .moment:
            context.sheetCoordinator.transitionToSheet(.momentSourcePicker)

        case .uitlaten:
            if context.viewModel.isWalkInProgress {
                context.sheetCoordinator.transitionToSheet(.endActivity)
            } else {
                context.sheetCoordinator.transitionToSheet(.startActivity(.walk))
            }

        case .slapen:
            if context.viewModel.isNapInProgress {
                context.sheetCoordinator.transitionToSheet(.endActivity)
            } else {
                context.sheetCoordinator.transitionToSheet(.startActivity(.nap))
            }

        case .coverageGap:
            if let activeGap = context.viewModel.activeCoverageGap {
                context.sheetCoordinator.transitionToSheet(.endCoverageGap(activeGap))
            } else {
                context.sheetCoordinator.transitionToSheet(.startCoverageGap)
            }

        default:
            context.sheetCoordinator.transitionToSheet(.quickLog(type))
        }
    }
}
