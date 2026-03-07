//
//  HealthCondition.swift
//  OtisShared
//
//  Core health condition models for chronic condition management
//  Foundation for health tracking features (Briefs 03-06)
//

import Foundation

// MARK: - Health Condition Category

/// Categories of health conditions for grouping in UI
public enum HealthConditionCategory: String, Codable, CaseIterable, Sendable {
    case allergyImmune
    case musculoskeletal
    case endocrine
    case cardiac
    case neurological
    case digestive
    case urinary
    case respiratory
    case eye
    case ear
    case skin
    case cognitive
    case cancer
    case other

    public var label: String {
        switch self {
        case .allergyImmune: return Strings.HealthConditions.categoryAllergyImmune
        case .musculoskeletal: return Strings.HealthConditions.categoryMusculoskeletal
        case .endocrine: return Strings.HealthConditions.categoryEndocrine
        case .cardiac: return Strings.HealthConditions.categoryCardiac
        case .neurological: return Strings.HealthConditions.categoryNeurological
        case .digestive: return Strings.HealthConditions.categoryDigestive
        case .urinary: return Strings.HealthConditions.categoryUrinary
        case .respiratory: return Strings.HealthConditions.categoryRespiratory
        case .eye: return Strings.HealthConditions.categoryEye
        case .ear: return Strings.HealthConditions.categoryEar
        case .skin: return Strings.HealthConditions.categorySkin
        case .cognitive: return Strings.HealthConditions.categoryCognitive
        case .cancer: return Strings.HealthConditions.categoryCancer
        case .other: return Strings.HealthConditions.categoryOther
        }
    }

    public var icon: String {
        switch self {
        case .allergyImmune: return "allergens"
        case .musculoskeletal: return "figure.walk"
        case .endocrine: return "syringe"
        case .cardiac: return "heart"
        case .neurological: return "brain.head.profile"
        case .digestive: return "stomach"
        case .urinary: return "drop"
        case .respiratory: return "lungs"
        case .eye: return "eye"
        case .ear: return "ear"
        case .skin: return "hand.raised"
        case .cognitive: return "brain"
        case .cancer: return "cross.case"
        case .other: return "cross.case"
        }
    }
}

// MARK: - Health Condition Type

/// Comprehensive list of chronic conditions dogs commonly experience
public enum HealthConditionType: String, Codable, CaseIterable, Identifiable, Sendable {
    // Allergies & Immune
    case foodAllergy
    case environmentalAllergy
    case atopicDermatitis
    case autoimmune

    // Musculoskeletal
    case hipDysplasia
    case elbowDysplasia
    case arthritis
    case luxatingPatella
    case ivdd  // Intervertebral disc disease

    // Endocrine
    case diabetes
    case hypothyroidism
    case hyperthyroidism
    case cushings
    case addisons

    // Cardiac
    case heartMurmur
    case dilatedCardiomyopathy
    case mitralValveDisease
    case congestiveHeartFailure

    // Neurological
    case epilepsy
    case vestibularDisease
    case degenerativeMyelopathy

    // Digestive
    case ibd  // Inflammatory bowel disease
    case pancreatitis
    case megaesophagus
    case exocrinePancreaticInsufficiency

    // Urinary/Renal
    case chronicKidneyDisease
    case bladderStones
    case incontinence

    // Respiratory
    case collapsedTrachea
    case laryngealParalysis
    case brachycephalicSyndrome

    // Eye
    case cataracts
    case glaucoma
    case progressiveRetinalAtrophy
    case dryEye

    // Ear
    case chronicOtitis

    // Skin
    case demodeticMange
    case sebaceousAdenitis

    // Cancer/Tumors
    case mastCellTumor
    case lymphoma
    case osteosarcoma
    case hemangiosarcoma

    // Cognitive
    case canineCognitiveDysfunction

    // Other
    case other

