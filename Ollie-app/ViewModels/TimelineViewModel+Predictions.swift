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
    /// PERF: Uses cached value from TimelineStatsCache instead of computing on every access
    private var historicalGapStats: GapStats {
        cachedGapStats
    }

    /// Expected gap based on historical patterns or default
    private var expectedGapMinutes: Int {
        guard let profile = profileStore.profile else { return 90 }
        let stats = cachedGapStats
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
    /// PERFORMANCE: Uses cached events to avoid synchronous Core Data fetch
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

        // PERFORMANCE: Use EventDataProvider's cached data instead of synchronous fetch
        let recentEvents = cachedRecentEvents.isEmpty ? eventDataProvider.recentEvents : cachedRecentEvents
        return PredictionCalculations.calculatePrediction(
            events: recentEvents,
            config: profile.predictionConfig,
            gapStats: historicalGapStats
        )
    }

    // MARK: - Sleep Status

    /// Current sleep state (sleeping, awake, or unknown)
    /// PERFORMANCE: Uses cached events to avoid synchronous Core Data fetch
    var currentSleepState: SleepState {
        // PERFORMANCE: Use EventDataProvider's cached data instead of synchronous fetch
        let recentEvents = cachedRecentEvents.isEmpty ? eventDataProvider.recentEvents : cachedRecentEvents
        return SleepCalculations.currentSleepState(events: recentEvents)
    }

    // MARK: - Combined Sleep + Potty Status

    /// Combined state for sleep + potty status display
    /// Determines which card(s) to show based on current conditions
    /// Uses cachedRecentEvents to avoid redundant database queries
    var combinedSleepPottyState: CombinedSleepPottyState {
        // PERFORMANCE: Use EventDataProvider's cached data instead of synchronous fetch
        let recentEvents = cachedRecentEvents.isEmpty ? eventDataProvider.recentEvents : cachedRecentEvents
        return calculateCombinedState(withEvents: recentEvents)
    }

    /// Calculate combined state using the provided events
    /// Use this when you have fresh events that haven't been cached yet (e.g., right after logging)
    func calculateCombinedState(withEvents recentEvents: [PuppyEvent]) -> CombinedSleepPottyState {
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
            // Clear it asynchronously - use DispatchQueue to ensure it runs AFTER view body completes
            // Task { @MainActor } can execute immediately, causing "Publishing changes from within view updates"
            DispatchQueue.main.async { [weak self] in
                self?.clearPostWakeState()
            }
        }

        // Calculate sleep state from the provided events (not cached)
        let sleepState = SleepCalculations.currentSleepState(events: recentEvents)

        // Calculate potty prediction from the provided events
        let prediction: PottyPrediction
        if let profile = profileStore.profile {
            prediction = PredictionCalculations.calculatePrediction(
                events: recentEvents,
                config: profile.predictionConfig,
                gapStats: cachedGapStats
            )
        } else {
            prediction = PottyPrediction(
                urgency: .unknown,
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: nil,
                lastWasIndoor: false
            )
        }

        return CombinedStatusCalculations.calculateCombinedState(
            sleepState: sleepState,
            pottyPrediction: prediction,
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
    /// PERFORMANCE: Uses cached events from EventDataProvider to avoid synchronous Core Data fetch
    var poopStatus: PoopStatus {
        let ageInWeeks = profileStore.profile?.ageInWeeks ?? 26
        // Use cached extended events (15 days) which covers the 14-day pattern analysis
        let historicalEvents = eventDataProvider.extendedEvents

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
        // PERFORMANCE: Fallback uses EventDataProvider's cached week events (no DB fetch)
        let recentEvents = eventDataProvider.weekEvents
        return PatternCalculations.analyzePatterns(events: recentEvents, periodDays: 7)
    }

    // MARK: - Streaks

    /// Current streak information
    /// PERFORMANCE: Use cached events from EventDataProvider to avoid synchronous Core Data fetch
    var streakInfo: StreakInfo {
        // Use cached month events (30 days) for streak calculation
        let allEvents = eventDataProvider.monthEvents
        return StreakCalculations.getStreakInfo(events: allEvents)
    }

    /// Outdoor potty percentage for the past 7 days
    /// PERFORMANCE: Use cached events from EventDataProvider to avoid synchronous Core Data fetch
    var outdoorPercentage: Int {
        // Use cached week events instead of synchronous fetch
        let recentEvents = cachedRecentEvents.isEmpty ? eventDataProvider.weekEvents : cachedRecentEvents
        let peeEvents = recentEvents.pee()

        let outdoorCount = peeEvents.filter { $0.location == .buiten }.count
        let totalCount = peeEvents.count

        guard totalCount > 0 else { return 0 }
        return (outdoorCount * 100) / totalCount
    }

    /// Number of consecutive days at 100% outdoor potty success
    /// PERFORMANCE: Use cached events from EventDataProvider to avoid synchronous Core Data fetch
    var consecutivePerfectDays: Int {
        // Use cached extended events (15 days) which covers the 14-day lookback
        let cachedEvents = eventDataProvider.extendedEvents
        return PottyMasteryService.consecutivePerfectDays(from: cachedEvents)
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
    /// PERFORMANCE: Uses cached events from EventDataProvider to avoid synchronous Core Data fetch
    var incidentsSincePottyMastery: [PuppyEvent] {
        // Use cached month events (30 days)
        let historicalEvents = eventDataProvider.monthEvents
        return PottyMasteryService.incidentsSinceMastery(historicalEvents: historicalEvents)
    }

    /// Indoor incidents in the last 7 days
    /// PERFORMANCE: Uses cached events from EventDataProvider to avoid synchronous Core Data fetch
    var indoorIncidentsLastWeek: [PuppyEvent] {
        // Use cached week events
        PottyMasteryService.indoorIncidentsLastWeek(historicalEvents: eventDataProvider.weekEvents)
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
    /// PERFORMANCE: Uses cached events to avoid synchronous Core Data fetch
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
        // PERFORMANCE: Use EventDataProvider's cached data instead of synchronous fetch
        let recentEvents = cachedRecentEvents.isEmpty ? eventDataProvider.recentEvents : cachedRecentEvents
        return AINudgeOrchestrator.shared.reorderUpcomingItems(
            profile: profile,
            actionable: separated.actionable,
            upcoming: separated.upcoming,
            recentEvents: recentEvents
        )
    }

    /// Optional AI-enhanced status copy for the daily potty card.
    /// Falls back to deterministic prediction strings when AI is unavailable.
    /// PERFORMANCE: Uses cached events to avoid synchronous Core Data fetch
    var aiEnhancedPottyStatusCopy: (title: String, subtitle: String?) {
        let baselineTitle = PredictionCalculations.displayText(for: pottyPrediction, puppyName: puppyName)
        let baselineSubtitle = PredictionCalculations.subtitleText(for: pottyPrediction)
        guard let profile = profileStore.profile else {
            return (baselineTitle, baselineSubtitle)
        }
        // PERFORMANCE: Use EventDataProvider's cached data instead of synchronous fetch
        let recentEvents = cachedRecentEvents.isEmpty ? eventDataProvider.recentEvents : cachedRecentEvents
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
        // With @Observable, touching a tracked property triggers view update
        // The aiLoggingRecommendations computed property will return updated values
        refreshTrigger += 1
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
        // With @Observable, touching a tracked property triggers view update
        refreshTrigger += 1
    }

    /// Calculate first week stats for the card
    /// PERFORMANCE: Uses cached events from EventDataProvider to avoid synchronous Core Data fetches
    var firstWeekStats: FirstWeekStats? {
        FirstWeekCardService.calculateStats(
            profile: profileStore.profile,
            todayEvents: events,
            recentEvents: eventDataProvider.recentEvents,
            weekEvents: eventDataProvider.weekEvents
        )
    }
}
