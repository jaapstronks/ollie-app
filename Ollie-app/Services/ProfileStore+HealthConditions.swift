//
//  ProfileStore+HealthConditions.swift
//  Ollie-app
//
//  ProfileStore extension for health condition and allergy CRUD operations
//  Part of Brief 03: Health Foundation
//

import Foundation
import OtisShared
import os

extension ProfileStore {

    // MARK: - Health Conditions CRUD

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

    // MARK: - Allergies CRUD

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

    // MARK: - Convenience Accessors

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
