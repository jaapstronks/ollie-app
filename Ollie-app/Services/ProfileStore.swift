//
//  ProfileStore.swift
//  Ollie-app
//
//  Manages reading and writing the puppy profile with Core Data and automatic CloudKit sync
//

import Foundation
import CoreData
import OllieShared
import Combine
import os

/// Manages reading and writing the puppy profile
/// Architecture: Core Data with NSPersistentCloudKitContainer for automatic CloudKit sync
@MainActor
class ProfileStore: ObservableObject {
    @Published private(set) var profile: PuppyProfile?
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var isSyncing: Bool = false

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "ProfileStore")
    private var cancellables = Set<AnyCancellable>()

    /// App Group suite name for sharing with Intents/Widgets
    private static let appGroupSuiteName = Constants.appGroupIdentifier

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController

        loadProfile()
        setupRemoteChangeObserver()
    }

    // MARK: - Setup

    private func setupRemoteChangeObserver() {
        // Listen for Core Data remote changes (CloudKit sync)
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)

        // Listen for share acceptance to reload profile
        NotificationCenter.default.publisher(for: .cloudKitShareAccepted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleShareAccepted()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change for profile")
        loadProfile()
    }

    private func handleShareAccepted() {
        logger.info("Share accepted - reloading profile from shared store")
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

        // Save to Core Data
        if let existing = CDPuppyProfile.fetch(byId: updatedProfile.id, in: viewContext) {
            existing.update(from: updatedProfile)
        } else {
            _ = CDPuppyProfile.create(from: updatedProfile, in: viewContext)
        }

        do {
            try persistenceController.save()
            profile = updatedProfile
            syncToAppGroup()
            WidgetDataProvider.shared.updateProfileName(updatedProfile.name)
            WatchSyncService.shared.syncToWatch()
        } catch {
            logger.error("Failed to save profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Initial Sync

    /// Perform initial sync on app launch
    func initialSync() async {
        // With NSPersistentCloudKitContainer, sync is automatic
        // Just refresh the view context
        viewContext.refreshAllObjects()
        loadProfile()
    }

    /// Force sync with CloudKit
    func forceSync() async {
        await initialSync()
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

    /// Update the profile photo filename
    func updateProfilePhoto(_ filename: String?) {
        guard var currentProfile = profile else { return }
        currentProfile.profilePhotoFilename = filename
        saveProfile(currentProfile)
    }

    /// Update the dog's name
    func updateName(_ name: String) {
        guard var currentProfile = profile else { return }
        currentProfile.name = name
        saveProfile(currentProfile)
    }

    /// Reset profile (for testing or re-onboarding)
    func resetProfile() {
        // Delete from Core Data
        if let existing = CDPuppyProfile.fetchProfile(in: viewContext) {
            viewContext.delete(existing)
            try? persistenceController.save()
        }
        profile = nil
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

    private func loadProfile() {
        isLoading = true
        defer { isLoading = false }

        // Check if user is a participant (has shared data) - prioritize shared profile
        if let sharedStore = persistenceController.getSharedStore(),
           let cdProfile = CDPuppyProfile.fetchProfile(in: viewContext, from: sharedStore),
           let loadedProfile = cdProfile.toPuppyProfile() {
            logger.info("Loaded profile from shared store (participant mode)")
            profile = loadedProfile
            syncToAppGroup()
            WidgetDataProvider.shared.updateProfileName(loadedProfile.name)
            return
        }

        // Fall back to private store (owner mode)
        if let privateStore = persistenceController.getPrivateStore(),
           let cdProfile = CDPuppyProfile.fetchProfile(in: viewContext, from: privateStore),
           let loadedProfile = cdProfile.toPuppyProfile() {
            logger.info("Loaded profile from private store (owner mode)")
            profile = loadedProfile
            syncToAppGroup()
            WidgetDataProvider.shared.updateProfileName(loadedProfile.name)
            return
        }

        // No profile found in either store - try generic fetch as fallback
        guard let cdProfile = CDPuppyProfile.fetchProfile(in: viewContext),
              let loadedProfile = cdProfile.toPuppyProfile() else {
            profile = nil
            return
        }

        profile = loadedProfile
        syncToAppGroup()
        WidgetDataProvider.shared.updateProfileName(loadedProfile.name)
    }

    // MARK: - Share Acceptance Support

    /// Check if user has an existing profile in their private store
    /// Used to warn before accepting a share invitation
    func hasExistingPrivateProfile() -> Bool {
        guard let privateStore = persistenceController.getPrivateStore() else { return false }
        return CDPuppyProfile.hasProfile(in: viewContext, store: privateStore)
    }

    /// Delete existing profile from private store (called when accepting a share)
    /// Since multi-dog is not supported yet, we need to clear the private profile
    func deletePrivateProfile() {
        guard let privateStore = persistenceController.getPrivateStore() else { return }

        CDPuppyProfile.deleteAllProfiles(in: viewContext, from: privateStore)

        do {
            try persistenceController.save()
            logger.info("Deleted existing private profile to make room for shared profile")
        } catch {
            logger.error("Failed to delete private profile: \(error.localizedDescription)")
        }
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
