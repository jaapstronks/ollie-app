//
//  ReviewService.swift
//  Ollie-app
//
//  Handles App Store review request timing
//

import StoreKit
import SwiftUI
import UIKit

/// Service to prompt for App Store reviews at appropriate moments
@MainActor
final class ReviewService {
    // MARK: - Singleton

    static let shared = ReviewService()

    // MARK: - User Defaults Keys

    private enum Keys {
        static let firstLaunchDate = "review_firstLaunchDate"
        static let lastReviewRequestDate = "review_lastRequestDate"
        static let consecutiveDaysUsed = "review_consecutiveDays"
        static let lastActiveDate = "review_lastActiveDate"
        static let hasRequestedReview = "review_hasRequested"
        static let bestOutdoorStreak = "review_bestOutdoorStreak"
        static let celebratedStreak = "review_celebratedStreak"
    }

    // MARK: - Configuration

    /// Minimum days of use before showing review prompt
    private let minimumDaysForReview = 7

    /// Minimum days between review requests
    private let daysBetweenRequests = 90

    /// Outdoor streak milestones that trigger review prompt
    private let streakMilestones = [7, 14, 21, 30]

    // MARK: - State

    private let defaults = UserDefaults.standard

    // MARK: - Init

    private init() {
        // Record first launch if not set
        if defaults.object(forKey: Keys.firstLaunchDate) == nil {
            defaults.set(Date(), forKey: Keys.firstLaunchDate)
        }
    }

    // MARK: - Public Methods

    /// Call this when the app becomes active to track usage days
    func recordAppActive() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastActive = defaults.object(forKey: Keys.lastActiveDate) as? Date {
            let lastActiveDay = Calendar.current.startOfDay(for: lastActive)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                let current = defaults.integer(forKey: Keys.consecutiveDaysUsed)
                defaults.set(current + 1, forKey: Keys.consecutiveDaysUsed)
            } else if daysDiff > 1 {
                // Streak broken
                defaults.set(1, forKey: Keys.consecutiveDaysUsed)
            }
            // daysDiff == 0 means same day, no change needed
        } else {
            // First recorded active day
            defaults.set(1, forKey: Keys.consecutiveDaysUsed)
        }

        defaults.set(today, forKey: Keys.lastActiveDate)
    }

    /// Check if we should prompt for review based on usage duration
    /// Call this after the user completes a positive action (e.g., logging an event)
    func checkForUsageBasedReview() {
        guard canRequestReview() else { return }

        let consecutiveDays = defaults.integer(forKey: Keys.consecutiveDaysUsed)

        if consecutiveDays >= minimumDaysForReview {
            requestReview()
        }
    }

    /// Check if we should prompt for review based on an outdoor streak milestone
    /// - Parameter currentStreak: The user's current outdoor potty streak
    func checkForStreakMilestoneReview(currentStreak: Int) {
        guard canRequestReview() else { return }

        let celebratedStreak = defaults.integer(forKey: Keys.celebratedStreak)

        // Find the highest milestone the user has reached that we haven't celebrated
        for milestone in streakMilestones.reversed() {
            if currentStreak >= milestone && celebratedStreak < milestone {
                defaults.set(milestone, forKey: Keys.celebratedStreak)
                requestReview()
                return
            }
        }
    }

    /// Call when user achieves a notable milestone (e.g., first full week all potty outside)
    func celebrateMilestone() {
        guard canRequestReview() else { return }
        requestReview()
    }

    // MARK: - Private Methods

    private func canRequestReview() -> Bool {
        // Don't request if we've requested recently
        if let lastRequest = defaults.object(forKey: Keys.lastReviewRequestDate) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents(
                [.day],
                from: lastRequest,
                to: Date()
            ).day ?? 0

            if daysSinceLastRequest < daysBetweenRequests {
                return false
            }
        }

        // Ensure user has been using the app for at least a few days
        guard let firstLaunch = defaults.object(forKey: Keys.firstLaunchDate) as? Date else {
            return false
        }

        let daysSinceFirstLaunch = Calendar.current.dateComponents(
            [.day],
            from: firstLaunch,
            to: Date()
        ).day ?? 0

        return daysSinceFirstLaunch >= 3 // At least 3 days since install
    }

    private func requestReview() {
        defaults.set(Date(), forKey: Keys.lastReviewRequestDate)
        defaults.set(true, forKey: Keys.hasRequestedReview)

        // Request review using the appropriate API
        if #available(iOS 16.0, *) {
            // Use the modern SwiftUI-based API
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                AppStore.requestReview(in: scene)
            }
        } else {
            // Fallback for earlier iOS versions
            SKStoreReviewController.requestReview()
        }
    }

    // MARK: - Reset (for testing)

    #if DEBUG
    func resetForTesting() {
        defaults.removeObject(forKey: Keys.firstLaunchDate)
        defaults.removeObject(forKey: Keys.lastReviewRequestDate)
        defaults.removeObject(forKey: Keys.consecutiveDaysUsed)
        defaults.removeObject(forKey: Keys.lastActiveDate)
        defaults.removeObject(forKey: Keys.hasRequestedReview)
        defaults.removeObject(forKey: Keys.celebratedStreak)
    }
    #endif
}
