//
//  SkillProgressTypes.swift
//  OtisShared
//
//  Supporting types for SkillProgress: TrainingContext, ProofingLevels,
//  ProofingDimension, SessionOutcome
//

import Foundation

// MARK: - Training Context

/// A context (location/environment) where training has occurred
public struct TrainingContext: Codable, Identifiable, Hashable, Sendable {
    public var id: String  // e.g., "home", "garden", "park", "street", "indoor_public"

    /// Last time this skill was successfully practiced in this context
    public var lastSuccessAt: Date

    /// Success rate in this specific context (0.0 - 1.0)
    public var successRate: Double

    /// Total reps attempted in this context
    public var totalReps: Int

    /// Successful reps in this context
    public var successReps: Int

    public init(
        id: String,
        lastSuccessAt: Date = Date(),
        successRate: Double = 0.0,
        totalReps: Int = 0,
        successReps: Int = 0
    ) {
        self.id = id
        self.lastSuccessAt = lastSuccessAt
        self.successRate = successRate
        self.totalReps = totalReps
        self.successReps = successReps
    }

    /// Update with new session results
    public mutating func recordSession(successes: Int, failures: Int) {
        let newReps = successes + failures
        totalReps += newReps
        successReps += successes

        // Recalculate success rate
        successRate = totalReps > 0 ? Double(successReps) / Double(totalReps) : 0.0

        if successes > 0 {
            lastSuccessAt = Date()
        }
    }
}

// MARK: - Proofing Levels

/// Levels for each of the 3Ds in proofing (0-5 scale)
public struct ProofingLevels: Codable, Equatable, Sendable {
    /// Duration level (0-5): How long the dog holds the behavior
    /// 0 = instant, 5 = 60+ seconds
    public var duration: Int

    /// Distance level (0-5): How far the handler is from the dog
    /// 0 = next to dog, 5 = 30+ feet away
    public var distance: Int

    /// Distraction level (0-5): Environmental complexity
    /// 0 = quiet room, 5 = busy public space with other dogs
    public var distraction: Int

    public init(duration: Int = 0, distance: Int = 0, distraction: Int = 0) {
        self.duration = min(max(duration, 0), 5)
        self.distance = min(max(distance, 0), 5)
        self.distraction = min(max(distraction, 0), 5)
    }

    /// Overall proofing progress (0.0 - 1.0)
    public var overallProgress: Double {
        Double(duration + distance + distraction) / 15.0
    }

    /// Whether all 3Ds are at maximum level
    public var isFullyProofed: Bool {
        duration >= 5 && distance >= 5 && distraction >= 5
    }

    /// Reset to easy when increasing one dimension
    /// "Only increase one D at a time" rule
    public mutating func resetOtherDimensions(increasing dimension: ProofingDimension) {
        switch dimension {
        case .duration:
            distance = 0
            distraction = 0
        case .distance:
            duration = 0
            distraction = 0
        case .distraction:
            duration = 0
            distance = 0
        }
    }
}

// MARK: - Proofing Dimension

/// The three dimensions of proofing
public enum ProofingDimension: String, Codable, CaseIterable, Sendable {
    case duration
    case distance
    case distraction

    public var labelKey: String {
        rawValue
    }

    public var icon: String {
        switch self {
        case .duration: return "clock.fill"
        case .distance: return "ruler.fill"
        case .distraction: return "sparkles"
        }
    }
}

// MARK: - Session Outcome

/// Records the outcome of a single training session
public struct SessionOutcome: Codable, Equatable, Sendable {
    public var successReps: Int
    public var failedReps: Int
    public var timestamp: Date
    public var context: String?

    public init(
        successReps: Int,
        failedReps: Int,
        timestamp: Date = Date(),
        context: String? = nil
    ) {
        self.successReps = successReps
        self.failedReps = failedReps
        self.timestamp = timestamp
        self.context = context
    }

    /// Success rate for this session
    public var successRate: Double {
        let total = successReps + failedReps
        guard total > 0 else { return 0.0 }
        return Double(successReps) / Double(total)
    }

    /// Whether this session met the 80% threshold
    public var metThreshold: Bool {
        successRate >= 0.8
    }
}