    // MARK: - Properties

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .foodAllergy: return Strings.HealthConditions.foodAllergy
        case .environmentalAllergy: return Strings.HealthConditions.environmentalAllergy
        case .atopicDermatitis: return Strings.HealthConditions.atopicDermatitis
        case .autoimmune: return Strings.HealthConditions.autoimmune
        case .hipDysplasia: return Strings.HealthConditions.hipDysplasia
        case .elbowDysplasia: return Strings.HealthConditions.elbowDysplasia
        case .arthritis: return Strings.HealthConditions.arthritis
        case .luxatingPatella: return Strings.HealthConditions.luxatingPatella
        case .ivdd: return Strings.HealthConditions.ivdd
        case .diabetes: return Strings.HealthConditions.diabetes
        case .hypothyroidism: return Strings.HealthConditions.hypothyroidism
        case .hyperthyroidism: return Strings.HealthConditions.hyperthyroidism
        case .cushings: return Strings.HealthConditions.cushings
        case .addisons: return Strings.HealthConditions.addisons
        case .heartMurmur: return Strings.HealthConditions.heartMurmur
        case .dilatedCardiomyopathy: return Strings.HealthConditions.dilatedCardiomyopathy
        case .mitralValveDisease: return Strings.HealthConditions.mitralValveDisease
        case .congestiveHeartFailure: return Strings.HealthConditions.congestiveHeartFailure
        case .epilepsy: return Strings.HealthConditions.epilepsy
        case .vestibularDisease: return Strings.HealthConditions.vestibularDisease
        case .degenerativeMyelopathy: return Strings.HealthConditions.degenerativeMyelopathy
        case .ibd: return Strings.HealthConditions.ibd
        case .pancreatitis: return Strings.HealthConditions.pancreatitis
        case .megaesophagus: return Strings.HealthConditions.megaesophagus
        case .exocrinePancreaticInsufficiency: return Strings.HealthConditions.exocrinePancreaticInsufficiency
        case .chronicKidneyDisease: return Strings.HealthConditions.chronicKidneyDisease
        case .bladderStones: return Strings.HealthConditions.bladderStones
        case .incontinence: return Strings.HealthConditions.incontinence
        case .collapsedTrachea: return Strings.HealthConditions.collapsedTrachea
        case .laryngealParalysis: return Strings.HealthConditions.laryngealParalysis
        case .brachycephalicSyndrome: return Strings.HealthConditions.brachycephalicSyndrome
        case .cataracts: return Strings.HealthConditions.cataracts
        case .glaucoma: return Strings.HealthConditions.glaucoma
        case .progressiveRetinalAtrophy: return Strings.HealthConditions.progressiveRetinalAtrophy
        case .dryEye: return Strings.HealthConditions.dryEye
        case .chronicOtitis: return Strings.HealthConditions.chronicOtitis
        case .demodeticMange: return Strings.HealthConditions.demodeticMange
        case .sebaceousAdenitis: return Strings.HealthConditions.sebaceousAdenitis
        case .mastCellTumor: return Strings.HealthConditions.mastCellTumor
        case .lymphoma: return Strings.HealthConditions.lymphoma
        case .osteosarcoma: return Strings.HealthConditions.osteosarcoma
        case .hemangiosarcoma: return Strings.HealthConditions.hemangiosarcoma
        case .canineCognitiveDysfunction: return Strings.HealthConditions.canineCognitiveDysfunction
        case .other: return Strings.HealthConditions.otherCondition
        }
    }

    public var icon: String {
        switch self {
        case .foodAllergy, .environmentalAllergy, .atopicDermatitis:
            return "allergens"
        case .hipDysplasia, .elbowDysplasia, .arthritis, .luxatingPatella, .ivdd:
            return "figure.walk"
        case .diabetes, .hypothyroidism, .hyperthyroidism, .cushings, .addisons:
            return "syringe"
        case .heartMurmur, .dilatedCardiomyopathy, .mitralValveDisease, .congestiveHeartFailure:
            return "heart"
        case .epilepsy, .vestibularDisease, .degenerativeMyelopathy:
            return "brain.head.profile"
        case .ibd, .pancreatitis, .megaesophagus, .exocrinePancreaticInsufficiency:
            return "stomach"
        case .chronicKidneyDisease, .bladderStones, .incontinence:
            return "drop"
        case .collapsedTrachea, .laryngealParalysis, .brachycephalicSyndrome:
            return "lungs"
        case .cataracts, .glaucoma, .progressiveRetinalAtrophy, .dryEye:
            return "eye"
        case .chronicOtitis:
            return "ear"
        case .demodeticMange, .sebaceousAdenitis:
            return "hand.raised"
        case .canineCognitiveDysfunction:
            return "brain"
        case .autoimmune, .mastCellTumor, .lymphoma, .osteosarcoma, .hemangiosarcoma, .other:
            return "cross.case"
        }
    }

    public var category: HealthConditionCategory {
        switch self {
        case .foodAllergy, .environmentalAllergy, .atopicDermatitis, .autoimmune:
            return .allergyImmune
        case .hipDysplasia, .elbowDysplasia, .arthritis, .luxatingPatella, .ivdd:
            return .musculoskeletal
        case .diabetes, .hypothyroidism, .hyperthyroidism, .cushings, .addisons:
            return .endocrine
        case .heartMurmur, .dilatedCardiomyopathy, .mitralValveDisease, .congestiveHeartFailure:
            return .cardiac
        case .epilepsy, .vestibularDisease, .degenerativeMyelopathy:
            return .neurological
        case .ibd, .pancreatitis, .megaesophagus, .exocrinePancreaticInsufficiency:
            return .digestive
        case .chronicKidneyDisease, .bladderStones, .incontinence:
            return .urinary
        case .collapsedTrachea, .laryngealParalysis, .brachycephalicSyndrome:
            return .respiratory
        case .cataracts, .glaucoma, .progressiveRetinalAtrophy, .dryEye:
            return .eye
        case .chronicOtitis:
            return .ear
        case .demodeticMange, .sebaceousAdenitis:
            return .skin
        case .canineCognitiveDysfunction:
            return .cognitive
        case .mastCellTumor, .lymphoma, .osteosarcoma, .hemangiosarcoma:
            return .cancer
        case .other:
            return .other
        }
    }

    /// Symptoms commonly associated with this condition
    public var commonSymptoms: [SymptomType] {
        switch self {
        case .hipDysplasia, .arthritis:
            return [.limping, .stiffness, .difficultyRising, .reluctanceToClimb]
        case .epilepsy:
            return [.seizure, .confusion, .drooling, .trembling]
        case .diabetes:
            return [.excessiveThirst, .frequentUrination, .weightLoss, .lethargy]
        case .foodAllergy, .environmentalAllergy:
            return [.itching, .earInfection, .hotSpots, .pawLicking]
        case .chronicKidneyDisease:
            return [.excessiveThirst, .frequentUrination, .vomiting, .appetiteLoss]
        case .heartMurmur, .congestiveHeartFailure:
            return [.coughing, .breathingDifficulty, .exerciseIntolerance, .fainting]
        case .hypothyroidism:
            return [.lethargy, .weightGain, .hairLoss, .dryCoat]
        case .cushings:
            return [.excessiveThirst, .frequentUrination, .hairLoss, .panting]
        case .ibd:
            return [.vomiting, .diarrhea, .appetiteLoss, .weightLoss]
        case .canineCognitiveDysfunction:
            return [.confusion, .disorientation, .restlessness, .anxiety]
        default:
            return []
        }
    }

    /// Warning signs that indicate condition may be worsening
    public var warningSignals: [String] {
        switch self {
        case .congestiveHeartFailure:
            return [
                Strings.HealthConditions.warningBreathingRate,
                Strings.HealthConditions.warningNightCoughing,
                Strings.HealthConditions.warningPaleGums,
                Strings.HealthConditions.warningCollapse
            ]
        case .diabetes:
            return [
                Strings.HealthConditions.warningSuddenLethargy,
                Strings.HealthConditions.warningVomiting,
                Strings.HealthConditions.warningSweetBreath,
                Strings.HealthConditions.warningDisorientation
            ]
        case .epilepsy:
            return [
                Strings.HealthConditions.warningClusterSeizures,
                Strings.HealthConditions.warningLongSeizure,
                Strings.HealthConditions.warningNoRecovery
            ]
        case .chronicKidneyDisease:
            return [
                Strings.HealthConditions.warningNotEating,
                Strings.HealthConditions.warningVomiting,
                Strings.HealthConditions.warningWeakness,
                Strings.HealthConditions.warningBadBreath
            ]
        default:
            return []
        }
    }
}

