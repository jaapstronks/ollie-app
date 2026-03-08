//
//  SheetContent+Builder.swift
//  Otis-app
//
//  Main content builder that dispatches to domain-specific sheet builders
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    /// Sheet category for routing to appropriate builder
    private enum SheetCategory {
        case event
        case activity
        case coverageGap
        case media
        case subscription
        case guide
        case placeholder
    }

    /// Determines which category this sheet belongs to
    private var category: SheetCategory {
        switch self {
        // Event sheets
        case .potty, .allEvents, .quickLog, .logEvent, .locationPicker, .editEvent, .medicationLog, .symptomLog, .seniorMobility, .behaviorLog:
            return .event

        // Activity sheets
        case .startActivity, .endActivity, .endSleep, .walkLog, .napLog:
            return .activity

        // Coverage gap sheets
        case .startCoverageGap, .endCoverageGap, .gapDetection, .catchUp:
            return .coverageGap

        // Media sheets
        case .mediaPicker, .momentSourcePicker, .logMoment:
            return .media

        // Subscription sheets
        case .otisPlus, .subscriptionSuccess:
            return .subscription

        // Guide and informational sheets
        case .developmentJourney, .socializationWindow, .medicalCare,
             .crateTrainingGuide, .pottyTrainingGuide, .fullTimeline,
             .walkScheduleEditor, .addAppointmentWithPrefill:
            return .guide

        // Placeholder sheets (handled elsewhere)
        case .weightLog, .trainingLog, .socializationLog, .settings, .profileEdit, .notificationSettings, .groomingSettings, .groomingQuickLog:
            return .placeholder
        }
    }

    // MARK: - Main Content Builder

    /// Builds the appropriate view content for this sheet
    @MainActor @ViewBuilder
    func buildContent(context: SheetContentContext) -> some View {
        switch category {
        case .event:
            buildEventContent(context: context)

        case .activity:
            buildActivityContent(context: context)

        case .coverageGap:
            buildCoverageGapContent(context: context)

        case .media:
            buildMediaContent(context: context)

        case .subscription:
            buildSubscriptionContent(context: context)

        case .guide:
            buildGuideContent(context: context)

        case .placeholder:
            EmptyView()
        }
    }

    // MARK: - Content with Detents

    /// Builds content with appropriate presentation detents applied
    @MainActor @ViewBuilder
    func buildContentWithDetents(
        context: SheetContentContext,
        horizontalSizeClass: UserInterfaceSizeClass?
    ) -> some View {
        buildContent(context: context)
            .adaptivePresentationDetents(
                compact: compactDetents,
                regular: regularDetents
            )
    }
}
