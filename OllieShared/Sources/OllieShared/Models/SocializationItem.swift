//
//  SocializationItem.swift
//  OllieShared
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

// MARK: - Socialization Window Status

/// Status of the socialization window based on puppy age
public enum SocializationWindowStatus: Sendable {
    case peak
    case open
    case closing
    case justClosed
    case closed

    public init(ageInWeeks: Int) {
        switch ageInWeeks {
        case ..<10:
            self = .peak
        case 10..<14:
            self = .open
        case 14..<16:
            self = .closing
        case 16..<20:
            self = .justClosed
        default:
            self = .closed
        }
    }

    public var color: String {
        switch self {
        case .peak: return "green"
        case .open: return "blue"
        case .closing: return "orange"
        case .justClosed: return "yellow"
        case .closed: return "gray"
        }
    }

    public var message: String {
        switch self {
        case .peak:
            return Strings.Socialization.windowPeak
        case .open:
            return Strings.Socialization.windowOpen
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
