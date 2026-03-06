//
//  TrainingAISummary.swift
//  OtisShared
//
//  Data model for AI/LLM integration - provides training progress snapshots
//  and event history for generating personalized training guidance.
//
//  All names are anonymized with IDs:
//  - Dog: referenced as "dog_id" (profile UUID)
//  - Household members: referenced by their UUID
//  - Locations: referenced by context ID
//

import Foundation

// MARK: - Training AI Summary

/// Complete training state snapshot for AI/LLM consumption
/// Designed for function calling - provides structured data for daily check-ins
public struct TrainingAISummary: Codable, Sendable {

    /// Profile/dog identifier (anonymized)
    public let profileId: UUID

    /// Dog's age in weeks (affects training recommendations)
    public let ageInWeeks: Int

    /// Days since puppy came home
    public let daysHome: Int

    /// Timestamp when this summary was generated
    public let generatedAt: Date

    // MARK: - Current State Snapshot

    /// Overall training statistics
    public let stats: TrainingStats

    /// Skills grouped by current phase
    public let skillsByPhase: [String: [SkillSnapshot]]

    /// Skills currently in regression (highest priority)
    public let skillsNeedingWork: [SkillSnapshot]

    /// Skills due for maintenance review
    public let skillsDueForReview: [SkillSnapshot]

    /// Active learning skills (current focus)
    public let skillsInActiveLearning: [SkillSnapshot]

    // MARK: - Recent Activity

    /// Training sessions from the last 7 days
    public let recentSessions: [SessionSummary]

    /// Recent regressions (skills that failed maintenance)
    public let recentRegressions: [RegressionEvent]

    /// Count of sessions per household member in last 7 days
    public let sessionsByMember: [String: Int]

    // MARK: - Historical Summary

    /// Total regressions by skill (for detecting patterns)
    public let regressionHistory: [String: Int]

    /// Average days between sessions (consistency metric)
    public let averageSessionGapDays: Double?

    /// Contexts explored (generalization progress)
    public let contextsExplored: [String]

    // MARK: - Recommendations

    /// Suggested next skill to focus on
    public let suggestedNextSkill: String?

    /// Skills that haven't been practiced recently
    public let staleSkilIs: [StaleSkillInfo]

    /// Whether the owner might be going too fast
    public let paceWarning: PaceWarning?
}

// MARK: - Supporting Types

/// Snapshot of a single skill's progress
public struct SkillSnapshot: Codable, Sendable {
    public let skillId: String
    public let phase: String
    public let confidenceScore: Double
    public let totalReps: Int
    public let lastPracticedAt: Date?
    public let daysSinceLastPractice: Int?
    public let maintenanceTier: Int?
    public let nextReviewDate: Date?
    public let proofingProgress: ProofingSnapshot?
    public let contextCount: Int

    public init(
        skillId: String,
        phase: String,
        confidenceScore: Double,
        totalReps: Int,
        lastPracticedAt: Date? = nil,
        daysSinceLastPractice: Int? = nil,
        maintenanceTier: Int? = nil,
        nextReviewDate: Date? = nil,
        proofingProgress: ProofingSnapshot? = nil,
        contextCount: Int = 0
    ) {
        self.skillId = skillId
        self.phase = phase
        self.confidenceScore = confidenceScore
        self.totalReps = totalReps
        self.lastPracticedAt = lastPracticedAt
        self.daysSinceLastPractice = daysSinceLastPractice
        self.maintenanceTier = maintenanceTier
        self.nextReviewDate = nextReviewDate
        self.proofingProgress = proofingProgress
        self.contextCount = contextCount
    }
}

/// 3D proofing progress snapshot
public struct ProofingSnapshot: Codable, Sendable {
    public let duration: Int  // 0-5
    public let distance: Int  // 0-5
    public let distraction: Int  // 0-5
    public let overallProgress: Double  // 0.0-1.0

    public init(duration: Int, distance: Int, distraction: Int) {
        self.duration = duration
        self.distance = distance
        self.distraction = distraction
        self.overallProgress = Double(duration + distance + distraction) / 15.0
    }
}

