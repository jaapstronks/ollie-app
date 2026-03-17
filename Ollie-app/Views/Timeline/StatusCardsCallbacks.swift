//
//  StatusCardsCallbacks.swift
//  Ollie-app
//
//  Groups all callbacks for TodayStatusCardsSection to simplify the interface.
//

import Foundation
import OtisShared

/// Groups all callbacks for TodayStatusCardsSection
/// Reduces init parameters from 25+ to a single struct
@MainActor
struct StatusCardsCallbacks {

    // MARK: - Nudge Callbacks

    /// Callbacks for nudge card actions (dismiss, complete, etc.)
    struct NudgeCallbacks {
        var onDismissCrateNudge: () -> Void
        var onDismissWalkTargetNudge: () -> Void
        var onDismissGroomingNudge: () -> Void
        var onDismissAppointmentNudge: (String) -> Void
        var onMarkAppointmentDone: (AppointmentNudgeCandidate) -> Void
        var onCreateAppointmentPrefill: (AppointmentNudgeCandidate) -> AppointmentPrefill?
        var onMarkGroomingComplete: (GroomingActivity) -> Void
        var onViewAllGrooming: () -> Void

        @MainActor static let empty = NudgeCallbacks(
            onDismissCrateNudge: {},
            onDismissWalkTargetNudge: {},
            onDismissGroomingNudge: {},
            onDismissAppointmentNudge: { _ in },
            onMarkAppointmentDone: { _ in },
            onCreateAppointmentPrefill: { _ in nil },
            onMarkGroomingComplete: { _ in },
            onViewAllGrooming: {}
        )
    }

    // MARK: - Recap Callbacks

    /// Callbacks for recap card navigation
    struct RecapCallbacks {
        var onShowMonthRecap: () -> Void
        var onShowYearRecap: () -> Void

        @MainActor static let empty = RecapCallbacks(
            onShowMonthRecap: {},
            onShowYearRecap: {}
        )
    }

    // MARK: - First Week Callbacks

    /// Callbacks for first week prompt cards
    struct FirstWeekCallbacks {
        var onAddPhoto: () -> Void
        var onInviteFamily: () -> Void

        @MainActor static let empty = FirstWeekCallbacks(
            onAddPhoto: {},
            onInviteFamily: {}
        )
    }

    // MARK: - Recent Moment Callbacks

    /// Callbacks for recent moment card
    struct RecentMomentCallbacks {
        var onNavigateToDiary: () -> Void
        var onDismiss: () -> Void

        @MainActor static let empty = RecentMomentCallbacks(
            onNavigateToDiary: {},
            onDismiss: {}
        )
    }

    // MARK: - Properties

    var nudge: NudgeCallbacks
    var recap: RecapCallbacks
    var firstWeek: FirstWeekCallbacks
    var recentMoment: RecentMomentCallbacks
    var onNavigateToTrain: (() -> Void)?

    // MARK: - Convenience Init

    init(
        nudge: NudgeCallbacks = .empty,
        recap: RecapCallbacks = .empty,
        firstWeek: FirstWeekCallbacks = .empty,
        recentMoment: RecentMomentCallbacks = .empty,
        onNavigateToTrain: (() -> Void)? = nil
    ) {
        self.nudge = nudge
        self.recap = recap
        self.firstWeek = firstWeek
        self.recentMoment = recentMoment
        self.onNavigateToTrain = onNavigateToTrain
    }

    /// Empty callbacks for previews
    static let empty = StatusCardsCallbacks()
}
