//
//  TrainingTheoryStore.swift
//  Ollie-app
//
//  Local-only store for tracking theory reading progress.
//  Uses UserDefaults for persistence - NOT synced via CloudKit.
//  This is per-human progress (which human has read the theory),
//  not per-dog progress.
//

import Foundation
import os

/// Manages local-only theory progress (UserDefaults, not synced)
@Observable
@MainActor
final class TrainingTheoryStore {

    // MARK: - Constants

    private static let storageKey = "trainingTheoryProgress"

    // MARK: - State

    private(set) var theoryProgress: [String: TheoryProgress] = [:]

    // MARK: - Logging

    private let logger = Logger(subsystem: "com.ollie.app", category: "TrainingTheoryStore")

    // MARK: - Init

    init() {
        loadFromStorage()
    }

    // MARK: - Public API

    /// Check if theory is complete for a skill
    func isTheoryComplete(forSkill skillId: String) -> Bool {
        theoryProgress[skillId]?.isComplete ?? false
    }

    /// Check if theory was skipped for a skill
    func wasTheorySkipped(forSkill skillId: String) -> Bool {
        theoryProgress[skillId]?.skipped ?? false
    }

    /// Get progress for a skill
    func progress(forSkill skillId: String) -> TheoryProgress? {
        theoryProgress[skillId]
    }

    /// Get pages read count for a skill
    func pagesReadCount(forSkill skillId: String) -> Int {
        theoryProgress[skillId]?.pagesRead.count ?? 0
    }

    /// Mark a page as read
    func markPageRead(_ pageIndex: Int, forSkill skillId: String, totalPages: Int) {
        var progress = theoryProgress[skillId] ?? TheoryProgress(skillId: skillId)
        progress.pagesRead.insert(pageIndex)
        progress.updateCompletion(totalPages: totalPages)
        theoryProgress[skillId] = progress
        saveToStorage()

        if progress.isComplete {
            logger.info("Theory completed for skill: \(skillId)")
        }
    }

    /// Skip theory for a skill (user already knows it)
    func skipTheory(forSkill skillId: String) {
        var progress = theoryProgress[skillId] ?? TheoryProgress(skillId: skillId)
        progress.isComplete = true
        progress.skipped = true
        progress.completedAt = Date()
        theoryProgress[skillId] = progress
        saveToStorage()

        logger.info("Theory skipped for skill: \(skillId)")
    }

    /// Reset theory progress for a skill (e.g., user wants to re-read)
    func resetTheory(forSkill skillId: String) {
        theoryProgress[skillId] = TheoryProgress(skillId: skillId)
        saveToStorage()

        logger.info("Theory reset for skill: \(skillId)")
    }

    // MARK: - Storage

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            logger.debug("No stored theory progress found")
            return
        }

        do {
            let decoder = JSONDecoder()
            let progressArray = try decoder.decode([TheoryProgress].self, from: data)
            theoryProgress = Dictionary(uniqueKeysWithValues: progressArray.map { ($0.skillId, $0) })
            logger.debug("Loaded theory progress for \(progressArray.count) skills")
        } catch {
            logger.error("Failed to decode theory progress: \(error.localizedDescription)")
        }
    }

    private func saveToStorage() {
        do {
            let encoder = JSONEncoder()
            let progressArray = Array(theoryProgress.values)
            let data = try encoder.encode(progressArray)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            logger.error("Failed to encode theory progress: \(error.localizedDescription)")
        }
    }
}
