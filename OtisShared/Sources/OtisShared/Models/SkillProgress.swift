//
//  SkillProgress.swift
//  OtisShared
//
//  Tracks the progress of a training skill through its lifecycle,
//  including learning phases, 3D proofing levels, success rates,
//  and spaced repetition scheduling.
//
//  Supporting types are in separate files:
//  - SkillLearningPhase.swift - Learning phase enum
//  - SkillProgressTypes.swift - TrainingContext, ProofingLevels, ProofingDimension, SessionOutcome
//  - SkillProgressHelpers.swift - MaintenanceIntervals, StandardTrainingContext
//

import Foundation

// MARK: - Skill Progress

/// Comprehensive progress tracking for a training skill
/// Replaces the simple MasteredSkill model with full lifecycle tracking
public struct SkillProgress: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID

    /// The skill ID this progress tracks (e.g., "sit", "come", "watchMe")
    public var skillId: String

    // MARK: - Learning Phase

    /// Current phase in the skill lifecycle
    public var phase: SkillLearningPhase

    // MARK: - 3D Proofing Progress

    /// Current levels for Duration, Distance, Distraction
    public var proofingLevels: ProofingLevels

    // MARK: - Success Tracking

    /// Confidence score based on recent success rate (0.0 - 1.0)
    /// Calculated from rolling window of recent sessions
    public var confidenceScore: Double

    /// Total successful reps logged (lifetime)
    public var totalSuccessReps: Int

    /// Total failed reps logged (lifetime)
    public var totalFailedReps: Int

    /// Recent session outcomes for rolling average (last 10 sessions)
    /// Each entry is (successReps, failedReps)
    public var recentSessions: [SessionOutcome]

    // MARK: - Spaced Repetition

    /// Current maintenance interval tier (1-6+)
    /// 1 = 1 day, 2 = 3 days, 3 = 1 week, 4 = 2 weeks, 5 = 1 month, 6+ = 2-3 months
    public var maintenanceTier: Int

    /// Next scheduled review date (nil if not in maintenance phase)
    public var nextReviewDate: Date?

    /// Last time this skill was practiced
    public var lastPracticedAt: Date?

    // MARK: - Maintenance Mode

    /// Whether this skill is in simplified maintenance mode
    /// When true, the skill bypasses the normal phase progression and uses
    /// simplified weekly reminders instead of the full training lifecycle
    public var isInMaintenanceMode: Bool

    // MARK: - Generalization Contexts

    /// Locations/environments where this skill has been practiced
    public var practicedContexts: [TrainingContext]

    // MARK: - Timestamps

    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - Computed Properties

    /// Total reps logged
    public var totalReps: Int {
        totalSuccessReps + totalFailedReps
    }

    /// Lifetime success rate
    public var lifetimeSuccessRate: Double {
        guard totalReps > 0 else { return 0.0 }
        return Double(totalSuccessReps) / Double(totalReps)
    }

    /// Whether the skill is due for a maintenance review
    public var isDueForReview: Bool {
        guard phase == .maintaining, let nextReview = nextReviewDate else {
            return false
        }
        return Date() >= nextReview
    }

    /// Number of unique contexts where skill has been practiced successfully
    public var contextCount: Int {
        practicedContexts.filter { $0.successRate >= 0.8 }.count
    }

    /// Days since last practice
    public var daysSinceLastPractice: Int? {
        guard let lastPractice = lastPracticedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: lastPractice, to: Date()).day
    }

    /// Whether the skill needs a maintenance refresh (for maintenance mode)
    /// Skills in maintenance mode should be refreshed weekly
    public var needsMaintenanceRefresh: Bool {
        guard isInMaintenanceMode else { return false }
        guard let days = daysSinceLastPractice else { return true }
        return days >= 7
    }

    /// Whether the skill is overdue for maintenance (2+ weeks without practice)
    public var isMaintenanceOverdue: Bool {
        guard isInMaintenanceMode else { return false }
        guard let days = daysSinceLastPractice else { return true }
        return days >= 14
    }

    /// Whether skill qualifies for generalization phase
    /// Requires 80%+ success rate in proofing
    public var readyForGeneralization: Bool {
        phase == .proofing &&
        confidenceScore >= 0.8 &&
        proofingLevels.overallProgress >= 0.6  // At least some progress in 3Ds
    }

    /// Whether skill qualifies for maintenance phase
    /// Requires 80%+ success rate across multiple contexts
    public var readyForMaintenance: Bool {
        phase == .generalizing &&
        confidenceScore >= 0.8 &&
        contextCount >= 3  // Successfully practiced in at least 3 contexts
    }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        skillId: String,
        phase: SkillLearningPhase = .notStarted,
        proofingLevels: ProofingLevels = ProofingLevels(),
        confidenceScore: Double = 0.0,
        totalSuccessReps: Int = 0,
        totalFailedReps: Int = 0,
        recentSessions: [SessionOutcome] = [],
        maintenanceTier: Int = 0,
        nextReviewDate: Date? = nil,
        lastPracticedAt: Date? = nil,
        isInMaintenanceMode: Bool = false,
        practicedContexts: [TrainingContext] = [],
        createdAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.skillId = skillId
        self.phase = phase
        self.proofingLevels = proofingLevels
        self.confidenceScore = confidenceScore
        self.totalSuccessReps = totalSuccessReps
        self.totalFailedReps = totalFailedReps
        self.recentSessions = recentSessions
        self.maintenanceTier = maintenanceTier
        self.nextReviewDate = nextReviewDate
        self.lastPracticedAt = lastPracticedAt
        self.isInMaintenanceMode = isInMaintenanceMode
        self.practicedContexts = practicedContexts
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
    }

    // MARK: - Coding Keys

    public enum CodingKeys: String, CodingKey {
        case id
        case skillId = "skill_id"
        case phase
        case proofingLevels = "proofing_levels"
        case confidenceScore = "confidence_score"
        case totalSuccessReps = "total_success_reps"
        case totalFailedReps = "total_failed_reps"
        case recentSessions = "recent_sessions"
        case maintenanceTier = "maintenance_tier"
        case nextReviewDate = "next_review_date"
        case lastPracticedAt = "last_practiced_at"
        case isInMaintenanceMode = "is_in_maintenance_mode"
        case practicedContexts = "practiced_contexts"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
}

