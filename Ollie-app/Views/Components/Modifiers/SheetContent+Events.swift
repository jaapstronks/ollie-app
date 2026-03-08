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
                onSelectGrooming: {
                    context.sheetCoordinator.transitionToSheet(.groomingQuickLog(preselectedType: nil))
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
                }
            )

        case .medicationLog:
            if let medicationStore = context.viewModel.medicationStore {
                MedicationLogSheet(
                    profileStore: context.viewModel.profileStore,
                    medicationStore: medicationStore,
                    onComplete: { medication in
                        context.sheetCoordinator.dismissSheet()
                    },
                    onCancel: {
                        context.sheetCoordinator.dismissSheet()
                    }
                )
            } else {
                EmptyView()
            }

        case .symptomLog(let conditionId):
            SymptomLogSheet(
                preselectedConditionId: conditionId,
                onSave: { symptomLog in
                    HealthSymptomStore.shared.log(symptomLog)
                    context.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
            )
            .environmentObject(context.viewModel.profileStore)

        case .seniorMobility:
            MobilityAssessmentSheet(
                onSave: { assessment in
                    SeniorWellnessStore.shared.recordMobility(
                        score: assessment.score,
                        observations: assessment.observations,
                        note: assessment.note
                    )
                    context.sheetCoordinator.dismissSheet()
                }
            )
            .environmentObject(context.viewModel.profileStore)

        case .groomingSettings:
            NavigationStack {
                GroomingSettingsView(profileStore: context.viewModel.profileStore)
            }

        case .groomingQuickLog(let preselectedType):
            GroomingQuickLogSheet(
                puppyName: context.viewModel.puppyName,
                preselectedType: preselectedType
            )

        case .behaviorLog:
            BehaviorLogSheet(
                onSave: { category, trigger, intensity, outcome, behaviorContext, time, note in
                    context.viewModel.logBehaviorIncident(
                        category: category,
                        trigger: trigger,
                        intensity: intensity,
                        outcome: outcome,
                        context: behaviorContext,
                        time: time,
                        note: note
                    )
                    context.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
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

        case .medicatie:
            context.sheetCoordinator.transitionToSheet(.medicationLog)

        case .gedrag:
            context.sheetCoordinator.transitionToSheet(.behaviorLog)

        default:
            context.sheetCoordinator.transitionToSheet(.quickLog(type))
        }
    }
}
