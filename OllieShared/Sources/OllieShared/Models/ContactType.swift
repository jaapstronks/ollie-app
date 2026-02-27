//
//  ContactType.swift
//  OllieShared
//
//  Types of contacts that can be stored for a dog

import Foundation

/// Types of contacts that can be stored
public enum ContactType: String, Codable, CaseIterable, Sendable {
    case vet
    case emergencyVet
    case sitter
    case daycare
    case groomer
    case trainer
    case walker
    case petStore
    case breeder
    case other

    /// SF Symbol icon for the contact type
    public var icon: String {
        switch self {
        case .vet: return "stethoscope"
        case .emergencyVet: return "cross.case.fill"
        case .sitter: return "house.fill"
        case .daycare: return "building.2.fill"
        case .groomer: return "scissors"
        case .trainer: return "figure.walk.motion"
        case .walker: return "figure.walk"
        case .petStore: return "bag.fill"
        case .breeder: return "pawprint.fill"
        case .other: return "person.fill"
        }
    }

    /// Localized display name for the contact type
    public var displayName: String {
        switch self {
        case .vet:
            return String(localized: "Veterinarian", comment: "Contact type: veterinarian")
        case .emergencyVet:
            return String(localized: "Emergency Vet", comment: "Contact type: emergency veterinarian")
        case .sitter:
            return String(localized: "Pet Sitter", comment: "Contact type: pet sitter")
        case .daycare:
            return String(localized: "Daycare", comment: "Contact type: doggy daycare")
        case .groomer:
            return String(localized: "Groomer", comment: "Contact type: dog groomer")
        case .trainer:
            return String(localized: "Trainer", comment: "Contact type: dog trainer")
        case .walker:
            return String(localized: "Dog Walker", comment: "Contact type: dog walker")
        case .petStore:
            return String(localized: "Pet Store", comment: "Contact type: pet store")
        case .breeder:
            return String(localized: "Breeder", comment: "Contact type: breeder")
        case .other:
            return String(localized: "Other", comment: "Contact type: other contact")
        }
    }
}
