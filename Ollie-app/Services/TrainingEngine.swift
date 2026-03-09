//
//  TrainingEngine.swift
//  Ollie-app
//
//  Implements the smart training logic from the training-logic-briefing:
//  - Priority queue (regression > active learning > maintenance > generalization)
//  - Session composition (70% focus, 20% maintenance, 10% warm-up)
//  - Spaced repetition with expanding intervals
//  - Regression handling when skills fail maintenance checks
//

import Foundation
import OtisShared

// MARK: - Training Priority

/// Priority level for skill scheduling
public enum TrainingPriority: Int, Comparable {
    case regressionRecovery = 1   // Highest - previously mastered skill that failed
    case activeLearning = 2       // Currently being taught
    case scheduledMaintenance = 3 // Due for spaced repetition check
    case generalization = 4       // Ready to practice in new contexts
    case enrichment = 5           // Optional tricks/games

    public static func < (lhs: TrainingPriority, rhs: TrainingPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .regressionRecovery: return Strings.Training.refresherNeeded
        case .activeLearning: return Strings.Training.mainFocus
        case .scheduledMaintenance: return Strings.Training.dueForReview
        case .generalization: return Strings.Training.practiceInNewContext
        case .enrichment: return Strings.Training.warmUp
        }
    }
}

// MARK: - Prioritized Skill

/// A skill with its priority context for session planning
public struct PrioritizedSkill: Identifiable, Hashable {
    public var id: String { progress.skillId }
    public let progress: SkillProgress
    public let priority: TrainingPriority
    public let reason: String

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: PrioritizedSkill, rhs: PrioritizedSkill) -> Bool {
        lhs.id == rhs.id
    }

    /// Time since last practiced (nil if never practiced)
    public var timeSinceLastPractice: TimeInterval? {
        guard let lastPracticed = progress.lastPracticedAt else { return nil }
        return Date().timeIntervalSince(lastPracticed)
    }

    /// Days since last practiced
    public var daysSinceLastPractice: Int? {
        guard let interval = timeSinceLastPractice else { return nil }
        return Int(interval / (24 * 60 * 60))
    }
}

// MARK: - Training Session Plan

/// A generated training session plan
public struct TrainingSessionPlan {
    /// Easy warm-up skill to start (10% of session)
    public var warmup: PrioritizedSkill?

    /// Primary focus skills - new learning or regression recovery (60-70%)
    public var primaryFocus: [PrioritizedSkill]

    /// Maintenance review skills - previously mastered (20-30%)
    public var maintenance: [PrioritizedSkill]

    /// Easy finish skill (same as warm-up or another mastered skill)
    public var easyFinish: PrioritizedSkill?

    /// Estimated session duration in minutes
    public var estimatedDurationMinutes: Int {
        var total = 0
        if warmup != nil { total += 1 }
        total += primaryFocus.count * 3  // ~3 min per primary skill
        total += maintenance.count * 1   // ~1 min per maintenance skill
        if easyFinish != nil { total += 1 }
        return max(total, 5)
    }

    /// All skills in session order
    public var allSkillsInOrder: [PrioritizedSkill] {
        var skills: [PrioritizedSkill] = []
        if let warmup = warmup { skills.append(warmup) }
        skills.append(contentsOf: primaryFocus)
        skills.append(contentsOf: maintenance)
        if let finish = easyFinish { skills.append(finish) }
        return skills
    }

    /// Whether session has any skills
    public var isEmpty: Bool {
        warmup == nil && primaryFocus.isEmpty && maintenance.isEmpty
    }
}

// MARK: - Session Feedback

/// Feedback about a session result based on success rate
public enum SessionFeedback {
    case excellent      // 90%+ - ready to advance
    case good           // 80-89% - solid, confirm soon
    case needsWork      // 50-79% - stay at current level
    case stepBack       // <50% - regress to previous stage

    public static func from(successRate: Double) -> SessionFeedback {
        switch successRate {
        case 0.9...: return .excellent
        case 0.8..<0.9: return .good
        case 0.5..<0.8: return .needsWork
        default: return .stepBack
        }
    }

    public var label: String {
        switch self {
        case .excellent: return Strings.Training.excellentSession
        case .good: return Strings.Training.goodProgress
        case .needsWork: return Strings.Training.needsMoreWork
        case .stepBack: return Strings.Training.stepBackRecommended
        }
    }

    public var shouldAdvance: Bool {
        self == .excellent || self == .good
    }
}

// MARK: - Training Engine

/// The core training logic engine
/// Implements priority queue, session composition, and spaced repetition
public class TrainingEngine {

    // MARK: - Priority Queue

