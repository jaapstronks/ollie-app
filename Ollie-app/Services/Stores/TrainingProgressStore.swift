//
//  TrainingProgressStore.swift
//  Otis-app
//
//  Manages preparation progress and training rules via Core Data (synced to CloudKit)
//

import Foundation
import Combine
import CoreData
import os
import OtisShared

// MARK: - Legacy Storage Keys (for migration)

/// Centralized UserDefaults keys for training progress (legacy - migrating to Core Data)
private enum TrainingStorageKeys {
    static let completedPreparationItems = "training.completedPreparationItems"
    static let seenRules = "training.seenRules"
    static let completedPhases = "training.completedPhases"
}

/// Manages preparation item completion and rule acknowledgment state
/// Data is stored on CDPuppyProfile and syncs via CloudKit
@Observable
@MainActor
final class TrainingProgressStore {

    // MARK: - State

    private(set) var completedPreparationItems: Set<String> = []
    private(set) var seenRules: Set<String> = []
    private(set) var completedPhases: [String: Set<String>] = [:]  // skillId -> phaseIds

    // MARK: - Private

    @ObservationIgnored private let persistenceController: PersistenceController
    @ObservationIgnored private let logger = Logger.otis(category: "TrainingProgressStore")
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadState()
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Reload when active profile changes
        // PERF: Use RunLoop.main to prevent "Publishing changes from within view updates"
        NotificationCenter.default.publisher(for: .activeProfileChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadState()
            }
            .store(in: &cancellables)

        // PERF: Register with centralized coordinator instead of individual listener
        // This reduces 12+ simultaneous reactions to 1 coordinated, debounced response
        CloudKitSyncCoordinator.shared.registerCallback(identifier: "TrainingProgressStore") { [weak self] in
            self?.loadState()
        }
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

    /// Load state from Core Data (with migration from UserDefaults)
    private func loadState() {
        guard let cdProfile = getActiveProfile() else {
            // No profile yet - check for legacy UserDefaults data to hold temporarily
            loadFromUserDefaults()
            return
        }

        let state = cdProfile.getTrainingPreparationState()

        // Check if Core Data has data or if we need to migrate from UserDefaults
        if state.completedPreparationItems.isEmpty && state.seenRules.isEmpty && state.completedPhases.isEmpty {
            // Try to migrate from UserDefaults
            if migrateFromUserDefaults(to: cdProfile) {
                // Reload after migration
                let newState = cdProfile.getTrainingPreparationState()
                completedPreparationItems = newState.completedPreparationItems
                seenRules = newState.seenRules
                completedPhases = newState.completedPhases
                return
            }
        }

        completedPreparationItems = state.completedPreparationItems
        seenRules = state.seenRules
        completedPhases = state.completedPhases
    }

    /// Legacy: Load from UserDefaults (for temporary state before profile exists)
    private func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
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

    /// Migrate data from UserDefaults to Core Data
    /// Returns true if migration was performed
    @discardableResult
    private func migrateFromUserDefaults(to cdProfile: CDPuppyProfile) -> Bool {
        let defaults = UserDefaults.standard

        let savedItems = defaults.stringArray(forKey: TrainingStorageKeys.completedPreparationItems) ?? []
        let savedRules = defaults.stringArray(forKey: TrainingStorageKeys.seenRules) ?? []
        let savedPhases = defaults.dictionary(forKey: TrainingStorageKeys.completedPhases) as? [String: [String]] ?? [:]

        // Only migrate if there's data to migrate
        guard !savedItems.isEmpty || !savedRules.isEmpty || !savedPhases.isEmpty else {
            return false
        }

        logger.info("Migrating training preparation data from UserDefaults to Core Data")

        let state = TrainingPreparationState(
            completedPreparationItems: Set(savedItems),
            seenRules: Set(savedRules),
            completedPhases: savedPhases.mapValues { Set($0) }
        )

        cdProfile.setTrainingPreparationState(state)
        saveToProfile()

        // Clear UserDefaults after successful migration
        defaults.removeObject(forKey: TrainingStorageKeys.completedPreparationItems)
        defaults.removeObject(forKey: TrainingStorageKeys.seenRules)
        defaults.removeObject(forKey: TrainingStorageKeys.completedPhases)

        logger.info("Successfully migrated training preparation data to Core Data")
        return true
    }

    /// Get the active CDPuppyProfile
    private func getActiveProfile() -> CDPuppyProfile? {
        guard let activeId = UserDefaults.standard.string(forKey: "activeProfileId"),
              let uuid = UUID(uuidString: activeId) else {
            // Fallback: try to get any profile
            return CDPuppyProfile.fetchProfile(in: viewContext)
        }
        return CDPuppyProfile.fetch(byId: uuid, in: viewContext)
    }

    /// Save current state to Core Data
    private func saveToProfile() {
        guard let cdProfile = getActiveProfile() else {
            // No profile - save to UserDefaults temporarily (will migrate later)
            saveToUserDefaults()
            return
        }

        let state = TrainingPreparationState(
            completedPreparationItems: completedPreparationItems,
            seenRules: seenRules,
            completedPhases: completedPhases
        )

        cdProfile.setTrainingPreparationState(state)

        do {
            try persistenceController.save()
        } catch {
            logger.error("Failed to save training preparation state: \(error.localizedDescription)")
        }
    }

    /// Legacy: Save to UserDefaults (fallback when no profile exists)
    private func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(Array(completedPreparationItems), forKey: TrainingStorageKeys.completedPreparationItems)
        defaults.set(Array(seenRules), forKey: TrainingStorageKeys.seenRules)
        let serializable = completedPhases.mapValues { Array($0) }
        defaults.set(serializable, forKey: TrainingStorageKeys.completedPhases)
    }

    private func savePreparationItems() {
        saveToProfile()
    }

    private func saveSeenRules() {
        saveToProfile()
    }

    private func saveCompletedPhases() {
        saveToProfile()
    }
}