// MARK: - Condition Severity

/// How severe the condition currently is
public enum ConditionSeverity: String, Codable, CaseIterable, Sendable {
    case mild
    case moderate
    case severe
    case managed  // Was severe, now under control

    public var label: String {
        switch self {
        case .mild: return Strings.HealthConditions.severityMild
        case .moderate: return Strings.HealthConditions.severityModerate
        case .severe: return Strings.HealthConditions.severitySevere
        case .managed: return Strings.HealthConditions.severityManaged
        }
    }

    public var colorName: String {
        switch self {
        case .mild: return "otisSuccess"
        case .moderate: return "otisWarning"
        case .severe: return "otisDestructive"
        case .managed: return "otisInfo"
        }
    }
}

// MARK: - Condition Status

/// Current status of the condition
public enum ConditionStatus: String, Codable, CaseIterable, Sendable {
    case active        // Currently dealing with
    case monitoring    // Stable, watching
    case resolved      // No longer present
    case remission     // Cancer-specific

    public var label: String {
        switch self {
        case .active: return Strings.HealthConditions.statusActive
        case .monitoring: return Strings.HealthConditions.statusMonitoring
        case .resolved: return Strings.HealthConditions.statusResolved
        case .remission: return Strings.HealthConditions.statusRemission
        }
    }
}

