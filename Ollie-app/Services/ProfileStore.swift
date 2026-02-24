//
//  ProfileStore.swift
//  Ollie-app
//

import Foundation
import OllieShared
import Combine

/// Manages reading and writing the puppy profile
@MainActor
class ProfileStore: ObservableObject {
    @Published private(set) var profile: PuppyProfile?
    @Published private(set) var isLoading: Bool = true

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// App Group suite name for sharing with Intents/Widgets
    private static let appGroupSuiteName = Constants.appGroupIdentifier

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        loadProfile()
    }

    // MARK: - Public Methods

    /// Check if a profile exists
    var hasProfile: Bool {
        profile != nil
    }

    /// Save a new or updated profile
    func saveProfile(_ newProfile: PuppyProfile) {
        profile = newProfile
        writeProfile()
    }

    /// Update the meal schedule
    func updateMealSchedule(_ schedule: MealSchedule) {
        guard var currentProfile = profile else { return }
        currentProfile.mealSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Update the exercise config
    func updateExerciseConfig(_ config: ExerciseConfig) {
        guard var currentProfile = profile else { return }
        currentProfile.exerciseConfig = config
        saveProfile(currentProfile)
    }

    /// Update the prediction config
    func updatePredictionConfig(_ config: PredictionConfig) {
        guard var currentProfile = profile else { return }
        currentProfile.predictionConfig = config
        saveProfile(currentProfile)
    }

    /// Update the notification settings
    func updateNotificationSettings(_ settings: NotificationSettings) {
        guard var currentProfile = profile else { return }
        currentProfile.notificationSettings = settings
        saveProfile(currentProfile)
    }

    /// Update the walk schedule
    func updateWalkSchedule(_ schedule: WalkSchedule) {
        guard var currentProfile = profile else { return }
        currentProfile.walkSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Reset profile (for testing or re-onboarding)
    func resetProfile() {
        profile = nil
        let url = profileURL
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Medication Schedule

    /// Update the medication schedule
    func updateMedicationSchedule(_ schedule: MedicationSchedule) {
        guard var currentProfile = profile else { return }
        currentProfile.medicationSchedule = schedule
        saveProfile(currentProfile)
    }

    /// Add a new medication
    func addMedication(_ medication: Medication) {
        guard var currentProfile = profile else { return }
        currentProfile.medicationSchedule.medications.append(medication)
        saveProfile(currentProfile)
    }

    /// Update an existing medication
    func updateMedication(_ medication: Medication) {
        guard var currentProfile = profile else { return }
        if let index = currentProfile.medicationSchedule.medications.firstIndex(where: { $0.id == medication.id }) {
            currentProfile.medicationSchedule.medications[index] = medication
            saveProfile(currentProfile)
        }
    }

    /// Delete a medication by ID
    func deleteMedication(id: UUID) {
        guard var currentProfile = profile else { return }
        currentProfile.medicationSchedule.medications.removeAll { $0.id == id }
        saveProfile(currentProfile)
    }

    /// Toggle medication active state
    func toggleMedicationActive(id: UUID) {
        guard var currentProfile = profile else { return }
        if let index = currentProfile.medicationSchedule.medications.firstIndex(where: { $0.id == id }) {
            currentProfile.medicationSchedule.medications[index].isActive.toggle()
            saveProfile(currentProfile)
        }
    }

    // MARK: - Private Methods

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var profileURL: URL {
        documentsURL.appendingPathComponent(Constants.profileFileName)
    }

    private func loadProfile() {
        isLoading = true
        defer { isLoading = false }

        guard fileManager.fileExists(atPath: profileURL.path),
              let data = try? Data(contentsOf: profileURL),
              let loadedProfile = try? decoder.decode(PuppyProfile.self, from: data) else {
            profile = nil
            return
        }

        profile = loadedProfile

        // Sync to App Group on load for Intents/Widgets
        syncToAppGroup()

        // Also update widget data with profile name on load
        WidgetDataProvider.shared.updateProfileName(loadedProfile.name)
    }

    private func writeProfile() {
        guard let profile = profile,
              let data = try? encoder.encode(profile) else {
            return
        }

        try? data.write(to: profileURL, options: .atomic)

        // Sync minimal profile to App Group for Intents/Widgets
        syncToAppGroup()

        // Update widget data with new profile name
        WidgetDataProvider.shared.updateProfileName(profile.name)

        // Sync to Apple Watch
        WatchSyncService.shared.syncToWatch()
    }

    // MARK: - App Group Sync

    /// Syncs a minimal profile to App Group for use by App Intents and Widgets
    /// Called automatically after any profile save
    private func syncToAppGroup() {
        guard let profile = profile else { return }

        let sharedProfile = SharedProfile(from: profile)
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupSuiteName),
              let data = try? JSONEncoder().encode(sharedProfile) else {
            return
        }

        sharedDefaults.set(data, forKey: IntentDataStore.profileKey)
    }

    /// Force sync the current profile to App Group
    /// Call this if profile was loaded from elsewhere and needs to be shared
    func forceAppGroupSync() {
        syncToAppGroup()
    }
}
