//
//  SymptomType.swift
//  OtisShared
//
//  Symptom types for health logging and condition tracking
//  Used in Brief 04 for symptom logging feature
//

import Foundation

// MARK: - Symptom Category

/// Categories for organizing symptoms in UI
public enum SymptomCategory: String, Codable, Sendable {
    case mobility
    case neurological
    case respiratory
    case digestive
    case urinary
    case skin
    case eyes
    case ears
    case general
    case behavioral
    case other

    public var label: String {
        switch self {
        case .mobility: return Strings.Symptoms.categoryMobility
        case .neurological: return Strings.Symptoms.categoryNeurological
        case .respiratory: return Strings.Symptoms.categoryRespiratory
        case .digestive: return Strings.Symptoms.categoryDigestive
        case .urinary: return Strings.Symptoms.categoryUrinary
        case .skin: return Strings.Symptoms.categorySkin
        case .eyes: return Strings.Symptoms.categoryEyes
        case .ears: return Strings.Symptoms.categoryEars
        case .general: return Strings.Symptoms.categoryGeneral
        case .behavioral: return Strings.Symptoms.categoryBehavioral
        case .other: return Strings.Symptoms.categoryOther
        }
    }
}

// MARK: - Symptom Urgency

/// Urgency level for symptoms - some need immediate vet attention
public enum SymptomUrgency: String, Codable, Sendable {
    case emergency      // Vet NOW
    case soonIfPersists // Within 24-48h if doesn't resolve
    case monitor        // Track and mention at next vet visit

    public var label: String {
        switch self {
        case .emergency: return Strings.Symptoms.urgencyEmergency
        case .soonIfPersists: return Strings.Symptoms.urgencySoon
        case .monitor: return Strings.Symptoms.urgencyMonitor
        }
    }

    public var colorName: String {
        switch self {
        case .emergency: return "otisDestructive"
        case .soonIfPersists: return "otisWarning"
        case .monitor: return "otisInfo"
        }
    }
}

// MARK: - Symptom Type

/// Comprehensive list of symptoms dogs may exhibit
public enum SymptomType: String, Codable, CaseIterable, Identifiable, Sendable {
    // Pain/Mobility
    case limping
    case stiffness
    case difficultyRising
    case reluctanceToClimb
    case bunnyHopping
    case lamenessRearLegs
    case lamenessFrontLegs

    // Neurological
    case seizure
    case trembling
    case headTilt
    case circling
    case confusion
    case disorientation
    case lossOfBalance

    // Respiratory
    case coughing
    case breathingDifficulty
    case rapidBreathing
    case reverseSneezing
    case wheezing

    // Digestive
    case vomiting
    case diarrhea
    case constipation
    case bloating
    case appetiteLoss
    case excessiveGas

    // Urinary
    case frequentUrination
    case difficultyUrinating
    case bloodInUrine
    case accidents

    // Skin/Coat
    case itching
    case hotSpots
    case hairLoss
    case rash
    case dryCoat
    case excessiveShedding
    case pawLicking
    case faceRubbing

    // Eyes
    case eyeDischarge
    case eyeRedness
    case cloudiness
    case squinting
    case bumpingIntoThings

    // Ears
    case earInfection
    case headShaking
    case earOdor
    case scratching

    // General
    case lethargy
    case weakness
    case weightLoss
    case weightGain
    case excessiveThirst
    case drooling
    case badBreath
    case fainting
    case exerciseIntolerance
    case restlessness
    case panting

