# Brief 03: Health Foundation

> **Status:** Ready for Implementation
> **Priority:** High
> **Dependencies:** None
> **Estimated Effort:** Medium-High

## Objective

Create the core data models and infrastructure for chronic health condition management. This is the foundation that Briefs 04-06 build upon.

## Models to Create

### 1. HealthConditionType Enum

Comprehensive list of chronic conditions dogs commonly experience:

```swift
// OtisShared/Models/HealthCondition.swift

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
    case demodectic mange
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
        case .foodAllergy: return String(localized: "Food Allergy")
        case .environmentalAllergy: return String(localized: "Environmental Allergy")
        case .hipDysplasia: return String(localized: "Hip Dysplasia")
        case .diabetes: return String(localized: "Diabetes")
        case .epilepsy: return String(localized: "Epilepsy")
        case .arthritis: return String(localized: "Arthritis")
        case .chronicKidneyDisease: return String(localized: "Chronic Kidney Disease")
        case .heartMurmur: return String(localized: "Heart Murmur")
        case .hypothyroidism: return String(localized: "Hypothyroidism")
        case .ibd: return String(localized: "Inflammatory Bowel Disease")
        case .canineCognitiveDysfunction: return String(localized: "Cognitive Dysfunction")
        // ... etc for all cases
        case .other: return String(localized: "Other Condition")
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
        case .chronicKidneyDisease, .bladderStones, .incontinence:
            return "drop"
        case .canineCognitiveDysfunction:
            return "brain"
        default:
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
        case .canineCognitiveDysfunction:
            return .cognitive
        default:
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
        default:
            return []
        }
    }

    /// Things to watch for that indicate worsening
    public var warningSignals: [String] {
        switch self {
        case .congestiveHeartFailure:
            return [
                "Resting respiratory rate >30 breaths/min",
                "Coughing at night",
                "Blue or pale gums",
                "Collapse or fainting"
            ]
        case .diabetes:
            return [
                "Sudden lethargy or weakness",
                "Vomiting",
                "Sweet or fruity breath",
                "Disorientation"
            ]
        case .epilepsy:
            return [
                "Cluster seizures (2+ in 24 hours)",
                "Seizure lasting >5 minutes",
                "Not recovering between seizures"
            ]
        default:
            return []
        }
    }
}

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
        case .allergyImmune: return String(localized: "Allergies & Immune")
        case .musculoskeletal: return String(localized: "Joints & Mobility")
        case .endocrine: return String(localized: "Hormonal")
        case .cardiac: return String(localized: "Heart")
        case .neurological: return String(localized: "Neurological")
        case .digestive: return String(localized: "Digestive")
        case .urinary: return String(localized: "Kidney & Urinary")
        case .respiratory: return String(localized: "Respiratory")
        case .eye: return String(localized: "Eyes")
        case .ear: return String(localized: "Ears")
        case .skin: return String(localized: "Skin")
        case .cognitive: return String(localized: "Cognitive")
        case .cancer: return String(localized: "Cancer")
        case .other: return String(localized: "Other")
        }
    }
}
```

### 2. HealthCondition Model

Track diagnosed conditions:

```swift
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
        status: ConditionStatus = .active
    ) {
        self.id = id
        self.type = type
        self.customName = customName
        self.diagnosedDate = diagnosedDate
        self.severity = severity
        self.status = status
        self.isGenetic = false
        self.breedRelated = false
        self.notes = nil
        self.vetRecommendations = nil
        self.associatedMedicationIds = []
        self.monitoringFrequency = .weekly
        self.lastReviewDate = nil
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    public var displayName: String {
        customName ?? type.label
    }

    public var daysSinceDiagnosis: Int {
        Calendar.current.dateComponents([.day], from: diagnosedDate, to: Date()).day ?? 0
    }

    public var needsReview: Bool {
        guard let lastReview = lastReviewDate else { return true }
        let daysSinceReview = Calendar.current.dateComponents([.day], from: lastReview, to: Date()).day ?? 0
        return daysSinceReview >= monitoringFrequency.days
    }
}

public enum ConditionSeverity: String, Codable, CaseIterable, Sendable {
    case mild
    case moderate
    case severe
    case managed  // Was severe, now under control

    public var label: String {
        switch self {
        case .mild: return String(localized: "Mild")
        case .moderate: return String(localized: "Moderate")
        case .severe: return String(localized: "Severe")
        case .managed: return String(localized: "Managed")
        }
    }

    public var colorName: String {
        switch self {
        case .mild: return "green"
        case .moderate: return "yellow"
        case .severe: return "red"
        case .managed: return "blue"
        }
    }
}

public enum ConditionStatus: String, Codable, CaseIterable, Sendable {
    case active        // Currently dealing with
    case monitoring    // Stable, watching
    case resolved      // No longer present
    case remission     // Cancer-specific

    public var label: String {
        switch self {
        case .active: return String(localized: "Active")
        case .monitoring: return String(localized: "Monitoring")
        case .resolved: return String(localized: "Resolved")
        case .remission: return String(localized: "In Remission")
        }
    }
}

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
        case .daily: return String(localized: "Daily")
        case .weekly: return String(localized: "Weekly")
        case .biweekly: return String(localized: "Every 2 weeks")
        case .monthly: return String(localized: "Monthly")
        case .quarterly: return String(localized: "Every 3 months")
        }
    }
}
```

