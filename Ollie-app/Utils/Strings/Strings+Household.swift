//
//  Strings+Household.swift
//  Otis-app
//
//  Household members strings
//

import Foundation

private let table = "Household"

extension Strings {

    // MARK: - Household Members
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