    // Behavioral
    case anxiety
    case aggression
    case hiding
    case vocalization

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .limping: return Strings.Symptoms.limping
        case .stiffness: return Strings.Symptoms.stiffness
        case .difficultyRising: return Strings.Symptoms.difficultyRising
        case .reluctanceToClimb: return Strings.Symptoms.reluctanceToClimb
        case .bunnyHopping: return Strings.Symptoms.bunnyHopping
        case .lamenessRearLegs: return Strings.Symptoms.lamenessRearLegs
        case .lamenessFrontLegs: return Strings.Symptoms.lamenessFrontLegs
        case .seizure: return Strings.Symptoms.seizure
        case .trembling: return Strings.Symptoms.trembling
        case .headTilt: return Strings.Symptoms.headTilt
        case .circling: return Strings.Symptoms.circling
        case .confusion: return Strings.Symptoms.confusion
        case .disorientation: return Strings.Symptoms.disorientation
        case .lossOfBalance: return Strings.Symptoms.lossOfBalance
        case .coughing: return Strings.Symptoms.coughing
        case .breathingDifficulty: return Strings.Symptoms.breathingDifficulty
        case .rapidBreathing: return Strings.Symptoms.rapidBreathing
        case .reverseSneezing: return Strings.Symptoms.reverseSneezing
        case .wheezing: return Strings.Symptoms.wheezing
        case .vomiting: return Strings.Symptoms.vomiting
        case .diarrhea: return Strings.Symptoms.diarrhea
        case .constipation: return Strings.Symptoms.constipation
        case .bloating: return Strings.Symptoms.bloating
        case .appetiteLoss: return Strings.Symptoms.appetiteLoss
        case .excessiveGas: return Strings.Symptoms.excessiveGas
        case .frequentUrination: return Strings.Symptoms.frequentUrination
        case .difficultyUrinating: return Strings.Symptoms.difficultyUrinating
        case .bloodInUrine: return Strings.Symptoms.bloodInUrine
        case .accidents: return Strings.Symptoms.accidents
        case .itching: return Strings.Symptoms.itching
        case .hotSpots: return Strings.Symptoms.hotSpots
        case .hairLoss: return Strings.Symptoms.hairLoss
        case .rash: return Strings.Symptoms.rash
        case .dryCoat: return Strings.Symptoms.dryCoat
        case .excessiveShedding: return Strings.Symptoms.excessiveShedding
        case .pawLicking: return Strings.Symptoms.pawLicking
        case .faceRubbing: return Strings.Symptoms.faceRubbing
        case .eyeDischarge: return Strings.Symptoms.eyeDischarge
        case .eyeRedness: return Strings.Symptoms.eyeRedness
        case .cloudiness: return Strings.Symptoms.cloudiness
        case .squinting: return Strings.Symptoms.squinting
        case .bumpingIntoThings: return Strings.Symptoms.bumpingIntoThings
        case .earInfection: return Strings.Symptoms.earInfection
        case .headShaking: return Strings.Symptoms.headShaking
        case .earOdor: return Strings.Symptoms.earOdor
        case .scratching: return Strings.Symptoms.scratching
        case .lethargy: return Strings.Symptoms.lethargy
        case .weakness: return Strings.Symptoms.weakness
        case .weightLoss: return Strings.Symptoms.weightLoss
        case .weightGain: return Strings.Symptoms.weightGain
        case .excessiveThirst: return Strings.Symptoms.excessiveThirst
        case .drooling: return Strings.Symptoms.drooling
        case .badBreath: return Strings.Symptoms.badBreath
        case .fainting: return Strings.Symptoms.fainting
        case .exerciseIntolerance: return Strings.Symptoms.exerciseIntolerance
        case .restlessness: return Strings.Symptoms.restlessness
        case .panting: return Strings.Symptoms.panting
        case .anxiety: return Strings.Symptoms.anxiety
        case .aggression: return Strings.Symptoms.aggression
        case .hiding: return Strings.Symptoms.hiding
        case .vocalization: return Strings.Symptoms.vocalization
        }
    }

    public var icon: String {
        switch self {
        case .limping, .stiffness, .difficultyRising, .reluctanceToClimb,
             .bunnyHopping, .lamenessRearLegs, .lamenessFrontLegs:
            return "figure.walk"
        case .seizure, .trembling, .headTilt, .circling, .confusion,
             .disorientation, .lossOfBalance:
            return "brain.head.profile"
        case .coughing, .breathingDifficulty, .rapidBreathing,
             .reverseSneezing, .wheezing:
            return "lungs"
        case .vomiting, .diarrhea, .constipation, .bloating,
             .appetiteLoss, .excessiveGas:
            return "stomach"
        case .frequentUrination, .difficultyUrinating, .bloodInUrine, .accidents:
            return "drop"
        case .itching, .hotSpots, .hairLoss, .rash, .dryCoat,
             .excessiveShedding, .pawLicking, .faceRubbing:
            return "hand.raised"
        case .eyeDischarge, .eyeRedness, .cloudiness, .squinting, .bumpingIntoThings:
            return "eye"
        case .earInfection, .headShaking, .earOdor, .scratching:
            return "ear"
        case .anxiety, .aggression, .hiding, .vocalization:
            return "brain"
        default:
            return "cross.case"
        }
    }

    public var category: SymptomCategory {
        switch self {
        case .limping, .stiffness, .difficultyRising, .reluctanceToClimb,
             .bunnyHopping, .lamenessRearLegs, .lamenessFrontLegs:
            return .mobility
        case .seizure, .trembling, .headTilt, .circling, .confusion,
             .disorientation, .lossOfBalance:
            return .neurological
        case .coughing, .breathingDifficulty, .rapidBreathing,
             .reverseSneezing, .wheezing:
            return .respiratory
        case .vomiting, .diarrhea, .constipation, .bloating,
             .appetiteLoss, .excessiveGas:
            return .digestive
        case .frequentUrination, .difficultyUrinating, .bloodInUrine, .accidents:
            return .urinary
        case .itching, .hotSpots, .hairLoss, .rash, .dryCoat,
             .excessiveShedding, .pawLicking, .faceRubbing:
            return .skin
        case .eyeDischarge, .eyeRedness, .cloudiness, .squinting, .bumpingIntoThings:
            return .eyes
        case .earInfection, .headShaking, .earOdor, .scratching:
            return .ears
        case .lethargy, .weakness, .weightLoss, .weightGain, .excessiveThirst,
             .drooling, .badBreath, .fainting, .exerciseIntolerance,
             .restlessness, .panting:
            return .general
        case .anxiety, .aggression, .hiding, .vocalization:
            return .behavioral
        }
    }

    /// Urgency level - some symptoms need immediate vet attention
    public var urgencyLevel: SymptomUrgency {
        switch self {
        case .seizure, .breathingDifficulty, .bloating, .fainting,
             .bloodInUrine, .difficultyUrinating:
            return .emergency
        case .vomiting, .diarrhea, .lethargy, .appetiteLoss:
            return .soonIfPersists
        default:
            return .monitor
        }
    }
}
