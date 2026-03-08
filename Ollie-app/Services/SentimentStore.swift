//
//  SentimentStore.swift
//  Ollie-app
//
//  Manages user-specific sentiment check-ins and determines when to prompt for ratings.
//  Each user (identified by CloudKit record ID) has their own sentiment data,
//  synced via Core Data + CloudKit.
//

import Foundation
import SwiftUI
import Combine
import CoreData
import OtisShared

// MARK: - Sentiment Store

@MainActor
final class SentimentStore: ObservableObject {
    static let shared = SentimentStore()

    @Published private(set) var checkIns: [SentimentCategory: SentimentCheckIn] = [:]
    @Published var primaryFocus: SentimentCategory?

    /// Date when onboarding (5 core questions) was completed
    @Published private(set) var onboardingCompletedAt: Date?

    private let checkInIntervalDays = 2  // Ask about each category every 2 days
    private let postOnboardingGraceDays = 2  // Wait before asking behavioral questions after onboarding

    /// Key for storing onboarding completion date per user
    private var onboardingCompletedKey: String {
        guard let userID = UserIdentityStore.shared.currentUserRecordID else {
            return "sentimentOnboardingCompletedAt"
        }
        return "sentimentOnboardingCompletedAt_\(userID)"
    }

    /// Key for storing primary focus per user
    private var primaryFocusKey: String {
        guard let userID = UserIdentityStore.shared.currentUserRecordID else {
            return "sentimentPrimaryFocus"
        }
        return "sentimentPrimaryFocus_\(userID)"
    }

    private init() {
        loadOnboardingDate()
        loadPrimaryFocus()
        // Check-ins are loaded when user identity is available
        Task {
            await loadCheckInsFromCoreData()
        }
    }

    // MARK: - State

    /// Current sentiment state for AI context.
    var state: SentimentState {
        SentimentState(
            checkIns: checkIns,
            primaryFocus: primaryFocus,
            lastCheckInDate: checkIns.values.map(\.date).max()
        )
    }

    /// Categories where user is struggling (score 1-3, fresh).
    var strugglingCategories: [SentimentCategory] {
        state.strugglingCategories
    }

    /// Categories where tips should be muted (score 5, fresh).
    var mutedCategories: [SentimentCategory] {
        state.mutedCategories
    }

    // MARK: - Check-In Logic

    /// Record a new check-in for the current user.
    func recordCheckIn(category: SentimentCategory, score: Int, contextSummary: String? = nil) {
        let checkIn = SentimentCheckIn(category: category, score: score, contextSummary: contextSummary)
        checkIns[category] = checkIn
        saveToCoreData(checkIn)

        // Check if we just completed onboarding
        if onboardingCompletedAt == nil && pendingOnboardingQuestions().isEmpty {
            markOnboardingComplete()
        }
    }

    /// Set or clear the primary focus.
    func setPrimaryFocus(_ category: SentimentCategory?) {
        primaryFocus = category
        savePrimaryFocus()
    }

    /// Get score for a category if fresh.
    func score(for category: SentimentCategory) -> Int? {
        state.score(for: category)
    }

    /// Check if a category needs tips (struggling or no data).
    func needsTips(for category: SentimentCategory) -> Bool {
        guard let checkIn = checkIns[category], checkIn.isFresh else {
            return true  // No data = might need tips
        }
        return checkIn.isStruggling
    }

    /// Check if tips should be muted for a category.
    func shouldMuteTips(for category: SentimentCategory) -> Bool {
        guard let checkIn = checkIns[category], checkIn.isFresh else {
            return false
        }
        return checkIn.shouldMuteTips
    }

    // MARK: - Question Scheduling

    /// Determine which question to show today, if any.
    /// Returns nil if no question should be shown.
    func nextQuestionToAsk(profile: PuppyProfile) -> SentimentCategory? {
        let ageWeeks = profile.ageInWeeks

        // Build list of relevant categories
        var categories = SentimentCategory.coreCategories

        // Only add behavioral categories if past grace period after onboarding
        if shouldIncludeBehavioralQuestions {
            categories.append(contentsOf: SentimentCategory.ageRelevantCategories(ageWeeks: ageWeeks))
        }

        // On first launch (no check-ins), return the first core category
        if checkIns.isEmpty {
            return .pottyTraining
        }

        // Find categories that need a check-in (never asked or stale)
        let needsCheckIn = categories.filter { category in
            guard let checkIn = checkIns[category] else {
                return true  // Never asked
            }
            return checkIn.ageInDays >= checkInIntervalDays
        }

        // Prioritize: never asked > most stale
        let sorted = needsCheckIn.sorted { cat1, cat2 in
            let age1 = checkIns[cat1]?.ageInDays ?? Int.max
            let age2 = checkIns[cat2]?.ageInDays ?? Int.max
            return age1 > age2
        }

        return sorted.first
    }

