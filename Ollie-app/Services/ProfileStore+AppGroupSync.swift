//
//  ProfileStore+AppGroupSync.swift
//  Otis-app
//
//  App Group sync for widgets and App Intents.
//

import Foundation
import OtisShared
import os

// MARK: - App Group Sync

extension ProfileStore {

    /// App Group suite name for sharing with Intents/Widgets
    static let appGroupSuiteName = Constants.appGroupIdentifier

    /// Syncs the active profile to App Group for use by App Intents and Widgets
    /// Called automatically after any profile save or switch
    func syncToAppGroup() {
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
}
