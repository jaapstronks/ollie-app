//
//  HouseholdMember.swift
//  OtisShared
//
//  Household member model for event attribution in shared households
//

import Foundation

/// A member of the household who logs events for a puppy
public struct HouseholdMember: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var avatarData: Data?              // Small profile image (compressed)
    public var colorHex: String               // Fallback avatar color (e.g., "#FF6B6B")
    public var cloudKitUserRecordID: String?  // For auto-detection when sharing
    public var isCurrentUser: Bool
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        avatarData: Data? = nil,
        colorHex: String = HouseholdMember.randomColor(),
        cloudKitUserRecordID: String? = nil,
        isCurrentUser: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.avatarData = avatarData
        self.colorHex = colorHex
        self.cloudKitUserRecordID = cloudKitUserRecordID
        self.isCurrentUser = isCurrentUser
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
    }

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> HouseholdMember {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }

    /// First initial for avatar fallback display
    public var initial: String {
        String(name.prefix(1)).uppercased()
    }

    // MARK: - Predefined Colors

    /// Available colors for member avatars
    public static let availableColors: [String] = [
        "#FF6B6B",  // Coral red
        "#4ECDC4",  // Teal
        "#45B7D1",  // Sky blue
        "#96CEB4",  // Sage green
        "#FFEAA7",  // Soft yellow
        "#DDA0DD",  // Plum
        "#FF8C42",  // Orange
        "#98D8C8",  // Mint
        "#F7DC6F",  // Gold
        "#BB8FCE",  // Lavender
        "#85C1E9",  // Light blue
        "#F8B500",  // Amber
    ]

    /// Returns a random color from the available colors
    public static func randomColor() -> String {
        availableColors.randomElement() ?? "#4ECDC4"
    }

    // MARK: - Coding Keys

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarData = "avatar_data"
        case colorHex = "color_hex"
        case cloudKitUserRecordID = "cloudkit_user_record_id"
        case isCurrentUser = "is_current_user"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
}

// MARK: - HouseholdMembers Container

/// Container for household members stored in a profile
public struct HouseholdMembers: Codable, Sendable {
    public var members: [HouseholdMember]

    public init(members: [HouseholdMember] = []) {
        self.members = members
    }

    /// Returns an empty household members container
    public static func empty() -> HouseholdMembers {
        HouseholdMembers(members: [])
    }

    /// Find a member by ID
    public func member(byId id: UUID) -> HouseholdMember? {
        members.first { $0.id == id }
    }

    /// Find a member by CloudKit user record ID
    public func member(byCloudKitUserRecordID recordID: String) -> HouseholdMember? {
        members.first { $0.cloudKitUserRecordID == recordID }
    }

    /// Get the current user's member
    public func currentUser() -> HouseholdMember? {
        members.first { $0.isCurrentUser }
    }

    /// Check if any member exists with the given CloudKit user record ID
    public func hasCloudKitMember(_ recordID: String) -> Bool {
        members.contains { $0.cloudKitUserRecordID == recordID }
    }
}

// MARK: - Mutation Helpers

extension HouseholdMembers {

    /// Add a new member
    public mutating func add(_ member: HouseholdMember) {
        // If new member is current user, clear flag on others
        if member.isCurrentUser {
            for i in members.indices {
                members[i].isCurrentUser = false
            }
        }
        members.append(member)
    }

    /// Update an existing member
    public mutating func update(_ member: HouseholdMember) {
        // If updated member is now current user, clear flag on others
        if member.isCurrentUser {
            for i in members.indices where members[i].id != member.id {
                members[i].isCurrentUser = false
            }
        }

        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member.withUpdatedTimestamp()
        }
    }

    /// Delete a member by ID
    public mutating func delete(id: UUID) {
        members.removeAll { $0.id == id }
    }

    /// Set which member is the current user
    public mutating func setCurrentUser(id: UUID) {
        for i in members.indices {
            members[i].isCurrentUser = (members[i].id == id)
        }
    }
}
