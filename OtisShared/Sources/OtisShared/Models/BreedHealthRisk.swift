//
//  BreedHealthRisk.swift
//  OtisShared
//
//  Breed-specific health risk data for proactive health screening
//  Maps dog breeds to common health predispositions
//

import Foundation

// MARK: - Risk Level

/// How likely a breed is to develop a condition
public enum RiskLevel: String, Codable, CaseIterable, Sendable {
    case low
    case moderate
    case high
    case veryHigh

    public var label: String {
        switch self {
        case .low: return Strings.HealthConditions.riskLow
        case .moderate: return Strings.HealthConditions.riskModerate
        case .high: return Strings.HealthConditions.riskHigh
        case .veryHigh: return Strings.HealthConditions.riskVeryHigh
        }
    }

    public var colorName: String {
        switch self {
        case .low: return "otisSuccess"
        case .moderate: return "otisInfo"
        case .high: return "otisWarning"
        case .veryHigh: return "otisDestructive"
        }
    }
}

// MARK: - Condition Risk

/// A specific health risk for a breed
public struct ConditionRisk: Codable, Sendable, Equatable {
    public let conditionType: HealthConditionType
    public let riskLevel: RiskLevel
    /// Lower bound of typical onset age in months (nil if no data)
    public let typicalOnsetAgeMonthsMin: Int?
    /// Upper bound of typical onset age in months (nil if ongoing)
    public let typicalOnsetAgeMonthsMax: Int?
    public let screeningRecommendedAgeMonths: Int?
    public let warningsToWatch: [String]
    public let preventionTips: [String]

    public init(
        conditionType: HealthConditionType,
        riskLevel: RiskLevel,
        typicalOnsetAgeMonths: ClosedRange<Int>? = nil,
        screeningRecommendedAgeMonths: Int? = nil,
        warningsToWatch: [String] = [],
        preventionTips: [String] = []
    ) {
        self.conditionType = conditionType
        self.riskLevel = riskLevel
        self.typicalOnsetAgeMonthsMin = typicalOnsetAgeMonths?.lowerBound
        self.typicalOnsetAgeMonthsMax = typicalOnsetAgeMonths?.upperBound
        self.screeningRecommendedAgeMonths = screeningRecommendedAgeMonths
        self.warningsToWatch = warningsToWatch
        self.preventionTips = preventionTips
    }

    /// Typical onset age range for display (e.g., "12-36 months")
    public var typicalOnsetAgeRange: String? {
        guard let min = typicalOnsetAgeMonthsMin else { return nil }
        if let max = typicalOnsetAgeMonthsMax {
            return "\(min)-\(max) months"
        } else {
            return "\(min)+ months"
        }
    }
}

// MARK: - Breed Health Risk

/// Health risks associated with a specific breed
public struct BreedHealthRisk: Codable, Sendable {
    public let breedId: Int?
    public let breedName: String
    public let breedGroup: String?
    public let risks: [ConditionRisk]

    public init(
        breedId: Int? = nil,
        breedName: String,
        breedGroup: String? = nil,
        risks: [ConditionRisk]
    ) {
        self.breedId = breedId
        self.breedName = breedName
        self.breedGroup = breedGroup
        self.risks = risks
    }
}

// MARK: - Static Breed Risk Data