/// Summary of a training session for AI context
public struct SessionSummary: Codable, Sendable {
    public let skillId: String
    public let timestamp: Date
    public let successReps: Int
    public let failedReps: Int
    public let successRate: Double
    public let context: String?
    public let loggedById: String?  // Household member UUID as string

    public init(
        skillId: String,
        timestamp: Date,
        successReps: Int,
        failedReps: Int,
        context: String? = nil,
        loggedById: String? = nil
    ) {
        self.skillId = skillId
        self.timestamp = timestamp
        self.successReps = successReps
        self.failedReps = failedReps
        let total = successReps + failedReps
        self.successRate = total > 0 ? Double(successReps) / Double(total) : 0.0
        self.context = context
        self.loggedById = loggedById
    }
}

/// A regression event (skill failed maintenance check)
public struct RegressionEvent: Codable, Sendable {
    public let skillId: String
    public let occurredAt: Date
    public let previousPhase: String
    public let successRateAtFailure: Double
    public let daysSinceLastPractice: Int?
    public let recoveredAt: Date?
    public let sessionsToRecover: Int?

    public init(
        skillId: String,
        occurredAt: Date,
        previousPhase: String = "maintaining",
        successRateAtFailure: Double,
        daysSinceLastPractice: Int? = nil,
        recoveredAt: Date? = nil,
        sessionsToRecover: Int? = nil
    ) {
        self.skillId = skillId
        self.occurredAt = occurredAt
        self.previousPhase = previousPhase
        self.successRateAtFailure = successRateAtFailure
        self.daysSinceLastPractice = daysSinceLastPractice
        self.recoveredAt = recoveredAt
        self.sessionsToRecover = sessionsToRecover
    }
}

/// Info about a skill that hasn't been practiced recently
public struct StaleSkillInfo: Codable, Sendable {
    public let skillId: String
    public let daysSinceLastPractice: Int
    public let phase: String
    public let riskLevel: String  // "low", "medium", "high"

    public init(skillId: String, daysSinceLastPractice: Int, phase: String) {
        self.skillId = skillId
        self.daysSinceLastPractice = daysSinceLastPractice
        self.phase = phase

        // Determine risk based on days and phase
        switch phase {
        case "maintaining":
            self.riskLevel = daysSinceLastPractice > 30 ? "high" :
                             daysSinceLastPractice > 14 ? "medium" : "low"
        case "luring", "addingCue", "proofing", "generalizing":
            self.riskLevel = daysSinceLastPractice > 7 ? "high" :
                             daysSinceLastPractice > 3 ? "medium" : "low"
        default:
            self.riskLevel = "low"
        }
    }
}

/// Warning about training pace
public struct PaceWarning: Codable, Sendable {
    public let type: PaceWarningType
    public let details: String
    public let affectedSkills: [String]?

    public init(type: PaceWarningType, details: String, affectedSkills: [String]? = nil) {
        self.type = type
        self.details = details
        self.affectedSkills = affectedSkills
    }
}

/// Types of pace warnings
public enum PaceWarningType: String, Codable, Sendable {
    case tooFast = "too_fast"           // Multiple regressions, advancing too quickly
    case inconsistent = "inconsistent"   // Large gaps between sessions
    case tooSlow = "too_slow"           // High success but not advancing
    case overTraining = "over_training"  // Too many sessions per day
}

/// Overall training statistics
public struct TrainingStats: Codable, Sendable {
    public let totalSkillsStarted: Int
    public let skillsInLearning: Int
    public let skillsInMaintenance: Int
    public let skillsNeedingWork: Int
    public let averageConfidence: Double
    public let totalLifetimeReps: Int
    public let contextsExplored: Int
    public let totalSessions: Int
    public let sessionsLast7Days: Int

    public init(
        totalSkillsStarted: Int,
        skillsInLearning: Int,
        skillsInMaintenance: Int,
        skillsNeedingWork: Int,
        averageConfidence: Double,
        totalLifetimeReps: Int,
        contextsExplored: Int,
        totalSessions: Int = 0,
        sessionsLast7Days: Int = 0
    ) {
        self.totalSkillsStarted = totalSkillsStarted
        self.skillsInLearning = skillsInLearning
        self.skillsInMaintenance = skillsInMaintenance
        self.skillsNeedingWork = skillsNeedingWork
        self.averageConfidence = averageConfidence
        self.totalLifetimeReps = totalLifetimeReps
        self.contextsExplored = contextsExplored
        self.totalSessions = totalSessions
        self.sessionsLast7Days = sessionsLast7Days
    }
}

