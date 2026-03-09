//
//  TimelineViewModel+Predictions.swift
//  Otis-app
//
//  Prediction-related functionality for TimelineViewModel
//

import Combine
import Foundation
import OtisShared
import UIKit

extension TimelineViewModel {
    // MARK: - Potty Predictions

    /// Historical gap statistics for pattern-based predictions (last 7 days)
    private var historicalGapStats: GapStats {
        let historicalEvents = getHistoricalEvents(days: 7)
        let gaps = GapCalculations.recentGaps(events: historicalEvents, days: 7)
        return GapCalculations.calculateGapStats(gaps: gaps)
    }

    /// Expected gap based on historical patterns or default
    private var expectedGapMinutes: Int {
        guard let profile = profileStore.profile else { return 90 }
        let stats = historicalGapStats
        // Use median if we have enough data (5+ gaps), otherwise use default
        if stats.count >= 5 && stats.medianMinutes > 0 {
            return stats.medianMinutes
        }
        return profile.predictionConfig.defaultGapMinutes
    }

    /// Predicted minutes until next potty break
    var predictedNextPlasMinutes: Int? {
        // Use pattern-based expected gap
        guard let minutesSince = minutesSinceLastPlas else {
            return expectedGapMinutes
        }

        let remaining = expectedGapMinutes - minutesSince
        return max(0, remaining)
    }

    /// Predicted time for next potty break (for weather alerts)
    var predictedNextPlasTime: Date? {
        guard let minutes = predictedNextPlasMinutes else { return nil }
        return Date().addingTimeInterval(Double(minutes) * 60)
    }

    /// Current potty prediction with urgency level and triggers
    /// Uses cachedRecentEvents to avoid redundant database queries
    var pottyPrediction: PottyPrediction {
        guard let profile = profileStore.profile else {
            return PottyPrediction(
                urgency: .unknown,
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: nil,
                lastWasIndoor: false
            )
        }

        // Use cached recent events instead of querying each time
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents
        return PredictionCalculations.calculatePrediction(
            events: recentEvents,
            config: profile.predictionConfig,
            gapStats: historicalGapStats
        )
    }

    // MARK: - Sleep Status

    /// Current sleep state (sleeping, awake, or unknown)
    /// Uses cachedRecentEvents to avoid redundant database queries
    var currentSleepState: SleepState {
        // Use cached recent events instead of querying each time
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents
        return SleepCalculations.currentSleepState(events: recentEvents)
    }

    // MARK: - Combined Sleep + Potty Status

    /// Combined state for sleep + potty status display
    /// Determines which card(s) to show based on current conditions
    /// Uses cachedRecentEvents to avoid redundant database queries
    var combinedSleepPottyState: CombinedSleepPottyState {
        // Use cached recent events instead of querying each time
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents

        // Check for first run state FIRST (highest priority)
        // Only show for users who just completed onboarding with puppy already home
        if let profile = profileStore.profile,
           !dismissedFirstRunWelcome,
           isFirstRunState(recentEvents: recentEvents, profile: profile) {
            return .firstRun(puppyName: profile.name)
        }

        // Check if wake state should be cleared
        if CombinedStatusCalculations.shouldClearWakeState(
            wakeState: wakeTimePottyState,
            pottyWasLoggedSince: lastPottyLogTime
        ) {
            // Clear it asynchronously
            Task { @MainActor in
                self.clearPostWakeState()
            }
        }

        return CombinedStatusCalculations.calculateCombinedState(
            sleepState: currentSleepState,
            pottyPrediction: pottyPrediction,
            wakeTimePottyState: wakeTimePottyState,
            recentEvents: recentEvents,
            dismissedAssumedSleepDate: dismissedAssumedSleepDate,
            hasActiveCoverageGap: activeCoverageGap != nil,
            dismissedStaleLoggingDate: dismissedStaleLoggingDate
        )
    }

