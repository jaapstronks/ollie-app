//
//  ProfileStore+Health.swift
//  Ollie-app
//
//  ProfileStore extension for health-related operations:
//  - Health conditions CRUD
//  - Allergies CRUD
//  - Medication schedule management
//  - Behavior interventions
//

import Foundation
import OtisShared
import os

// MARK: - Health Conditions

extension ProfileStore {

    // MARK: Health Conditions CRUD

    /// Add a new health condition to the active profile
    func addCondition(_ condition: HealthCondition) {
        guard var profile = activeProfile else { return }
        profile.healthConditions.append(condition)
        saveProfile(profile)
        logger.info("Added health condition: \(condition.displayName)")
    }

    /// Update an existing health condition
    func updateCondition(_ condition: HealthCondition) {
        guard var profile = activeProfile else { return }
        if let index = profile.healthConditions.firstIndex(where: { $0.id == condition.id }) {
            profile.healthConditions[index] = condition.withUpdatedTimestamp()
            saveProfile(profile)
            logger.info("Updated health condition: \(condition.displayName)")
        }
    }

    /// Delete a health condition by ID
    func deleteCondition(id: UUID) {
        guard var profile = activeProfile else { return }
        profile.healthConditions.removeAll { $0.id == id }
        saveProfile(profile)
        logger.info("Deleted health condition: \(id)")
    }

    /// Mark a condition as reviewed (updates lastReviewDate)
    func markConditionReviewed(id: UUID) {
        guard var profile = activeProfile else { return }
        if let index = profile.healthConditions.firstIndex(where: { $0.id == id }) {
            var condition = profile.healthConditions[index]
            condition.lastReviewDate = Date()
            condition.modifiedAt = Date()
            profile.healthConditions[index] = condition
            saveProfile(profile)
            logger.info("Marked condition as reviewed: \(condition.displayName)")
        }
    }

    /// Link a medication to a condition
    func linkMedication(medicationId: UUID, toCondition conditionId: UUID) {
        guard var profile = activeProfile else { return }
        if let index = profile.healthConditions.firstIndex(where: { $0.id == conditionId }) {
            var condition = profile.healthConditions[index]
            if !condition.associatedMedicationIds.contains(medicationId) {
                condition.associatedMedicationIds.append(medicationId)
                condition.modifiedAt = Date()
                profile.healthConditions[index] = condition
                saveProfile(profile)
            }
        }
    }

    /// Unlink a medication from a condition
    func unlinkMedication(medicationId: UUID, fromCondition conditionId: UUID) {
        guard var profile = activeProfile else { return }
        if let index = profile.healthConditions.firstIndex(where: { $0.id == conditionId }) {
            var condition = profile.healthConditions[index]
            condition.associatedMedicationIds.removeAll { $0 == medicationId }
            condition.modifiedAt = Date()
            profile.healthConditions[index] = condition
            saveProfile(profile)
        }
    }

    // MARK: Health Condition Accessors

    /// Get all active health conditions for the current profile
    var activeConditions: [HealthCondition] {
        activeProfile?.activeHealthConditions ?? []
    }

    /// Get conditions that need review based on their monitoring frequency
    func conditionsNeedingReview() -> [HealthCondition] {
        activeProfile?.conditionsNeedingReview ?? []
    }

    /// Get breed-specific health risks for the current profile
    func breedHealthRisks() -> BreedHealthRisk? {
        activeProfile?.breedHealthRisks
    }

    /// Get conditions the breed is at risk for but haven't been diagnosed
    func undiagnosedRisks() -> [ConditionRisk] {
        activeProfile?.undiagnosedRisks ?? []
    }

    /// Get screenings that are due based on age
    func dueScreenings() -> [ConditionRisk] {
        activeProfile?.dueScreenings ?? []
    }
}

// MARK: - Allergies

extension ProfileStore {

    // MARK: Allergies CRUD

    /// Add a new allergy to the active profile
    func addAllergy(_ allergy: Allergy) {
        guard var profile = activeProfile else { return }
        profile.allergies.append(allergy)
        saveProfile(profile)
        logger.info("Added allergy: \(allergy.allergen)")
    }

    /// Update an existing allergy
    func updateAllergy(_ allergy: Allergy) {
        guard var profile = activeProfile else { return }
        if let index = profile.allergies.firstIndex(where: { $0.id == allergy.id }) {
            profile.allergies[index] = allergy.withUpdatedTimestamp()
            saveProfile(profile)
            logger.info("Updated allergy: \(allergy.allergen)")
        }
    }

    /// Delete an allergy by ID
    func deleteAllergy(id: UUID) {
        guard var profile = activeProfile else { return }
        profile.allergies.removeAll { $0.id == id }
        saveProfile(profile)
        logger.info("Deleted allergy: \(id)")
    }

    // MARK: Allergy Accessors

    /// Get all allergies for the current profile
    var currentAllergies: [Allergy] {
        activeProfile?.allergies ?? []
    }

    /// Get critical (severe/life-threatening) allergies
    var criticalAllergies: [Allergy] {
        activeProfile?.criticalAllergies ?? []
    }

    /// Check if dog has any food allergies
    var hasFoodAllergies: Bool {
        currentAllergies.contains { $0.allergyType == .food }
    }

    /// Get food allergens list for quick reference
    var foodAllergens: [String] {
        currentAllergies
            .filter { $0.allergyType == .food }
            .map { $0.allergen }
    }
}

// MARK: - Medications

extension ProfileStore {

    // MARK: Medication CRUD

    /// Helper to get profile to update - either by ID or active profile
    private func medicationProfileToUpdate(for profileId: UUID?) -> PuppyProfile? {
        if let id = profileId {
            return profile(for: id)
        }
        return activeProfile
    }

    /// Add a new medication
    func addMedication(_ medication: Medication, for profileId: UUID? = nil) {
        guard var currentProfile = medicationProfileToUpdate(for: profileId) else { return }
        currentProfile.medicationSchedule.medications.append(medication)
        saveProfile(currentProfile)
    }

    /// Update an existing medication
    func updateMedication(_ medication: Medication, for profileId: UUID? = nil) {
        guard var currentProfile = medicationProfileToUpdate(for: profileId) else { return }
        if let index = currentProfile.medicationSchedule.medications.firstIndex(where: { $0.id == medication.id }) {
            currentProfile.medicationSchedule.medications[index] = medication
            saveProfile(currentProfile)
        }
    }

    /// Delete a medication by ID
    func deleteMedication(id: UUID, for profileId: UUID? = nil) {
        guard var currentProfile = medicationProfileToUpdate(for: profileId) else { return }
        currentProfile.medicationSchedule.medications.removeAll { $0.id == id }
        saveProfile(currentProfile)
    }

    /// Toggle medication active state
    func toggleMedicationActive(id: UUID, for profileId: UUID? = nil) {
        guard var currentProfile = medicationProfileToUpdate(for: profileId) else { return }
        if let index = currentProfile.medicationSchedule.medications.firstIndex(where: { $0.id == id }) {
            currentProfile.medicationSchedule.medications[index].isActive.toggle()
            saveProfile(currentProfile)
        }
    }
}

// MARK: - Behavior Interventions

extension ProfileStore {

    // MARK: Behavior Intervention CRUD

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
