//
//  TrialManager.swift
//  Otis-app
//
//  Manages the 14-day local trial (separate from StoreKit trial)

import Combine
import Foundation
import os
import OtisShared

/// Manages local 14-day trial state
/// This is separate from StoreKit's introductory offer - it's a local trial
/// that gives users full access for 14 days without requiring payment info
@MainActor
class TrialManager: ObservableObject {
    static let shared = TrialManager()

    // MARK: - Constants

    private static let trialDurationDays = 14
    private static let existingUserEventThreshold = 20

    // MARK: - Storage Keys

    private enum StorageKey {
        static let shownTouchpoints = "trial.shownTouchpoints"
        static let hasDeclinedTrial = "trial.hasDeclined"
    }

    // MARK: - Published State

    /// The date when the trial started (nil if never started)
    @Published private(set) var trialStartDate: Date?

    /// Set of touchpoints that have been shown to the user
    @Published private(set) var shownTouchpoints: Set<Int> = []

    /// Whether the user explicitly declined the trial
    @Published private(set) var hasDeclinedTrial: Bool = false

    private let logger = Logger.otis(category: "TrialManager")

    // MARK: - Computed Properties

    /// The date when the trial ends (nil if never started)
    var trialEndDate: Date? {
        guard let start = trialStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: Self.trialDurationDays, to: start)
    }

    /// Number of days remaining in trial (0 if expired or not started)
    var daysRemaining: Int {
        guard let end = trialEndDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, days)
    }

    /// Current day of the trial (1-14, or 0 if not started)
    var currentTrialDay: Int {
        guard let start = trialStartDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return min(days + 1, Self.trialDurationDays + 1) // +1 because day 1 is the first day
    }

    /// Whether the local trial is currently active
    var isTrialActive: Bool {
        guard let end = trialEndDate else { return false }
        return Date() < end
    }

    /// Whether the trial has expired (was started but is now past the end date)
    var isTrialExpired: Bool {
        guard trialStartDate != nil else { return false }
        guard let end = trialEndDate else { return false }
        return Date() >= end
    }

    /// Whether the user has never started a trial
    var hasNeverStartedTrial: Bool {
        trialStartDate == nil
    }

    /// Urgency level for UI styling (calm, attention, urgent)
    var urgencyLevel: TrialUrgencyLevel {
        let days = daysRemaining
        if days > 7 {
            return .calm       // Days 14-8
        } else if days > 3 {
            return .attention  // Days 7-4
        } else {
            return .urgent     // Days 3-1
        }
    }

    // MARK: - Initialization

    private init() {
        loadState()
    }

    // MARK: - Trial Management

    /// Start the 14-day local trial
    func startTrial() {
        guard trialStartDate == nil else {
            logger.warning("Trial already started, ignoring startTrial call")
            return
        }

        let now = Date()
        trialStartDate = now
        hasDeclinedTrial = false

        // Save to both UserDefaults and Keychain for tamper resistance
        saveTrialStartDate(now)

        logger.info("Trial started at \(now)")
        Analytics.trackTrialStarted(
            transactionId: 0, // Local trial, no transaction
            productId: "local.trial.14day",
            trialEndAt: trialEndDate ?? now
        )
    }

    /// Called when user explicitly declines the trial
    func declineTrial() {
        hasDeclinedTrial = true
        UserDefaults.standard.set(true, forKey: StorageKey.hasDeclinedTrial)
        logger.info("User declined trial")
    }

    /// Grant migration trial to existing users with sufficient data
    /// Call this when an existing user (with >20 events) opens the app
    func grantMigrationTrialIfEligible(eventCount: Int) {
        // Only grant if user hasn't started a trial and has enough events
        guard trialStartDate == nil,
              !hasDeclinedTrial,
              eventCount >= Self.existingUserEventThreshold else {
            return
        }

        startTrial()
        logger.info("Migration trial granted - user had \(eventCount) events")
    }

    // MARK: - Touchpoints

    /// Get the current touchpoint to show (if any)
    func currentTouchpoint() -> TrialTouchpoint? {
        guard isTrialActive else { return nil }

        let day = currentTrialDay

        // Find the touchpoint for this day that hasn't been shown yet
        for touchpoint in TrialTouchpoint.allCases {
            if touchpoint.day == day && !shownTouchpoints.contains(touchpoint.rawValue) {
                return touchpoint
            }
        }

        return nil
    }

    /// Mark a touchpoint as shown
    func markTouchpointShown(_ touchpoint: TrialTouchpoint) {
        shownTouchpoints.insert(touchpoint.rawValue)
        saveShownTouchpoints()
        logger.info("Marked touchpoint day \(touchpoint.rawValue) as shown")
    }

    /// Check if a specific touchpoint has been shown
    func hasTouchpointBeenShown(_ touchpoint: TrialTouchpoint) -> Bool {
        shownTouchpoints.contains(touchpoint.rawValue)
    }

    // MARK: - Debug

    /// Reset trial state (for debugging)
    func resetForDebug() {
        trialStartDate = nil
        shownTouchpoints = []
        hasDeclinedTrial = false

        UserDefaults.standard.removeObject(forKey: KeychainHelper.Key.trialStartDate)
        UserDefaults.standard.removeObject(forKey: StorageKey.shownTouchpoints)
        UserDefaults.standard.removeObject(forKey: StorageKey.hasDeclinedTrial)
        try? KeychainHelper.delete(key: KeychainHelper.Key.trialStartDate)

        logger.info("Trial state reset for debugging")
    }

    /// Override trial start date (for debugging)
    func setTrialStartDateForDebug(_ date: Date) {
        trialStartDate = date
        saveTrialStartDate(date)
        logger.info("Trial start date overridden to \(date)")
    }

    // MARK: - Private - Persistence

    private func loadState() {
        // Load trial start date (prefer Keychain, fall back to UserDefaults)
        if let keychainDate = loadTrialStartDateFromKeychain() {
            trialStartDate = keychainDate
        } else if let defaultsDate = UserDefaults.standard.object(forKey: KeychainHelper.Key.trialStartDate) as? Date {
            trialStartDate = defaultsDate
            // Migrate to Keychain
            saveTrialStartDateToKeychain(defaultsDate)
        }

        // Load shown touchpoints
        if let data = UserDefaults.standard.data(forKey: StorageKey.shownTouchpoints),
           let touchpoints = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            shownTouchpoints = touchpoints
        }

        // Load declined state
        hasDeclinedTrial = UserDefaults.standard.bool(forKey: StorageKey.hasDeclinedTrial)
    }

    private func saveTrialStartDate(_ date: Date) {
        // Save to UserDefaults for quick access
        UserDefaults.standard.set(date, forKey: KeychainHelper.Key.trialStartDate)

        // Save to Keychain for tamper resistance
        saveTrialStartDateToKeychain(date)
    }

    private func saveTrialStartDateToKeychain(_ date: Date) {
        do {
            let data = try JSONEncoder().encode(date)
            try KeychainHelper.save(data, for: KeychainHelper.Key.trialStartDate)
        } catch {
            logger.error("Failed to save trial start date to Keychain: \(error.localizedDescription)")
        }
    }

    private func loadTrialStartDateFromKeychain() -> Date? {
        guard let data = KeychainHelper.load(key: KeychainHelper.Key.trialStartDate) else {
            return nil
        }
        return try? JSONDecoder().decode(Date.self, from: data)
    }

    private func saveShownTouchpoints() {
        if let data = try? JSONEncoder().encode(shownTouchpoints) {
            UserDefaults.standard.set(data, forKey: StorageKey.shownTouchpoints)
        }
    }
}

// MARK: - Urgency Level

enum TrialUrgencyLevel {
    case calm       // Days 14-8: Blue/neutral styling
    case attention  // Days 7-4: Yellow/amber styling
    case urgent     // Days 3-1: Red/warning styling
}
