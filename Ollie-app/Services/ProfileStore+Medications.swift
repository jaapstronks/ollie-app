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

    /// Update the medication schedule
    func updateMedicationSchedule(_ schedule: MedicationSchedule) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.medicationSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Add a new medication
    func addMedication(_ medication: Medication) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.medicationSchedule.medications.append(medication)
        saveProfile(currentProfile)
    }

    /// Update an existing medication
    func updateMedication(_ medication: Medication) {
        guard var currentProfile = activeProfile else { return }
        if let index = currentProfile.medicationSchedule.medications.firstIndex(where: { $0.id == medication.id }) {
            currentProfile.medicationSchedule.medications[index] = medication
            saveProfile(currentProfile)
        }
    }

    /// Delete a medication by ID
    func deleteMedication(id: UUID) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.medicationSchedule.medications.removeAll { $0.id == id }
        saveProfile(currentProfile)
    }

    /// Toggle medication active state
    func toggleMedicationActive(id: UUID) {
        guard var currentProfile = activeProfile else { return }
        if let index = currentProfile.medicationSchedule.medications.firstIndex(where: { $0.id == id }) {
            currentProfile.medicationSchedule.medications[index].isActive.toggle()
            saveProfile(currentProfile)
        }
    }
}