// MARK: - Regression Log Entry

/// Persistent log entry for tracking regressions over time
/// Stored separately from SkillProgress to maintain history even after recovery
public struct RegressionLogEntry: Codable, Identifiable, Sendable {
    public var id: UUID
    public var skillId: String
    public var occurredAt: Date
    public var previousTier: Int
    public var successRateAtFailure: Double
    public var recoveredAt: Date?
    public var sessionsToRecover: Int?

    public init(
        id: UUID = UUID(),
        skillId: String,
        occurredAt: Date = Date(),
        previousTier: Int,
        successRateAtFailure: Double,
        recoveredAt: Date? = nil,
        sessionsToRecover: Int? = nil
    ) {
        self.id = id
        self.skillId = skillId
        self.occurredAt = occurredAt
        self.previousTier = previousTier
        self.successRateAtFailure = successRateAtFailure
        self.recoveredAt = recoveredAt
        self.sessionsToRecover = sessionsToRecover
    }

    /// Duration of regression in days (nil if not yet recovered)
    public var regressionDurationDays: Int? {
        guard let recovered = recoveredAt else { return nil }
        return Calendar.current.dateComponents([.day], from: occurredAt, to: recovered).day
    }
}

// MARK: - Factory Methods

extension TrainingAISummary {

    /// Create a summary from skill progress and training events
    public static func create(
        profileId: UUID,
        ageInWeeks: Int,
        daysHome: Int,
        skillProgress: [SkillProgress],
        recentTrainingEvents: [SessionSummary],
        regressionLog: [RegressionLogEntry]
    ) -> TrainingAISummary {

        // Group skills by phase
        var skillsByPhase: [String: [SkillSnapshot]] = [:]
        var skillsNeedingWork: [SkillSnapshot] = []
        var skillsDueForReview: [SkillSnapshot] = []
        var skillsInActiveLearning: [SkillSnapshot] = []

        for progress in skillProgress {
            let snapshot = SkillSnapshot(
                skillId: progress.skillId,
                phase: progress.phase.rawValue,
                confidenceScore: progress.confidenceScore,
                totalReps: progress.totalReps,
                lastPracticedAt: progress.lastPracticedAt,
                daysSinceLastPractice: progress.lastPracticedAt.map {
                    Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0
                },
                maintenanceTier: progress.phase == .maintaining ? progress.maintenanceTier : nil,
                nextReviewDate: progress.nextReviewDate,
                proofingProgress: progress.phase == .proofing ? ProofingSnapshot(
                    duration: progress.proofingLevels.duration,
                    distance: progress.proofingLevels.distance,
                    distraction: progress.proofingLevels.distraction
                ) : nil,
                contextCount: progress.contextCount
            )

            // Add to phase group
            let phaseKey = progress.phase.rawValue
            skillsByPhase[phaseKey, default: []].append(snapshot)

            // Add to priority lists
            if progress.phase == .needsWork {
                skillsNeedingWork.append(snapshot)
            } else if progress.isDueForReview {
                skillsDueForReview.append(snapshot)
            } else if progress.phase.isActiveLearning {
                skillsInActiveLearning.append(snapshot)
            }
        }

        // Calculate stats
        let started = skillProgress.filter { $0.phase != .notStarted }
        let avgConfidence = started.isEmpty ? 0.0 :
            started.reduce(0.0) { $0 + $1.confidenceScore } / Double(started.count)

        let stats = TrainingStats(
            totalSkillsStarted: started.count,
            skillsInLearning: skillProgress.filter { $0.phase.isActiveLearning }.count,
            skillsInMaintenance: skillProgress.filter { $0.phase == .maintaining }.count,
            skillsNeedingWork: skillsNeedingWork.count,
            averageConfidence: avgConfidence,
            totalLifetimeReps: skillProgress.reduce(0) { $0 + $1.totalReps },
            contextsExplored: Set(skillProgress.flatMap { $0.practicedContexts.map { $0.id } }).count,
            totalSessions: recentTrainingEvents.count,
            sessionsLast7Days: recentTrainingEvents.filter {
                Calendar.current.dateComponents([.day], from: $0.timestamp, to: Date()).day ?? 0 <= 7
            }.count
        )

        // Sessions by member
        var sessionsByMember: [String: Int] = [:]
        for session in recentTrainingEvents {
            if let memberId = session.loggedById {
                sessionsByMember[memberId, default: 0] += 1
            }
        }

        // Regression history
        var regressionHistory: [String: Int] = [:]
        for entry in regressionLog {
            regressionHistory[entry.skillId, default: 0] += 1
        }

        // Recent regressions (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentRegressions = regressionLog
            .filter { $0.occurredAt >= thirtyDaysAgo }
            .map { entry in
                RegressionEvent(
                    skillId: entry.skillId,
                    occurredAt: entry.occurredAt,
                    successRateAtFailure: entry.successRateAtFailure,
                    recoveredAt: entry.recoveredAt,
                    sessionsToRecover: entry.sessionsToRecover
                )
            }

        // Calculate average session gap
        let sortedSessions = recentTrainingEvents.sorted { $0.timestamp < $1.timestamp }
        var totalGap: TimeInterval = 0
        var gapCount = 0
        for i in 1..<sortedSessions.count {
            let gap = sortedSessions[i].timestamp.timeIntervalSince(sortedSessions[i-1].timestamp)
            totalGap += gap
            gapCount += 1
        }
        let avgGapDays = gapCount > 0 ? (totalGap / Double(gapCount)) / (24 * 60 * 60) : nil

        // Find stale skills
        let staleSkills = skillProgress
            .filter { $0.phase != .notStarted && $0.lastPracticedAt != nil }
            .compactMap { progress -> StaleSkillInfo? in
                guard let lastPracticed = progress.lastPracticedAt else { return nil }
                let days = Calendar.current.dateComponents([.day], from: lastPracticed, to: Date()).day ?? 0
                guard days > 3 else { return nil }  // Only flag if > 3 days
                return StaleSkillInfo(
                    skillId: progress.skillId,
                    daysSinceLastPractice: days,
                    phase: progress.phase.rawValue
                )
            }
            .sorted { $0.daysSinceLastPractice > $1.daysSinceLastPractice }

        // Detect pace warnings
        var paceWarning: PaceWarning?

        // Too fast: multiple regressions in last 14 days
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentRegressionCount = regressionLog.filter { $0.occurredAt >= twoWeeksAgo }.count
        if recentRegressionCount >= 3 {
            let affectedSkills = Array(Set(regressionLog.filter { $0.occurredAt >= twoWeeksAgo }.map { $0.skillId }))
            paceWarning = PaceWarning(
                type: .tooFast,
                details: "\(recentRegressionCount) regressions in the last 2 weeks suggests advancing too quickly",
                affectedSkills: affectedSkills
            )
        }
        // Inconsistent: average gap > 3 days
        else if let gap = avgGapDays, gap > 3 {
            paceWarning = PaceWarning(
                type: .inconsistent,
                details: "Average \(Int(gap)) days between sessions. More frequent, shorter sessions are more effective."
            )
        }

        // Suggested next skill: first skill in active learning, or first due for review
        let suggestedNext = skillsNeedingWork.first?.skillId ??
                           skillsInActiveLearning.first?.skillId ??
                           skillsDueForReview.first?.skillId

        return TrainingAISummary(
            profileId: profileId,
            ageInWeeks: ageInWeeks,
            daysHome: daysHome,
            generatedAt: Date(),
            stats: stats,
            skillsByPhase: skillsByPhase,
            skillsNeedingWork: skillsNeedingWork,
            skillsDueForReview: skillsDueForReview,
            skillsInActiveLearning: skillsInActiveLearning,
            recentSessions: Array(recentTrainingEvents.prefix(20)),
            recentRegressions: recentRegressions,
            sessionsByMember: sessionsByMember,
            regressionHistory: regressionHistory,
            averageSessionGapDays: avgGapDays,
            contextsExplored: Array(Set(skillProgress.flatMap { $0.practicedContexts.map { $0.id } })),
            suggestedNextSkill: suggestedNext,
            staleSkilIs: staleSkills,
            paceWarning: paceWarning
        )
    }
}
