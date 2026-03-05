//
//  ProfileStore+HouseholdMembers.swift
//  Otis-app
//
//  Household member management extension for ProfileStore
//

import Foundation
import os
import OtisShared

extension ProfileStore {

    // MARK: - Household Members

    /// Get all household members for the active profile
    func householdMembers() -> [HouseholdMember] {
        activeProfile?.householdMembers.members ?? []
    }

    /// Get the current user's household member
    func currentUserMember() -> HouseholdMember? {
        activeProfile?.householdMembers.currentUser()
    }

    /// Add a new household member
    func addHouseholdMember(_ member: HouseholdMember) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.householdMembers.add(member)
        saveProfile(currentProfile)
    }

    /// Update an existing household member
    func updateHouseholdMember(_ member: HouseholdMember) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.householdMembers.update(member)
        saveProfile(currentProfile)
    }

    /// Delete a household member by ID
    func deleteHouseholdMember(id: UUID) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.householdMembers.delete(id: id)
        saveProfile(currentProfile)
    }

    /// Set which member is the current user
    func setCurrentUserMember(id: UUID) {
        guard var currentProfile = activeProfile else { return }
        currentProfile.householdMembers.setCurrentUser(id: id)
        saveProfile(currentProfile)
    }

    /// Ensure a "Me" member exists for the current user
    /// Called on first launch or when household is empty
    func ensureCurrentUserExists() {
        guard var currentProfile = activeProfile else { return }

        // Check if we already have a current user
        if currentProfile.householdMembers.currentUser() != nil {
            return
        }

        // Create a default "Me" member
        let meMember = HouseholdMember(
            name: Strings.Household.me,
            isCurrentUser: true
        )
        currentProfile.householdMembers.add(meMember)
        saveProfile(currentProfile)

        logger.info("Created default 'Me' household member")
    }

    /// Find household member by ID
    func householdMember(byId id: UUID) -> HouseholdMember? {
        activeProfile?.householdMembers.member(byId: id)
    }

    // MARK: - Partner Activity Handoff State

    /// Key for storing last seen partner activity timestamp
    private static let lastSeenPartnerActivityKey = "lastSeenPartnerActivityTimestamp"

    /// Get the timestamp when user last dismissed partner activity card
    var lastSeenPartnerActivityTimestamp: Date? {
        get {
            guard let profileId = activeProfile?.id else { return nil }
            let key = "\(Self.lastSeenPartnerActivityKey)_\(profileId.uuidString)"
            let timestamp = UserDefaults.standard.double(forKey: key)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            guard let profileId = activeProfile?.id else { return }
            let key = "\(Self.lastSeenPartnerActivityKey)_\(profileId.uuidString)"
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// Mark partner activity as seen (dismisses the handoff card)
    func markPartnerActivitySeen() {
        lastSeenPartnerActivityTimestamp = Date()
        logger.debug("Partner activity marked as seen")
    }
}
