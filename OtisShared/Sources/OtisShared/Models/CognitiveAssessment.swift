//
//  CognitiveAssessment.swift
//  OtisShared
//
//  Cognitive dysfunction screening model using DISHAA framework
//  Part of Brief 05: Senior Wellness
//

import Foundation

// MARK: - CCD Category (DISHAA)

/// Categories for Canine Cognitive Dysfunction screening
public enum CCDCategory: String, Codable, CaseIterable, Sendable {
    case disorientation
    case interactions
    case sleep
    case houseSoiling
    case activity
    case anxiety

    public var label: String {
        switch self {
        case .disorientation: return Strings.SeniorWellness.ccdDisorientation
        case .interactions: return Strings.SeniorWellness.ccdInteractions
        case .sleep: return Strings.SeniorWellness.ccdSleep
        case .houseSoiling: return Strings.SeniorWellness.ccdHouseSoiling
        case .activity: return Strings.SeniorWellness.ccdActivity
        case .anxiety: return Strings.SeniorWellness.ccdAnxiety
        }
    }

    public var icon: String {
        switch self {
        case .disorientation: return "location.slash"
        case .interactions: return "person.2"
        case .sleep: return "moon.fill"
        case .houseSoiling: return "house.fill"
        case .activity: return "figure.walk"
        case .anxiety: return "exclamationmark.triangle"
        }
    }

    /// Symptoms belonging to this category
    public var symptoms: [CCDSymptom] {
        CCDSymptom.allCases.filter { $0.category == self }
    }
}

// MARK: - CCD Symptom

/// Individual symptoms for cognitive dysfunction screening
public enum CCDSymptom: String, Codable, CaseIterable, Sendable {
    // Disorientation
    case lostFamiliarPlaces
    case staresAtWalls
    case wrongSideOfDoor

    // Interactions
    case lessInterested
    case notGreeting
    case avoidsPetting

    // Sleep
    case pacesAtNight
    case sleepsMoreDay
    case wakesYouUp

    // House soiling
    case accidents
    case forgetsToSignal

    // Activity
    case lessPlayInterest
    case aimlessWandering
    case repetitiveBehaviors

    // Anxiety
    case moreAnxious
    case newFears
    case increasedVocalization

    public var category: CCDCategory {
        switch self {
        case .lostFamiliarPlaces, .staresAtWalls, .wrongSideOfDoor:
            return .disorientation
        case .lessInterested, .notGreeting, .avoidsPetting:
            return .interactions
        case .pacesAtNight, .sleepsMoreDay, .wakesYouUp:
            return .sleep
        case .accidents, .forgetsToSignal:
            return .houseSoiling
        case .lessPlayInterest, .aimlessWandering, .repetitiveBehaviors:
            return .activity
        case .moreAnxious, .newFears, .increasedVocalization:
            return .anxiety
        }
    }

    public var label: String {
        switch self {
        // Disorientation
        case .lostFamiliarPlaces:
            return Strings.SeniorWellness.symptomLostFamiliarPlaces
        case .staresAtWalls:
            return Strings.SeniorWellness.symptomStaresAtWalls
        case .wrongSideOfDoor:
            return Strings.SeniorWellness.symptomWrongSideOfDoor

        // Interactions
        case .lessInterested:
            return Strings.SeniorWellness.symptomLessInterested
        case .notGreeting:
            return Strings.SeniorWellness.symptomNotGreeting
        case .avoidsPetting:
            return Strings.SeniorWellness.symptomAvoidsPetting

        // Sleep
        case .pacesAtNight:
            return Strings.SeniorWellness.symptomPacesAtNight
        case .sleepsMoreDay:
            return Strings.SeniorWellness.symptomSleepsMoreDay
        case .wakesYouUp:
            return Strings.SeniorWellness.symptomWakesYouUp

        // House soiling
        case .accidents:
            return Strings.SeniorWellness.symptomAccidents
        case .forgetsToSignal:
            return Strings.SeniorWellness.symptomForgetsToSignal

        // Activity
        case .lessPlayInterest:
            return Strings.SeniorWellness.symptomLessPlayInterest
        case .aimlessWandering:
            return Strings.SeniorWellness.symptomAimlessWandering
        case .repetitiveBehaviors:
            return Strings.SeniorWellness.symptomRepetitiveBehaviors

        // Anxiety
        case .moreAnxious:
            return Strings.SeniorWellness.symptomMoreAnxious
        case .newFears:
            return Strings.SeniorWellness.symptomNewFears
        case .increasedVocalization:
            return Strings.SeniorWellness.symptomIncreasedVocalization
        }
    }
}

