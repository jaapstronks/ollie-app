//
//  SocializationItem.swift
//  OtisShared
//

import Foundation

// MARK: - Socialization Category

/// A category of socialization items
public struct SocializationCategory: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    public let items: [SocializationItem]

    public init(id: String, name: String, icon: String, items: [SocializationItem]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.items = items
    }

    public var localizedName: String {
        name
    }
}

// MARK: - Socialization Item

/// A single socialization item to expose the puppy to
public struct SocializationItem: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let targetExposures: Int
    public let isWalkable: Bool
    public let priority: Int

    public static let defaultTargetExposures = 3
    public static let defaultPriority = 1

    public init(
        id: String,
        name: String,
        description: String? = nil,
        targetExposures: Int = defaultTargetExposures,
        isWalkable: Bool = false,
        priority: Int = defaultPriority
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.targetExposures = targetExposures
        self.isWalkable = isWalkable
        self.priority = priority
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        targetExposures = try container.decodeIfPresent(Int.self, forKey: .targetExposures) ?? Self.defaultTargetExposures
        isWalkable = try container.decodeIfPresent(Bool.self, forKey: .isWalkable) ?? false
        priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? Self.defaultPriority
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, targetExposures, isWalkable, priority
    }
}

// MARK: - Exposure

/// A single exposure to a socialization item
public struct Exposure: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let itemId: String
    public let date: Date
    public let distance: ExposureDistance
    public let reaction: SocializationReaction
    public let note: String?
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        itemId: String,
        date: Date = Date(),
        distance: ExposureDistance,
        reaction: SocializationReaction,
        note: String? = nil,
        createdAt: Date? = nil,
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.itemId = itemId
        self.date = date
        self.distance = distance
        self.reaction = reaction
        self.note = note

        let now = Date()
        self.createdAt = createdAt ?? now
        self.modifiedAt = modifiedAt ?? now
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case date
        case distance
        case reaction
        case note
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
}

// MARK: - Exposure Distance

/// How close the puppy was to the stimulus
public enum ExposureDistance: String, Codable, CaseIterable, Identifiable, Sendable {
    case far = "ver"
    case near = "dichtbij"
    case direct = "direct"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .far: return "eye"
        case .near: return "figure.stand"
        case .direct: return "hand.raised.fill"
        }
    }

    public var label: String {
        switch self {
        case .far: return Strings.Socialization.distanceFar
        case .near: return Strings.Socialization.distanceNear
        case .direct: return Strings.Socialization.distanceDirect
        }
    }

    public var description: String {
        switch self {
        case .far: return Strings.Socialization.distanceFarDescription
        case .near: return Strings.Socialization.distanceNearDescription
        case .direct: return Strings.Socialization.distanceDirectDescription
        }
    }
}

// MARK: - Socialization Reaction

/// The puppy's reaction to the stimulus
public enum SocializationReaction: String, Codable, CaseIterable, Identifiable, Sendable {
    case positief = "positief"
    case neutraal = "neutraal"
    case onzeker = "onzeker"
    case angstig = "angstig"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .positief: return "heart.fill"
        case .neutraal: return "checkmark.circle.fill"
        case .onzeker: return "questionmark.circle.fill"
        case .angstig: return "exclamationmark.triangle.fill"
        }
    }

    public var label: String {
        switch self {
        case .positief: return Strings.Socialization.reactionPositive
        case .neutraal: return Strings.Socialization.reactionNeutral
        case .onzeker: return Strings.Socialization.reactionUnsure
        case .angstig: return Strings.Socialization.reactionFearful
        }
    }

    public var description: String {
        switch self {
        case .positief: return Strings.Socialization.reactionPositiveDescription
        case .neutraal: return Strings.Socialization.reactionNeutralDescription
        case .onzeker: return Strings.Socialization.reactionUnsureDescription
        case .angstig: return Strings.Socialization.reactionFearfulDescription
        }
    }

    public var isPositive: Bool {
        self == .positief || self == .neutraal
    }

    public var needsFearProtocol: Bool {
        self == .onzeker || self == .angstig
    }
}

// MARK: - Socialization Phase

/// The current phase of socialization based on days home and age
public enum SocializationPhase: String, Codable, CaseIterable, Identifiable, Sendable {
    case settlingIn = "settling_in"
    case firstSteps = "first_steps"
    case buildingConfidence = "building_confidence"
    case peakWindow = "peak_window"
    case maintenance = "maintenance"

    public var id: String { rawValue }

    /// Determines the current phase based on days home and age in weeks
    public static func current(daysHome: Int, ageInWeeks: Int) -> SocializationPhase {
        // Maintenance if past socialization window
        if ageInWeeks >= 16 {
            return .maintenance
        }

        // Phase based on days home
        if daysHome <= 3 {
            return .settlingIn
        } else if daysHome <= 14 {
            return .firstSteps
        } else if daysHome <= 42 {  // ~6 weeks
            return .buildingConfidence
        } else {
            return .peakWindow
        }
    }

