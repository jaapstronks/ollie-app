//
//  PottyMasteryService.swift
//  Ollie-app
//
//  Manages potty training mastery state, incident tracking, and prompts.
//  Extracted from TimelineViewModel+Predictions for better separation of concerns.
//

import Foundation
import OtisShared

/// Service for managing potty training mastery state and prompts
struct PottyMasteryService {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let pottyTrainingMastered = UserPreferences.Key.pottyTrainingMastered.rawValue
        static let pottyTrainingMasteredDate = UserPreferences.Key.pottyTrainingMasteredDate.rawValue
        static let pottyMasteryPromptDismissCount = UserPreferences.Key.pottyMasteryPromptDismissCount.rawValue
        static let pottyMasteryPromptDismissedDate = UserPreferences.Key.pottyMasteryPromptDismissedDate.rawValue
        static let pottyReactivationPromptDismissedDate = UserPreferences.Key.pottyReactivationPromptDismissedDate.rawValue
        static let pottyLastIncidentAcknowledgedDate = UserPreferences.Key.pottyLastIncidentAcknowledgedDate.rawValue
    }

    // MARK: - Mastery State

    /// Whether potty training has been marked as mastered
    static var isMastered: Bool {
        UserDefaults.standard.bool(forKey: Keys.pottyTrainingMastered)
    }

    /// Date when potty training was marked as mastered
    static var masteredDate: Date? {
        let timestamp = UserDefaults.standard.double(forKey: Keys.pottyTrainingMasteredDate)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    // MARK: - Consecutive Perfect Days

    /// Calculate number of consecutive days at 100% outdoor potty success
    /// Returns 0 if any indoor accident occurred, or if no data
    /// PERFORMANCE: Use the events-based overload with pre-fetched data instead
    @MainActor
    static func consecutivePerfectDays(eventStore: EventStore) -> Int {
        // Fetch 14 days of events once instead of 14 individual day queries
        let fourteenDaysAgo = Date().addingDays(-14)
        let allEvents = eventStore.getEvents(from: fourteenDaysAgo, to: Date())
        return consecutivePerfectDays(from: allEvents)
    }

    /// Calculate number of consecutive days at 100% outdoor potty success
    /// PERFORMANCE: Uses pre-fetched events to avoid Core Data queries
    static func consecutivePerfectDays(from allEvents: [PuppyEvent]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var perfectDays = 0
        for dayOffset in 0..<14 { // Check up to 14 days back
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }

            // Filter events for this day from pre-fetched data
            let dayEvents = allEvents.filter { $0.time >= dayStart && $0.time < dayEnd }
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

    // MARK: - Training Guide Visibility

    /// Whether potty training guide should be shown in Train tab
    /// Hides when at 100% outdoor for 4+ consecutive days with activity
    /// Re-shows when there's an indoor accident
    @MainActor
    static func shouldShowPottyTrainingGuide(eventStore: EventStore) -> Bool {
        // Check for recent indoor accident (within last 24 hours)
        let last24Hours = Date().addingTimeInterval(-24 * 60 * 60)
        let recentEvents = eventStore.getEvents(from: last24Hours, to: Date())
        let hasRecentIndoorAccident = recentEvents.potty().contains { $0.location == .binnen }

        // If there's a recent accident, always show the guide
        if hasRecentIndoorAccident {
            return true
        }

        // Hide if 4+ consecutive perfect days
        return consecutivePerfectDays(eventStore: eventStore) < 4
    }

    // MARK: - Mastery Prompt

    /// Whether the potty mastery prompt card should be shown
    /// Shows when at 100% for multiple consecutive days, respecting dismiss cooldown
    @MainActor
    static func shouldShowMasteryPrompt(eventStore: EventStore) -> Bool {
        // Check if already mastered
        if isMastered {
            return false
        }

        // Get dismiss count and calculate required threshold
        // First time: 3 days, after first dismiss: 5 days, after second: 7 days, etc.
        let dismissCount = UserDefaults.standard.integer(forKey: Keys.pottyMasteryPromptDismissCount)
        let requiredDays = 3 + (dismissCount * 2)

        // Check if we have enough consecutive perfect days
        let perfectDays = consecutivePerfectDays(eventStore: eventStore)
        guard perfectDays >= requiredDays else {
            return false
        }

        // Check if we're within the 2-week cooldown after dismissal
        let dismissedTimestamp = UserDefaults.standard.double(forKey: Keys.pottyMasteryPromptDismissedDate)
        if dismissedTimestamp > 0 {
            let dismissedDate = Date(timeIntervalSince1970: dismissedTimestamp)
            let twoWeeksLater = dismissedDate.addingDays(14)
            if Date() < twoWeeksLater {
                return false // Still in cooldown
            }
        }

        return true
    }

    /// Dismiss the mastery prompt (increments dismiss count and sets cooldown)
    static func dismissMasteryPrompt() {
        let currentCount = UserDefaults.standard.integer(forKey: Keys.pottyMasteryPromptDismissCount)
        UserDefaults.standard.set(currentCount + 1, forKey: Keys.pottyMasteryPromptDismissCount)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Keys.pottyMasteryPromptDismissedDate)
    }

    /// Mark potty training as mastered
    static func markAsMastered() {
        UserDefaults.standard.set(true, forKey: Keys.pottyTrainingMastered)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Keys.pottyTrainingMasteredDate)
    }

    // MARK: - Incident Tracking

    /// Indoor incidents since potty training was mastered
    static func incidentsSinceMastery(historicalEvents: [PuppyEvent]) -> [PuppyEvent] {
        guard let masteredDate = masteredDate else { return [] }
        return historicalEvents.indoorPotty().filter { $0.time > masteredDate }
    }

    /// Indoor incidents in the last 7 days
    static func indoorIncidentsLastWeek(historicalEvents: [PuppyEvent]) -> [PuppyEvent] {
        historicalEvents.indoorPotty()
    }

    // MARK: - Reactivation Prompt

    /// Whether to show reactivation prompt (3+ incidents in a week after mastering)
    static func shouldShowReactivationPrompt(indoorIncidentsLastWeek: [PuppyEvent]) -> Bool {
        guard isMastered else { return false }

        // Check 7-day dismissal cooldown
        let dismissedTimestamp = UserDefaults.standard.double(forKey: Keys.pottyReactivationPromptDismissedDate)
        if dismissedTimestamp > 0 {
            let dismissedDate = Date(timeIntervalSince1970: dismissedTimestamp)
            let cooldownEnd = dismissedDate.addingDays(7)
            if Date() < cooldownEnd { return false }
        }

        return indoorIncidentsLastWeek.count >= 3
    }

    /// Dismiss the reactivation prompt
    static func dismissReactivationPrompt() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Keys.pottyReactivationPromptDismissedDate)
    }

    /// Reactivate potty training (un-master)
    static func reactivateTraining() {
        UserDefaults.standard.set(false, forKey: Keys.pottyTrainingMastered)
        UserDefaults.standard.removeObject(forKey: Keys.pottyTrainingMasteredDate)
        // Reset dismiss counts so mastery prompt starts fresh
        UserDefaults.standard.removeObject(forKey: Keys.pottyMasteryPromptDismissCount)
        UserDefaults.standard.removeObject(forKey: Keys.pottyMasteryPromptDismissedDate)
    }

    // MARK: - Incident Message

    /// Whether to show gentle incident message (1-2 incidents, not yet reactivation)
    static func shouldShowIncidentMessage(
        incidentsSinceMastery: [PuppyEvent],
        shouldShowReactivationPrompt: Bool
    ) -> Bool {
        guard isMastered else { return false }
        guard !shouldShowReactivationPrompt else { return false }
        guard !incidentsSinceMastery.isEmpty else { return false }

        // Check if latest incident was acknowledged (incidents are newest-first from indoorPotty)
        guard let lastIncidentTime = incidentsSinceMastery.first?.time else { return false }
        let acknowledgedTimestamp = UserDefaults.standard.double(forKey: Keys.pottyLastIncidentAcknowledgedDate)
        if acknowledgedTimestamp > 0 {
            let acknowledgedDate = Date(timeIntervalSince1970: acknowledgedTimestamp)
            if lastIncidentTime <= acknowledgedDate { return false }
        }

        return true
    }

    /// Acknowledge the latest incident
    static func acknowledgeIncident() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Keys.pottyLastIncidentAcknowledgedDate)
    }
}
