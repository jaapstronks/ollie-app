//
//  CombinedStatusCalculations.swift
//  Ollie-app
//
//  Combined sleep + potty state machine for intelligent status card display
//  Prevents conflicting messages like "needs to pee NOW" while sleeping

import Foundation
import OllieShared

/// Combined state for sleep + potty status display
/// Determines which card(s) to show based on current conditions
enum CombinedSleepPottyState: Equatable {
    /// Puppy is awake - show normal separate cards
    case awake

    /// Sleeping, potty is not urgent - show only sleep card, hide potty card
    case sleepingPottyOkay(sleepingSince: Date, sleepDurationMin: Int)

    /// Sleeping, but potty is urgent/overdue - show combined card
    case sleepingPottyUrgent(
        sleepingSince: Date,
        sleepDurationMin: Int,
        pottyUrgency: PottyUrgency,
        minutesOverdue: Int?
    )

    /// Just woke up and potty was urgent while sleeping - show post-wake prompt
    case justWokeNeedsPotty(
        wokeAt: Date,
        minutesSinceWake: Int,
        pottyWasOverdueBy: Int?
    )

    /// Unknown state - show nothing special
    case unknown

    // MARK: - Computed Properties

    /// Whether the puppy is currently sleeping
    var isSleeping: Bool {
        switch self {
        case .sleepingPottyOkay, .sleepingPottyUrgent:
            return true
        default:
            return false
        }
    }

    /// Whether we should show the post-wake potty prompt
    var shouldShowPostWakePrompt: Bool {
        if case .justWokeNeedsPotty = self { return true }
        return false
    }

    /// Whether we should show the combined sleep+potty card
    var shouldShowCombinedCard: Bool {
        if case .sleepingPottyUrgent = self { return true }
        return false
    }

    /// Whether we should show normal separate cards
    var shouldShowSeparateCards: Bool {
        if case .awake = self { return true }
        return false
    }

    /// Whether we should hide the standalone potty card
    var shouldHidePottyCard: Bool {
        switch self {
        case .sleepingPottyOkay, .sleepingPottyUrgent, .justWokeNeedsPotty:
            return true
        default:
            return false
        }
    }

    /// Whether we should hide the standalone sleep card
    var shouldHideSleepCard: Bool {
        switch self {
        case .sleepingPottyUrgent:
            return true
        default:
            return false
        }
    }
}

/// Potty urgency level captured at wake time (for post-wake tracking)
struct WakeTimePottyState: Equatable {
    let capturedAt: Date
    let wasOverdue: Bool
    let minutesOverdue: Int?
    let minutesSinceLast: Int?

    /// Duration in minutes to show the post-wake prompt
    static let postWakePromptDurationMinutes = 10

    /// Whether the post-wake prompt has expired
    var hasExpired: Bool {
        let minutesSinceWake = Date().minutesSince(capturedAt)
        return minutesSinceWake >= Self.postWakePromptDurationMinutes
    }
}

/// Calculations for combined sleep + potty state
struct CombinedStatusCalculations {

    // MARK: - Public Methods

    /// Calculate the combined state based on sleep and potty status
    /// - Parameters:
    ///   - sleepState: Current sleep state (sleeping, awake, unknown)
    ///   - pottyPrediction: Current potty prediction with urgency
    ///   - wakeTimePottyState: Captured potty state at wake time (if any)
    /// - Returns: Combined state for display logic
    static func calculateCombinedState(
        sleepState: SleepState,
        pottyPrediction: PottyPrediction,
        wakeTimePottyState: WakeTimePottyState?
    ) -> CombinedSleepPottyState {

        // Check for post-wake state first (takes priority if just woke with urgent potty)
        if let wakeState = wakeTimePottyState,
           wakeState.wasOverdue,
           !wakeState.hasExpired,
           sleepState.isAwake {
            let minutesSinceWake = Date().minutesSince(wakeState.capturedAt)
            return .justWokeNeedsPotty(
                wokeAt: wakeState.capturedAt,
                minutesSinceWake: minutesSinceWake,
                pottyWasOverdueBy: wakeState.minutesOverdue
            )
        }

        switch sleepState {
        case .sleeping(let since, let durationMin):
            // Check if potty is urgent while sleeping
            if isPottyUrgent(pottyPrediction.urgency) {
                return .sleepingPottyUrgent(
                    sleepingSince: since,
                    sleepDurationMin: durationMin,
                    pottyUrgency: pottyPrediction.urgency,
                    minutesOverdue: minutesOverdue(from: pottyPrediction.urgency)
                )
            } else {
                return .sleepingPottyOkay(
                    sleepingSince: since,
                    sleepDurationMin: durationMin
                )
            }

        case .awake:
            return .awake

        case .unknown:
            return .unknown
        }
    }

    /// Capture the potty state at wake time (for post-wake tracking)
    /// - Parameter pottyPrediction: Current potty prediction
    /// - Returns: Captured state if potty was urgent, nil otherwise
    static func captureWakeTimePottyState(
        pottyPrediction: PottyPrediction
    ) -> WakeTimePottyState? {
        let overdue = minutesOverdue(from: pottyPrediction.urgency)
        let isUrgent = isPottyUrgent(pottyPrediction.urgency)

        // Only capture if potty was soon or overdue
        guard isUrgent else { return nil }

        return WakeTimePottyState(
            capturedAt: Date(),
            wasOverdue: overdue != nil && overdue! > 0,
            minutesOverdue: overdue,
            minutesSinceLast: pottyPrediction.minutesSinceLast
        )
    }

    /// Check if the captured wake state should be cleared
    /// (e.g., potty was logged, or timeout expired)
    static func shouldClearWakeState(
        wakeState: WakeTimePottyState?,
        pottyWasLoggedSince: Date?
    ) -> Bool {
        guard let wakeState = wakeState else { return false }

        // Clear if expired
        if wakeState.hasExpired { return true }

        // Clear if potty was logged after wake
        if let logTime = pottyWasLoggedSince, logTime > wakeState.capturedAt {
            return true
        }

        return false
    }

    // MARK: - Private Helpers

    /// Check if potty urgency is at a level we consider "urgent"
    /// (soon, overdue, or post-accident)
    private static func isPottyUrgent(_ urgency: PottyUrgency) -> Bool {
        switch urgency {
        case .soon, .overdue, .postAccident:
            return true
        default:
            return false
        }
    }

    /// Extract minutes overdue from urgency (if applicable)
    private static func minutesOverdue(from urgency: PottyUrgency) -> Int? {
        switch urgency {
        case .overdue(let minutes):
            return minutes
        case .soon(let remaining) where remaining <= 0:
            return 0
        default:
            return nil
        }
    }
}
