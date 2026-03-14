//
//  FirstWeekExperienceService.swift
//  Ollie-app
//
//  Manages progressive feature disclosure and nudges during the first week.
//  Controls when features unlock based on actual usage patterns.
//

import Foundation
import OtisShared
import SwiftUI

/// Service that manages progressive disclosure of features during first week.
/// Features unlock based on actual usage, not just time.
@Observable
@MainActor
final class FirstWeekExperienceService {
    static let shared = FirstWeekExperienceService()

    // MARK: - Storage Keys

    private enum Key: String {
        case onboardingCompletedDate = "firstWeek_onboardingCompletedDate"
        case firstEventDate = "firstWeek_firstEventDate"
        case firstPhotoDate = "firstWeek_firstPhotoDate"
        case familyInviteSent = "firstWeek_familyInviteSent"
        case photoPromptDismissDate = "firstWeek_photoPromptDismissDate"
        case photoPromptDismissCount = "firstWeek_photoPromptDismissCount"
        case invitePromptDismissDate = "firstWeek_invitePromptDismissDate"
        case invitePromptDismissCount = "firstWeek_invitePromptDismissCount"
        case firstEventCelebrationShown = "firstWeek_firstEventCelebrationShown"
        case streakCelebrationLastDay = "firstWeek_streakCelebrationLastDay"
    }

    // MARK: - State

    private(set) var isFirstWeek: Bool = true
    private(set) var daysSinceOnboarding: Int = 0

    // MARK: - Cached Event Counts

    @ObservationIgnored private var cachedPottyCount: Int = 0
    @ObservationIgnored private var cachedSleepWakeCycles: Int = 0
    @ObservationIgnored private var cachedMealCount: Int = 0
    @ObservationIgnored private var cachedWalkCount: Int = 0
    @ObservationIgnored private var cachedTotalEventCount: Int = 0
    @ObservationIgnored private var cachedPhotoCount: Int = 0
    @ObservationIgnored private var cachedDaysWithEvents: Int = 0

    // MARK: - Initialization

    private init() {
        updateState()
    }

    // MARK: - State Update

    /// Call this after events change to update cached counts
    func refreshCounts(from events: [PuppyEvent]) {
        cachedPottyCount = events.filter { $0.type == .plassen || $0.type == .poepen }.count
        cachedMealCount = events.filter { $0.type == .eten }.count
        cachedWalkCount = events.filter { $0.type == .uitlaten }.count
        cachedPhotoCount = events.filter { $0.photo != nil || $0.video != nil }.count
        cachedTotalEventCount = events.filter { $0.type != .coverageGap }.count

        // Count sleep/wake cycles (pairs of sleep + wake events)
        let sleepCount = events.filter { $0.type == .slapen }.count
        let wakeCount = events.filter { $0.type == .ontwaken }.count
        cachedSleepWakeCycles = min(sleepCount, wakeCount)

        // Count unique days with events
        let calendar = Calendar.current
        let uniqueDays = Set(events.compactMap { event -> DateComponents? in
            guard event.type != .coverageGap else { return nil }
            return calendar.dateComponents([.year, .month, .day], from: event.time)
        })
        cachedDaysWithEvents = uniqueDays.count

        // Update first event date if needed
        if firstEventDate == nil && cachedTotalEventCount > 0 {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Key.firstEventDate.rawValue)
        }