    public var icon: String {
        switch self {
        case .settlingIn: return "house.fill"
        case .firstSteps: return "pawprint.fill"
        case .buildingConfidence: return "figure.walk"
        case .peakWindow: return "star.fill"
        case .maintenance: return "checkmark.seal.fill"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .settlingIn: return 0
        case .firstSteps: return 1
        case .buildingConfidence: return 2
        case .peakWindow: return 3
        case .maintenance: return 4
        }
    }
}

// MARK: - Comfortable Item

/// Represents explicit comfort with a socialization item
public struct ComfortableItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let itemId: String
    public let comfortableAt: Date
    public let method: ComfortMethod
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        itemId: String,
        comfortableAt: Date = Date(),
        method: ComfortMethod = .logged,
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.itemId = itemId
        self.comfortableAt = comfortableAt
        self.method = method
        self.modifiedAt = modifiedAt ?? Date()
    }

    public enum ComfortMethod: String, Codable, Sendable {
        case logged = "logged"          // Reached via exposure logging
        case quickCheck = "quick-check" // Quick inventory check-off
    }
}

// MARK: - Early Milestone

/// Represents an early-days milestone achievement
public struct EarlyMilestoneRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let milestoneId: String
    public let achievedAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        milestoneId: String,
        achievedAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.milestoneId = milestoneId
        self.achievedAt = achievedAt
        self.modifiedAt = modifiedAt ?? Date()
    }
}

/// Definition of an early milestone from JSON
public struct EarlyMilestoneDefinition: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    public let autoTrigger: String?

    public init(id: String, name: String, icon: String, autoTrigger: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.autoTrigger = autoTrigger
    }
}

// MARK: - Socialization Window Status

/// Status of the socialization window based on puppy age.
/// This is the SINGLE SOURCE OF TRUTH for all window-related calculations.
///
/// The socialization window has distinct phases based on developmental science:
///
/// - **Secondary socialization (weeks 3-12)**: Peak receptivity period
///   - Brain and learning capacity mature around 8 weeks
///   - Maximum openness to new experiences
///   - Puppies most willing to approach strangers
///
/// - **Fear window closing (weeks 12-16)**: Transition period
///   - Natural survival mechanism: "If I haven't seen it before, I should be afraid"
///   - Puppies become increasingly hesitant with new experiences
///   - Socialization still possible but requires more patience
///
/// - **Window closed (16+ weeks)**: Post-window period
///   - Adaptation to new experiences becomes significantly harder
///   - Continued exposure still valuable but different approach needed
///
/// Note: There are two related tracking concepts:
/// - **Developmental window** (weeks 3-16): Full critical period
/// - **Active tracking window** (weeks 8-16): When puppy is typically home
///   (See `SocializationWindow` in WeeklyProgress.swift for the tracking window)
public enum SocializationWindowStatus: Sendable {
    /// Secondary socialization: Maximum receptivity (weeks 3-12)
    case peak
    /// Fear window closing: Still possible but increasingly hesitant (weeks 12-16)
    case closing
    /// Recently closed: Encourage continued exposure (weeks 16-20)
    case justClosed
    /// Well past window: Different approach needed (20+ weeks)
    case closed

    // MARK: - Constants

    /// First week of the critical socialization window (developmental perspective)
    public static let windowStartWeek = 3

    /// Last week of the critical socialization window
    public static let windowEndWeek = 16

    /// End of peak receptivity / start of fear window closing
    public static let peakEndWeek = 12

    // MARK: - Initialization

    public init(ageInWeeks: Int) {
        switch ageInWeeks {
        case ..<Self.peakEndWeek:
            self = .peak
        case Self.peakEndWeek..<Self.windowEndWeek:
            self = .closing
        case Self.windowEndWeek..<20:
            self = .justClosed
        default:
            self = .closed
        }
    }

    // MARK: - Window State Properties

    /// Whether the socialization window is currently open (peak or closing)
    public var isOpen: Bool {
        switch self {
        case .peak, .closing: return true
        case .justClosed, .closed: return false
        }
    }

    /// Whether we're in the peak receptivity period (before week 12)
    public var isPeak: Bool {
        self == .peak
    }

    /// Weeks remaining in the window for a given age
    public static func weeksRemaining(ageInWeeks: Int) -> Int? {
        guard ageInWeeks >= windowStartWeek && ageInWeeks <= windowEndWeek else {
            return nil
        }
        return windowEndWeek - ageInWeeks
    }

    /// Progress through the window (0.0 = start, 1.0 = end) for a given age
    public static func progressPercentage(ageInWeeks: Int) -> Double {
        if ageInWeeks < windowStartWeek { return 0.0 }
        if ageInWeeks > windowEndWeek { return 1.0 }
        let windowDuration = windowEndWeek - windowStartWeek
        return Double(ageInWeeks - windowStartWeek) / Double(windowDuration)
    }

    // MARK: - Display Properties

    public var color: String {
        switch self {
        case .peak: return "green"
        case .closing: return "orange"
        case .justClosed: return "yellow"
        case .closed: return "gray"
        }
    }

    public var message: String {
        switch self {
        case .peak:
            return Strings.Socialization.windowPeak
        case .closing:
            return Strings.Socialization.windowClosing
        case .justClosed:
            return Strings.Socialization.windowJustClosed
        case .closed:
            return Strings.Socialization.windowClosed
        }
    }

    public var showBanner: Bool {
        self != .closed
    }
}