    /// Whether behavioral questions should be included in scheduling.
    /// False during grace period after onboarding.
    private var shouldIncludeBehavioralQuestions: Bool {
        // If onboarding isn't complete, don't show behavioral questions at all
        guard let completedAt = onboardingCompletedAt else {
            return false
        }

        // Check if we're past the grace period
        let daysSinceOnboarding = Calendar.current.dateComponents(
            [.day],
            from: completedAt,
            to: Date()
        ).day ?? 0

        return daysSinceOnboarding >= postOnboardingGraceDays
    }

    /// Check if initial onboarding questions are needed.
    /// Returns categories that haven't been asked yet from core set.
    func pendingOnboardingQuestions() -> [SentimentCategory] {
        SentimentCategory.coreCategories.filter { checkIns[$0] == nil }
    }

    /// Whether we should show the onboarding flow (multiple questions at once).
    var needsOnboarding: Bool {
        pendingOnboardingQuestions().count >= 3
    }

    // MARK: - Onboarding Tracking

    /// Mark that onboarding was completed.
    private func markOnboardingComplete() {
        let now = Date()
        onboardingCompletedAt = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: onboardingCompletedKey)
    }

    /// Load onboarding completion date from UserDefaults.
    private func loadOnboardingDate() {
        let timestamp = UserDefaults.standard.double(forKey: onboardingCompletedKey)
        if timestamp > 0 {
            onboardingCompletedAt = Date(timeIntervalSince1970: timestamp)
        }
    }

    // MARK: - Primary Focus Persistence

    private func savePrimaryFocus() {
        if let focus = primaryFocus {
            UserDefaults.standard.set(focus.rawValue, forKey: primaryFocusKey)
        } else {
            UserDefaults.standard.removeObject(forKey: primaryFocusKey)
        }
    }

    private func loadPrimaryFocus() {
        if let rawValue = UserDefaults.standard.string(forKey: primaryFocusKey),
           let category = SentimentCategory(rawValue: rawValue) {
            primaryFocus = category
        }
    }

    // MARK: - Core Data Persistence

    /// Load check-ins from Core Data for the current user.
    func loadCheckInsFromCoreData() async {
        guard let userRecordID = UserIdentityStore.shared.currentUserRecordID else {
            // User identity not set up yet - will reload when available
            return
        }

        let context = PersistenceController.shared.container.viewContext

        await context.perform { [weak self] in
            guard let cdIdentity = CDUserIdentity.fetch(byCloudKitRecordID: userRecordID, in: context) else {
                return
            }

            let checkInsMap = CDUserSentimentCheckIn.fetchAllAsMap(for: cdIdentity, in: context)

            Task { @MainActor [weak self] in
                self?.checkIns = checkInsMap

                // Check if onboarding was already completed based on loaded data
                if self?.onboardingCompletedAt == nil && self?.pendingOnboardingQuestions().isEmpty == true {
                    self?.markOnboardingComplete()
                }
            }
        }
    }

    /// Save a check-in to Core Data for the current user.
    private func saveToCoreData(_ checkIn: SentimentCheckIn) {
        guard let userRecordID = UserIdentityStore.shared.currentUserRecordID else {
            print("Cannot save sentiment check-in: no user identity")
            return
        }

        let context = PersistenceController.shared.container.viewContext

        context.perform {
            guard let cdIdentity = CDUserIdentity.fetch(byCloudKitRecordID: userRecordID, in: context) else {
                print("Cannot save sentiment check-in: user identity not in Core Data")
                return
            }

            CDUserSentimentCheckIn.upsert(checkIn, for: cdIdentity, in: context)

            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Failed to save sentiment check-in: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - User Switch Support

    /// Reload check-ins when user changes (e.g., different iCloud account).
    func reloadForCurrentUser() {
        checkIns.removeAll()
        primaryFocus = nil
        onboardingCompletedAt = nil
        loadOnboardingDate()
        loadPrimaryFocus()
        Task {
            await loadCheckInsFromCoreData()
        }
    }

    /// Clear all check-ins (for testing).
    func clearAll() {
        checkIns.removeAll()
        primaryFocus = nil
        onboardingCompletedAt = nil
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
        UserDefaults.standard.removeObject(forKey: primaryFocusKey)
    }
}
