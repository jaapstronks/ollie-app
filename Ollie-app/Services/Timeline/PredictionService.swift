//
//  PredictionService.swift
//  Otis-app
//
//  Extracted from TimelineViewModel+Predictions.swift
//  Handles potty/sleep predictions, streaks, and pattern analysis
//

import Foundation
import OtisShared

/// Handles prediction calculations and state management
/// Extracted from TimelineViewModel to improve testability and separation of concerns
@Observable
@MainActor
final class PredictionService {

    // MARK: - Dependencies

    @ObservationIgnored private let profileStore: ProfileStore

    // MARK: - State

    private(set) var pottyPrediction: PottyPrediction
    private(set) var sleepState: SleepState
    private(set) var combinedState: CombinedSleepPottyState
    private(set) var poopStatus: PoopStatus
    private(set) var streakInfo: StreakInfo
    private(set) var dailyDigest: DailyDigest
    private(set) var wakeTimePottyState: WakeTimePottyState?

    // MARK: - Internal State

    /// Time of last potty event (for clearing post-wake state)
    @ObservationIgnored private(set) var lastPottyLogTime: Date?

    /// Date when user dismissed the assumed overnight sleep card
    @ObservationIgnored var dismissedAssumedSleepDate: Date?

    /// Date when user dismissed the stale logging banner
    @ObservationIgnored var dismissedStaleLoggingDate: Date?

    /// Whether user has dismissed the first run welcome
    @ObservationIgnored var dismissedFirstRunWelcome: Bool = UserDefaults.standard.bool(forKey: "dismissedFirstRunWelcome")

    // MARK: - Init

    init(profileStore: ProfileStore) {
        self.profileStore = profileStore

        // Initialize with default values
        self.pottyPrediction = PottyPrediction(
            urgency: .unknown,
            trigger: .none,
            expectedGapMinutes: 90,
            minutesSinceLast: nil,
            lastWasIndoor: false
        )
        self.sleepState = .unknown
        self.combinedState = .unknown
        self.poopStatus = PoopStatus(
            todayCount: 0,
            expectedRange: 2...4,
            lastPoopTime: nil,
            daytimeMinutesSinceLast: nil,
            recentWalkWithoutPoop: false,
            urgency: .good,
            message: nil,
            hasPatternData: false,
            patternDailyMedian: nil
        )
        self.streakInfo = StreakInfo(
            currentStreak: 0,
            bestStreak: 0,
            lastOutdoorTime: nil,
            lastIndoorTime: nil
        )
        self.dailyDigest = DailyDigest(dayNumber: nil, parts: [])
    }

    // MARK: - Refresh

    /// Refresh all prediction state from events
    func refresh(
        todayEvents: [PuppyEvent],
        recentEvents: [PuppyEvent],
        historicalEvents: [PuppyEvent],
        allEvents: [PuppyEvent],
        currentDate: Date,
        isShowingToday: Bool,
        hasActiveCoverageGap: Bool
    ) {
        // PERFORMANCE: Check debug toggle to skip expensive prediction calculations
        guard !PerformanceDebug.disablePredictions else {
            if PerformanceDebug.logExpensiveOperations {
                print("[PERF] SKIPPED: PredictionService.refresh (disabled by toggle)")
            }
            return
        }

        guard let profile = profileStore.profile else {
            // Reset to defaults if no profile
            pottyPrediction = PottyPrediction(
                urgency: .unknown,
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: nil,
                lastWasIndoor: false
            )
            sleepState = .unknown
            combinedState = .unknown
            return
        }

        // Calculate historical gap stats
        let gaps = GapCalculations.recentGaps(events: historicalEvents, days: 7)
        let gapStats = GapCalculations.calculateGapStats(gaps: gaps)

        // Update potty prediction
        pottyPrediction = PredictionCalculations.calculatePrediction(
            events: recentEvents,
            config: profile.predictionConfig,
            gapStats: gapStats
        )

        // Update sleep state
        sleepState = SleepCalculations.currentSleepState(events: recentEvents)

        // Check if wake state should be cleared
        if CombinedStatusCalculations.shouldClearWakeState(
            wakeState: wakeTimePottyState,
            pottyWasLoggedSince: lastPottyLogTime
        ) {
            clearPostWakeState()
        }

        // Update combined state
        if !dismissedFirstRunWelcome && isFirstRunState(recentEvents: recentEvents, profile: profile, isShowingToday: isShowingToday) {
            combinedState = .firstRun(puppyName: profile.name)
        } else {
            combinedState = CombinedStatusCalculations.calculateCombinedState(
                sleepState: sleepState,
                pottyPrediction: pottyPrediction,
                wakeTimePottyState: wakeTimePottyState,
                recentEvents: recentEvents,
                dismissedAssumedSleepDate: dismissedAssumedSleepDate,
                hasActiveCoverageGap: hasActiveCoverageGap,
                dismissedStaleLoggingDate: dismissedStaleLoggingDate
            )
        }

        // Update poop status
        let ageInWeeks = profile.ageInWeeks
        poopStatus = PoopCalculations.calculateStatus(
            todayEvents: todayEvents,
            historicalEvents: historicalEvents,
            ageInWeeks: ageInWeeks
        )

        // Update streak info
        streakInfo = StreakCalculations.getStreakInfo(events: allEvents)

        // Update daily digest
        dailyDigest = DigestCalculations.generateDigest(
            events: todayEvents,
            profile: profile,
            date: currentDate
        )
    }

