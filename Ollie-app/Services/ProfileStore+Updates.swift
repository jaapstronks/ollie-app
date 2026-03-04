//
//  ProfileStore+Updates.swift
//  Otis-app
//
//  Single-property update methods for ProfileStore
//

import Foundation
import OtisShared

extension ProfileStore {

    // MARK: - Configuration Updates

    /// Update the meal schedule
    func updateMealSchedule(_ schedule: MealSchedule) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.mealSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Update the exercise config
    func updateExerciseConfig(_ config: ExerciseConfig) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.exerciseConfig = config
        saveProfile(currentProfile)
    }

    /// Update the prediction config
    func updatePredictionConfig(_ config: PredictionConfig) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.predictionConfig = config
        saveProfile(currentProfile)
    }

    /// Update the notification settings
    func updateNotificationSettings(_ settings: NotificationSettings) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.notificationSettings = settings
        saveProfile(currentProfile)
    }

    /// Update the walk schedule
    func updateWalkSchedule(_ schedule: WalkSchedule) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.walkSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Update the profile photo filename
    func updateProfilePhoto(_ filename: String?) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.profilePhotoFilename = filename
        saveProfile(currentProfile)
    }

    /// Update the webhook configuration
    func updateWebhookConfig(_ config: WebhookConfig) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.webhookConfig = config
        saveProfile(currentProfile)
    }

    // MARK: - Profile Property Updates

    /// Update the dog's name
    func updateName(_ name: String) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.name = name
        saveProfile(currentProfile)
    }

    /// Update the passed date (when the dog passed away)
    func updatePassedDate(_ date: Date?) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.passedDate = date
        saveProfile(currentProfile)
    }

    /// Update the breed selection
    func updateBreed(name: String?, breedId: Int?, sizeCategory: PuppyProfile.SizeCategory?) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.breed = name
        currentProfile.breedId = breedId
        if let size = sizeCategory {
            currentProfile.sizeCategory = size
        }
        saveProfile(currentProfile)
    }

    /// Update just the breedId (for migration from breed name)
    func updateBreedId(_ breedId: Int) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.breedId = breedId
        saveProfile(currentProfile)
    }
}
