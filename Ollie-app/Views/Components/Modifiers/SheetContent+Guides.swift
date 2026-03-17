//
//  SheetContent+Guides.swift
//  Otis-app
//
//  Sheet content builders for guide and informational sheets
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    // MARK: - Guide & Informational Sheets

    @MainActor @ViewBuilder
    func buildGuideContent(context: SheetContentContext) -> some View {
        switch self {
        case .developmentJourney:
            DevelopmentJourneySheet(
                onNavigateToSocialization: {
                    context.sheetCoordinator.presentSheet(.socializationWindow)
                },
                onNavigateToMedical: {
                    context.sheetCoordinator.presentSheet(.medicalCare)
                }
            )

        case .socializationWindow:
            SocializationWindowSheet(
                onNavigateToDevelopment: {
                    context.sheetCoordinator.presentSheet(.developmentJourney)
                },
                onLogExposure: {
                    context.sheetCoordinator.presentSheet(.socializationLog)
                }
            )

        case .medicalCare:
            MedicalCareSheet(
                onNavigateToDevelopment: {
                    context.sheetCoordinator.presentSheet(.developmentJourney)
                },
                onSelectMilestone: { _ in
                    // Milestone completion is handled separately in HealthTabView
                }
            )

        case .crateTrainingGuide:
            CrateTrainingGuideSheet(eventStore: context.eventStore)

        case .pottyTrainingGuide:
            PottyTrainingGuideSheet(
                viewModel: PottyTrainingGuideViewModel(
                    streakInfo: context.viewModel.streakInfo,
                    patternAnalysis: context.viewModel.patternAnalysis,
                    outdoorPercentage: context.viewModel.outdoorPercentage,
                    ageInWeeks: context.profile?.ageInWeeks ?? 12,
                    shouldShowIncidentMessage: context.viewModel.shouldShowPottyIncidentMessage,
                    shouldShowReactivationPrompt: context.viewModel.shouldShowPottyReactivationPrompt,
                    incidentCount: context.viewModel.incidentsSincePottyMastery.count
                )
            )

        case .fullTimeline:
            FullTimelineSheet(
                viewModel: context.viewModel,
                onEditEvent: { event in
                    context.viewModel.editEvent(event)
                },
                onDeleteEvent: { event in
                    context.viewModel.deleteEvent(event)
                },
                onPhotoTap: { event in
                    context.selectedPhotoEvent.wrappedValue = event
                }
            )

        case .walkScheduleEditor:
            if let profile = context.profile {
                WalkScheduleEditor(
                    initialSchedule: profile.walkSchedule,
                    ageInMonths: profile.ageInMonths,
                    onSave: { newSchedule in
                        context.profileStore.updateWalkSchedule(newSchedule)
                        context.sheetCoordinator.dismissSheet()
                    }
                )
            } else {
                Text("Profile not available")
            }

        case .addAppointmentWithPrefill(let prefill):
            if let appointmentStore = context.viewModel.appointmentStore {
                AddEditAppointmentSheet(
                    appointmentStore: appointmentStore,
                    prefill: prefill
                )
            } else {
                Text("Appointment store not available")
            }

        default:
            EmptyView()
        }
    }
}