    /// Check if this is a first run state (just completed onboarding, no events yet)
    private func isFirstRunState(recentEvents: [PuppyEvent], profile: PuppyProfile) -> Bool {
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

    // MARK: - Poop Status

    /// Current poop status with pattern-based insights
    var poopStatus: PoopStatus {
        let ageInWeeks = profileStore.profile?.ageInWeeks ?? 26
        let historicalEvents = getHistoricalEvents(days: PoopCalculations.patternAnalysisDays)

        return PoopCalculations.calculateStatus(
            todayEvents: events,
            historicalEvents: historicalEvents,
            ageInWeeks: ageInWeeks
        )
    }

    // MARK: - Pattern Analysis

    /// Pattern analysis for last 7 days (uses cached value for performance)
    var patternAnalysis: PatternAnalysis {
        // Return cached value if available
        if let cached = cachedPatternAnalysis {
            return cached
        }
        // Fallback to computing (shouldn't happen often)
        let sevenDaysAgo = Date().addingDays(-7)
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        return PatternCalculations.analyzePatterns(events: recentEvents, periodDays: 7)
    }

    // MARK: - Streaks

    /// Current streak information
    var streakInfo: StreakInfo {
        // Get all events for accurate streak calculation
        let allEvents = getAllEvents()
        return StreakCalculations.getStreakInfo(events: allEvents)
    }

    /// Outdoor potty percentage for the past 7 days
    /// Uses the same data source as streakInfo for consistency
    var outdoorPercentage: Int {
        let recentEvents = getHistoricalEvents(days: 7)
        let peeEvents = recentEvents.pee()

        let outdoorCount = peeEvents.filter { $0.location == .buiten }.count
        let totalCount = peeEvents.count

        guard totalCount > 0 else { return 0 }
        return (outdoorCount * 100) / totalCount
    }

    /// Number of consecutive days at 100% outdoor potty success
    /// Delegates to PottyMasteryService
    var consecutivePerfectDays: Int {
        PottyMasteryService.consecutivePerfectDays(eventStore: eventStore)
    }

    /// Whether potty training guide should be shown in Train tab
    /// Delegates to PottyMasteryService
    var shouldShowPottyTrainingGuide: Bool {
        PottyMasteryService.shouldShowPottyTrainingGuide(eventStore: eventStore)
    }

    /// Whether the potty mastery prompt card should be shown
    /// Delegates to PottyMasteryService
    var shouldShowPottyMasteryPrompt: Bool {
        PottyMasteryService.shouldShowMasteryPrompt(eventStore: eventStore)
    }

    // MARK: - Potty Mastery Incident Tracking

    /// Indoor incidents since potty training was mastered
    var incidentsSincePottyMastery: [PuppyEvent] {
        let historicalEvents = getHistoricalEvents(days: 30)
        return PottyMasteryService.incidentsSinceMastery(historicalEvents: historicalEvents)
    }

    /// Indoor incidents in the last 7 days
    var indoorIncidentsLastWeek: [PuppyEvent] {
        PottyMasteryService.indoorIncidentsLastWeek(historicalEvents: getHistoricalEvents(days: 7))
    }

    /// Whether to show reactivation prompt (3+ incidents in a week after mastering)
    var shouldShowPottyReactivationPrompt: Bool {
        PottyMasteryService.shouldShowReactivationPrompt(indoorIncidentsLastWeek: indoorIncidentsLastWeek)
    }

    /// Whether to show gentle incident message (1-2 incidents, not yet reactivation)
    var shouldShowPottyIncidentMessage: Bool {
        PottyMasteryService.shouldShowIncidentMessage(
            incidentsSinceMastery: incidentsSincePottyMastery,
            shouldShowReactivationPrompt: shouldShowPottyReactivationPrompt
        )
    }

    // MARK: - Daily Digest

    /// Daily digest summary for current date
    var dailyDigest: DailyDigest {
        DigestCalculations.generateDigest(
            events: events,
            profile: profileStore.profile,
            date: currentDate
        )
    }

    // MARK: - Upcoming Events

    /// Upcoming meals and walks for today, with optional weather forecasts
    /// Returns legacy format with all items combined
    func upcomingItems(forecasts: [HourForecast] = []) -> [UpcomingItem] {
        guard let profile = profileStore.profile else { return [] }
        return UpcomingCalculations.calculateUpcoming(
            events: events,
            mealSchedule: profile.mealSchedule,
            walkSchedule: profile.walkSchedule,
            forecasts: forecasts,
            date: currentDate,
            isWalkInProgress: isWalkInProgress
        )
    }

    /// Separated actionable and upcoming items
    /// - Actionable: items within 10 min or overdue (shown prominently)
    /// - Upcoming: items more than 10 min away (shown in compact list)
    func separatedUpcomingItems(forecasts: [HourForecast] = []) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        guard let profile = profileStore.profile else { return ([], []) }
        let separated: (actionable: [ActionableItem], upcoming: [UpcomingItem]) = UpcomingCalculations.calculateUpcoming(
            events: events,
            mealSchedule: profile.mealSchedule,
            walkSchedule: profile.walkSchedule,
            forecasts: forecasts,
            date: currentDate,
            isWalkInProgress: isWalkInProgress
        )
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents
        return AINudgeOrchestrator.shared.reorderUpcomingItems(
            profile: profile,
            actionable: separated.actionable,
            upcoming: separated.upcoming,
            recentEvents: recentEvents
        )
    }

