//
//  ProfileStore+Updates.swift
//  Otis-app
//
//  Single-property update methods for ProfileStore
//  All methods accept an optional profileId - if nil, uses the active profile
//

import Foundation
import OtisShared

extension ProfileStore {

    // MARK: - Helper

    /// Get profile to update - either by ID or active profile
    private func profileToUpdate(for profileId: UUID?) -> PuppyProfile? {
        if let id = profileId {
            return profile(for: id)
        }
        return activeProfile
    }

    // MARK: - Configuration Updates

    /// Update the meal schedule
    func updateMealSchedule(_ schedule: MealSchedule, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.mealSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Update the exercise config
    func updateExerciseConfig(_ config: ExerciseConfig, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.exerciseConfig = config
        saveProfile(currentProfile)
    }

    /// Update the prediction config
    func updatePredictionConfig(_ config: PredictionConfig, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.predictionConfig = config
        saveProfile(currentProfile)
    }

    /// Update the notification settings
    func updateNotificationSettings(_ settings: NotificationSettings, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.notificationSettings = settings
        saveProfile(currentProfile)
    }

    /// Update the walk schedule
    func updateWalkSchedule(_ schedule: WalkSchedule, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.walkSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Update the profile photo filename
    func updateProfilePhoto(_ filename: String?, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.profilePhotoFilename = filename
        saveProfile(currentProfile)
    }

    /// Update the webhook configuration
    func updateWebhookConfig(_ config: WebhookConfig, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.webhookConfig = config
        saveProfile(currentProfile)
    }

    // MARK: - Profile Property Updates

    /// Update the dog's name
    func updateName(_ name: String, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.name = name
        saveProfile(currentProfile)
    }

    /// Update the passed date (when the dog passed away)
    func updatePassedDate(_ date: Date?, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.passedDate = date
        saveProfile(currentProfile)
    }

    /// Update the breed selection
    func updateBreed(name: String?, breedId: Int?, sizeCategory: PuppyProfile.SizeCategory?, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.breed = name
        currentProfile.breedId = breedId
        if let size = sizeCategory {
            currentProfile.sizeCategory = size
        }
        saveProfile(currentProfile)
    }

    /// Update just the breedId (for migration from breed name)
    func updateBreedId(_ breedId: Int, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.breedId = breedId
        saveProfile(currentProfile)
    }

    /// Update the medication schedule
    func updateMedicationSchedule(_ schedule: MedicationSchedule, for profileId: UUID? = nil) {
        guard var currentProfile = profileToUpdate(for: profileId) else { return }
        currentProfile.medicationSchedule = schedule
        saveProfile(currentProfile)
    }
}
