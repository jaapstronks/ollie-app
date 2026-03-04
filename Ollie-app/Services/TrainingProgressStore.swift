//
//  TrainingProgressStore.swift
//  Otis-app
//
//  Manages preparation progress and training rules via UserDefaults
//

import Foundation
import Combine

// MARK: - Storage Keys

/// Centralized UserDefaults keys for training progress
private enum TrainingStorageKeys {
    static let completedPreparationItems = "training.completedPreparationItems"
    static let seenRules = "training.seenRules"
    static let completedPhases = "training.completedPhases"
}

/// Manages preparation item completion and rule acknowledgment state
@MainActor
final class TrainingProgressStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var completedPreparationItems: Set<String> = []
    @Published private(set) var seenRules: Set<String> = []
    @Published private(set) var completedPhases: [String: Set<String>] = [:]  // skillId -> phaseIds

    // MARK: - Private

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadState()
    }

    // MARK: - Computed Properties

    /// Check if all preparation items are complete
    /// This needs a reference to the training plan to check
    func isPreparationComplete(requiredItems: [PreparationItem]) -> Bool {
        let requiredIds = Set(requiredItems.map { $0.id })
        return requiredIds.isSubset(of: completedPreparationItems)
    }

    /// Check if all equipment items are complete
    func isEquipmentComplete(equipmentItems: [PreparationItem]) -> Bool {
        let equipmentIds = Set(equipmentItems.map { $0.id })
        return equipmentIds.isSubset(of: completedPreparationItems)
    }

    /// Check if all concept items are complete
    func isConceptsComplete(conceptItems: [PreparationItem]) -> Bool {
        let conceptIds = Set(conceptItems.map { $0.id })
        return conceptIds.isSubset(of: completedPreparationItems)
    }

    // MARK: - Preparation Items

    /// Mark a preparation item as completed
    func completePreparationItem(_ id: String) {
        guard !completedPreparationItems.contains(id) else { return }
        completedPreparationItems.insert(id)
        savePreparationItems()
    }

    /// Unmark a preparation item as completed
    func uncompletePreparationItem(_ id: String) {
        guard completedPreparationItems.contains(id) else { return }
        completedPreparationItems.remove(id)
        savePreparationItems()
    }

    /// Toggle completion state of a preparation item
    func togglePreparationItem(_ id: String) {
        if completedPreparationItems.contains(id) {
            uncompletePreparationItem(id)
        } else {
            completePreparationItem(id)
        }
    }

    /// Check if a preparation item is completed
    func isPreparationItemCompleted(_ id: String) -> Bool {
        completedPreparationItems.contains(id)
    }

    // MARK: - Rules

    /// Mark a rule as seen/acknowledged
    func markRuleAsSeen(_ id: String) {
        guard !seenRules.contains(id) else { return }
        seenRules.insert(id)
        saveSeenRules()
    }

    /// Check if a rule has been seen
    func hasSeenRule(_ id: String) -> Bool {
        seenRules.contains(id)
    }

    /// Get unseen rules for a specific step
    func unseenRules(for stepId: String, allRules: [TrainingRule]) -> [TrainingRule] {
        allRules.filter { rule in
            rule.triggeredByStep == stepId && !seenRules.contains(rule.id)
        }
    }

    /// Get all seen rules
    func getSeenRules(from allRules: [TrainingRule]) -> [TrainingRule] {
        allRules.filter { seenRules.contains($0.id) }
    }

    // MARK: - Phase Completion

    /// Mark a phase as completed for a specific skill
    func completePhase(_ phaseId: String, forSkill skillId: String) {
        var phases = completedPhases[skillId] ?? Set()
        guard !phases.contains(phaseId) else { return }
        phases.insert(phaseId)
        completedPhases[skillId] = phases
        saveCompletedPhases()
    }

    /// Unmark a phase as completed
    func uncompletePhase(_ phaseId: String, forSkill skillId: String) {
        guard var phases = completedPhases[skillId], phases.contains(phaseId) else { return }
        phases.remove(phaseId)
        completedPhases[skillId] = phases.isEmpty ? nil : phases
        saveCompletedPhases()
    }

    /// Toggle phase completion state
    func togglePhase(_ phaseId: String, forSkill skillId: String) {
        if isPhaseCompleted(phaseId, forSkill: skillId) {
            uncompletePhase(phaseId, forSkill: skillId)
        } else {
            completePhase(phaseId, forSkill: skillId)
        }
    }

    /// Check if a phase is completed for a skill
    func isPhaseCompleted(_ phaseId: String, forSkill skillId: String) -> Bool {
        completedPhases[skillId]?.contains(phaseId) ?? false
    }

    /// Check if all phases are completed for a skill
    func allPhasesCompleted(for skill: Skill) -> Bool {
        let effectivePhases = skill.effectivePhases
        guard !effectivePhases.isEmpty else { return true }
        let completed = completedPhases[skill.id] ?? Set()
        return effectivePhases.allSatisfy { completed.contains($0.id) }
    }

    /// Get completed phase count for a skill
    func completedPhaseCount(for skill: Skill) -> Int {
        let completed = completedPhases[skill.id] ?? Set()
        return skill.effectivePhases.filter { completed.contains($0.id) }.count
    }

    /// Reset all phases for a specific skill
    func resetPhases(forSkill skillId: String) {
        completedPhases[skillId] = nil
        saveCompletedPhases()
    }

    // MARK: - Reset

    /// Reset all progress (for testing or starting fresh)
    func resetAllProgress() {
        completedPreparationItems.removeAll()
        seenRules.removeAll()
        completedPhases.removeAll()
        savePreparationItems()
        saveSeenRules()
        saveCompletedPhases()
    }

    // MARK: - Private: Persistence

    private func loadState() {
        if let savedItems = defaults.stringArray(forKey: TrainingStorageKeys.completedPreparationItems) {
            completedPreparationItems = Set(savedItems)
        }
        if let savedRules = defaults.stringArray(forKey: TrainingStorageKeys.seenRules) {
            seenRules = Set(savedRules)
        }
        if let savedPhases = defaults.dictionary(forKey: TrainingStorageKeys.completedPhases) as? [String: [String]] {
            completedPhases = savedPhases.mapValues { Set($0) }
        }
    }

    private func savePreparationItems() {
        defaults.set(Array(completedPreparationItems), forKey: TrainingStorageKeys.completedPreparationItems)
    }

    private func saveSeenRules() {
        defaults.set(Array(seenRules), forKey: TrainingStorageKeys.seenRules)
    }

    private func saveCompletedPhases() {
        let serializable = completedPhases.mapValues { Array($0) }
        defaults.set(serializable, forKey: TrainingStorageKeys.completedPhases)
    }
}