### 3. SymptomType Enum

For logging symptoms (used in Brief 04):

```swift
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
    case redness
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
        case .limping: return String(localized: "Limping")
        case .seizure: return String(localized: "Seizure")
        case .vomiting: return String(localized: "Vomiting")
        case .diarrhea: return String(localized: "Diarrhea")
        case .coughing: return String(localized: "Coughing")
        case .itching: return String(localized: "Itching/Scratching")
        case .lethargy: return String(localized: "Lethargy")
        case .appetiteLoss: return String(localized: "Loss of Appetite")
        case .excessiveThirst: return String(localized: "Excessive Thirst")
        // ... etc
        default: return rawValue.capitalized
        }
    }

    public var icon: String {
        switch self {
        case .limping, .stiffness, .difficultyRising:
            return "figure.walk"
        case .seizure, .trembling, .confusion:
            return "brain.head.profile"
        case .vomiting, .diarrhea, .appetiteLoss:
            return "stomach"
        case .coughing, .breathingDifficulty:
            return "lungs"
        case .itching, .hotSpots:
            return "hand.raised"
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
        case .itching, .hotSpots, .hairLoss, .rash, .pawLicking:
            return .skin
        case .lethargy, .weakness, .excessiveThirst, .panting:
            return .general
        default:
            return .other
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
}

public enum SymptomUrgency: String, Codable, Sendable {
    case emergency      // Vet NOW
    case soonIfPersists // Within 24-48h if doesn't resolve
    case monitor        // Track and mention at next vet visit
}
```

### 4. BreedHealthRisk Model

Map breeds to common health predispositions:

