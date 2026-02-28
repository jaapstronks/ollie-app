//
//  Achievement.swift
//  OllieShared
//
//  Achievement model for the milestone celebrations system
//  Represents unlocked achievements with tiered celebration levels

import Foundation

// MARK: - Celebration Tier

/// Tier levels determine how prominently an achievement is celebrated
public enum CelebrationTier: Int, Codable, Sendable, Comparable {
    /// Tier 1: Inline shimmer, no interruption
    case subtle = 1
    /// Tier 2: Card slide-up with confetti
    case notable = 2
    /// Tier 3: Full-screen celebration
    case major = 3

    public static func < (lhs: CelebrationTier, rhs: CelebrationTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Display name for settings
    public var displayName: String {
        switch self {
        case .subtle: return String(localized: "Subtle")
        case .notable: return String(localized: "Notable")
        case .major: return String(localized: "Major")
        }
    }

    /// Description for settings
    public var description: String {
        switch self {
        case .subtle: return String(localized: "Inline shimmer effect")
        case .notable: return String(localized: "Card with confetti")
        case .major: return String(localized: "Full-screen celebration")
        }
    }
}

// MARK: - Achievement Category

/// Categories for organizing achievements
public enum AchievementCategory: String, Codable, CaseIterable, Sendable {
    case pottyStreak
    case training
    case socialization
    case health
    case lifestyle
    case timeBased

    /// SF Symbol icon for the category
    public var icon: String {
        switch self {
        case .pottyStreak: return "flame.fill"
        case .training: return "graduationcap.fill"
        case .socialization: return "person.3.fill"
        case .health: return "heart.fill"
        case .lifestyle: return "pawprint.fill"
        case .timeBased: return "calendar.badge.clock"
        }
    }

    /// Display name
    public var displayName: String {
        switch self {
        case .pottyStreak: return String(localized: "Potty Training")
        case .training: return String(localized: "Training")
        case .socialization: return String(localized: "Socialization")
        case .health: return String(localized: "Health")
        case .lifestyle: return String(localized: "Lifestyle")
        case .timeBased: return String(localized: "Milestones")
        }
    }
}

// MARK: - Achievement

/// Represents a single achievement that can be unlocked
public struct Achievement: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let category: AchievementCategory
    public let tier: CelebrationTier
    public let labelKey: String
    public let descriptionKey: String?
    public let value: Int?  // e.g., "7" for 7-day streak
    public let milestoneId: UUID?  // Link to milestone if applicable

