//
//  Strings+Profile.swift
//  Otis-app
//
//  Profile picker and multi-puppy related strings

import Foundation

private let table = "Profile"

extension Strings {

    // MARK: - Profile Picker

    enum Profile {
        static let yourDogs = String(localized: "Your Dogs", table: table)
        static let addDog = String(localized: "Add Dog", table: table)
        static let switchProfile = String(localized: "Switch Dog", table: table)

        // Ownership badges
        static let owner = String(localized: "Owner", table: table)
        static func sharedBy(_ name: String) -> String {
            String(localized: "Shared by \(name)", table: table)
        }
        static let shared = String(localized: "Shared", table: table)

        // Profile actions
        static let manageProfiles = String(localized: "Manage Dogs", table: table)
        static let leaveProfile = String(localized: "Leave", table: table)
        static let deleteProfile = String(localized: "Delete", table: table)

        // Confirmations
        static let deleteConfirmTitle = String(localized: "Delete Profile?", table: table)
        static func deleteConfirmMessage(_ name: String) -> String {
            String(localized: "This will permanently delete all data for \(name). This action cannot be undone.", table: table)
        }

        static let leaveConfirmTitle = String(localized: "Leave Shared Profile?", table: table)
        static func leaveConfirmMessage(_ name: String) -> String {
            String(localized: "You will no longer have access to \(name)'s data. You can be invited again later.", table: table)
        }

        // Profile limits
        static func profileLimit(_ count: Int, max: Int) -> String {
            String(localized: "\(count)/\(max) dogs", table: table)
        }
        static let upgradeForMoreDogs = String(localized: "Upgrade to Otis+ to add more dogs", table: table)
        static let atProfileLimit = String(localized: "You've reached your profile limit", table: table)

        // Profile switching
        static func switchingTo(_ name: String) -> String {
            String(localized: "Switching to \(name)...", table: table)
        }

        // Empty state
        static let noProfiles = String(localized: "No profiles yet", table: table)
        static let createFirstProfile = String(localized: "Create your first puppy profile to get started", table: table)

        // Accessibility
        static let activeProfile = String(localized: "Active profile", table: table)
        static func profileSelected(_ name: String) -> String {
            String(localized: "\(name), selected", table: table)
        }

        // MARK: - Profile Photo (used by existing views)

        static let addPhoto = String(localized: "Add photo", table: table)
        static let changePhoto = String(localized: "Change photo", table: table)
        static let removePhoto = String(localized: "Remove photo", table: table)
        static let photoTitle = String(localized: "Profile Photo", table: table)
        static let adjustPhoto = String(localized: "Adjust Photo", table: table)
        static let cropHint = String(localized: "Pinch to zoom, drag to position", table: table)
    }
}