// MARK: - Progress Mutation Methods

extension SkillProgress {

    /// Record a training session and update progress
    public mutating func recordSession(
        successes: Int,
        failures: Int,
        context: String? = nil
    ) {
        let outcome = SessionOutcome(
            successReps: successes,
            failedReps: failures,
            context: context
        )

        // Update totals
        totalSuccessReps += successes
        totalFailedReps += failures

        // Add to recent sessions (keep last 10)
        recentSessions.append(outcome)
        if recentSessions.count > 10 {
            recentSessions.removeFirst()
        }

        // Recalculate confidence score from recent sessions
        updateConfidenceScore()

        // Update context if provided
        if let contextId = context {
            updateContext(contextId, successes: successes, failures: failures)
        }

        // Update timestamps
        lastPracticedAt = Date()
        modifiedAt = Date()

        // Auto-advance phase if applicable
        checkPhaseProgression()
    }

    /// Update confidence score based on recent sessions
    private mutating func updateConfidenceScore() {
        guard !recentSessions.isEmpty else {
            confidenceScore = 0.0
            return
        }

        let totalSuccess = recentSessions.reduce(0) { $0 + $1.successReps }
        let totalReps = recentSessions.reduce(0) { $0 + $1.successReps + $1.failedReps }

        confidenceScore = totalReps > 0 ? Double(totalSuccess) / Double(totalReps) : 0.0
    }

