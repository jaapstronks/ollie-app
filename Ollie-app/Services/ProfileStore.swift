//
//  ProfileStore.swift
//  Ollie-app
//

import Foundation
import OllieShared
import Combine
import os

/// Manages reading and writing the puppy profile with CloudKit sync
@MainActor
class ProfileStore: ObservableObject {
    @Published private(set) var profile: PuppyProfile?
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var isSyncing: Bool = false

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let cloudKit = CloudKitService.shared
    private let logger = Logger.ollie(category: "ProfileStore")

    /// App Group suite name for sharing with Intents/Widgets
    private static let appGroupSuiteName = Constants.appGroupIdentifier

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let profileCloudMigrationCompleted = "profileStore.cloudMigrationCompleted"
    }

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
        let updatedProfile = newProfile.withUpdatedTimestamp()
        profile = updatedProfile
        writeProfile()

        // Sync to CloudKit
        Task {
            await saveToCloud(updatedProfile)
        }
    }

    // MARK: - Initial Sync

    /// Perform initial sync on app launch
    func initialSync() async {
        guard cloudKit.isCloudAvailable else {
            logger.info("CloudKit not available, skipping profile sync")
            return
        }

        // Migrate existing local profile to CloudKit if needed
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.profileCloudMigrationCompleted) {
            await migrateLocalProfile()
        }

        // Fetch from cloud and merge
        await fetchFromCloud()
    }

    /// Force sync with CloudKit
    func forceSync() async {
        await fetchFromCloud()
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

    // MARK: - CloudKit Operations

    /// Save profile to CloudKit
    private func saveToCloud(_ profile: PuppyProfile) async {
        guard cloudKit.isCloudAvailable else {
            logger.info("CloudKit not available, profile saved locally only")
            return
        }

        do {
            try await cloudKit.saveProfile(profile)
            logger.info("Profile synced to CloudKit")
        } catch {
            logger.warning("Failed to save profile to cloud: \(error.localizedDescription)")
        }
    }

    /// Fetch profile from CloudKit and merge with local
    private func fetchFromCloud() async {
        guard cloudKit.isCloudAvailable else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            if let cloudProfile = try await cloudKit.fetchProfile() {
                let merged = mergeProfiles(local: profile, cloud: cloudProfile)
                if merged.id != profile?.id || merged.modifiedAt != profile?.modifiedAt {
                    profile = merged
                    writeProfile()
                    logger.info("Profile updated from CloudKit")
                }
            }
        } catch {
            logger.warning("Failed to fetch profile from cloud: \(error.localizedDescription)")
        }
    }

    /// Migrate existing local profile to CloudKit (one-time)
    private func migrateLocalProfile() async {
        guard let localProfile = profile else {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.profileCloudMigrationCompleted)
            return
        }

        logger.info("Migrating local profile to CloudKit")

        do {
            try await cloudKit.saveProfile(localProfile)
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.profileCloudMigrationCompleted)
            logger.info("Profile migration completed")
        } catch {
            logger.error("Profile migration failed: \(error.localizedDescription)")
        }
    }

    /// Merge local and cloud profiles, preferring newer modifiedAt
    private func mergeProfiles(local: PuppyProfile?, cloud: PuppyProfile) -> PuppyProfile {
        guard let local = local else {
            // No local profile, use cloud
            return cloud
        }

        // Same profile ID - use newer modifiedAt
        if local.id == cloud.id {
            return local.modifiedAt > cloud.modifiedAt ? local : cloud
        }

        // Different profile IDs - this shouldn't happen normally
        // Prefer cloud if it's newer, otherwise keep local
        logger.warning("Profile ID mismatch: local=\(local.id), cloud=\(cloud.id)")
        return cloud.modifiedAt > local.modifiedAt ? cloud : local
    }
}