extension BreedHealthRisk {
    /// Get health risks for a breed by name
    public static func risks(for breedName: String?, breedGroup: String? = nil) -> BreedHealthRisk? {
        guard let breedName = breedName else { return nil }

        let breedLower = breedName.lowercased()

        // Retrievers
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
                    ),
                    ConditionRisk(
                        conditionType: .dilatedCardiomyopathy,
                        riskLevel: .moderate,
                        typicalOnsetAgeMonths: 48...96,
                        screeningRecommendedAgeMonths: 48,
                        warningsToWatch: ["Coughing", "Exercise intolerance", "Rapid breathing"],
                        preventionTips: ["Regular cardiac screening", "Grain-inclusive diet (consult vet)"]
                    )
                ]
            )
        }

        // German Shepherds
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

        // Brachycephalic breeds
        if breedLower.contains("bulldog") || breedLower.contains("pug") ||
           breedLower.contains("boston terrier") || breedLower.contains("shih tzu") ||
           breedLower.contains("french bulldog") || breedLower.contains("pekingese") {
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

        // Cavalier King Charles Spaniel
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

        // Dachshunds
        if breedLower.contains("dachshund") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Hound",
                risks: [
                    ConditionRisk(
                        conditionType: .ivdd,
                        riskLevel: .veryHigh,
                        typicalOnsetAgeMonths: 36...84,
                        screeningRecommendedAgeMonths: nil,
                        warningsToWatch: ["Back pain", "Reluctance to jump", "Weakness in back legs", "Hunched back"],
                        preventionTips: ["Use ramps instead of stairs", "Prevent jumping on/off furniture", "Maintain healthy weight"]
                    )
                ]
            )
        }

        // Doberman
        if breedLower.contains("doberman") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Working",
                risks: [
                    ConditionRisk(
                        conditionType: .dilatedCardiomyopathy,
                        riskLevel: .veryHigh,
                        typicalOnsetAgeMonths: 48...84,
                        screeningRecommendedAgeMonths: 24,
                        warningsToWatch: ["Coughing", "Exercise intolerance", "Fainting", "Rapid breathing"],
                        preventionTips: ["Annual cardiac screening starting at age 2", "Holter monitor recommended"]
                    ),
                    ConditionRisk(
                        conditionType: .hypothyroidism,
                        riskLevel: .moderate,
                        typicalOnsetAgeMonths: 24...72,
                        screeningRecommendedAgeMonths: 24,
                        warningsToWatch: ["Weight gain", "Lethargy", "Hair loss"],
                        preventionTips: ["Regular thyroid screening"]
                    )
                ]
            )
        }

        // Boxer
        if breedLower.contains("boxer") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Working",
                risks: [
                    ConditionRisk(
                        conditionType: .dilatedCardiomyopathy,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: 48...96,
                        screeningRecommendedAgeMonths: 24,
                        warningsToWatch: ["Fainting", "Exercise intolerance", "Irregular heartbeat"],
                        preventionTips: ["Annual cardiac screening", "Holter monitor recommended"]
                    ),
                    ConditionRisk(
                        conditionType: .mastCellTumor,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: 72...120,
                        screeningRecommendedAgeMonths: nil,
                        warningsToWatch: ["New lumps or bumps", "Changes in existing lumps"],
                        preventionTips: ["Regular skin checks", "Immediate vet visit for new lumps"]
                    )
                ]
            )
        }

        // Cocker Spaniel
        if breedLower.contains("cocker spaniel") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Sporting",
                risks: [
                    ConditionRisk(
                        conditionType: .chronicOtitis,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: nil,
                        screeningRecommendedAgeMonths: nil,
                        warningsToWatch: ["Head shaking", "Ear scratching", "Ear odor", "Redness"],
                        preventionTips: ["Regular ear cleaning", "Keep ears dry", "Check ears weekly"]
                    ),
                    ConditionRisk(
                        conditionType: .cataracts,
                        riskLevel: .moderate,
                        typicalOnsetAgeMonths: 48...96,
                        screeningRecommendedAgeMonths: 48,
                        warningsToWatch: ["Cloudiness in eye", "Bumping into things"],
                        preventionTips: ["Regular eye exams"]
                    )
                ]
            )
        }

        // Labrador
        if breedLower.contains("labrador") {
            return BreedHealthRisk(
                breedId: nil,
                breedName: breedName,
                breedGroup: "Sporting",
                risks: [
                    ConditionRisk(
                        conditionType: .hipDysplasia,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: 12...36,
                        screeningRecommendedAgeMonths: 24,
                        warningsToWatch: ["Bunny hopping", "Difficulty rising", "Reluctance to climb stairs"],
                        preventionTips: ["Maintain healthy weight", "Controlled exercise as puppy"]
                    ),
                    ConditionRisk(
                        conditionType: .elbowDysplasia,
                        riskLevel: .high,
                        typicalOnsetAgeMonths: 6...18,
                        screeningRecommendedAgeMonths: 12,
                        warningsToWatch: ["Front leg lameness", "Stiffness after rest"],
                        preventionTips: ["Controlled exercise during growth", "Proper nutrition"]
                    )
                ]
            )
        }

        return nil
    }

    /// Size-based general risks (when breed is unknown)
    public static func sizeBasedRisks(for sizeCategory: PuppyProfile.SizeCategory) -> [ConditionRisk] {
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
                    typicalOnsetAgeMonths: 60...120,
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

    /// Check if a dog has reached the screening age for any conditions
    public static func screeningsDue(for breedName: String?, sizeCategory: PuppyProfile.SizeCategory, ageMonths: Int) -> [ConditionRisk] {
        var dueScreenings: [ConditionRisk] = []

        // Check breed-specific risks
        if let breedRisks = risks(for: breedName) {
            let breedDue = breedRisks.risks.filter { risk in
                guard let screeningAge = risk.screeningRecommendedAgeMonths else { return false }
                // Due if within 2 months of screening age
                return ageMonths >= (screeningAge - 2) && ageMonths <= (screeningAge + 2)
            }
            dueScreenings.append(contentsOf: breedDue)
        }

        // Check size-based risks
        let sizeDue = sizeBasedRisks(for: sizeCategory).filter { risk in
            guard let screeningAge = risk.screeningRecommendedAgeMonths else { return false }
            return ageMonths >= (screeningAge - 2) && ageMonths <= (screeningAge + 2)
        }
        dueScreenings.append(contentsOf: sizeDue)

        return dueScreenings
    }
}