    /// Update or create context entry
    private mutating func updateContext(_ contextId: String, successes: Int, failures: Int) {
        if let index = practicedContexts.firstIndex(where: { $0.id == contextId }) {
            practicedContexts[index].recordSession(successes: successes, failures: failures)
        } else {
            var newContext = TrainingContext(id: contextId)
            newContext.recordSession(successes: successes, failures: failures)
            practicedContexts.append(newContext)
        }
    }

    /// Check if skill should advance to next phase
    private mutating func checkPhaseProgression() {
        switch phase {
        case .notStarted:
            // First session starts the learning process
            if totalReps > 0 {
                phase = .luring
            }

        case .luring:
            // Advance to adding cue after consistent success
            // Research suggests ~80% success rate over 3+ sessions
            if recentSessions.count >= 3 && confidenceScore >= 0.8 {
                phase = .addingCue
            }

        case .addingCue:
            // Advance to proofing when cue is reliable
            if recentSessions.count >= 3 && confidenceScore >= 0.8 {
                phase = .proofing
            }

        case .proofing:
            // Advance to generalization when 3Ds are progressing and success is high
            if readyForGeneralization {
                phase = .generalizing
            }

        case .generalizing:
            // Advance to maintenance when practiced in multiple contexts
            if readyForMaintenance {
                advanceToMaintenance()
            }

        case .maintaining:
            // Check if maintenance review passed/failed
            // This is handled by processMaintenanceCheck()
            break

        case .needsWork:
            // Return to maintenance when back above threshold
            if confidenceScore >= 0.8 && recentSessions.count >= 2 {
                advanceToMaintenance()
            }
        }
    }

    /// Transition to maintenance phase with spaced repetition
    private mutating func advanceToMaintenance() {
        phase = .maintaining
        maintenanceTier = 1
        scheduleNextReview()
    }

    /// Process a maintenance check result
    public mutating func processMaintenanceCheck(successRate: Double) {
        if successRate >= 0.8 {
            // Success - advance to next tier
            maintenanceTier += 1
            scheduleNextReview()
        } else {
            // Failure - regression
            triggerRegression()
        }
        modifiedAt = Date()
    }

    /// Schedule the next maintenance review based on current tier
    private mutating func scheduleNextReview() {
        let interval = MaintenanceIntervals.interval(forTier: maintenanceTier)
        nextReviewDate = Date().addingTimeInterval(interval)
    }

    /// Trigger regression to "needs work" state
    public mutating func triggerRegression() {
        phase = .needsWork
        maintenanceTier = 1
        // Schedule immediate review (1 day)
        nextReviewDate = Date().addingTimeInterval(MaintenanceIntervals.interval(forTier: 1))
        modifiedAt = Date()
    }

    /// Create an updated copy with new timestamp
    public func withUpdatedTimestamp() -> SkillProgress {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }

    // MARK: - Maintenance Mode Methods

    /// Enable simplified maintenance mode for this skill
    /// This bypasses the normal phase progression and uses weekly reminders
    public mutating func enableMaintenanceMode() {
        isInMaintenanceMode = true
        phase = .maintaining
        maintenanceTier = 3  // Start at weekly tier
        lastPracticedAt = lastPracticedAt ?? Date()
        modifiedAt = Date()
    }

    /// Disable maintenance mode and return to normal phase progression
    public mutating func disableMaintenanceMode() {
        isInMaintenanceMode = false
        modifiedAt = Date()
    }

    /// Record a maintenance refresh (simplified session recording)
    public mutating func recordMaintenanceRefresh() {
        lastPracticedAt = Date()
        modifiedAt = Date()

        // If in maintenance mode, just update the timestamp
        // No need to track success/failure for simple refreshes
        if isInMaintenanceMode {
            return
        }

        // For normal maintenance phase, use regular tracking
        if phase == .maintaining {
            maintenanceTier = min(maintenanceTier + 1, 6)
            scheduleNextReview()
        }
    }
}