    /// Get all skills sorted by priority
    /// Priority order: regression > active learning > maintenance > generalization
    public static func prioritizedSkills(
        from progressList: [SkillProgress],
        currentDate: Date = Date()
    ) -> [PrioritizedSkill] {
        var prioritized: [PrioritizedSkill] = []

        for progress in progressList {
            let (priority, reason) = determinePriority(for: progress, currentDate: currentDate)

            // Skip not started skills - they're not in the priority queue yet
            guard progress.phase != .notStarted else { continue }

            prioritized.append(PrioritizedSkill(
                progress: progress,
                priority: priority,
                reason: reason
            ))
        }

        // Sort by priority (lower raw value = higher priority)
        return prioritized.sorted { $0.priority < $1.priority }
    }

    /// Determine priority and reason for a single skill
    private static func determinePriority(
        for progress: SkillProgress,
        currentDate: Date
    ) -> (TrainingPriority, String) {
        switch progress.phase {
        case .needsWork:
            return (.regressionRecovery, Strings.Training.skillNeedsRefresher)

        case .luring, .addingCue, .proofing:
            return (.activeLearning, Strings.Training.mainFocus)

        case .generalizing:
            return (.generalization, Strings.Training.practiceInNewContext)

        case .maintaining:
            if let nextReview = progress.nextReviewDate, nextReview <= currentDate {
                return (.scheduledMaintenance, Strings.Training.dueForReview)
            } else {
                // Not due yet - low priority
                return (.enrichment, Strings.Training.warmUp)
            }

        case .notStarted:
            return (.enrichment, "")
        }
    }

    // MARK: - Session Composition

    /// Generate a training session plan based on the 70/30 rule
    /// - Parameters:
    ///   - progressList: All skill progress records
    ///   - targetDurationMinutes: Target session length (default 5-10 min)
    /// - Returns: A structured session plan
    public static func generateSessionPlan(
        from progressList: [SkillProgress],
        targetDurationMinutes: Int = 10
    ) -> TrainingSessionPlan {
        let prioritized = prioritizedSkills(from: progressList)

        // Categorize skills
        let regressionSkills = prioritized.filter { $0.priority == .regressionRecovery }
        let activeSkills = prioritized.filter { $0.priority == .activeLearning }
        let maintenanceSkills = prioritized.filter { $0.priority == .scheduledMaintenance }
        let easySkills = prioritized.filter {
            $0.progress.phase == .maintaining && $0.progress.confidenceScore >= 0.9
        }

        var plan = TrainingSessionPlan(
            warmup: nil,
            primaryFocus: [],
            maintenance: [],
            easyFinish: nil
        )

        // 1. Warm-up (10%): Easy mastered skill
        plan.warmup = easySkills.first

        // 2. Primary focus (60-70%): Regression recovery OR active learning
        // "Regression trumps progression" rule
        if !regressionSkills.isEmpty {
            // Focus on regressed skills first
            plan.primaryFocus = Array(regressionSkills.prefix(2))
        } else {
            // Normal active learning
            plan.primaryFocus = Array(activeSkills.prefix(2))
        }

        // 3. Maintenance review (20-30%): Due for spaced repetition
        // Take 1-3 skills based on session length
        let maintenanceCount = targetDurationMinutes >= 10 ? 3 : (targetDurationMinutes >= 7 ? 2 : 1)
        plan.maintenance = Array(maintenanceSkills.prefix(maintenanceCount))

        // 4. Easy finish: Same as warm-up or different easy skill
        if let warmup = plan.warmup {
            // Use a different easy skill if available
            plan.easyFinish = easySkills.first(where: { $0.id != warmup.id }) ?? warmup
        } else if let anyMastered = prioritized.first(where: { $0.progress.phase == .maintaining }) {
            plan.easyFinish = anyMastered
        }

        return plan
    }

    // MARK: - Skills Due for Review

    /// Get skills that are due for maintenance review
    public static func skillsDueForReview(
        from progressList: [SkillProgress],
        currentDate: Date = Date()
    ) -> [SkillProgress] {
        progressList.filter { progress in
            progress.phase == .maintaining &&
            progress.isDueForReview
        }.sorted {
            // Sort by most overdue first
            ($0.nextReviewDate ?? Date.distantFuture) < ($1.nextReviewDate ?? Date.distantFuture)
        }
    }

    // MARK: - Skills in Regression

    /// Get skills that need urgent attention (regression state)
    public static func skillsNeedingWork(from progressList: [SkillProgress]) -> [SkillProgress] {
        progressList.filter { $0.phase == .needsWork }
    }

    // MARK: - Process Session Result

