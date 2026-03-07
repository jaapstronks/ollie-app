//
//  MobilityAssessment.swift
//  OtisShared
//
//  Mobility assessment model for senior dog wellness tracking
//  Part of Brief 05: Senior Wellness
//

import Foundation

// MARK: - Mobility Observation

/// Observable mobility issues for senior dogs
public enum MobilityObservation: String, Codable, CaseIterable, Sendable {
    case stiffAfterRest
    case difficultyRising
    case reluctantStairs
    case bunnyHopping
    case limping
    case slowerWalks
    case troubleSlipperyFloors
    case collapsingRearLegs
    case draggingPaws

    public var label: String {
        switch self {
        case .stiffAfterRest: return Strings.SeniorWellness.observationStiffAfterRest
        case .difficultyRising: return Strings.SeniorWellness.observationDifficultyRising
        case .reluctantStairs: return Strings.SeniorWellness.observationReluctantStairs
        case .bunnyHopping: return Strings.SeniorWellness.observationBunnyHopping
        case .limping: return Strings.SeniorWellness.observationLimping
        case .slowerWalks: return Strings.SeniorWellness.observationSlowerWalks
        case .troubleSlipperyFloors: return Strings.SeniorWellness.observationTroubleSlipperyFloors
        case .collapsingRearLegs: return Strings.SeniorWellness.observationCollapsingRearLegs
        case .draggingPaws: return Strings.SeniorWellness.observationDraggingPaws
        }
    }

    public var icon: String {
        switch self {
        case .stiffAfterRest: return "bed.double.fill"
        case .difficultyRising: return "arrow.up.circle"
        case .reluctantStairs: return "stairs"
        case .bunnyHopping: return "hare.fill"
        case .limping: return "figure.walk"
        case .slowerWalks: return "tortoise.fill"
        case .troubleSlipperyFloors: return "exclamationmark.triangle"
        case .collapsingRearLegs: return "arrow.down.circle"
        case .draggingPaws: return "pawprint.fill"
        }
    }
}

// MARK: - Mobility Score Description

/// Descriptions for mobility scores 1-5
public enum MobilityScoreLevel: Int, Codable, CaseIterable, Sendable {
    case cannotWalkWithoutHelp = 1
    case strugglesSignificantly = 2
    case moderateDifficulty = 3
    case mildStiffness = 4
    case movingWellForAge = 5

    public var label: String {
        switch self {
        case .cannotWalkWithoutHelp: return Strings.SeniorWellness.mobilityLevel1
        case .strugglesSignificantly: return Strings.SeniorWellness.mobilityLevel2
        case .moderateDifficulty: return Strings.SeniorWellness.mobilityLevel3
        case .mildStiffness: return Strings.SeniorWellness.mobilityLevel4
        case .movingWellForAge: return Strings.SeniorWellness.mobilityLevel5
        }
    }

    public var shortLabel: String {
        switch self {
        case .cannotWalkWithoutHelp: return Strings.SeniorWellness.mobilityLevelShort1
        case .strugglesSignificantly: return Strings.SeniorWellness.mobilityLevelShort2
        case .moderateDifficulty: return Strings.SeniorWellness.mobilityLevelShort3
        case .mildStiffness: return Strings.SeniorWellness.mobilityLevelShort4
        case .movingWellForAge: return Strings.SeniorWellness.mobilityLevelShort5
        }
    }
}

// MARK: - Mobility Assessment

/// A single mobility assessment for tracking senior dog wellness
public struct MobilityAssessment: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var score: Int  // 1-5
    public var observations: [MobilityObservation]
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        score: Int,
        observations: [MobilityObservation] = [],
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.score = max(1, min(5, score))
        self.observations = observations
        self.note = note
        self.createdAt = createdAt
    }

    /// Get the mobility level enum for this score
    public var level: MobilityScoreLevel? {
        MobilityScoreLevel(rawValue: score)
    }

    /// Whether this indicates struggling mobility (1-2)
    public var isStruggling: Bool { score <= 2 }

    /// Whether this indicates moderate issues (3)
    public var isModerate: Bool { score == 3 }

    /// Whether this indicates good mobility (4-5)
    public var isGood: Bool { score >= 4 }

    /// Days since this assessment was recorded
    public var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// Whether this assessment is still fresh (within 7 days)
    public var isFresh: Bool {
        daysAgo <= 7
    }

    /// Score description
    public var scoreDescription: String {
        level?.shortLabel ?? Strings.SeniorWellness.mobilityLevelShort3
    }
}

// MARK: - Mobility Trend

/// Trend direction for mobility over time
public enum MobilityTrend: String, Codable, Sendable {
    case improving
    case stable
    case declining

    public var label: String {
        switch self {
        case .improving: return Strings.SeniorWellness.trendImproving
        case .stable: return Strings.SeniorWellness.trendStable
        case .declining: return Strings.SeniorWellness.trendDeclining
        }
    }

    public var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    public var colorName: String {
        switch self {
        case .improving: return "otisSuccess"
        case .stable: return "otisInfo"
        case .declining: return "otisWarning"
        }
    }
}

// MARK: - Mobility State

/// Aggregated mobility state for AI context
public struct MobilityState: Codable, Sendable {
    public let latestAssessment: MobilityAssessment?
    public let trend: MobilityTrend?
    public let averageScore: Double?
    public let assessmentCount: Int
    public let stiffMorningsThisWeek: Int

    public init(
        latestAssessment: MobilityAssessment? = nil,
        trend: MobilityTrend? = nil,
        averageScore: Double? = nil,
        assessmentCount: Int = 0,
        stiffMorningsThisWeek: Int = 0
    ) {
        self.latestAssessment = latestAssessment
        self.trend = trend
        self.averageScore = averageScore
        self.assessmentCount = assessmentCount
        self.stiffMorningsThisWeek = stiffMorningsThisWeek
    }

    /// Whether mobility data suggests concerns
    public var hasConcerns: Bool {
        guard let latest = latestAssessment else { return false }
        return latest.isStruggling || trend == .declining || stiffMorningsThisWeek >= 3
    }
}
