//
//  SocializationItem.swift
//  Ollie-app
//
//  Models for socialization checklist feature

import Foundation

// MARK: - Socialization Category

/// A category of socialization items (e.g., "Mensen", "Dieren")
struct SocializationCategory: Identifiable, Codable {
    let id: String              // "mensen", "dieren", etc.
    let name: String            // Display name (localized key)
    let icon: String            // SF Symbol name, e.g. "person.2.fill"
    let items: [SocializationItem]

    /// Localized display name
    var localizedName: String {
        // Return the name as-is since seed data will contain localized strings
        name
    }
}

// MARK: - Socialization Item

/// A single socialization item to expose the puppy to
struct SocializationItem: Identifiable, Codable {
    let id: String              // "kind-0-5"
    let name: String            // "Kind (0-5 jaar)"
    let description: String?    // Tip text
    let targetExposures: Int    // Goal count (default: 3)
    let isWalkable: Bool        // Can encounter during walks

    /// Default target if not specified in seed data
    static let defaultTargetExposures = 3
}

// MARK: - Exposure

/// A single exposure to a socialization item
struct Exposure: Identifiable, Codable, Equatable {
    let id: UUID
    let itemId: String          // Reference to SocializationItem.id
    let date: Date
    let distance: ExposureDistance
    let reaction: SocializationReaction
    let note: String?

    // MARK: - Timestamps for sync
    var createdAt: Date
    var modifiedAt: Date

    init(
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

    enum CodingKeys: String, CodingKey {
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
enum ExposureDistance: String, Codable, CaseIterable, Identifiable {
    case far = "ver"
    case near = "dichtbij"
    case direct = "direct"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .far: return "eye"
        case .near: return "figure.stand"
        case .direct: return "hand.raised.fill"
        }
    }

    var label: String {
        switch self {
        case .far: return Strings.Socialization.distanceFar
        case .near: return Strings.Socialization.distanceNear
        case .direct: return Strings.Socialization.distanceDirect
        }
    }

    var description: String {
        switch self {
        case .far: return Strings.Socialization.distanceFarDescription
        case .near: return Strings.Socialization.distanceNearDescription
        case .direct: return Strings.Socialization.distanceDirectDescription
        }
    }
}

// MARK: - Socialization Reaction

/// The puppy's reaction to the stimulus
enum SocializationReaction: String, Codable, CaseIterable, Identifiable {
    case positief = "positief"
    case neutraal = "neutraal"   // THIS IS THE GOAL
    case onzeker = "onzeker"
    case angstig = "angstig"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .positief: return "heart.fill"
        case .neutraal: return "checkmark.circle.fill"
        case .onzeker: return "questionmark.circle.fill"
        case .angstig: return "exclamationmark.triangle.fill"
        }
    }

    var label: String {
        switch self {
        case .positief: return Strings.Socialization.reactionPositive
        case .neutraal: return Strings.Socialization.reactionNeutral
        case .onzeker: return Strings.Socialization.reactionUnsure
        case .angstig: return Strings.Socialization.reactionFearful
        }
    }

    var description: String {
        switch self {
        case .positief: return Strings.Socialization.reactionPositiveDescription
        case .neutraal: return Strings.Socialization.reactionNeutralDescription
        case .onzeker: return Strings.Socialization.reactionUnsureDescription
        case .angstig: return Strings.Socialization.reactionFearfulDescription
        }
    }

    /// Whether this reaction is considered positive progress
    var isPositive: Bool {
        self == .positief || self == .neutraal
    }

    /// Whether this reaction should trigger fear protocol tips
    var needsFearProtocol: Bool {
        self == .onzeker || self == .angstig
    }
}

// MARK: - Socialization Window Status

/// Status of the socialization window based on puppy age
enum SocializationWindowStatus {
    case peak           // < 10 weeks - critical period
    case open           // 10-14 weeks - still good
    case closing        // 14-16 weeks - urgency
    case justClosed     // 16-20 weeks - can still work on it
    case closed         // > 20 weeks - focus on maintenance

    init(ageInWeeks: Int) {
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

    var color: String {
        switch self {
        case .peak: return "green"
        case .open: return "blue"
        case .closing: return "orange"
        case .justClosed: return "yellow"
        case .closed: return "gray"
        }
    }

    var message: String {
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

    var showBanner: Bool {
        self != .closed
    }
}