    /// Optional AI-enhanced status copy for the daily potty card.
    /// Falls back to deterministic prediction strings when AI is unavailable.
    var aiEnhancedPottyStatusCopy: (title: String, subtitle: String?) {
        let baselineTitle = PredictionCalculations.displayText(for: pottyPrediction, puppyName: puppyName)
        let baselineSubtitle = PredictionCalculations.subtitleText(for: pottyPrediction)
        guard let profile = profileStore.profile else {
            return (baselineTitle, baselineSubtitle)
        }
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents
        return AINudgeOrchestrator.shared.dailyStatusCopy(
            profile: profile,
            baselineTitle: baselineTitle,
            baselineSubtitle: baselineSubtitle,
            prediction: pottyPrediction,
            sleepState: currentSleepState,
            recentEvents: recentEvents
        )
    }

    var aiLoggingRecommendations: [AILoggingCategoryRecommendation] {
        guard let profile = profileStore.profile else { return [] }
        return AINudgeOrchestrator.shared.pendingLoggingRecommendations(for: profile.id)
    }

    func applyAILoggingRecommendation(_ recommendation: AILoggingCategoryRecommendation) {
        guard var profile = profileStore.profile else { return }

        var settings = profile.notificationSettings
        switch recommendation.category {
        case .potty:
            settings.pottyReminders.isEnabled = false
        case .walk:
            settings.walkReminders.isEnabled = false
        case .meal:
            settings.mealReminders.isEnabled = false
        case .training, .socialization:
            // No category-specific reminder toggles yet; acknowledge only.
            break
        }

        profile.notificationSettings = settings
        profileStore.updateNotificationSettings(settings, for: profile.id)
        notifyRefreshNotifications()
        AINudgeOrchestrator.shared.markRecommendationApplied(profileID: profile.id, category: recommendation.category)
        HapticFeedback.success()
    }

    func dismissAILoggingRecommendation(_ recommendation: AILoggingCategoryRecommendation) {
        guard let profile = profileStore.profile else { return }
        AINudgeOrchestrator.shared.markRecommendationDismissed(profileID: profile.id, category: recommendation.category)
        HapticFeedback.selection()
        // Trigger view update so the card disappears
        objectWillChange.send()
    }

    // MARK: - First Week Card

    /// Whether the first week card should be shown
    /// Delegates to FirstWeekCardService
    var shouldShowFirstWeekCard: Bool {
        FirstWeekCardService.shouldShowCard(profile: profileStore.profile, isShowingToday: isShowingToday)
    }

    /// Whether the first week card is currently collapsed
    /// Delegates to FirstWeekCardService
    var isFirstWeekCardCollapsed: Bool {
        FirstWeekCardService.isCollapsed
    }

    /// Toggle the first week card collapsed state
    func toggleFirstWeekCard() {
        FirstWeekCardService.toggleCollapsed()
        objectWillChange.send()
    }

    /// Calculate first week stats for the card
    /// Delegates to FirstWeekCardService
    var firstWeekStats: FirstWeekStats? {
        FirstWeekCardService.calculateStats(
            profile: profileStore.profile,
            todayEvents: events,
            eventStore: eventStore
        )
    }
}