// MARK: - CCD Severity

/// Severity levels based on total symptom count
public enum CCDSeverity: String, Codable, Sendable {
    case none
    case mild
    case moderate
    case severe

    public var label: String {
        switch self {
        case .none: return Strings.SeniorWellness.severityNone
        case .mild: return Strings.SeniorWellness.severityMild
        case .moderate: return Strings.SeniorWellness.severityModerate
        case .severe: return Strings.SeniorWellness.severitySevere
        }
    }

    public var guidance: String {
        switch self {
        case .none:
            return Strings.SeniorWellness.guidanceNone
        case .mild:
            return Strings.SeniorWellness.guidanceMild
        case .moderate:
            return Strings.SeniorWellness.guidanceModerate
        case .severe:
            return Strings.SeniorWellness.guidanceSevere
        }
    }

    public var colorName: String {
        switch self {
        case .none: return "otisSuccess"
        case .mild: return "otisInfo"
        case .moderate: return "otisWarning"
        case .severe: return "otisError"
        }
    }
}

// MARK: - Cognitive Assessment

/// A single cognitive dysfunction screening assessment
public struct CognitiveAssessment: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var symptoms: Set<CCDSymptom>
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        symptoms: Set<CCDSymptom> = [],
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.symptoms = symptoms
        self.note = note
        self.createdAt = createdAt
    }

    /// Total number of symptoms checked
    public var totalScore: Int {
        symptoms.count
    }

    /// Maximum possible score (total symptoms)
    public static var maxScore: Int {
        CCDSymptom.allCases.count  // 18
    }

    /// Get symptom count for a specific category
    public func score(for category: CCDCategory) -> Int {
        symptoms.filter { $0.category == category }.count
    }

    /// Symptoms grouped by category
    public var symptomsByCategory: [CCDCategory: [CCDSymptom]] {
        Dictionary(grouping: Array(symptoms), by: { $0.category })
    }

    /// Severity based on total score
    public var severity: CCDSeverity {
        switch totalScore {
        case 0: return .none
        case 1...3: return .mild
        case 4...8: return .moderate
        default: return .severe
        }
    }

    /// Days since this assessment was recorded
    public var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// Months since this assessment was recorded
    public var monthsAgo: Int {
        Calendar.current.dateComponents([.month], from: createdAt, to: Date()).month ?? 0
    }

    /// Whether this assessment is still current (within 30 days)
    public var isCurrent: Bool {
        daysAgo <= 30
    }

    /// Whether the dog shows any cognitive symptoms
    public var hasSymptoms: Bool {
        !symptoms.isEmpty
    }
}

// MARK: - Cognitive State

/// Aggregated cognitive state for AI context
public struct CognitiveState: Codable, Sendable {
    public let latestAssessment: CognitiveAssessment?
    public let severity: CCDSeverity?
    public let assessmentCount: Int
    public let monthsSinceLastAssessment: Int?

    public init(
        latestAssessment: CognitiveAssessment? = nil,
        severity: CCDSeverity? = nil,
        assessmentCount: Int = 0,
        monthsSinceLastAssessment: Int? = nil
    ) {
        self.latestAssessment = latestAssessment
        self.severity = severity
        self.assessmentCount = assessmentCount
        self.monthsSinceLastAssessment = monthsSinceLastAssessment
    }

    /// Whether cognitive data suggests concerns
    public var hasConcerns: Bool {
        guard let severity = severity else { return false }
        return severity != .none
    }

    /// Whether a new assessment is due (monthly)
    public var assessmentDue: Bool {
        guard let months = monthsSinceLastAssessment else { return true }
        return months >= 1
    }
}
