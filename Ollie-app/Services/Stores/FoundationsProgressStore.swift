//
//  FoundationsProgressStore.swift
//  Ollie-app
//
//  Tracks completion of training foundations modules.
//  Stored locally (UserDefaults) - per-human, not synced via CloudKit.
//

import Foundation
import SwiftUI

/// Progress data for a single foundations module
struct FoundationsModuleProgress: Codable, Equatable {
    var moduleId: String
    var pagesViewed: Set<Int>
    var quizzesAnswered: Set<String>
    var isComplete: Bool
    var skipped: Bool
    var completedAt: Date?

    init(moduleId: String) {
        self.moduleId = moduleId
        self.pagesViewed = []
        self.quizzesAnswered = []
        self.isComplete = false
        self.skipped = false
        self.completedAt = nil
    }
}

/// Manages foundations module completion state
@Observable
@MainActor
final class FoundationsProgressStore {
    private static let storageKey = "foundationsProgress"

    // MARK: - State

    private(set) var moduleProgress: [String: FoundationsModuleProgress] = [:]

    // MARK: - Computed Properties

    /// Is the required "Getting Started" module complete?
    var isGettingStartedComplete: Bool {
        progress(for: "gettingStarted").isComplete || progress(for: "gettingStarted").skipped
    }

    /// Is the "How Dogs Learn" module complete?
    var isHowDogsLearnComplete: Bool {
        progress(for: "howDogsLearn").isComplete || progress(for: "howDogsLearn").skipped
    }

    /// Is the "Taking It Further" module complete?
    var isTakingFurtherComplete: Bool {
        progress(for: "takingFurther").isComplete || progress(for: "takingFurther").skipped
    }

    /// Should we show "How Dogs Learn" as a suggestion?
    /// Unlocks after completing 2+ foundation skills
    func shouldSuggestHowDogsLearn(masteredSkillCount: Int) -> Bool {
        !isHowDogsLearnComplete && masteredSkillCount >= 2
    }

    /// Should we show "Taking It Further" as a suggestion?
    /// Unlocks when user has any skill at phase 3+ inside
    func shouldSuggestTakingFurther(hasReachedProofingPhase: Bool) -> Bool {
        !isTakingFurtherComplete && hasReachedProofingPhase
    }

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Progress Access

    func progress(for moduleId: String) -> FoundationsModuleProgress {
        moduleProgress[moduleId] ?? FoundationsModuleProgress(moduleId: moduleId)
    }

    // MARK: - Actions

    func markPageViewed(_ pageIndex: Int, forModule moduleId: String) {
        var progress = progress(for: moduleId)
        progress.pagesViewed.insert(pageIndex)
        moduleProgress[moduleId] = progress
        save()
    }

    func markQuizAnswered(_ quizId: String, forModule moduleId: String) {
        var progress = progress(for: moduleId)
        progress.quizzesAnswered.insert(quizId)
        moduleProgress[moduleId] = progress
        save()
    }

    func markComplete(moduleId: String) {
        var progress = progress(for: moduleId)
        progress.isComplete = true
        progress.completedAt = Date()
        moduleProgress[moduleId] = progress
        save()
    }

    func markSkipped(moduleId: String) {
        var progress = progress(for: moduleId)
        progress.skipped = true
        progress.completedAt = Date()
        moduleProgress[moduleId] = progress
        save()
    }

    func reset(moduleId: String) {
        moduleProgress[moduleId] = FoundationsModuleProgress(moduleId: moduleId)
        save()
    }

    func resetAll() {
        moduleProgress = [:]
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(moduleProgress)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("Failed to save foundations progress: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            return
        }

        do {
            moduleProgress = try JSONDecoder().decode([String: FoundationsModuleProgress].self, from: data)
        } catch {
            print("Failed to load foundations progress: \(error)")
            moduleProgress = [:]
        }
    }

    // MARK: - Migration from old PreparationSection

    /// Migrates from old preparation checklist to new foundations system
    func migrateFromPreparation(progressStore: TrainingProgressStore) {
        // If user already completed old preparation, mark module 1 as complete
        // This ensures existing users don't have to redo the intro

        // Check if all old preparation items were completed
        let oldItems = ["clicker", "treats", "quietSpace", "understandOperant", "understandClassical", "understandTiming"]
        let allCompleted = oldItems.allSatisfy { progressStore.isPreparationItemCompleted($0) }

        if allCompleted && !isGettingStartedComplete {
            markComplete(moduleId: "gettingStarted")
        }
    }
}
