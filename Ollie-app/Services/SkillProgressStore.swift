//
//  SkillProgressStore.swift
//  Ollie-app
//
//  Manages skill progress data with Core Data storage and CloudKit sync.
//  Replaces the simple MasteredSkill tracking with full lifecycle management.
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages skill progress tracking with Core Data persistence
@MainActor
final class SkillProgressStore: BaseStore, ProfileAccessible {

    // MARK: - State

    private(set) var skillProgress: [SkillProgress] = []
    private(set) var isLoading: Bool = true

    // MARK: - ProfileAccessible

    weak var profileStore: ProfileStore?

    // MARK: - Computed Properties

    /// Dictionary lookup for quick access by skill ID
    var progressBySkillId: [String: SkillProgress] {
        Dictionary(uniqueKeysWithValues: skillProgress.map { ($0.skillId, $0) })
    }

    /// Get progress for a specific skill (creates default if not found)
    func progress(for skillId: String) -> SkillProgress {
        if let existing = progressBySkillId[skillId] {
            return existing
        }
        // Return a default "not started" progress
        return SkillProgress(skillId: skillId)
    }

    /// Skills currently in regression (needs work)
    var skillsNeedingWork: [SkillProgress] {
        skillProgress.filter { $0.phase == .needsWork }
    }

    /// Skills due for maintenance review
    var skillsDueForReview: [SkillProgress] {
        TrainingEngine.skillsDueForReview(from: skillProgress)
    }

    /// Skills in active learning phases
    var skillsInActiveLearning: [SkillProgress] {
        skillProgress.filter { $0.phase.isActiveLearning }
    }

    /// Skills in maintenance phase
    var skillsInMaintenance: [SkillProgress] {
        skillProgress.filter { $0.phase == .maintaining }
    }

