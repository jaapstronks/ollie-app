//
//  AchievementService.swift
//  Ollie-app
//
//  Service for detecting achievements and managing celebration queue
//  Implements fatigue prevention to avoid overwhelming users

import Foundation
import SwiftUI
import OllieShared
import Combine
import os

/// Service for detecting achievements and managing the celebration queue
@MainActor
final class AchievementService: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state: AchievementState
    @Published private(set) var pendingCelebration: Achievement?

    // MARK: - Settings

    @AppStorage(UserPreferences.Key.celebrationStyle.rawValue)
    private var celebrationStyleRaw: String = CelebrationStyle.full.rawValue

    var celebrationStyle: CelebrationStyle {
        CelebrationStyle(rawValue: celebrationStyleRaw) ?? .full
    }

    // MARK: - Private

    private let logger = Logger.ollie(category: "AchievementService")
    private static let stateFileName = "achievement_state.json"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Singleton

    static let shared = AchievementService()

    // MARK: - Init

    private init() {
        self.state = Self.loadState()
        logger.info("AchievementService initialized with \(self.state.unlockedAchievements.count) unlocked achievements")
    }

    // MARK: - Milestone Completion Detection

    /// Check if completing a milestone triggers an achievement
    /// Call this AFTER the milestone has been marked complete
    func checkMilestoneCompletion(milestone: Milestone) -> Achievement? {
        logger.debug("Checking milestone completion: \(milestone.labelKey)")

        // Don't create achievements for non-actionable milestones (developmental periods)
        guard milestone.isActionable else {
            return nil
        }

        // Create achievement based on milestone category
        let achievement = createAchievement(for: milestone)

        // Check if already unlocked
        guard !state.isUnlocked(achievement.id) else {
            logger.debug("Achievement already unlocked: \(achievement.id)")
            return nil
        }

        // Unlock the achievement
        state.unlock(achievement)
        saveState()

        // Determine effective tier based on fatigue rules and user preferences
        let effectiveTier = determineEffectiveTier(for: achievement)

        guard let tier = effectiveTier else {
            // Celebrations disabled
            logger.debug("Celebrations disabled, skipping UI for: \(achievement.id)")
            return nil
        }

        // Record the celebration
        switch tier {
        case .major:
            state.recordTier3Shown()
            saveState()
        case .notable:
            state.recordTier2Shown()
            saveState()
        case .subtle:
            break // No fatigue tracking for subtle celebrations
        }

        // Return achievement with effective tier
        // Note: We return the achievement with its original tier, the view layer
        // should use determineEffectiveTier() to get the display tier
        return achievement
    }

    /// Create an achievement for a completed milestone
    private func createAchievement(for milestone: Milestone) -> Achievement {
        // Determine tier based on milestone importance
        let tier = determineMilestoneTier(milestone)

        return Achievement(
            id: "milestone.\(milestone.category.rawValue).\(milestone.id.uuidString)",
            category: mapMilestoneCategory(milestone.category),
            tier: tier,
            labelKey: "achievement.milestone.\(milestone.category.rawValue)",
            descriptionKey: nil,
            value: nil,
            milestoneId: milestone.id
        )
    }

    /// Determine the celebration tier for a milestone
    private func determineMilestoneTier(_ milestone: Milestone) -> CelebrationTier {
        // Major tier for significant health milestones
        if milestone.category == .health {
            // Final vaccination (third) is a major achievement
            if milestone.labelKey.contains("third") || milestone.labelKey.contains("yearlyVaccination") {
                return .major
            }
            // Other vaccinations are notable
            if milestone.labelKey.contains("Vaccination") {
                return .notable
            }
        }

        // Administrative milestones are notable
        if milestone.category == .administrative {
            return .notable
        }

        // Custom milestones are notable
        if milestone.isCustom {
            return .notable
        }

        // Default to notable for actionable milestones
        return .notable
    }

    /// Map milestone category to achievement category
    private func mapMilestoneCategory(_ category: MilestoneCategory) -> AchievementCategory {
        switch category {
        case .health: return .health
        case .developmental: return .socialization
        case .administrative: return .lifestyle
        case .custom: return .lifestyle
        }
    }

    // MARK: - Effective Tier Calculation

    /// Determine the effective tier considering fatigue rules and user preferences
    func determineEffectiveTier(for achievement: Achievement) -> CelebrationTier? {
        // Apply user preference first
        guard let styleTier = celebrationStyle.transform(achievement.tier) else {
            return nil // Celebrations disabled
        }

        // Then apply fatigue rules
        return state.effectiveTier(
            for: Achievement(
                id: achievement.id,
                category: achievement.category,
                tier: styleTier,
                labelKey: achievement.labelKey,
                descriptionKey: achievement.descriptionKey,
                value: achievement.value,
                milestoneId: achievement.milestoneId
            )
        )
    }

    // MARK: - Celebration Queue

    /// Set the pending celebration to show
    func setPendingCelebration(_ achievement: Achievement?) {
        pendingCelebration = achievement
    }

    /// Clear the pending celebration
    func clearPendingCelebration() {
        pendingCelebration = nil
    }

    /// Queue an achievement for later celebration
    func queueAchievement(_ achievement: Achievement) {
        state.queueAchievement(achievement.id)
        saveState()
    }

    /// Pop the next queued achievement
    func popQueuedAchievement() -> String? {
        let id = state.popQueuedAchievement()
        if id != nil {
            saveState()
        }
        return id
    }

    // MARK: - Personal Bests

    /// Check if a value is a new personal best
    func isPersonalBest(for category: String, value: Int) -> Bool {
        state.isPersonalBest(for: category, value: value)
    }

    /// Record a new personal best
    func recordPersonalBest(for category: String, value: Int) {
        guard state.isPersonalBest(for: category, value: value) else { return }
        state.personalBests[category] = value
        saveState()
    }

    // MARK: - Queries

    /// Get all unlocked achievements
    func unlockedAchievements() -> [String: Date] {
        state.unlockedAchievements
    }

    /// Check if an achievement is unlocked
    func isUnlocked(_ achievementId: String) -> Bool {
        state.isUnlocked(achievementId)
    }

    /// Get the date an achievement was unlocked
    func unlockDate(for achievementId: String) -> Date? {
        state.unlockDate(for: achievementId)
    }

    // MARK: - Persistence

    private static func loadState() -> AchievementState {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return .empty
        }

        let fileURL = documentsURL.appendingPathComponent(stateFileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AchievementState.self, from: data)
        } catch {
            Logger.ollie(category: "AchievementService").error("Failed to load achievement state: \(error.localizedDescription)")
            return .empty
        }
    }

    private func saveState() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Could not get documents directory")
            return
        }

        let fileURL = documentsURL.appendingPathComponent(Self.stateFileName)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: .atomic)
            logger.debug("Saved achievement state")
        } catch {
            logger.error("Failed to save achievement state: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset (for testing/debugging)

    #if DEBUG
    func resetAllAchievements() {
        state = .empty
        saveState()
        logger.info("Reset all achievements")
    }
    #endif
}