    // MARK: - Potty State Tracking

    /// Record potty log time for post-wake state tracking
    func recordPottyLogTime() {
        lastPottyLogTime = Date()
        // Clear post-wake state when potty is logged
        wakeTimePottyState = nil
    }

    /// Capture wake time potty state for post-wake tracking
    func captureWakeTimePottyState() {
        wakeTimePottyState = CombinedStatusCalculations.captureWakeTimePottyState(
            pottyPrediction: pottyPrediction
        )
    }

    /// Clear the post-wake potty state manually
    func clearPostWakeState() {
        wakeTimePottyState = nil
    }

    // MARK: - First Run State

    /// Dismiss the first run welcome permanently
    func dismissFirstRunWelcome() {
        dismissedFirstRunWelcome = true
        UserDefaults.standard.set(true, forKey: "dismissedFirstRunWelcome")
    }

    // MARK: - Assumed Overnight Sleep

    /// Dismiss the assumed overnight sleep card for today
    func dismissAssumedOvernightSleep() {
        dismissedAssumedSleepDate = Date()
        HapticFeedback.selection()
    }

    // MARK: - Stale Logging

    /// Dismiss the stale logging banner for today
    func dismissStaleLogging() {
        dismissedStaleLoggingDate = Date()
        HapticFeedback.selection()
    }

    // MARK: - Helper Methods

    /// Calculate outdoor potty percentage for the past N days
    func outdoorPercentage(historicalEvents: [PuppyEvent]) -> Int {
        let peeEvents = historicalEvents.pee()

        let outdoorCount = peeEvents.filter { $0.location == .buiten }.count
        let totalCount = peeEvents.count

        guard totalCount > 0 else { return 0 }
        return (outdoorCount * 100) / totalCount
    }

    /// Calculate predicted next potty time (for weather alerts)
    var predictedNextPlasTime: Date? {
        guard let minutes = pottyPrediction.minutesSinceLast else { return nil }
        let remaining = pottyPrediction.expectedGapMinutes - minutes
        guard remaining > 0 else { return nil }
        return Date().addingTimeInterval(Double(remaining) * 60)
    }

    // MARK: - Private Helpers

    /// Check if this is a first run state (just completed onboarding, no events yet)
    private func isFirstRunState(recentEvents: [PuppyEvent], profile: PuppyProfile, isShowingToday: Bool) -> Bool {
        // Must be viewing today
        guard isShowingToday else { return false }

        // Puppy must already be home (homeDate <= today)
        guard profile.daysHome >= 0 else { return false }

        // Must be within first 2 days of having the puppy
        guard profile.daysHome <= 1 else { return false }

        // No events logged yet (excluding system events like coverage gaps)
        let userEvents = recentEvents.filter { $0.type != .coverageGap }
        return userEvents.isEmpty
    }
}