    public init(
        id: String,
        category: AchievementCategory,
        tier: CelebrationTier,
        labelKey: String,
        descriptionKey: String? = nil,
        value: Int? = nil,
        milestoneId: UUID? = nil
    ) {
        self.id = id
        self.category = category
        self.tier = tier
        self.labelKey = labelKey
        self.descriptionKey = descriptionKey
        self.value = value
        self.milestoneId = milestoneId
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Achievement Label Resolution

extension Achievement {

    /// Resolve the label key to a localized string
    public var localizedLabel: String {
        AchievementLabelResolver.resolve(labelKey, value: value)
    }

    /// Resolve the description key to a localized string
    public var localizedDescription: String? {
        guard let key = descriptionKey else { return nil }
        return AchievementLabelResolver.resolve(key, value: value)
    }

    /// Short celebration message
    public var celebrationMessage: String {
        AchievementLabelResolver.celebrationMessage(for: labelKey, value: value)
    }
}

/// Resolves achievement label keys to localized strings
public enum AchievementLabelResolver {

    public static func resolve(_ key: String, value: Int? = nil) -> String {
        switch key {
        // Potty achievements
        case "achievement.pottyStreak.3":
            return String(localized: "3-Day Outdoor Streak")
        case "achievement.pottyStreak.7":
            return String(localized: "7-Day Outdoor Streak")
        case "achievement.pottyStreak.14":
            return String(localized: "Potty Trained!")
        case "achievement.pottyStreak.record":
            if let days = value {
                return String(localized: "\(days)-Day Record!")
            }
            return String(localized: "New Streak Record!")

        // Training achievements
        case "achievement.training.firstCommand":
            return String(localized: "First Command Learned")
        case "achievement.training.5commands":
            return String(localized: "5 Commands Mastered")
        case "achievement.training.10commands":
            return String(localized: "Star Pupil!")

        // Socialization achievements
        case "achievement.social.firstDog":
            return String(localized: "First Dog Met")
        case "achievement.social.10dogs":
            return String(localized: "10 Dogs Met")
        case "achievement.social.categoryComplete":
            return String(localized: "Category Complete!")
        case "achievement.social.windowComplete":
            return String(localized: "Socialization Champion!")

        // Health achievements
        case "achievement.health.firstVaccination":
            return String(localized: "First Vaccination")
        case "achievement.health.allVaccinations":
            return String(localized: "Fully Vaccinated!")
        case "achievement.health.firstVetVisit":
            return String(localized: "First Vet Visit")

        // Lifestyle achievements
        case "achievement.lifestyle.firstWalk":
            return String(localized: "First Walk")
        case "achievement.lifestyle.50walks":
            return String(localized: "50 Walks Logged!")
        case "achievement.lifestyle.100walks":
            return String(localized: "100 Walks!")

        // Time-based achievements
        case "achievement.time.monthlyBirthday":
            if let months = value {
                return String(localized: "\(months) Months Old!")
            }
            return String(localized: "Monthly Birthday!")
        case "achievement.time.firstYear":
            return String(localized: "Happy 1st Birthday!")
        case "achievement.time.gotchaDay":
            return String(localized: "Gotcha Day Anniversary!")

        // Milestone completions (generic)
        case "achievement.milestone.health":
            return String(localized: "Health Milestone Complete")
        case "achievement.milestone.developmental":
            return String(localized: "Developmental Milestone")
        case "achievement.milestone.administrative":
            return String(localized: "Administrative Task Done")
        case "achievement.milestone.custom":
            return String(localized: "Custom Milestone Complete")

        default:
            return key
        }
    }

    public static func celebrationMessage(for key: String, value: Int? = nil) -> String {
        switch key {
        case "achievement.pottyStreak.7":
            return String(localized: "Amazing consistency!")
        case "achievement.pottyStreak.14":
            return String(localized: "You did it!")
        case "achievement.pottyStreak.record":
            if let days = value {
                return String(localized: "\(days) days - new personal best!")
            }
            return String(localized: "New personal best!")
        case "achievement.health.allVaccinations":
            return String(localized: "Protected and ready to explore!")
        case "achievement.time.firstYear":
            return String(localized: "What an incredible year!")
        default:
            return String(localized: "Keep up the great work!")
        }
    }
}

// MARK: - Achievement Factory

/// Factory methods for creating common achievements
extension Achievement {

    /// Create a health milestone achievement
    public static func healthMilestone(
        milestoneId: UUID,
        label: String,
        isVaccination: Bool = false
    ) -> Achievement {
        Achievement(
            id: "milestone.health.\(milestoneId.uuidString)",
            category: .health,
            tier: isVaccination ? .notable : .subtle,
            labelKey: "achievement.milestone.health",
            milestoneId: milestoneId
        )
    }

    /// Create a potty streak achievement
    public static func pottyStreak(days: Int, isRecord: Bool) -> Achievement {
        let tier: CelebrationTier
        let labelKey: String

        if days >= 14 {
            tier = .major
            labelKey = "achievement.pottyStreak.14"
        } else if days >= 7 || isRecord {
            tier = .notable
            labelKey = isRecord ? "achievement.pottyStreak.record" : "achievement.pottyStreak.7"
        } else {
            tier = .subtle
            labelKey = "achievement.pottyStreak.3"
        }

        return Achievement(
            id: "potty.streak.\(days)",
            category: .pottyStreak,
            tier: tier,
            labelKey: labelKey,
            value: days
        )
    }

    /// Create a monthly birthday achievement
    public static func monthlyBirthday(months: Int) -> Achievement {
        Achievement(
            id: "birthday.month.\(months)",
            category: .timeBased,
            tier: months == 12 ? .major : .notable,
            labelKey: months == 12 ? "achievement.time.firstYear" : "achievement.time.monthlyBirthday",
            value: months
        )
    }
}
