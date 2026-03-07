//
//  AIContext+Training.swift
//  Ollie-app
//
//  Training AI context components: Training Progress, Training Detail, Socialization
//

import Foundation
import OtisShared

// MARK: - Training Progress Context

/// Skills training progress summary.
struct TrainingProgressContext: AIContextComponent {
    static let componentKey = "training"
    static let estimatedTokens = 200

    let skillsStarted: Int
    let skillsInLearning: Int
    let skillsInMaintenance: Int
    let skillsNeedingWork: Int
    let averageConfidence: Double
    let sessionsLast7Days: Int
    let averageSessionGapDays: Double?
    let recentRegressionCount: Int
    let skillsDueForReview: Int
    let paceWarning: String?
    let suggestedNextSkill: String?

    init(summary: TrainingAISummary) {
        self.skillsStarted = summary.stats.totalSkillsStarted
        self.skillsInLearning = summary.stats.skillsInLearning
        self.skillsInMaintenance = summary.stats.skillsInMaintenance
        self.skillsNeedingWork = summary.stats.skillsNeedingWork
        self.averageConfidence = summary.stats.averageConfidence
        self.sessionsLast7Days = summary.stats.sessionsLast7Days
        self.averageSessionGapDays = summary.averageSessionGapDays
        self.recentRegressionCount = summary.recentRegressions.count
        self.skillsDueForReview = summary.skillsDueForReview.count
        self.paceWarning = summary.paceWarning?.type.rawValue
        self.suggestedNextSkill = summary.suggestedNextSkill
    }

    init() {
        self.skillsStarted = 0
        self.skillsInLearning = 0
        self.skillsInMaintenance = 0
        self.skillsNeedingWork = 0
        self.averageConfidence = 0
        self.sessionsLast7Days = 0
        self.averageSessionGapDays = nil
        self.recentRegressionCount = 0
        self.skillsDueForReview = 0
        self.paceWarning = nil
        self.suggestedNextSkill = nil
    }
}

// MARK: - Training Detail Context

/// Detailed training context for skill-specific AI guidance.
struct TrainingDetailContext: AIContextComponent {
    static let componentKey = "training_detail"
    static let estimatedTokens = 400

    let skillsByPhase: [String: [SkillDetail]]
    let recentSessions: [SessionDetail]
    let regressionHistory: [String: Int]
    let staleSkills: [StaleSkillDetail]
    let contextsExploredCount: Int

    struct SkillDetail: Codable, Sendable {
        let skillId: String
        let confidence: Double
        let totalReps: Int
        let daysSinceLastPractice: Int?
        let maintenanceTier: Int?
        let proofingProgress: Double?
    }

    struct SessionDetail: Codable, Sendable {
        let skillId: String
        let daysAgo: Int
        let successRate: Double
        let context: String?
    }

    struct StaleSkillDetail: Codable, Sendable {
        let skillId: String
        let daysSinceLastPractice: Int
        let phase: String
        let riskLevel: String
    }

    init(summary: TrainingAISummary) {
        var byPhase: [String: [SkillDetail]] = [:]
        for (phase, snapshots) in summary.skillsByPhase {
            byPhase[phase] = snapshots.map { snapshot in
                SkillDetail(
                    skillId: snapshot.skillId,
                    confidence: snapshot.confidenceScore,
                    totalReps: snapshot.totalReps,
                    daysSinceLastPractice: snapshot.daysSinceLastPractice,
                    maintenanceTier: snapshot.maintenanceTier,
                    proofingProgress: snapshot.proofingProgress?.overallProgress
                )
            }
        }
        self.skillsByPhase = byPhase

        let now = Date()
        self.recentSessions = summary.recentSessions.prefix(10).map { session in
            let daysAgo = Calendar.current.dateComponents([.day], from: session.timestamp, to: now).day ?? 0
            return SessionDetail(
                skillId: session.skillId,
                daysAgo: daysAgo,
                successRate: session.successRate,
                context: session.context
            )
        }

        self.regressionHistory = summary.regressionHistory

        self.staleSkills = summary.staleSkilIs.map { stale in
            StaleSkillDetail(
                skillId: stale.skillId,
                daysSinceLastPractice: stale.daysSinceLastPractice,
                phase: stale.phase,
                riskLevel: stale.riskLevel
            )
        }

        self.contextsExploredCount = summary.contextsExplored.count
    }
}

// MARK: - Socialization Context

/// Socialization progress and window status.
struct SocializationContext: AIContextComponent {
    static let componentKey = "socialization"
    static let estimatedTokens = 100

    let inCriticalWindow: Bool
    let weeksRemainingInWindow: Int?
    let overallProgress: Double
    let exposuresThisWeek: Int
    let lowExposureCategories: [String]
    let completedCategories: Int

    init(profile: PuppyProfile, socializationProgress: SocializationProgress?) {
        let ageWeeks = profile.ageInWeeks
        self.inCriticalWindow = ageWeeks >= 8 && ageWeeks <= 16

        if inCriticalWindow {
            self.weeksRemainingInWindow = max(0, 16 - ageWeeks)
        } else {
            self.weeksRemainingInWindow = nil
        }

        if let progress = socializationProgress {
            self.overallProgress = progress.overallProgress
            self.exposuresThisWeek = progress.exposuresThisWeek
            self.lowExposureCategories = progress.lowExposureCategories
            self.completedCategories = progress.completedCategories
        } else {
            self.overallProgress = 0
            self.exposuresThisWeek = 0
            self.lowExposureCategories = []
            self.completedCategories = 0
        }
    }
}

/// Lightweight progress info for socialization
struct SocializationProgress {
    let overallProgress: Double
    let exposuresThisWeek: Int
    let lowExposureCategories: [String]
    let completedCategories: Int
}
