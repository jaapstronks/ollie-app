//
//  Strings+Household.swift
//  Otis-app
//
//  User profile and household strings
//

import Foundation

private let table = "Household"

extension Strings {

    // MARK: - User Profile (CloudKit-based identity)
    enum UserProfile {
        static let title = String(localized: "Your Profile", table: table)
        static let me = String(localized: "Me", table: table)
        static let name = String(localized: "Name", table: table)
        static let color = String(localized: "Avatar color", table: table)
        static let colorHint = String(localized: "Used when no photo is set.", table: table)
        static let namePlaceholder = String(localized: "Your name", table: table)
        static let settingsDescription = String(localized: "How you appear in shared data", table: table)

        // Photo
        static let addPhoto = String(localized: "Add photo", table: table)
        static let changePhoto = String(localized: "Change photo", table: table)
        static let removePhoto = String(localized: "Remove photo", table: table)

        // iCloud identity
        static let iCloudIdentity = String(localized: "iCloud Identity", table: table)
        static let iCloudIdentityDescription = String(localized: "Your identity is linked to your iCloud account.", table: table)
        static let notSignedIn = String(localized: "Not signed into iCloud", table: table)

        // Unknown user (for attribution display)
        static let unknownUser = String(localized: "Unknown", table: table)

        // Setup prompts (onboarding and share acceptance)
        static let setupTitle = String(localized: "Introduce yourself", table: table)
        static let setupSubtitle = String(localized: "This helps identify who logged what when sharing with family.", table: table)
        static let setupLater = String(localized: "Set up later", table: table)
    }

    // MARK: - Household Members (Legacy - kept for backwards compatibility)
    enum Household {
        // General
        static let title = String(localized: "Household", table: table)
        static let me = String(localized: "Me", table: table)

        // Settings
        static let settingsFooter = String(localized: "Track who logs each event when sharing with family.", table: table)

        // List view
        static let noMembers = String(localized: "No household members", table: table)
        static let noMembersHint = String(localized: "Add family members who help care for your puppy.", table: table)
        static let addMember = String(localized: "Add member", table: table)
        static let editMember = String(localized: "Edit member", table: table)
        static let footerHint = String(localized: "Swipe left on a member to edit or delete.", table: table)

        // Form fields
        static let name = String(localized: "Name", table: table)
        static let color = String(localized: "Avatar color", table: table)
        static let colorHint = String(localized: "Used when no photo is set.", table: table)
        static let thisIsMe = String(localized: "This is me", table: table)
        static let thisIsMeHint = String(localized: "Events you log will be attributed to this member.", table: table)

        // Photo
        static let addPhoto = String(localized: "Add photo", table: table)
        static let changePhoto = String(localized: "Change photo", table: table)
        static let removePhoto = String(localized: "Remove photo", table: table)

        // Delete confirmation
        static let deleteConfirmTitle = String(localized: "Delete member?", table: table)
        static let deleteConfirmMessage = String(localized: "This member will be removed. Events they logged will keep their attribution.", table: table)
    }
}