    /// Count of skills that have been started
    var startedSkillCount: Int {
        skillProgress.filter { $0.phase != .notStarted }.count
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "SkillProgressStore")
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        // If we have a profile, load profile-scoped data and migrate orphans
        if let profile = getCurrentProfile() {
            // First, migrate any orphaned records to this profile
            migrateOrphanedRecords(to: profile)

            // Load profile-scoped progress
            let cdProgress = CDSkillProgress.fetchAll(for: profile, in: viewContext)
            skillProgress = cdProgress.compactMap { $0.toSkillProgress() }
            logger.debug("Loaded \(self.skillProgress.count) skill progress records for profile")
        } else {
            // Fallback to loading all records (for backwards compatibility during init)
            let cdProgress = CDSkillProgress.fetchAll(in: viewContext)
            skillProgress = cdProgress.compactMap { $0.toSkillProgress() }
            logger.debug("Loaded \(self.skillProgress.count) skill progress records (no profile)")
        }
    }

    /// Migrate orphaned skill progress records to the current profile
    /// This ensures existing local-only records get synced to CloudKit
    private func migrateOrphanedRecords(to profile: CDPuppyProfile) {
        let orphaned = CDSkillProgress.fetchOrphaned(in: viewContext)
        guard !orphaned.isEmpty else { return }

        logger.info("Migrating \(orphaned.count) orphaned skill progress records to profile")

        for cdProgress in orphaned {
            cdProgress.profile = profile
        }

        performSave(operation: "Migrate orphaned skill progress to profile") {
            // No additional state update needed
        }
    }

    // MARK: - CRUD Operations

    /// Get or create progress for a skill
    func getOrCreateProgress(for skillId: String) -> SkillProgress {
        if let existing = progressBySkillId[skillId] {
            return existing
        }

        // Create new progress
        let newProgress = SkillProgress(skillId: skillId)
        saveProgress(newProgress)
        return newProgress
    }

    /// Save or update skill progress
    func saveProgress(_ progress: SkillProgress) {
        // Check if exists in Core Data
        if let cdProgress = CDSkillProgress.fetch(bySkillId: progress.skillId, in: viewContext) {
            cdProgress.update(from: progress)
            // Ensure profile link exists (for migration of existing records)
            if cdProgress.profile == nil, let profile = getCurrentProfile() {
                cdProgress.profile = profile
            }
        } else {
            // Create new record linked to profile for CloudKit sync
            if let profile = getCurrentProfile() {
                _ = CDSkillProgress.create(from: progress, profile: profile, in: viewContext)
            } else {
                // Fallback: create without profile (will be migrated later)
                logger.warning("Creating skill progress without profile link - will need migration")
                _ = CDSkillProgress.create(from: progress, in: viewContext)
            }
        }

        performSave(operation: "Save skill progress: \(progress.skillId)") {
            // Update local cache
            if let index = skillProgress.firstIndex(where: { $0.skillId == progress.skillId }) {
                skillProgress[index] = progress
            } else {
                skillProgress.append(progress)
            }
        }
    }

    /// Delete skill progress
    func deleteProgress(for skillId: String) {
        if let cdProgress = CDSkillProgress.fetch(bySkillId: skillId, in: viewContext) {
            viewContext.delete(cdProgress)

            performDelete(operation: "Delete skill progress: \(skillId)") {
                skillProgress.removeAll { $0.skillId == skillId }
            }
        }
    }

    // MARK: - Training Session Processing

    /// Record a training session and update skill progress
    /// - Parameters:
    ///   - skillId: The skill being trained
    ///   - successReps: Number of successful repetitions
    ///   - failedReps: Number of failed repetitions
    ///   - context: Optional training context (location)
    /// - Returns: Session feedback based on success rate
    @discardableResult
    func recordTrainingSession(
        skillId: String,
        successReps: Int,
        failedReps: Int,
        context: String? = nil
    ) -> SessionFeedback {
        var progress = getOrCreateProgress(for: skillId)

        let feedback = TrainingEngine.processSessionResult(
            progress: &progress,
            successReps: successReps,
            failedReps: failedReps,
            context: context
        )

        saveProgress(progress)
        return feedback
    }

    /// Process a maintenance check for a skill
    /// - Parameters:
    ///   - skillId: The skill being checked
    ///   - successReps: Number of successful repetitions
    ///   - failedReps: Number of failed repetitions
    /// - Returns: Whether the check passed (>= 80% success)
    @discardableResult
    func processMaintenanceCheck(
        skillId: String,
        successReps: Int,
        failedReps: Int
    ) -> Bool {
        var progress = getOrCreateProgress(for: skillId)

        let passed = TrainingEngine.processMaintenanceCheck(
            progress: &progress,
            successReps: successReps,
            failedReps: failedReps
        )

        saveProgress(progress)
        return passed
    }

    // MARK: - Phase Management

    /// Transition a skill directly to maintaining phase (for manual mastery)
    func transitionToMaintaining(skillId: String) {
        var progress = getOrCreateProgress(for: skillId)
        progress.phase = .maintaining
        progress.maintenanceTier = 1
        progress.nextReviewDate = Date().addingTimeInterval(24 * 60 * 60) // 1 day
        progress.modifiedAt = Date()
        saveProgress(progress)

        logger.info("Transitioned \(skillId) to maintaining phase")
    }

    /// Transition a skill out of maintaining phase (for unmark mastered)
    func transitionFromMaintaining(skillId: String) {
        guard let existingProgress = progressBySkillId[skillId],
              existingProgress.phase == .maintaining else {
            return
        }

        var progress = existingProgress
        // Go back to the most appropriate phase based on proofing progress
        let overallProgress = progress.proofingLevels.overallProgress
        if overallProgress >= 0.6 {  // ~3/5 average
            progress.phase = .generalizing
        } else if overallProgress >= 0.2 {  // ~1/5 average
            progress.phase = .proofing
        } else {
            progress.phase = .addingCue
        }
        progress.maintenanceTier = 0
        progress.nextReviewDate = nil
        progress.modifiedAt = Date()
        saveProgress(progress)

        logger.info("Transitioned \(skillId) from maintaining to \(progress.phase.rawValue)")
    }

    /// Manually advance a skill to the next phase
    func advancePhase(for skillId: String) {
        var progress = getOrCreateProgress(for: skillId)

        let currentPhase = progress.phase
        let nextPhase: SkillLearningPhase

        switch currentPhase {
        case .notStarted:
            nextPhase = .luring
        case .luring:
            nextPhase = .addingCue
        case .addingCue:
            nextPhase = .proofing
        case .proofing:
            nextPhase = .generalizing
        case .generalizing, .maintaining, .needsWork:
            // These transitions are handled automatically
            return
        }

        progress.phase = nextPhase
        progress.modifiedAt = Date()
        saveProgress(progress)

        logger.info("Advanced \(skillId) from \(currentPhase.rawValue) to \(nextPhase.rawValue)")
    }

    /// Manually trigger regression for a skill
    func triggerRegression(for skillId: String) {
        var progress = getOrCreateProgress(for: skillId)
        progress.triggerRegression()
        saveProgress(progress)

        logger.info("Triggered regression for \(skillId)")
    }

    // MARK: - Maintenance Mode

    /// All skill progress records (for maintenance mode filtering)
    var allProgress: [SkillProgress] {
        skillProgress
    }

    /// Skills in simplified maintenance mode
    var skillsInMaintenanceMode: [SkillProgress] {
        skillProgress.filter { $0.isInMaintenanceMode }
    }

    /// Skills needing a maintenance refresh (in maintenance mode, not practiced in 7+ days)
    var skillsNeedingRefresh: [SkillProgress] {
        skillProgress.filter { $0.needsMaintenanceRefresh }
    }

    /// Enable simplified maintenance mode for a skill
    func enableMaintenanceMode(for skillId: String) {
        var progress = getOrCreateProgress(for: skillId)
        progress.enableMaintenanceMode()
        saveProgress(progress)

        logger.info("Enabled maintenance mode for \(skillId)")
    }

    /// Disable maintenance mode for a skill
    func disableMaintenanceMode(for skillId: String) {
        guard let existingProgress = progressBySkillId[skillId] else { return }
        var progress = existingProgress
        progress.disableMaintenanceMode()
        saveProgress(progress)

        logger.info("Disabled maintenance mode for \(skillId)")
    }

    /// Record a maintenance refresh for a skill
    func recordMaintenanceRefresh(for skillId: String) {
        guard let existingProgress = progressBySkillId[skillId] else { return }
        var progress = existingProgress
        progress.recordMaintenanceRefresh()
        saveProgress(progress)

        logger.info("Recorded maintenance refresh for \(skillId)")
    }

    /// Check if a skill is in maintenance mode
    func isInMaintenanceMode(skillId: String) -> Bool {
        progressBySkillId[skillId]?.isInMaintenanceMode ?? false
    }

    // MARK: - Proofing (3Ds)

    /// Update proofing levels for a skill
    func updateProofingLevel(
        for skillId: String,
        dimension: ProofingDimension,
        level: Int
    ) {
        var progress = getOrCreateProgress(for: skillId)

        switch dimension {
        case .duration:
            progress.proofingLevels.duration = min(max(level, 0), 5)
        case .distance:
            progress.proofingLevels.distance = min(max(level, 0), 5)
        case .distraction:
            progress.proofingLevels.distraction = min(max(level, 0), 5)
        }

        progress.modifiedAt = Date()
        saveProgress(progress)
    }

    // MARK: - Session Planning

    /// Generate a training session plan based on current progress
    func generateSessionPlan(targetDurationMinutes: Int = 10) -> TrainingSessionPlan {
        TrainingEngine.generateSessionPlan(from: skillProgress, targetDurationMinutes: targetDurationMinutes)
    }

    /// Get prioritized list of all skills
    func prioritizedSkills() -> [PrioritizedSkill] {
        TrainingEngine.prioritizedSkills(from: skillProgress)
    }

    // MARK: - Statistics

    /// Get training statistics
    func getStats() -> TrainingEngine.TrainingStats {
        TrainingEngine.calculateStats(from: skillProgress)
    }

    /// Get upcoming maintenance reviews
    func getUpcomingReviews(days: Int = 7) -> [(skillId: String, dueDate: Date, isOverdue: Bool)] {
        TrainingEngine.nextReviewsSummary(from: skillProgress, days: days)
    }

    // MARK: - Migration from MasteredSkill

    /// Migrate existing MasteredSkill records to SkillProgress
    /// Call this once during app update to preserve existing mastery data
    func migrateFromMasteredSkills(_ masteredSkills: [MasteredSkill]) {
        let profile = getCurrentProfile()

        for mastered in masteredSkills {
            // Skip if already migrated
            guard !CDSkillProgress.exists(forSkillId: mastered.skillId, in: viewContext) else {
                continue
            }

            // Create a progress record in maintaining phase
            let progress = SkillProgress(
                skillId: mastered.skillId,
                phase: .maintaining,
                proofingLevels: ProofingLevels(duration: 3, distance: 3, distraction: 3),
                confidenceScore: 0.85,  // Assume solid confidence
                maintenanceTier: 3,     // Start at weekly checks
                nextReviewDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                lastPracticedAt: mastered.masteredAt,
                createdAt: mastered.masteredAt,
                modifiedAt: mastered.modifiedAt
            )

            // Link to profile for CloudKit sync
            if let profile = profile {
                _ = CDSkillProgress.create(from: progress, profile: profile, in: viewContext)
            } else {
                _ = CDSkillProgress.create(from: progress, in: viewContext)
            }
        }

        performSave(operation: "Migrate from MasteredSkill") {
            // Reload progress (profile-scoped if available)
            if let profile = profile {
                let cdProgress = CDSkillProgress.fetchAll(for: profile, in: viewContext)
                skillProgress = cdProgress.compactMap { $0.toSkillProgress() }
            } else {
                let cdProgress = CDSkillProgress.fetchAll(in: viewContext)
                skillProgress = cdProgress.compactMap { $0.toSkillProgress() }
            }
        }

        logger.info("Migrated \(masteredSkills.count) mastered skills to progress tracking")
    }
}