// MARK: - Monitoring Frequency

/// How often the condition should be reviewed
public enum MonitoringFrequency: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly

    public var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        }
    }

    public var label: String {
        switch self {
        case .daily: return Strings.HealthConditions.frequencyDaily
        case .weekly: return Strings.HealthConditions.frequencyWeekly
        case .biweekly: return Strings.HealthConditions.frequencyBiweekly
        case .monthly: return Strings.HealthConditions.frequencyMonthly
        case .quarterly: return Strings.HealthConditions.frequencyQuarterly
        }
    }
}

// MARK: - Health Condition Model

/// A diagnosed health condition for a dog
public struct HealthCondition: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var type: HealthConditionType
    public var customName: String?  // For .other type
    public var diagnosedDate: Date
    public var severity: ConditionSeverity
    public var status: ConditionStatus
    public var isGenetic: Bool
    public var breedRelated: Bool
    public var notes: String?
    public var vetRecommendations: String?
    public var associatedMedicationIds: [UUID]
    public var monitoringFrequency: MonitoringFrequency
    public var lastReviewDate: Date?
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        type: HealthConditionType,
        customName: String? = nil,
        diagnosedDate: Date = Date(),
        severity: ConditionSeverity = .moderate,
        status: ConditionStatus = .active,
        isGenetic: Bool = false,
        breedRelated: Bool = false,
        notes: String? = nil,
        vetRecommendations: String? = nil,
        associatedMedicationIds: [UUID] = [],
        monitoringFrequency: MonitoringFrequency = .weekly,
        lastReviewDate: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.customName = customName
        self.diagnosedDate = diagnosedDate
        self.severity = severity
        self.status = status
        self.isGenetic = isGenetic
        self.breedRelated = breedRelated
        self.notes = notes
        self.vetRecommendations = vetRecommendations
        self.associatedMedicationIds = associatedMedicationIds
        self.monitoringFrequency = monitoringFrequency
        self.lastReviewDate = lastReviewDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Display name - uses custom name for .other type, otherwise uses type label
    public var displayName: String {
        customName ?? type.label
    }

    /// Days since condition was diagnosed
    public var daysSinceDiagnosis: Int {
        Calendar.current.dateComponents([.day], from: diagnosedDate, to: Date()).day ?? 0
    }

    /// Whether it's time to review this condition based on monitoring frequency
    public var needsReview: Bool {
        guard let lastReview = lastReviewDate else { return true }
        let daysSinceReview = Calendar.current.dateComponents([.day], from: lastReview, to: Date()).day ?? 0
        return daysSinceReview >= monitoringFrequency.days
    }

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> HealthCondition {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }
}