        // Update first photo date if needed
        if firstPhotoDate == nil && cachedPhotoCount > 0 {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Key.firstPhotoDate.rawValue)
        }

        updateState()
    }

    private func updateState() {
        if let completedDate = onboardingCompletedDate {
            let days = Calendar.current.dateComponents([.day], from: completedDate, to: Date()).day ?? 0
            daysSinceOnboarding = max(0, days)
            isFirstWeek = days <= 7
        } else {
            daysSinceOnboarding = 0
            isFirstWeek = true
        }
    }

    // MARK: - Onboarding Completion

    /// Call when onboarding completes to start the first-week clock
    func markOnboardingCompleted() {
        guard onboardingCompletedDate == nil else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Key.onboardingCompletedDate.rawValue)
        updateState()
    }

    private var onboardingCompletedDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: Key.onboardingCompletedDate.rawValue)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    private var firstEventDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: Key.firstEventDate.rawValue)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    private var firstPhotoDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: Key.firstPhotoDate.rawValue)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    // MARK: - Feature Gating

    /// Whether potty predictions should be shown (need 3+ potty events)
    var shouldShowPottyPredictions: Bool {
        cachedPottyCount >= 3
    }

    /// Whether sleep analysis should be shown (need 2+ sleep/wake cycles)
    var shouldShowSleepAnalysis: Bool {
        cachedSleepWakeCycles >= 2
    }

    /// Whether meal reminders should be shown (need 1+ meal logged)
    var shouldShowMealReminders: Bool {
        cachedMealCount >= 1
    }

    /// Whether walk suggestions should be shown (need 1+ walk logged)
    var shouldShowWalkSuggestions: Bool {
        cachedWalkCount >= 1
    }

    /// Whether AI insights should be shown (need 15+ events over 3+ days)
    var shouldShowAIInsights: Bool {
        cachedTotalEventCount >= 15 && cachedDaysWithEvents >= 3
    }

    /// Whether sentiment check-ins should be shown (not on Day 0)
    var shouldShowSentimentCheckIn: Bool {
        daysSinceOnboarding >= 1
    }

    /// Whether weekly recap should be shown (need 7+ days)
    var shouldShowWeeklyRecap: Bool {
        daysSinceOnboarding >= 7
    }

    // MARK: - Photo Prompt

    /// Whether to show photo prompt (Day 2+, no photo yet, not dismissed today)
    var shouldShowPhotoPrompt: Bool {
        guard isFirstWeek else { return false }
        guard daysSinceOnboarding >= 2 else { return false }
        guard firstPhotoDate == nil else { return false }
        guard !isPhotoPromptDismissedToday else { return false }
        return true
    }

    private var isPhotoPromptDismissedToday: Bool {
        let timestamp = UserDefaults.standard.double(forKey: Key.photoPromptDismissDate.rawValue)
        guard timestamp > 0 else { return false }
        let dismissDate = Date(timeIntervalSince1970: timestamp)
        return Calendar.current.isDateInToday(dismissDate)
    }

    func dismissPhotoPrompt() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Key.photoPromptDismissDate.rawValue)
        let count = UserDefaults.standard.integer(forKey: Key.photoPromptDismissCount.rawValue)
        UserDefaults.standard.set(count + 1, forKey: Key.photoPromptDismissCount.rawValue)
    }

    // MARK: - Family Invite Prompt

    /// Whether to show invite prompt (Day 3+, 10+ events, not dismissed in last 3 days)
    var shouldShowInvitePrompt: Bool {
        guard isFirstWeek else { return false }
        guard daysSinceOnboarding >= 3 else { return false }
        guard cachedTotalEventCount >= 10 else { return false }
        guard !familyInviteSent else { return false }
        guard !isInvitePromptDismissedRecently else { return false }

        // Don't show more than twice
        let dismissCount = UserDefaults.standard.integer(forKey: Key.invitePromptDismissCount.rawValue)
        guard dismissCount < 2 else { return false }

        return true
    }

    private var familyInviteSent: Bool {
        UserDefaults.standard.bool(forKey: Key.familyInviteSent.rawValue)
    }

    private var isInvitePromptDismissedRecently: Bool {
        let timestamp = UserDefaults.standard.double(forKey: Key.invitePromptDismissDate.rawValue)
        guard timestamp > 0 else { return false }
        let dismissDate = Date(timeIntervalSince1970: timestamp)
        let daysSinceDismiss = Calendar.current.dateComponents([.day], from: dismissDate, to: Date()).day ?? 0
        return daysSinceDismiss < 3
    }

    func dismissInvitePrompt() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Key.invitePromptDismissDate.rawValue)
        let count = UserDefaults.standard.integer(forKey: Key.invitePromptDismissCount.rawValue)
        UserDefaults.standard.set(count + 1, forKey: Key.invitePromptDismissCount.rawValue)
    }

    func markFamilyInviteSent() {
        UserDefaults.standard.set(true, forKey: Key.familyInviteSent.rawValue)
    }

    // MARK: - First Event Celebration

    /// Whether to show first event celebration (only once ever)
    var shouldShowFirstEventCelebration: Bool {
        guard cachedTotalEventCount == 1 else { return false }
        return !UserDefaults.standard.bool(forKey: Key.firstEventCelebrationShown.rawValue)
    }

    func markFirstEventCelebrationShown() {
        UserDefaults.standard.set(true, forKey: Key.firstEventCelebrationShown.rawValue)
    }

    // MARK: - Streak Celebration

    /// Current streak (consecutive days with logging)
    var currentStreak: Int {
        cachedDaysWithEvents
    }

    /// Whether to show streak celebration (days 3, 5, 7 only, once per streak milestone)
    func shouldShowStreakCelebration(forStreak streak: Int) -> Bool {
        guard [3, 5, 7].contains(streak) else { return false }
        let lastCelebrated = UserDefaults.standard.integer(forKey: Key.streakCelebrationLastDay.rawValue)
        return streak > lastCelebrated
    }

    func markStreakCelebrationShown(forStreak streak: Int) {
        UserDefaults.standard.set(streak, forKey: Key.streakCelebrationLastDay.rawValue)
    }

    // MARK: - Retention Health

    /// Returns retention health status for analytics/intervention
    var retentionHealth: RetentionHealth {
        switch daysSinceOnboarding {
        case 0:
            return .newUser
        case 1:
            if cachedTotalEventCount >= 5 {
                return .healthy
            } else if cachedTotalEventCount >= 2 {
                return .atRisk
            } else {
                return .critical
            }
        case 2:
            if cachedTotalEventCount >= 10 {
                return .healthy
            } else if cachedTotalEventCount >= 5 {
                return .atRisk
            } else {
                return .critical
            }
        case 3...:
            if cachedDaysWithEvents >= 3 && cachedTotalEventCount >= 15 {
                return .healthy
            } else if cachedDaysWithEvents >= 2 {
                return .atRisk
            } else {
                return .critical
            }
        default:
            return .newUser
        }
    }

    enum RetentionHealth {
        case newUser
        case healthy
        case atRisk
        case critical
    }

    // MARK: - Debug/Reset

    #if DEBUG
    func resetForTesting() {
        for key in [
            Key.onboardingCompletedDate,
            Key.firstEventDate,
            Key.firstPhotoDate,
            Key.familyInviteSent,
            Key.photoPromptDismissDate,
            Key.photoPromptDismissCount,
            Key.invitePromptDismissDate,
            Key.invitePromptDismissCount,
            Key.firstEventCelebrationShown,
            Key.streakCelebrationLastDay
        ] {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
        cachedPottyCount = 0
        cachedSleepWakeCycles = 0
        cachedMealCount = 0
        cachedWalkCount = 0
        cachedTotalEventCount = 0
        cachedPhotoCount = 0
        cachedDaysWithEvents = 0
        updateState()
    }
    #endif
}

// MARK: - View Extension for Gating

extension View {
    /// Conditionally shows this view based on first-week gating
    @MainActor @ViewBuilder
    func gatedForFirstWeek(_ check: @escaping () -> Bool) -> some View {
        if check() {
            self
        }
    }
}
