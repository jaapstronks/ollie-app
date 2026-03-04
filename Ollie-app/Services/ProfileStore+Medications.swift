//
//  ProfileStore+Medications.swift
//  Otis-app
//
//  Medication schedule management extension for ProfileStore
//

import Foundation
import OtisShared

extension ProfileStore {

    // MARK: - Medication Schedule

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
