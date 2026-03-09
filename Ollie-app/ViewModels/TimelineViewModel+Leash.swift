//
//  TimelineViewModel+Leash.swift
//  Ollie-app
//
//  Leash training related functionality for TimelineViewModel

import Combine
import Foundation
import OtisShared

// MARK: - Sentiment Trend

enum SentimentTrend: String {
    case improving
    case stable
    case declining

    var label: String {
        switch self {
        case .improving: return Strings.Leash.improving
        case .stable: return Strings.Leash.stable
        case .declining: return Strings.Leash.declining
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

// MARK: - Prompt Frequency

enum LeashPromptFrequency {
    case veryFrequent    // Every walk, every few days
    case frequent        // Every 2 walks, 2x/week
    case standard        // Every 3 walks, weekly
    case infrequent      // Every 5 walks, biweekly

    var walksInterval: Int {
        switch self {
        case .veryFrequent: return 1
        case .frequent: return 2
        case .standard: return 3
        case .infrequent: return 5
        }
    }

    var daysInterval: Int {
        switch self {
        case .veryFrequent: return 3
        case .frequent: return 4
        case .standard: return 7
        case .infrequent: return 14
        }
    }
}

extension TimelineViewModel {

    // MARK: - Leash Sentiment Data

    /// Recent leash sentiment average (last 14 days)
    var leashRecentSentimentAverage: Double? {
        let recent = leashCheckIns(days: 14)
        guard !recent.isEmpty else { return nil }
        return Double(recent.map(\.score).reduce(0, +)) / Double(recent.count)
    }

    /// Previous period leash sentiment average (15-28 days ago)
    var leashPreviousPeriodAverage: Double? {
        let previous = leashCheckIns(daysAgo: 15, to: 28)
        guard !previous.isEmpty else { return nil }
        return Double(previous.map(\.score).reduce(0, +)) / Double(previous.count)
    }

    /// Sentiment trend compared to previous period
    var leashSentimentTrend: SentimentTrend? {
        guard let recent = leashRecentSentimentAverage,
              let previous = leashPreviousPeriodAverage else { return nil }
        let diff = recent - previous
        if diff > 0.3 { return .improving }
        if diff < -0.3 { return .declining }
        return .stable
    }

    /// Number of leash sentiment check-ins in the last 14 days
    var leashRecentCheckInCount: Int {
        leashCheckIns(days: 14).count
    }

    /// Last leash sentiment check-in
    var lastLeashCheckIn: SentimentCheckIn? {
        SentimentStore.shared.checkIns[.leashBehavior]
    }

    // MARK: - Post-Walk Prompt Logic

    /// Whether to show leash sentiment prompt after a walk
    var shouldShowPostWalkLeashPrompt: Bool {
        // Not if mastered
        guard !TrainingMasteryStore.shared.leashTrainingMastered else { return false }

        // Not if puppy too young
        guard let profile = profileStore.profile, profile.ageInWeeks >= 10 else { return false }

        // Only if viewing today
        guard isShowingToday else { return false }

        // Only if walk logged in last 5 minutes
        guard let lastWalk = lastWalkEvent,
              lastWalk.time.timeIntervalSinceNow > -300 else { return false }

        // Not every walk - frequency based on current sentiment
        let frequency = leashPromptFrequency
        let walksSince = walksSinceLastLeashPrompt
        let daysSince = daysSinceLastLeashPrompt

        guard walksSince >= frequency.walksInterval ||
              daysSince >= frequency.daysInterval else { return false }

        return true
    }

    /// How often to prompt based on recent sentiment
    var leashPromptFrequency: LeashPromptFrequency {
        guard let avg = leashRecentSentimentAverage else {
            return .standard  // weekly, every 3 walks
        }
        switch avg {
        case 4.5...5.0: return .infrequent   // biweekly, every 5 walks
        case 3.5..<4.5: return .standard     // weekly, every 3 walks
        case 2.5..<3.5: return .frequent     // 2x/week, every 2 walks
        default:        return .veryFrequent // every few days, every walk
        }
    }

    /// Last walk event
    private var lastWalkEvent: PuppyEvent? {
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents
        return recentEvents.walks().first
    }

    /// Number of walks since last leash sentiment prompt
    private var walksSinceLastLeashPrompt: Int {
        guard let lastPromptDate = TrainingMasteryStore.shared.leashLastSentimentAcknowledgedDate else {
            // Never prompted, count all recent walks
            return getHistoricalEvents(days: 30).walks().count
        }

        return getHistoricalEvents(days: 30).walks()
            .filter { $0.time > lastPromptDate }
            .count
    }

    /// Days since last leash sentiment prompt
    private var daysSinceLastLeashPrompt: Int {
        guard let lastPromptDate = TrainingMasteryStore.shared.leashLastSentimentAcknowledgedDate else {
            return 30  // Treat as long time if never prompted
        }
        return Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
    }

    // MARK: - Mastery Criteria

    /// Whether the leash mastery prompt card should be shown
    var shouldShowLeashMasteryPrompt: Bool {
        // Check if already mastered
        guard !TrainingMasteryStore.shared.leashTrainingMastered else { return false }

        // Need sufficient data (at least 3 check-ins in last 14 days)
        guard leashRecentCheckInCount >= 3 else { return false }

        // Average must be >= 4.5
        guard let avg = leashRecentSentimentAverage, avg >= 4.5 else { return false }

        // Progressive threshold after dismissals
        let dismissCount = TrainingMasteryStore.shared.leashMasteryPromptDismissCount
        let requiredDays = 14 + (dismissCount * 7)

        // All check-ins in the required period must be >= 4
        let checkInsInPeriod = leashCheckIns(days: requiredDays)
        guard checkInsInPeriod.allSatisfy({ $0.score >= 4 }) else { return false }

        // Cooldown after dismissal (14 days)
        if let dismissed = TrainingMasteryStore.shared.leashMasteryPromptDismissedDate {
            let cooldownDays = 14
            guard Date().timeIntervalSince(dismissed) > Double(cooldownDays * 86400) else { return false }
        }

        return true
    }

    // MARK: - Reactivation Logic

    /// Whether the leash reactivation prompt should be shown
    var shouldShowLeashReactivationPrompt: Bool {
        guard TrainingMasteryStore.shared.leashTrainingMastered else { return false }

        // Check cooldown (7 days)
        if let dismissed = TrainingMasteryStore.shared.leashReactivationPromptDismissedDate {
            guard Date().timeIntervalSince(dismissed) > 7 * 86400 else { return false }
        }

        // Trigger: 3+ bad sentiment ratings (score <= 2) in last 14 days
        let badRatings = leashCheckIns(days: 14).filter { $0.score <= 2 }
        if badRatings.count >= 3 { return true }

        return false
    }

    // MARK: - Walk Classification

    /// Whether to ask if an outdoor potty was part of a walk
    var shouldAskIfThatWasAWalk: Bool {
        // Only after outdoor potty logged in last 5 minutes
        guard let lastOutdoorPotty = lastOutdoorPottyEvent,
              lastOutdoorPotty.time.timeIntervalSinceNow > -300 else { return false }

        // No nearby walk already logged (within 10 min)
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents
        let nearbyWalk = recentEvents.walks().contains {
            abs($0.time.timeIntervalSince(lastOutdoorPotty.time)) < 600
        }
        guard !nearbyWalk else { return false }

        // Heuristics for "this was probably a walk"
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: lastOutdoorPotty.time)

        // Morning outdoor potty (6-10 AM) - likely a walk
        let isMorning = hour >= 6 && hour <= 10

        // Was after a wake event in last 30 min
        let wasAfterWake = recentEvents.wakes().contains {
            let gap = lastOutdoorPotty.time.timeIntervalSince($0.time)
            return gap > 0 && gap < 1800
        }

        // Long gap since last outdoor (> 2 hours)
        let previousOutdoor = recentEvents
            .filter { $0.location == .buiten && $0.time < lastOutdoorPotty.time }
            .sorted { $0.time > $1.time }
            .first
        let longGap = previousOutdoor.map { lastOutdoorPotty.time.timeIntervalSince($0.time) > 7200 } ?? true

        return isMorning || wasAfterWake || longGap
    }

    /// The most recent outdoor potty event
    private var lastOutdoorPottyEvent: PuppyEvent? {
        let recentEvents = cachedRecentEvents.isEmpty ? getRecentEvents() : cachedRecentEvents
        return recentEvents
            .potty()
            .filter { $0.location == .buiten }
            .first
    }

    // MARK: - Helper Methods

    /// Get leash behavior check-ins for the last N days
    private func leashCheckIns(days: Int) -> [SentimentCheckIn] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        guard let checkIn = SentimentStore.shared.checkIns[.leashBehavior],
              checkIn.date > cutoff else {
            return []
        }
        return [checkIn]  // Current store only keeps latest per category
    }

    /// Get leash behavior check-ins from daysAgo to toDays ago
    private func leashCheckIns(daysAgo: Int, to toDays: Int) -> [SentimentCheckIn] {
        let start = Date().addingTimeInterval(-Double(toDays) * 86400)
        let end = Date().addingTimeInterval(-Double(daysAgo) * 86400)
        guard let checkIn = SentimentStore.shared.checkIns[.leashBehavior],
              checkIn.date > start && checkIn.date <= end else {
            return []
        }
        return [checkIn]
    }

    /// Whether leash training guide should be shown in Train tab
    var shouldShowLeashTrainingGuide: Bool {
        guard let profile = profileStore.profile else { return false }
        // Show for puppies 10+ weeks old
        return profile.ageInWeeks >= 10
    }
}