```swift
public struct BreedHealthRisk: Codable, Sendable {
    public let breedId: Int?
    public let breedName: String
    public let breedGroup: String?
    public let risks: [ConditionRisk]

    public struct ConditionRisk: Codable, Sendable {
        public let conditionType: HealthConditionType
        public let riskLevel: RiskLevel
        public let typicalOnsetAgeMonths: ClosedRange<Int>?
        public let screeningRecommendedAgeMonths: Int?
        public let warningsToWatch: [String]
        public let preventionTips: [String]
    }
}

public enum RiskLevel: String, Codable, CaseIterable, Sendable {
    case low
    case moderate
    case high
    case veryHigh

    public var label: String {
        switch self {
        case .low: return String(localized: "Low Risk")
        case .moderate: return String(localized: "Moderate Risk")
        case .high: return String(localized: "High Risk")
        case .veryHigh: return String(localized: "Very High Risk")
        }
    }
}

// MARK: - Static Breed Risk Data

extension BreedHealthRisk {
    /// Get health risks for a breed
    public static func risks(for breedName: String?, breedGroup: String? = nil) -> BreedHealthRisk? {
        guard let breedName = breedName else { return nil }

        // Common breed group risks
        let breedLower = breedName.lowercased()

        if breedLower.contains("retriever") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Retrievers",
                risks: [
                    ConditionRisk(
                        conditionType: .hipDysplasia,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: 12...36,
                        screeningRecommendedAgeMonths: 24,
                        warningsToWatch: ["Bunny hopping", "Difficulty rising", "Reluctance to climb stairs"],
                        preventionTips: ["Maintain healthy weight", "Avoid over-exercising as puppy", "Consider joint supplements"]
                    ),
                    ConditionRisk(
                        conditionType: .elbowDysplasia,
                        riskLevel: .moderate,
                        typicalOnsetAgeMonths: 6...18,
                        screeningRecommendedAgeMonths: 12,
                        warningsToWatch: ["Front leg lameness", "Reluctance to play"],
                        preventionTips: ["Controlled exercise during growth"]
                    )
                ]
            )
        }

        if breedLower.contains("german shepherd") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Herding",
                risks: [
                    ConditionRisk(
                        conditionType: .hipDysplasia,
                        riskLevel: .veryHigh,
                        typicalOnsetAgeMonths: 12...36,
                        screeningRecommendedAgeMonths: 24,
                        warningsToWatch: ["Bunny hopping", "Swaying gait"],
                        preventionTips: ["OFA or PennHIP screening recommended"]
                    ),
                    ConditionRisk(
                        conditionType: .degenerativeMyelopathy,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: 84...120,
                        screeningRecommendedAgeMonths: 84,
                        warningsToWatch: ["Dragging rear paws", "Crossing back legs"],
                        preventionTips: ["DNA test available", "Keep active as long as possible"]
                    )
                ]
            )
        }

        if breedLower.contains("bulldog") || breedLower.contains("pug") ||
           breedLower.contains("boston terrier") || breedLower.contains("shih tzu") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Brachycephalic",
                risks: [
                    ConditionRisk(
                        conditionType: .brachycephalicSyndrome,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: 0...24,
                        screeningRecommendedAgeMonths: 12,
                        warningsToWatch: ["Loud breathing", "Snoring", "Exercise intolerance", "Blue gums during exercise"],
                        preventionTips: ["Avoid heat", "Use harness not collar", "Maintain healthy weight"]
                    )
                ]
            )
        }

        if breedLower.contains("cavalier") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Toy",
                risks: [
                    ConditionRisk(
                        conditionType: .mitralValveDisease,
                        riskLevel: .veryHigh,
                        typicalOnsetAgeMonths: 60...84,
                        screeningRecommendedAgeMonths: 24,
                        warningsToWatch: ["Coughing", "Exercise intolerance", "Rapid breathing at rest"],
                        preventionTips: ["Annual heart auscultation", "Echocardiogram by age 5"]
                    )
                ]
            )
        }

        // Generic size-based risks
        return nil
    }

    /// Size-based general risks (when breed unknown)
    public static func sizeBasedRisks(for sizeCategory: SizeCategory) -> [ConditionRisk] {
        switch sizeCategory {
        case .extraLarge, .large:
            return [
                ConditionRisk(
                    conditionType: .hipDysplasia,
                    riskLevel: .moderate,
                    typicalOnsetAgeMonths: 12...48,
                    screeningRecommendedAgeMonths: 24,
                    warningsToWatch: ["Bunny hopping", "Difficulty rising"],
                    preventionTips: ["Maintain healthy weight", "Controlled puppy exercise"]
                ),
                ConditionRisk(
                    conditionType: .arthritis,
                    riskLevel: .moderate,
                    typicalOnsetAgeMonths: 60...nil,
                    screeningRecommendedAgeMonths: 72,
                    warningsToWatch: ["Stiffness after rest", "Reluctance to jump"],
                    preventionTips: ["Joint supplements", "Regular moderate exercise"]
                )
            ]
        case .small:
            return [
                ConditionRisk(
                    conditionType: .luxatingPatella,
                    riskLevel: .moderate,
                    typicalOnsetAgeMonths: 12...48,
                    screeningRecommendedAgeMonths: 12,
                    warningsToWatch: ["Skipping on hind leg", "Occasional lameness"],
                    preventionTips: ["Maintain healthy weight", "Avoid jumping from heights"]
                ),
                ConditionRisk(
                    conditionType: .collapsedTrachea,
                    riskLevel: .moderate,
                    typicalOnsetAgeMonths: 48...84,
                    screeningRecommendedAgeMonths: nil,
                    warningsToWatch: ["Honking cough", "Coughing when excited"],
                    preventionTips: ["Use harness not collar", "Maintain healthy weight"]
                )
            ]
        case .medium:
            return []
        }
    }
}
```

### 5. Extend PuppyProfile

