//
//  SheetContent+CoverageGaps.swift
//  Otis-app
//
//  Sheet content builders for coverage gap and catch-up sheets
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    // MARK: - Coverage Gap Sheets

    @MainActor @ViewBuilder
    func buildCoverageGapContent(context: SheetContentContext) -> some View {
        switch self {
        case .startCoverageGap:
            StartCoverageGapSheet(
                onSave: { gapType, startTime, location, note in
                    context.viewModel.startCoverageGap(type: gapType, startTime: startTime, location: location, note: note)
                    context.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        case .endCoverageGap(let gap):
            EndCoverageGapSheet(
                gap: gap,
                onEnd: { endTime, note in
                    context.viewModel.endCoverageGap(gap, endTime: endTime, note: note)
                    context.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        case .gapDetection(let hours, let puppyName, let suggestedStartTime):
            GapDetectionSheet(
                hours: hours,
                puppyName: puppyName,
                suggestedStartTime: suggestedStartTime,
                onLogCoverage: {
                    context.sheetCoordinator.transitionToSheet(.startCoverageGap)
                },
                onDismiss: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        case .catchUp(let hours, let puppyName, let catchUpContext):
            CatchUpSheet(
                puppyName: puppyName,
                hoursSinceLastEvent: hours,
                context: catchUpContext,
                onComplete: { result in
                    context.viewModel.processCatchUpResult(result)
                    context.sheetCoordinator.dismissSheet()
                },
                onSkip: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        default:
            EmptyView()
        }
    }
}
