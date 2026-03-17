//
//  QualityOfLifeAssessment.swift
//  OtisShared
//
//  Quality of Life assessment model using HHHHHMM scale
//  Part of Brief 05: Senior Wellness
//

import Foundation

// MARK: - QoL Category

/// Categories for Quality of Life assessment (HHHHHMM scale)
public enum QoLCategory: String, Codable, CaseIterable, Sendable {
    case hurt
    case hunger
    case hydration
    case hygiene
    case happiness
    case mobility
    case moreDays

    public var label: String {
        switch self {
        case .hurt: return Strings.SeniorWellness.qolHurt
        case .hunger: return Strings.SeniorWellness.qolHunger
        case .hydration: return Strings.SeniorWellness.qolHydration
        case .hygiene: return Strings.SeniorWellness.qolHygiene
        case .happiness: return Strings.SeniorWellness.qolHappiness
        case .mobility: return Strings.SeniorWellness.qolMobility
        case .moreDays: return Strings.SeniorWellness.qolMoreDays
        }
    }

    public var question: String {
        switch self {
        case .hurt: return Strings.SeniorWellness.qolQuestionHurt
        case .hunger: return Strings.SeniorWellness.qolQuestionHunger
        case .hydration: return Strings.SeniorWellness.qolQuestionHydration
        case .hygiene: return Strings.SeniorWellness.qolQuestionHygiene
        case .happiness: return Strings.SeniorWellness.qolQuestionHappiness
        case .mobility: return Strings.SeniorWellness.qolQuestionMobility
        case .moreDays: return Strings.SeniorWellness.qolQuestionMoreDays
        }
    }

    public var icon: String {
        switch self {
        case .hurt: return "bandage.fill"
        case .hunger: return "fork.knife"
        case .hydration: return "drop.fill"
        case .hygiene: return "sparkles"
        case .happiness: return "heart.fill"
        case .mobility: return "figure.walk"
        case .moreDays: return "sun.max.fill"
        }
    }

    public var lowLabel: String {
        switch self {
        case .hurt: return Strings.SeniorWellness.qolHurtLow
        case .hunger: return Strings.SeniorWellness.qolHungerLow
        case .hydration: return Strings.SeniorWellness.qolHydrationLow
        case .hygiene: return Strings.SeniorWellness.qolHygieneLow
        case .happiness: return Strings.SeniorWellness.qolHappinessLow
        case .mobility: return Strings.SeniorWellness.qolMobilityLow
        case .moreDays: return Strings.SeniorWellness.qolMoreDaysLow
        }
    }

    public var highLabel: String {
        switch self {
        case .hurt: return Strings.SeniorWellness.qolHurtHigh
        case .hunger: return Strings.SeniorWellness.qolHungerHigh
        case .hydration: return Strings.SeniorWellness.qolHydrationHigh
        case .hygiene: return Strings.SeniorWellness.qolHygieneHigh
        case .happiness: return Strings.SeniorWellness.qolHappinessHigh
        case .mobility: return Strings.SeniorWellness.qolMobilityHigh
        case .moreDays: return Strings.SeniorWellness.qolMoreDaysHigh
        }
    }
}

// MARK: - QoL Interpretation

/// Interpretation of overall quality of life score
public enum QoLInterpretation: String, Codable, Sendable {
    case good
    case acceptable
    case compromised
    case poor

    public var label: String {
        switch self {
        case .good: return Strings.SeniorWellness.qolInterpretationGood
        case .acceptable: return Strings.SeniorWellness.qolInterpretationAcceptable
        case .compromised: return Strings.SeniorWellness.qolInterpretationCompromised
        case .poor: return Strings.SeniorWellness.qolInterpretationPoor
        }
    }

    public var message: String {
        switch self {
        case .good:
            return Strings.SeniorWellness.qolMessageGood
        case .acceptable:
            return Strings.SeniorWellness.qolMessageAcceptable
        case .compromised:
            return Strings.SeniorWellness.qolMessageCompromised
        case .poor:
            return Strings.SeniorWellness.qolMessagePoor
        }
    }

    public var colorName: String {
        switch self {
        case .good: return "otisSuccess"
        case .acceptable: return "otisInfo"
        case .compromised: return "otisWarning"
        case .poor: return "otisError"
        }
    }

