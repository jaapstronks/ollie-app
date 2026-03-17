//
//  Allergy.swift
//  OtisShared
//
//  Allergy tracking for dogs - quick access to known allergies
//  Part of the health foundation (Brief 03)
//

import Foundation

// MARK: - Allergy Type

/// Types of allergies dogs can have
public enum AllergyType: String, Codable, CaseIterable, Sendable {
    case food
    case environmental
    case medication
    case contact

    public var label: String {
        switch self {
        case .food: return Strings.Allergies.typeFood
        case .environmental: return Strings.Allergies.typeEnvironmental
        case .medication: return Strings.Allergies.typeMedication
        case .contact: return Strings.Allergies.typeContact
        }
    }

    public var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .environmental: return "leaf"
        case .medication: return "pills"
        case .contact: return "hand.raised"
        }
    }
}

// MARK: - Allergy Severity

/// How severe the allergic reaction is
public enum AllergySeverity: String, Codable, CaseIterable, Sendable {
    case mild
    case moderate
    case severe
    case lifeThreatening

    public var label: String {
        switch self {
        case .mild: return Strings.Allergies.severityMild
        case .moderate: return Strings.Allergies.severityModerate
        case .severe: return Strings.Allergies.severitySevere
        case .lifeThreatening: return Strings.Allergies.severityLifeThreatening
        }
    }

    public var colorName: String {
        switch self {
        case .mild: return "otisSuccess"
        case .moderate: return "otisWarning"
        case .severe: return "otisDestructive"
        case .lifeThreatening: return "otisDestructive"
        }
    }

    public var description: String {
        switch self {
        case .mild: return Strings.Allergies.severityMildDesc
        case .moderate: return Strings.Allergies.severityModerateDesc
        case .severe: return Strings.Allergies.severitySevereDesc
        case .lifeThreatening: return Strings.Allergies.severityLifeThreateningDesc
        }
    }
}

// MARK: - Allergy Model

/// A known allergy for a dog
public struct Allergy: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var allergen: String
    public var allergyType: AllergyType
    public var severity: AllergySeverity
    public var reaction: String?
    public var confirmedDate: Date?
    public var notes: String?
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        allergen: String,
        allergyType: AllergyType,
        severity: AllergySeverity = .moderate,
        reaction: String? = nil,
        confirmedDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.allergen = allergen
        self.allergyType = allergyType
        self.severity = severity
        self.reaction = reaction
        self.confirmedDate = confirmedDate
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> Allergy {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }
}

// MARK: - Common Allergens

/// Pre-defined common allergens for quick selection
public enum CommonAllergen: String, CaseIterable, Identifiable, Sendable {
    // Food allergens
    case chicken
    case beef
    case pork
    case lamb
    case fish
    case dairy
    case eggs
    case wheat
    case corn
    case soy
    case rice

    // Environmental allergens
    case grass
    case pollen
    case dustMites
    case mold
    case fleas

    // Contact allergens
    case latex
    case plastics
    case certainFabrics

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .chicken: return Strings.Allergies.allergenChicken
        case .beef: return Strings.Allergies.allergenBeef
        case .pork: return Strings.Allergies.allergenPork
        case .lamb: return Strings.Allergies.allergenLamb
        case .fish: return Strings.Allergies.allergenFish
        case .dairy: return Strings.Allergies.allergenDairy
        case .eggs: return Strings.Allergies.allergenEggs
        case .wheat: return Strings.Allergies.allergenWheat
        case .corn: return Strings.Allergies.allergenCorn
        case .soy: return Strings.Allergies.allergenSoy
        case .rice: return Strings.Allergies.allergenRice
        case .grass: return Strings.Allergies.allergenGrass
        case .pollen: return Strings.Allergies.allergenPollen
        case .dustMites: return Strings.Allergies.allergenDustMites
        case .mold: return Strings.Allergies.allergenMold
        case .fleas: return Strings.Allergies.allergenFleas
        case .latex: return Strings.Allergies.allergenLatex
        case .plastics: return Strings.Allergies.allergenPlastics
        case .certainFabrics: return Strings.Allergies.allergenFabrics
        }
    }

    public var suggestedType: AllergyType {
        switch self {
        case .chicken, .beef, .pork, .lamb, .fish, .dairy, .eggs, .wheat, .corn, .soy, .rice:
            return .food
        case .grass, .pollen, .dustMites, .mold, .fleas:
            return .environmental
        case .latex, .plastics, .certainFabrics:
            return .contact
        }
    }

    /// Get common allergens for a specific allergy type
    public static func allergens(for type: AllergyType) -> [CommonAllergen] {
        allCases.filter { $0.suggestedType == type }
    }
}
