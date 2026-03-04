//
//  ProfileStore.swift
//  Otis-app
//
//  Manages reading and writing puppy profiles with Core Data and automatic CloudKit sync
//  Supports multiple profiles (multi-puppy feature) with one active profile at a time
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages reading and writing puppy profiles
/// Architecture: Core Data with NSPersistentCloudKitContainer for automatic CloudKit sync
@MainActor
class ProfileStore: ObservableObject {
    // MARK: - Multi-Profile Support

    /// All loaded profiles (owned + shared)
    @Published private(set) var profiles: [PuppyProfile] = []

    /// ID of the currently active profile
    @Published private(set) var activeProfileId: UUID? {
        didSet {
            if let id = activeProfileId {
                UserDefaults.standard.set(id.uuidString, forKey: "activeProfileId")
            }
            // Post notification when active profile changes
            NotificationCenter.default.post(name: .activeProfileChanged, object: nil)
        }
    }

    /// The currently active profile (convenience accessor)
    var activeProfile: PuppyProfile? {
        profiles.first { $0.id == activeProfileId }
    }

    /// Backward compatibility: profile property maps to activeProfile
    var profile: PuppyProfile? {
        activeProfile
    }

    /// Number of owned profiles (counts against subscription limit)
    var ownedProfileCount: Int {
        profiles.filter { $0.ownership == .owned }.count
    }

    /// Number of shared profiles (unlimited, free)
    var sharedProfileCount: Int {
        profiles.filter { $0.ownership == .shared }.count
    }

    // MARK: - Existing Properties

    @Published private(set) var isLoading: Bool = true
    @Published private(set) var isSyncing: Bool = false

    private let persistenceController: PersistenceController
    let logger = Logger.otis(category: "ProfileStore")
    private var cancellables = Set<AnyCancellable>()

    /// App Group suite name for sharing with Intents/Widgets
    private static let appGroupSuiteName = Constants.appGroupIdentifier

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController

        // Restore last active profile ID
        if let storedId = UserDefaults.standard.string(forKey: "activeProfileId"),
           let uuid = UUID(uuidString: storedId) {
            activeProfileId = uuid
        }

        loadAllProfiles()
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

        // Listen for share acceptance to reload profiles
        NotificationCenter.default.publisher(for: .cloudKitShareAccepted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleShareAccepted()
            }
            .store(in: &cancellables)

        // Listen for seed data profile creation (UI testing mode)
        NotificationCenter.default.publisher(for: NSNotification.Name("ProfileStoreReload"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.logger.info("Received ProfileStoreReload notification - reloading profiles")
                self?.loadAllProfiles()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change for profiles")
        loadAllProfiles()
    }

    private func handleShareAccepted() {
        logger.info("Share accepted - reloading all profiles")
        loadAllProfiles()
    }

    // MARK: - Public Methods

    /// Check if any profile exists
    var hasProfile: Bool {
        !profiles.isEmpty
    }

    /// Switch to a different profile
    func switchToProfile(_ profileId: UUID) {
        guard profiles.contains(where: { $0.id == profileId }) else {
            logger.warning("Attempted to switch to non-existent profile: \(profileId)")
            return
        }

        activeProfileId = profileId
        syncToAppGroup()

        if let profile = activeProfile {
            WidgetDataProvider.shared.updateProfileName(profile.name)
            WatchSyncService.shared.syncToWatch()
        }

        logger.info("Switched to profile: \(self.activeProfile?.name ?? "unknown")")
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

            // Update local cache
            if let index = profiles.firstIndex(where: { $0.id == updatedProfile.id }) {
                profiles[index] = updatedProfile
            } else {
                profiles.append(updatedProfile)
            }

            // If this is the first profile or matches active, update widgets/watch
            if activeProfileId == nil {
                activeProfileId = updatedProfile.id
            }

            if updatedProfile.id == activeProfileId {
                syncToAppGroup()
                WidgetDataProvider.shared.updateProfileName(updatedProfile.name)
                WatchSyncService.shared.syncToWatch()
            }
        } catch {
            logger.error("Failed to save profile: \(error.localizedDescription)")
        }
    }

    /// Create a new profile (checks subscription limits)
    /// Returns nil if at owned profile limit
    func createProfile(_ newProfile: PuppyProfile) -> Bool {
        // Check if user can add more owned profiles
        let maxOwnedProfiles = SubscriptionManager.shared.effectiveStatus.hasOtisPlus ? maxOtisProfiles : maxFreeProfiles

        if ownedProfileCount >= maxOwnedProfiles {
            logger.warning("Cannot create profile - at limit (\(self.ownedProfileCount)/\(maxOwnedProfiles))")
            return false
        }

        saveProfile(newProfile)
        return true
    }

    /// Delete a profile
    func deleteProfile(_ profileId: UUID) {
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: viewContext) else {
            return
        }

