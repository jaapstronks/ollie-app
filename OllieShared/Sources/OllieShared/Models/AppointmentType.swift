//
//  AppointmentType.swift
//  OllieShared
//
//  Types of appointments that can be scheduled for a dog

import Foundation

/// Types of appointments that can be scheduled
public enum AppointmentType: String, Codable, CaseIterable, Sendable {
    case vetCheckup = "vet_checkup"
    case vetVaccination = "vet_vaccination"
    case vetEmergency = "vet_emergency"
    case vetSurgery = "vet_surgery"
    case grooming
    case training
    case daycare
    case boarding
    case dogWalker = "dog_walker"
    case playdate
    case other

    /// SF Symbol icon for the appointment type
    public var icon: String {
        switch self {
        case .vetCheckup: return "stethoscope"
        case .vetVaccination: return "syringe.fill"
        case .vetEmergency: return "cross.case.fill"
        case .vetSurgery: return "bandage.fill"
        case .grooming: return "scissors"
        case .training: return "figure.walk.motion"
        case .daycare: return "building.2.fill"
        case .boarding: return "house.fill"
        case .dogWalker: return "figure.walk"
        case .playdate: return "pawprint.fill"
        case .other: return "calendar"
        }
    }

    /// Color name for the appointment type (uses asset catalog colors)
    public var color: String {
        switch self {
        case .vetCheckup, .vetVaccination, .vetSurgery: return "vetBlue"
        case .vetEmergency: return "emergencyRed"
        case .grooming: return "groomingPurple"
        case .training: return "trainingGreen"
        case .daycare, .boarding: return "careOrange"
        case .dogWalker: return "walkTeal"
        case .playdate: return "playdatePink"
        case .other: return "otherGray"
        }
    }

    /// Localized display name for the appointment type
    public var displayName: String {
        switch self {
        case .vetCheckup:
            return String(localized: "Vet Checkup", comment: "Appointment type: veterinary checkup")
        case .vetVaccination:
            return String(localized: "Vaccination", comment: "Appointment type: vaccination")
        case .vetEmergency:
            return String(localized: "Emergency Vet", comment: "Appointment type: emergency veterinary visit")
        case .vetSurgery:
            return String(localized: "Surgery", comment: "Appointment type: surgery")
        case .grooming:
            return String(localized: "Grooming", comment: "Appointment type: grooming")
        case .training:
            return String(localized: "Training", comment: "Appointment type: training class")
        case .daycare:
            return String(localized: "Daycare", comment: "Appointment type: doggy daycare")
        case .boarding:
            return String(localized: "Boarding", comment: "Appointment type: boarding/kennel")
        case .dogWalker:
            return String(localized: "Dog Walker", comment: "Appointment type: dog walker")
        case .playdate:
            return String(localized: "Playdate", comment: "Appointment type: playdate")
        case .other:
            return String(localized: "Other", comment: "Appointment type: other")
        }
    }

    /// Whether this appointment type is health-related (for milestone linking)
    public var isHealthRelated: Bool {
        switch self {
        case .vetCheckup, .vetVaccination, .vetEmergency, .vetSurgery:
            return true
        default:
            return false
        }
    }

    /// Suggested ContactType for this appointment type
    public var suggestedContactType: ContactType? {
        switch self {
        case .vetCheckup, .vetVaccination, .vetSurgery:
            return .vet
        case .vetEmergency:
            return .emergencyVet
        case .grooming:
            return .groomer
        case .training:
            return .trainer
        case .daycare:
            return .daycare
        case .dogWalker:
            return .walker
        case .boarding:
            return .sitter
        default:
            return nil
        }
    }
}
