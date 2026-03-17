//
//  UserIdentity.swift
//  OtisShared
//
//  User identity model for event attribution using CloudKit participant identity.
//  Each iCloud account = one user identity. CloudKit sharing participants are
//  the source of truth for who's in the "family".
//

import Foundation

// MARK: - Responsibility Level

/// How involved this user is in managing the dog's care
/// Affects which nudges and reminders are shown by default
public enum ResponsibilityLevel: String, Codable, CaseIterable, Sendable {
    case caregiver   // Full visibility: appointments, medications, grooming schedules
    case helper      // Daily tasks: walks, feeding, potty, training, photos

    public var label: String {
        switch self {
        case .caregiver: return String(localized: "Caregiver", table: "Settings")
        case .helper: return String(localized: "Helper", table: "Settings")
        }
    }

    public var description: String {
        switch self {
        case .caregiver:
            return String(localized: "Manages vet appointments, medications, and grooming schedules", table: "Settings")
        case .helper:
            return String(localized: "Helps with walks, feeding, potty breaks, and training", table: "Settings")
        }
    }

    public var icon: String {
        switch self {
        case .caregiver: return "person.badge.shield.checkmark.fill"
        case .helper: return "figure.walk"
        }
    }
}

// MARK: - Nudge Categories

/// Categories of nudges/reminders that can be toggled per user
public enum NudgeCategory: String, Codable, CaseIterable, Sendable {
    case dailyCare       // potty, feeding, naps
    case walks           // walk reminders, suggestions
    case training        // skill practice nudges
    case appointments    // vet, groomer upcoming
    case medications     // dose reminders, refills
    case grooming        // home grooming schedule
    case milestones      // celebrations (everyone wants these)

    public var label: String {
        switch self {
        case .dailyCare: return String(localized: "Daily care", table: "Settings")
        case .walks: return String(localized: "Walks", table: "Settings")
        case .training: return String(localized: "Training", table: "Settings")
        case .appointments: return String(localized: "Appointments", table: "Settings")
        case .medications: return String(localized: "Medications", table: "Settings")
        case .grooming: return String(localized: "Grooming", table: "Settings")
        case .milestones: return String(localized: "Milestones", table: "Settings")
        }
    }

    public var description: String {
        switch self {
        case .dailyCare: return String(localized: "Potty breaks, feeding times, nap reminders", table: "Settings")
        case .walks: return String(localized: "Walk suggestions and reminders", table: "Settings")
        case .training: return String(localized: "Skill practice and training tips", table: "Settings")
        case .appointments: return String(localized: "Upcoming vet and groomer visits", table: "Settings")
        case .medications: return String(localized: "Medication doses and refill reminders", table: "Settings")
        case .grooming: return String(localized: "Home grooming schedule", table: "Settings")
        case .milestones: return String(localized: "Celebrations and achievements", table: "Settings")
        }
    }

    public var icon: String {
        switch self {
        case .dailyCare: return "drop.fill"
        case .walks: return "figure.walk"
        case .training: return "star.fill"
        case .appointments: return "calendar"
        case .medications: return "pills.fill"
        case .grooming: return "scissors"
        case .milestones: return "party.popper.fill"
        }
    }
}

extension ResponsibilityLevel {
    /// Default enabled nudge categories for this responsibility level
    public var defaultEnabledNudges: Set<NudgeCategory> {
        switch self {
        case .caregiver:
            return Set(NudgeCategory.allCases)
        case .helper:
            return [.dailyCare, .walks, .training, .milestones]
        }
    }
}

// MARK: - User Identity

/// A user identity representing the current device's user
/// Unlike HouseholdMember, this is tied to a CloudKit user record ID
public struct UserIdentity: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var avatarData: Data?              // Small profile image (compressed)
    public var colorHex: String               // Fallback avatar color (e.g., "#FF6B6B")
    public var cloudKitUserRecordID: String   // Required - the CloudKit user record ID
    public var responsibilityLevel: ResponsibilityLevel
    public var enabledNudges: Set<NudgeCategory>  // User's actual preferences (overrides defaults)
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        avatarData: Data? = nil,
        colorHex: String = UserIdentity.randomColor(),
        cloudKitUserRecordID: String,
        responsibilityLevel: ResponsibilityLevel = .caregiver,
        enabledNudges: Set<NudgeCategory>? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.avatarData = avatarData
        self.colorHex = colorHex
        self.cloudKitUserRecordID = cloudKitUserRecordID
        self.responsibilityLevel = responsibilityLevel
        self.enabledNudges = enabledNudges ?? responsibilityLevel.defaultEnabledNudges
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
    }

    /// Check if a nudge category is enabled for this user
    public func shouldShowNudge(_ category: NudgeCategory) -> Bool {
        enabledNudges.contains(category)
    }

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> UserIdentity {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }

    /// First initial for avatar fallback display
    public var initial: String {
        String(name.prefix(1)).uppercased()
    }

    // MARK: - Predefined Colors

    /// Available colors for user avatars
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
        case responsibilityLevel = "responsibility_level"
        case enabledNudges = "enabled_nudges"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }

    // MARK: - Decoding with Defaults

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatarData = try container.decodeIfPresent(Data.self, forKey: .avatarData)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        cloudKitUserRecordID = try container.decode(String.self, forKey: .cloudKitUserRecordID)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)

        // Decode new fields with defaults for migration
        responsibilityLevel = try container.decodeIfPresent(ResponsibilityLevel.self, forKey: .responsibilityLevel) ?? .caregiver
        enabledNudges = try container.decodeIfPresent(Set<NudgeCategory>.self, forKey: .enabledNudges) ?? responsibilityLevel.defaultEnabledNudges
    }
}

// MARK: - Migration Helper

extension UserIdentity {
    /// Create a UserIdentity from a legacy HouseholdMember
    /// Used for migration when the old HouseholdMember had cloudKitUserRecordID set
    public static func fromHouseholdMember(
        _ member: HouseholdMember,
        cloudKitUserRecordID: String
    ) -> UserIdentity {
        UserIdentity(
            id: member.id,
            name: member.name,
            avatarData: member.avatarData,
            colorHex: member.colorHex,
            cloudKitUserRecordID: cloudKitUserRecordID,
            createdAt: member.createdAt,
            modifiedAt: member.modifiedAt
        )
    }
}