    public var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .acceptable: return "minus.circle.fill"
        case .compromised: return "exclamationmark.circle.fill"
        case .poor: return "xmark.circle.fill"
        }
    }
}

// MARK: - Quality of Life Assessment

/// A comprehensive quality of life assessment
public struct QualityOfLifeAssessment: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var hurt: Int        // 1-10 (10 = no pain, well managed)
    public var hunger: Int      // 1-10 (10 = eating well)
    public var hydration: Int   // 1-10 (10 = drinking well)
    public var hygiene: Int     // 1-10 (10 = can be kept clean)
    public var happiness: Int   // 1-10 (10 = showing joy)
    public var mobility: Int    // 1-10 (10 = moving well)
    public var moreDays: Int    // 1-10 (10 = mostly good days)
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        hurt: Int = 5,
        hunger: Int = 5,
        hydration: Int = 5,
        hygiene: Int = 5,
        happiness: Int = 5,
        mobility: Int = 5,
        moreDays: Int = 5,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.hurt = Self.clampScore(hurt)
        self.hunger = Self.clampScore(hunger)
        self.hydration = Self.clampScore(hydration)
        self.hygiene = Self.clampScore(hygiene)
        self.happiness = Self.clampScore(happiness)
        self.mobility = Self.clampScore(mobility)
        self.moreDays = Self.clampScore(moreDays)
        self.note = note
        self.createdAt = createdAt
    }

    private static func clampScore(_ score: Int) -> Int {
        max(1, min(10, score))
    }

    /// Get score for a specific category
    public func score(for category: QoLCategory) -> Int {
        switch category {
        case .hurt: return hurt
        case .hunger: return hunger
        case .hydration: return hydration
        case .hygiene: return hygiene
        case .happiness: return happiness
        case .mobility: return mobility
        case .moreDays: return moreDays
        }
    }

    /// Total score across all categories
    public var totalScore: Int {
        hurt + hunger + hydration + hygiene + happiness + mobility + moreDays
    }

    /// Maximum possible score
    public static var maxScore: Int { 70 }

    /// Score as a percentage (0.0 - 1.0)
    public var scorePercentage: Double {
        Double(totalScore) / Double(Self.maxScore)
    }

    /// Overall interpretation based on score percentage
    public var interpretation: QoLInterpretation {
        switch scorePercentage {
        case 0.8...: return .good
        case 0.5..<0.8: return .acceptable
        case 0.35..<0.5: return .compromised
        default: return .poor
        }
    }

    /// Categories with concerning scores (≤ 3)
    public var concerningCategories: [QoLCategory] {
        QoLCategory.allCases.filter { score(for: $0) <= 3 }
    }

    /// Categories with good scores (≥ 8)
    public var strongCategories: [QoLCategory] {
        QoLCategory.allCases.filter { score(for: $0) >= 8 }
    }

    /// Days since this assessment was recorded
    public var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// Whether this assessment is still current (within 30 days)
    public var isCurrent: Bool {
        daysAgo <= 30
    }

    /// Whether there are any concerning areas
    public var hasConcerns: Bool {
        !concerningCategories.isEmpty || interpretation == .compromised || interpretation == .poor
    }
}

// MARK: - QoL State

/// Aggregated quality of life state for AI context
public struct QoLState: Codable, Sendable {
    public let latestAssessment: QualityOfLifeAssessment?
    public let interpretation: QoLInterpretation?
    public let assessmentCount: Int
    public let daysSinceLastAssessment: Int?

    public init(
        latestAssessment: QualityOfLifeAssessment? = nil,
        interpretation: QoLInterpretation? = nil,
        assessmentCount: Int = 0,
        daysSinceLastAssessment: Int? = nil
    ) {
        self.latestAssessment = latestAssessment
        self.interpretation = interpretation
        self.assessmentCount = assessmentCount
        self.daysSinceLastAssessment = daysSinceLastAssessment
    }

    /// Whether QoL data suggests concerns
    public var hasConcerns: Bool {
        guard let interpretation = interpretation else { return false }
        return interpretation == .compromised || interpretation == .poor
    }

    /// Whether a new assessment is due (monthly)
    public var assessmentDue: Bool {
        guard let days = daysSinceLastAssessment else { return true }
        return days >= 30
    }
}