        viewContext.delete(cdProfile)

        do {
            try persistenceController.save()

            // Remove from local cache
            profiles.removeAll { $0.id == profileId }

            // If deleted profile was active, switch to another
            if activeProfileId == profileId {
                activeProfileId = profiles.first?.id
                if let profile = activeProfile {
                    syncToAppGroup()
                    WidgetDataProvider.shared.updateProfileName(profile.name)
                }
            }

            WatchSyncService.shared.syncToWatch()
            logger.info("Deleted profile: \(profileId)")
        } catch {
            logger.error("Failed to delete profile: \(error.localizedDescription)")
        }
    }

    /// Leave a shared profile (stop participating)
    func leaveSharedProfile(_ profileId: UUID) {
        guard let profile = profiles.first(where: { $0.id == profileId }),
              profile.ownership == .shared else {
            logger.warning("Cannot leave profile - not a shared profile")
            return
        }

        // For shared profiles, just remove from our list
        // The data remains in the shared store but we no longer track it
        deleteProfile(profileId)
    }

    // MARK: - Initial Sync

    /// Perform initial sync on app launch
    func initialSync() async {
        // With NSPersistentCloudKitContainer, sync is automatic
        // Just refresh the view context
        viewContext.refreshAllObjects()
        loadAllProfiles()

        // Run breed migration if needed for active profile
        await migrateBreedNameToId()

        // Link any orphaned events to the first profile
        migrateOrphanedEventsIfNeeded()

        // Ensure current user exists in household members
        ensureCurrentUserExists()
    }

    /// Link orphaned events (without profile relationship) to the first profile
    private func migrateOrphanedEventsIfNeeded() {
        guard let firstProfile = profiles.first,
              let cdProfile = CDPuppyProfile.fetch(byId: firstProfile.id, in: viewContext) else {
            return
        }

        let linkedCount = CDPuppyEvent.linkOrphanedEvents(to: cdProfile, in: viewContext)
        if linkedCount > 0 {
            do {
                try persistenceController.save()
                logger.info("Linked \(linkedCount) orphaned events to profile '\(firstProfile.name)'")
            } catch {
                logger.error("Failed to save after linking orphaned events: \(error.localizedDescription)")
            }
        }
    }

    /// Migrate breed name to breedId if profile has breed but no breedId
    private func migrateBreedNameToId() async {
        guard let profile = activeProfile,
              let breedName = profile.breed,
              !breedName.isEmpty,
              profile.breedId == nil else {
            return
        }

        logger.info("Migrating breed name '\(breedName)' to breedId")

        // Fetch breeds and find matching breed
        await BreedService.shared.fetchBreeds()

        if let matchedBreed = BreedService.shared.findBreed(named: breedName) {
            updateBreedId(matchedBreed.id)
            logger.info("Migrated breed '\(breedName)' to breedId \(matchedBreed.id)")
        } else {
            logger.warning("Could not find breed match for '\(breedName)'")
        }
    }

    /// Force sync with CloudKit
    func forceSync() async {
        await initialSync()
    }

    /// Reset profile (for testing or re-onboarding)
    func resetProfile() {
        // Delete active profile from Core Data
        if let id = activeProfileId,
           let existing = CDPuppyProfile.fetch(byId: id, in: viewContext) {
            viewContext.delete(existing)
            do {
                try persistenceController.save()
            } catch {
                logger.error("Failed to save after profile reset: \(error.localizedDescription)")
            }
        }

        // Remove from local cache and switch to another
        if let id = activeProfileId {
            profiles.removeAll { $0.id == id }
        }
        activeProfileId = profiles.first?.id
    }

    /// Reset all profiles (for testing or full re-onboarding)
    func resetAllProfiles() {
        let allProfiles = CDPuppyProfile.fetchAllProfiles(in: viewContext)
        for profile in allProfiles {
            viewContext.delete(profile)
        }

        do {
            try persistenceController.save()
            profiles = []
            activeProfileId = nil
        } catch {
            logger.error("Failed to reset all profiles: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Create a test profile for UI testing if none exists
    private func createTestProfileIfNeeded() {
        // Check if profile already exists
        if CDPuppyProfile.fetchProfile(in: viewContext) != nil {
            return
        }

        logger.info("Creating test profile for UI testing")

        // Create test profile: "Oliver", 16 weeks old, Golden Retriever
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .weekOfYear, value: -16, to: Date()) ?? Date()
        let homeDate = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) ?? Date()

        var testProfile = PuppyProfile.defaultProfile(
            name: "Oliver",
            birthDate: birthDate,
            homeDate: homeDate,
            size: .medium
        )
        testProfile.breed = "Golden Retriever"

        _ = CDPuppyProfile.create(from: testProfile, in: viewContext)
        try? persistenceController.save()
    }

    /// Load all profiles from both private and shared stores
    private func loadAllProfiles() {
        isLoading = true
        defer { isLoading = false }

        // In UI testing mode, create a test profile if none exists
        if SeedData.isUITesting {
            createTestProfileIfNeeded()
        }

        var allProfiles: [PuppyProfile] = []

        // Load owned profiles from private store
        if let privateStore = persistenceController.getPrivateStore() {
            let ownedCDProfiles = CDPuppyProfile.fetchAllProfiles(in: viewContext, from: privateStore)
            let owned = ownedCDProfiles.compactMap { $0.toPuppyProfile(ownership: .owned) }
            allProfiles.append(contentsOf: owned)
            logger.info("Loaded \(owned.count) owned profile(s) from private store")
        }

        // Load shared profiles from shared store
        if let sharedStore = persistenceController.getSharedStore() {
            let sharedCDProfiles = CDPuppyProfile.fetchAllProfiles(in: viewContext, from: sharedStore)
            let shared = sharedCDProfiles.compactMap { $0.toPuppyProfile(ownership: .shared) }
            allProfiles.append(contentsOf: shared)
            logger.info("Loaded \(shared.count) shared profile(s) from shared store")
        }

        // Fallback: if stores not available, try generic fetch
        if allProfiles.isEmpty {
            let fallbackCDProfiles = CDPuppyProfile.fetchAllProfiles(in: viewContext)
            let fallback = fallbackCDProfiles.compactMap { $0.toPuppyProfile(ownership: .owned) }
            allProfiles.append(contentsOf: fallback)
            if !fallback.isEmpty {
                logger.info("Loaded \(fallback.count) profile(s) from fallback fetch")
            }
        }

        profiles = allProfiles

        // Ensure we have an active profile
        if activeProfileId == nil || !profiles.contains(where: { $0.id == activeProfileId }) {
            activeProfileId = profiles.first?.id
        }

        // Sync active profile to widgets/watch
        if let profile = activeProfile {
            syncToAppGroup()
            WidgetDataProvider.shared.updateProfileName(profile.name)
        }
    }

    // MARK: - Share Acceptance Support

    /// Check if user has an existing profile in their private store
    /// Used to inform user when accepting a share invitation (no longer destructive)
    func hasExistingPrivateProfile() -> Bool {
        guard let privateStore = persistenceController.getPrivateStore() else { return false }
        return CDPuppyProfile.hasProfile(in: viewContext, store: privateStore)
    }

    /// Delete existing profile from private store
    /// Only called for specific user action, not automatically on share acceptance
    @available(*, deprecated, message: "Multi-puppy support means we no longer need to delete profiles on share acceptance")
    func deletePrivateProfile() {
        guard let privateStore = persistenceController.getPrivateStore() else { return }

        CDPuppyProfile.deleteAllProfiles(in: viewContext, from: privateStore)

        do {
            try persistenceController.save()
            loadAllProfiles()
            logger.info("Deleted all profiles from private store")
        } catch {
            logger.error("Failed to delete private profile: \(error.localizedDescription)")
        }
    }

    // MARK: - App Group Sync

    /// Syncs the active profile to App Group for use by App Intents and Widgets
    /// Called automatically after any profile save or switch
    private func syncToAppGroup() {
        guard let profile = activeProfile else { return }

        let sharedProfile = SharedProfile(from: profile)
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupSuiteName) else {
            logger.warning("App Group UserDefaults unavailable - widget sync skipped")
            return
        }

        do {
            let data = try JSONEncoder().encode(sharedProfile)
            sharedDefaults.set(data, forKey: IntentDataStore.profileKey)

            // Also sync the active profile ID for widgets
            sharedDefaults.set(profile.id.uuidString, forKey: "activeProfileId")
        } catch {
            logger.error("Failed to encode profile for App Group sync: \(error.localizedDescription)")
        }
    }

    /// Force sync the current profile to App Group
    /// Call this if profile was loaded from elsewhere and needs to be shared
    func forceAppGroupSync() {
        syncToAppGroup()
    }

    // MARK: - Subscription Limits

    /// Check if user can add more owned profiles based on subscription
    func canAddOwnedProfile() -> Bool {
        let maxProfiles = SubscriptionManager.shared.effectiveStatus.hasOtisPlus ? maxOtisProfiles : maxFreeProfiles
        return ownedProfileCount < maxProfiles
    }

    /// Get the CDPuppyProfile for the active profile (used for profile-scoped event queries)
    func getActiveCDProfile() -> CDPuppyProfile? {
        guard let id = activeProfileId else { return nil }
        return CDPuppyProfile.fetch(byId: id, in: viewContext)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the active profile changes
    static let activeProfileChanged = Notification.Name("activeProfileChanged")
}

// MARK: - Profile Limits

/// Maximum owned profiles for free users
let maxFreeProfiles = 1

/// Maximum owned profiles for Otis+ subscribers
let maxOtisProfiles = 5
