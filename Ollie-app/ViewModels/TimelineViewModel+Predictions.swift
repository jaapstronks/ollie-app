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
    /// Returns 0 if any indoor accident occurred, or if no data
    var consecutivePerfectDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var perfectDays = 0
        for dayOffset in 0..<14 { // Check up to 14 days back
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }

            let dayEvents = eventStore.getEvents(from: dayStart, to: dayEnd)
            let pottyEvents = dayEvents.potty()

            // Need at least 1 potty event to count the day
            guard !pottyEvents.isEmpty else {
                break // No data for this day, stop counting
            }

            let indoorCount = pottyEvents.filter { $0.location == .binnen }.count
            if indoorCount > 0 {
                break // Found an indoor event, streak broken
            }

            perfectDays += 1
        }

        return perfectDays
    }

    /// Whether potty training guide should be shown in Train tab
    /// Hides when at 100% outdoor for 4+ consecutive days with activity
    /// Re-shows when there's an indoor accident
    var shouldShowPottyTrainingGuide: Bool {
        // Check for recent indoor accident (within last 24 hours)
        let last24Hours = Date().addingTimeInterval(-24 * 60 * 60)
        let recentEvents = eventStore.getEvents(from: last24Hours, to: Date())
        let hasRecentIndoorAccident = recentEvents.potty().contains { $0.location == .binnen }

        // If there's a recent accident, always show the guide
        if hasRecentIndoorAccident {
            return true
        }

        // Hide if 4+ consecutive perfect days
        return consecutivePerfectDays < 4
    }

    /// Whether the potty mastery prompt card should be shown
    /// Shows when at 100% for multiple consecutive days, respecting dismiss cooldown
    var shouldShowPottyMasteryPrompt: Bool {
        // Check if already mastered
        let isMastered = UserDefaults.standard.bool(forKey: UserPreferences.Key.pottyTrainingMastered.rawValue)
        if isMastered {
            return false
        }

        // Get dismiss count and calculate required threshold
        // First time: 3 days, after first dismiss: 5 days, after second: 7 days, etc.
        let dismissCount = UserDefaults.standard.integer(forKey: UserPreferences.Key.pottyMasteryPromptDismissCount.rawValue)
        let requiredDays = 3 + (dismissCount * 2)

        // Check if we have enough consecutive perfect days
        guard consecutivePerfectDays >= requiredDays else {
            return false
        }

        // Check if we're within the 2-week cooldown after dismissal
        let dismissedTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyMasteryPromptDismissedDate.rawValue)
        if dismissedTimestamp > 0 {
            let dismissedDate = Date(timeIntervalSince1970: dismissedTimestamp)
            let twoWeeksLater = Calendar.current.date(byAdding: .day, value: 14, to: dismissedDate) ?? Date()
            if Date() < twoWeeksLater {
                return false // Still in cooldown
            }
        }

        return true
    }

    // MARK: - Potty Mastery Incident Tracking

    /// Indoor incidents since potty training was mastered
    var incidentsSincePottyMastery: [PuppyEvent] {
        let masteredTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyTrainingMasteredDate.rawValue)
        guard masteredTimestamp > 0 else { return [] }
        let masteredDate = Date(timeIntervalSince1970: masteredTimestamp)
        let events = getHistoricalEvents(days: 30)
        return events.indoorPotty().filter { $0.time > masteredDate }
    }

    /// Indoor incidents in the last 7 days
    var indoorIncidentsLastWeek: [PuppyEvent] {
        getHistoricalEvents(days: 7).indoorPotty()
    }

    /// Whether to show reactivation prompt (3+ incidents in a week after mastering)
    var shouldShowPottyReactivationPrompt: Bool {
        let isMastered = UserDefaults.standard.bool(forKey: UserPreferences.Key.pottyTrainingMastered.rawValue)
        guard isMastered else { return false }

        // Check 7-day dismissal cooldown
        let dismissedTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyReactivationPromptDismissedDate.rawValue)
        if dismissedTimestamp > 0 {
            let dismissedDate = Date(timeIntervalSince1970: dismissedTimestamp)
            let cooldownEnd = Calendar.current.date(byAdding: .day, value: 7, to: dismissedDate) ?? Date()
            if Date() < cooldownEnd { return false }
        }

        return indoorIncidentsLastWeek.count >= 3
    }

    /// Whether to show gentle incident message (1-2 incidents, not yet reactivation)
    var shouldShowPottyIncidentMessage: Bool {
        let isMastered = UserDefaults.standard.bool(forKey: UserPreferences.Key.pottyTrainingMastered.rawValue)
        guard isMastered else { return false }
        guard !shouldShowPottyReactivationPrompt else { return false }

        let incidents = incidentsSincePottyMastery
        guard !incidents.isEmpty else { return false }

        // Check if latest incident was acknowledged (incidents are newest-first from indoorPotty)
        guard let lastIncidentTime = incidents.first?.time else { return false }
        let acknowledgedTimestamp = UserDefaults.standard.double(forKey: UserPreferences.Key.pottyLastIncidentAcknowledgedDate.rawValue)
        if acknowledgedTimestamp > 0 {
            let acknowledgedDate = Date(timeIntervalSince1970: acknowledgedTimestamp)
            if lastIncidentTime <= acknowledgedDate { return false }
        }

        return true
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
    }

    // MARK: - First Week Card

    /// Whether the first week card should be shown
    /// Shows during days 1-7, dismissable for the day
    var shouldShowFirstWeekCard: Bool {
        guard let profile = profileStore.profile else { return false }
        guard isShowingToday else { return false }

        // Only show during first week (days 1-7)
        guard profile.daysHome >= 1 && profile.daysHome <= 7 else { return false }

        // Check if already collapsed today
        if isFirstWeekCardCollapsedToday {
            return true // Show collapsed
        }

        return true
    }

    /// Whether the first week card is currently collapsed
    var isFirstWeekCardCollapsed: Bool {
        isFirstWeekCardCollapsedToday
    }

    /// Check if card was collapsed today
    private var isFirstWeekCardCollapsedToday: Bool {
        guard let collapsedDateString = UserDefaults.standard.string(
            forKey: UserPreferences.Key.firstWeekCardCollapsedDate.rawValue
        ) else {
            return false
        }

        // Parse the stored date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let collapsedDate = formatter.date(from: collapsedDateString) else {
            return false
        }

        // Check if it was collapsed today
        return Calendar.current.isDateInToday(collapsedDate)
    }

    /// Toggle the first week card collapsed state
    func toggleFirstWeekCard() {
        if isFirstWeekCardCollapsedToday {
            // Expand: clear the date
            UserDefaults.standard.removeObject(
                forKey: UserPreferences.Key.firstWeekCardCollapsedDate.rawValue
            )
        } else {
            // Collapse: store today's date
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let todayString = formatter.string(from: Date())
            UserDefaults.standard.set(
                todayString,
                forKey: UserPreferences.Key.firstWeekCardCollapsedDate.rawValue
            )
        }
        objectWillChange.send()
    }

    /// Calculate first week stats for the card
    var firstWeekStats: FirstWeekStats? {
        guard let profile = profileStore.profile else { return nil }

        // Get yesterday's events
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.startOfDay(for: Date())
        let yesterdayEvents = eventStore.getEvents(from: startOfYesterday, to: endOfYesterday)

        // Get historical events (last 7 days for suppression logic)
        let historicalEvents = getHistoricalEvents(days: 7)

        return FirstWeekCalculations.calculateStats(
            profile: profile,
            todayEvents: events,
            yesterdayEvents: yesterdayEvents,
            historicalEvents: historicalEvents
        )
    }
}
