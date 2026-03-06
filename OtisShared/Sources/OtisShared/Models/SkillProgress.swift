//
//  SkillProgress.swift
//  OtisShared
//
//  Tracks the progress of a training skill through its lifecycle,
//  including learning phases, 3D proofing levels, success rates,
//  and spaced repetition scheduling.
//

import Foundation

// MARK: - Skill Learning Phase

/// The lifecycle phase of a training skill
/// Based on professional dog training methodology (AKC, Susan Garrett, guide dog programs)
public enum SkillLearningPhase: String, Codable, CaseIterable, Sendable {
    /// Never practiced - skill not yet started
    case notStarted

    /// Learning the physical behavior through luring or shaping
    /// No verbal cue yet - dog is discovering the behavior
    case luring

    /// Pairing a verbal command and/or hand signal with the behavior
    /// Behavior is established, now adding the cue
    case addingCue

    /// Testing and reinforcing across the 3Ds: Duration, Distance, Distraction
    /// Only increase one D at a time
    case proofing

    /// Practicing in novel environments to ensure transfer
    /// Skill should work in multiple contexts
    case generalizing

    /// Skill is mastered, enters spaced repetition cycle
    /// Periodic maintenance checks with expanding intervals
    case maintaining

    /// Regression from maintenance - skill failed a check
    /// Gets highest priority until re-stabilized at 80%+
    case needsWork

    /// Display label key for the phase (localization handled by UI layer)
    public var labelKey: String {
        rawValue
    }

    /// Whether this phase is considered "active learning"
    public var isActiveLearning: Bool {
        switch self {
        case .luring, .addingCue, .proofing, .generalizing:
            return true
        default:
            return false
        }
    }

    /// Whether this skill needs maintenance reviews
    public var requiresMaintenance: Bool {
        self == .maintaining
    }

    /// Whether this skill is in regression state
    public var isRegression: Bool {
        self == .needsWork
    }

    /// Sort order for priority (lower = higher priority)
    public var priorityOrder: Int {
        switch self {
        case .needsWork: return 1      // Highest priority
        case .luring: return 2
        case .addingCue: return 3
        case .proofing: return 4
        case .generalizing: return 5
        case .maintaining: return 6
        case .notStarted: return 7     // Lowest priority
        }
    }
}

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

// MARK: - Proofing Level

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
        case practicedContexts = "practiced_contexts"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
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
}

// MARK: - Maintenance Intervals

/// Spaced repetition intervals for maintenance phase
public enum MaintenanceIntervals {
    /// Get the interval in seconds for a given tier
    public static func interval(forTier tier: Int) -> TimeInterval {
        switch tier {
        case 1: return 1 * 24 * 60 * 60        // 1 day
        case 2: return 3 * 24 * 60 * 60        // 3 days
        case 3: return 7 * 24 * 60 * 60        // 1 week
        case 4: return 14 * 24 * 60 * 60       // 2 weeks
        case 5: return 30 * 24 * 60 * 60       // 1 month
        default: return 60 * 24 * 60 * 60      // 2 months (tier 6+)
        }
    }

    /// Get the tier key for localization (UI layer handles actual localization)
    public static func tierKey(forTier tier: Int) -> String {
        switch tier {
        case 1: return "1day"
        case 2: return "3days"
        case 3: return "1week"
        case 4: return "2weeks"
        case 5: return "1month"
        default: return "2months"
        }
    }
}

// MARK: - Standard Context IDs

/// Standard context identifiers for generalization tracking
public enum StandardTrainingContext: String, CaseIterable, Sendable {
    case home = "home"
    case garden = "garden"
    case quietStreet = "quiet_street"
    case busyStreet = "busy_street"
    case park = "park"
    case indoorPublic = "indoor_public"  // Pet store, vet, etc.
    case carRide = "car_ride"
    case other = "other"

    public var labelKey: String {
        rawValue
    }

    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .garden: return "leaf.fill"
        case .quietStreet: return "road.lanes"
        case .busyStreet: return "car.fill"
        case .park: return "tree.fill"
        case .indoorPublic: return "building.2.fill"
        case .carRide: return "car.side.fill"
        case .other: return "mappin.circle.fill"
        }
    }

    /// Distraction level for this context (0-5)
    public var distractionLevel: Int {
        switch self {
        case .home: return 0
        case .garden: return 1
        case .quietStreet: return 2
        case .carRide: return 2
        case .indoorPublic: return 3
        case .park: return 4
        case .busyStreet: return 5
        case .other: return 2
        }
    }
}