```swift
// Add to PuppyProfile.swift
public struct PuppyProfile {
    // ... existing fields ...

    /// Diagnosed health conditions
    public var healthConditions: [HealthCondition]

    /// Known allergies (quick access)
    public var allergies: [Allergy]
}

public struct Allergy: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var allergen: String
    public var allergyType: AllergyType
    public var severity: AllergySeverity
    public var reaction: String?
    public var confirmedDate: Date?
    public var notes: String?
}

public enum AllergyType: String, Codable, CaseIterable, Sendable {
    case food
    case environmental
    case medication
    case contact

    public var label: String {
        switch self {
        case .food: return String(localized: "Food")
        case .environmental: return String(localized: "Environmental")
        case .medication: return String(localized: "Medication")
        case .contact: return String(localized: "Contact")
        }
    }
}

public enum AllergySeverity: String, Codable, CaseIterable, Sendable {
    case mild
    case moderate
    case severe
    case lifeThreatening

    public var label: String {
        switch self {
        case .mild: return String(localized: "Mild")
        case .moderate: return String(localized: "Moderate")
        case .severe: return String(localized: "Severe")
        case .lifeThreatening: return String(localized: "Life-threatening")
        }
    }
}
```

## Implementation

### Files to Create

```
OtisShared/Sources/OtisShared/Models/
├── HealthCondition.swift        (HealthConditionType, HealthCondition, enums)
├── SymptomType.swift            (SymptomType, SymptomCategory, SymptomUrgency)
├── BreedHealthRisk.swift        (BreedHealthRisk, ConditionRisk, static data)
├── Allergy.swift                (Allergy, AllergyType, AllergySeverity)

Ollie-app/Services/
├── HealthConditionStore.swift   (CRUD for conditions)
```

### Files to Modify

```
OtisShared/Sources/OtisShared/Models/PuppyProfile.swift
  - Add healthConditions: [HealthCondition]
  - Add allergies: [Allergy]
  - Add computed properties for health summary

Ollie-app/Services/ProfileStore.swift
  - Add condition CRUD methods
  - Add allergy CRUD methods
```

### Service Layer

```swift
// HealthConditionStore.swift or ProfileStore extension

extension ProfileStore {
    // MARK: - Health Conditions

    func addCondition(_ condition: HealthCondition) {
        var profile = currentProfile
        profile.healthConditions.append(condition)
        profile.modifiedAt = Date()
        save(profile)
    }

    func updateCondition(_ condition: HealthCondition) {
        var profile = currentProfile
        if let index = profile.healthConditions.firstIndex(where: { $0.id == condition.id }) {
            profile.healthConditions[index] = condition
            profile.healthConditions[index].modifiedAt = Date()
            profile.modifiedAt = Date()
            save(profile)
        }
    }

    func deleteCondition(id: UUID) {
        var profile = currentProfile
        profile.healthConditions.removeAll { $0.id == id }
        profile.modifiedAt = Date()
        save(profile)
    }

    var activeConditions: [HealthCondition] {
        currentProfile.healthConditions.filter { $0.status == .active || $0.status == .monitoring }
    }

    func conditionsNeedingReview() -> [HealthCondition] {
        activeConditions.filter { $0.needsReview }
    }

    // MARK: - Breed Risk Integration

    func breedHealthRisks() -> BreedHealthRisk? {
        BreedHealthRisk.risks(for: currentProfile.breed, breedGroup: nil)
    }

    func undiagnosedRisks() -> [BreedHealthRisk.ConditionRisk] {
        guard let breedRisks = breedHealthRisks() else { return [] }
        let diagnosedTypes = Set(currentProfile.healthConditions.map { $0.type })
        return breedRisks.risks.filter { !diagnosedTypes.contains($0.conditionType) }
    }
}
```

## Testing

- [ ] Create condition with each HealthConditionType
- [ ] Verify breed risk lookup for common breeds
- [ ] Test size-based fallback risks
- [ ] Verify condition CRUD operations
- [ ] Test monitoring frequency calculations
- [ ] Verify symptom type categorization
- [ ] Test allergy CRUD operations

## Notes

- Breed risk data can be expanded over time from veterinary sources
- Consider loading breed risk data from JSON file for easier updates
- This foundation enables Briefs 04-06 to build health features
- SymptomType enum will be used heavily in Brief 04 (Health Logging)