    /// Process the outcome of a training session and update skill progress
    /// - Parameters:
    ///   - progress: The skill progress to update
    ///   - successReps: Number of successful repetitions
    ///   - failedReps: Number of failed repetitions
    ///   - context: Optional training context (location)
    /// - Returns: Updated progress and feedback
    public static func processSessionResult(
        progress: inout SkillProgress,
        successReps: Int,
        failedReps: Int,
        context: String? = nil
    ) -> SessionFeedback {
        // Record the session
        progress.recordSession(successes: successReps, failures: failedReps, context: context)

        // Calculate feedback
        let totalReps = successReps + failedReps
        let successRate = totalReps > 0 ? Double(successReps) / Double(totalReps) : 0.0

        return SessionFeedback.from(successRate: successRate)
    }

    // MARK: - Maintenance Check

    /// Process a maintenance check result
    /// If failed (<80%), triggers regression
    public static func processMaintenanceCheck(
        progress: inout SkillProgress,
        successReps: Int,
        failedReps: Int
    ) -> Bool {
        let totalReps = successReps + failedReps
        let successRate = totalReps > 0 ? Double(successReps) / Double(totalReps) : 0.0

        progress.processMaintenanceCheck(successRate: successRate)

        return successRate >= 0.8
    }

    // MARK: - Context Suggestions

    /// Suggest new contexts for generalization practice
    public static func suggestNewContexts(for progress: SkillProgress) -> [StandardTrainingContext] {
        let practicedIds = Set(progress.practicedContexts.map { $0.id })

        return StandardTrainingContext.allCases
            .filter { !practicedIds.contains($0.rawValue) }
            .sorted { $0.distractionLevel < $1.distractionLevel }  // Suggest easier ones first
    }

    // MARK: - Session Duration Recommendations

    /// Get recommended session duration based on puppy age in weeks
    public static func recommendedSessionDuration(puppyAgeWeeks: Int) -> (min: Int, max: Int) {
        switch puppyAgeWeeks {
        case 0..<12:
            return (3, 5)    // Young puppies: very short
        case 12..<24:
            return (5, 8)    // 3-6 months: slightly longer
        case 24..<52:
            return (8, 12)   // 6-12 months: moderate
        default:
            return (10, 15)  // Adults: full sessions
        }
    }

    /// Get recommended sessions per day based on puppy age
    public static func recommendedSessionsPerDay(puppyAgeWeeks: Int) -> Int {
        switch puppyAgeWeeks {
        case 0..<12: return 5  // Many short sessions
        case 12..<24: return 4
        case 24..<52: return 3
        default: return 2
        }
    }

    // MARK: - Next Review Summary

    /// Get a summary of upcoming maintenance reviews
    public static func nextReviewsSummary(
        from progressList: [SkillProgress],
        days: Int = 7
    ) -> [(skillId: String, dueDate: Date, isOverdue: Bool)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        let now = Date()

        return progressList
            .filter { $0.phase == .maintaining && $0.nextReviewDate != nil }
            .compactMap { progress -> (String, Date, Bool)? in
                guard let dueDate = progress.nextReviewDate, dueDate <= cutoff else { return nil }
                return (progress.skillId, dueDate, dueDate < now)
            }
            .sorted { $0.1 < $1.1 }
    }
}

// MARK: - Training Statistics

extension TrainingEngine {

    /// Calculate overall training statistics
    public struct TrainingStats {
        public var totalSkillsStarted: Int
        public var skillsInLearning: Int
        public var skillsInMaintenance: Int
        public var skillsNeedingWork: Int
        public var averageConfidence: Double
        public var totalLifetimeReps: Int
        public var contextsExplored: Int
    }

    public static func calculateStats(from progressList: [SkillProgress]) -> TrainingStats {
        let started = progressList.filter { $0.phase != .notStarted }
        let learning = progressList.filter { $0.phase.isActiveLearning }
        let maintaining = progressList.filter { $0.phase == .maintaining }
        let needsWork = progressList.filter { $0.phase == .needsWork }

        let totalConfidence = started.reduce(0.0) { $0 + $1.confidenceScore }
        let avgConfidence = started.isEmpty ? 0.0 : totalConfidence / Double(started.count)

        let totalReps = progressList.reduce(0) { $0 + $1.totalReps }

        let allContexts = Set(progressList.flatMap { $0.practicedContexts.map { $0.id } })

        return TrainingStats(
            totalSkillsStarted: started.count,
            skillsInLearning: learning.count,
            skillsInMaintenance: maintaining.count,
            skillsNeedingWork: needsWork.count,
            averageConfidence: avgConfidence,
            totalLifetimeReps: totalReps,
            contextsExplored: allContexts.count
        )
    }
}
