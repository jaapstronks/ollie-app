//
//  SheetContent+Activities.swift
//  Otis-app
//
//  Sheet content builders for activity-related sheets (walks, naps, sleep)
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    // MARK: - Activity Sheets

    @MainActor @ViewBuilder
    func buildActivityContent(context: SheetContentContext) -> some View {
        switch self {
        case .startActivity(let activityType, let preselectedLocation):
            StartActivitySheet(
                activityType: activityType,
                puppyName: context.puppyName,
                preselectedLocation: preselectedLocation,
                onStartNow: { startTime, napLocation in
                    context.viewModel.startActivity(type: activityType, startTime: startTime, napLocation: napLocation)
                    context.sheetCoordinator.dismissSheet()
                },
                onLogCompleted: {
                    handleLogCompletedActivity(activityType, context: context)
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        case .endActivity:
            if let activity = context.viewModel.currentActivity {
                ActivityEndSheet(
                    activity: activity,
                    onEnd: { minutesAgo, note in
                        context.viewModel.endActivity(minutesAgo: minutesAgo, note: note)
                    },
                    onCancel: {
                        context.sheetCoordinator.dismissSheet()
                    },
                    onDiscard: {
                        context.viewModel.cancelActivity()
                    }
                )
            } else {
                EmptyView()
            }

        case .endSleep(let startTime):
            EndSleepSheet(
                sleepStartTime: startTime,
                onSave: { wakeUpTime in
                    context.viewModel.logWakeUp(time: wakeUpTime)
                    context.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        case .walkLog:
            WalkLogSheet(
                onSave: { startTime, duration, didPee, didPoop, spot, note in
                    context.viewModel.logWalkEvent(
                        time: startTime,
                        durationMin: duration,
                        didPee: didPee,
                        didPoop: didPoop,
                        spot: spot,
                        note: note
                    )
                    context.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                },
                spotStore: context.spotStore,
                locationManager: context.locationManager
            )

        case .napLog(let defaultDuration):
            NapLogSheet(
                onSave: { startTime, endTime, note, napLocation in
                    context.viewModel.logCompletedNap(startTime: startTime, endTime: endTime, note: note, napLocation: napLocation)
                    context.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                },
                defaultDurationMinutes: defaultDuration
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    @MainActor
    private func handleLogCompletedActivity(_ activityType: ActivityType, context: SheetContentContext) {
        if activityType == .walk {
            context.sheetCoordinator.transitionToSheet(.walkLog)
        } else {
            let recentEvents = context.viewModel.getRecentEvents()
            let defaultDuration = SleepCalculations.defaultNapDuration(events: recentEvents)
            context.sheetCoordinator.transitionToSheet(.napLog(defaultDuration: defaultDuration))
        }
    }
}
