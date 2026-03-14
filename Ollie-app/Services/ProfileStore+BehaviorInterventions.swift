//
//  ProfileStore+BehaviorInterventions.swift
//  Otis-app
//
//  Behavior intervention management extension for ProfileStore
//

import Foundation
import os
import OtisShared

extension ProfileStore {

    // MARK: - Behavior Interventions

    /// Get all behavior interventions for the active profile
    func behaviorInterventions() -> [BehaviorIntervention] {
        activeProfile?.behaviorInterventions ?? []
    }

    /// Get active interventions for a specific behavior category
    func activeInterventions(for category: BehaviorCategory) -> [BehaviorIntervention] {
        behaviorInterventions().filter { $0.category == category && $0.isActive }
    }

    /// Get all active interventions
    func activeInterventions() -> [BehaviorIntervention] {
        behaviorInterventions().filter { $0.isActive }
    }

    /// Add a new behavior intervention
    func addIntervention(_ intervention: BehaviorIntervention) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.behaviorInterventions.append(intervention)
        saveProfile(currentProfile)
        logger.info("Added intervention: \(intervention.name) for \(intervention.category.rawValue)")
    }

    /// Update an existing intervention
    func updateIntervention(_ intervention: BehaviorIntervention) {
        guard var currentProfile = activeProfile else { return }
        if let index = currentProfile.behaviorInterventions.firstIndex(where: { $0.id == intervention.id }) {
            currentProfile.behaviorInterventions[index] = intervention
            saveProfile(currentProfile)
        }
    }

    /// Delete an intervention by ID
    func deleteIntervention(id: UUID) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.behaviorInterventions.removeAll { $0.id == id }
        saveProfile(currentProfile)
    }

    /// Mark an intervention as practiced
    func markInterventionPracticed(id: UUID, on date: Date = Date()) {
        guard var currentProfile = activeProfile else { return }
        if let index = currentProfile.behaviorInterventions.firstIndex(where: { $0.id == id }) {
            currentProfile.behaviorInterventions[index].markPracticed(on: date)
            saveProfile(currentProfile)
            logger.debug("Marked intervention practiced: \(currentProfile.behaviorInterventions[index].name)")
        }
    }

    /// Toggle intervention active state
    func toggleInterventionActive(id: UUID) {
        guard var currentProfile = activeProfile else { return }
        if let index = currentProfile.behaviorInterventions.firstIndex(where: { $0.id == id }) {
            currentProfile.behaviorInterventions[index].isActive.toggle()
            saveProfile(currentProfile)
        }
    }

    /// Create intervention from template
    func addInterventionFromTemplate(_ template: InterventionTemplate, for category: BehaviorCategory, notes: String? = nil) {
        let intervention = template.toIntervention(for: category, notes: notes)
        addIntervention(intervention)
    }
}
