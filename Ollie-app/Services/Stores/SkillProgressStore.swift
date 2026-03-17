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

    // MARK: - CloudKit Sync

    override var cloudKitRecordType: String? { "CD_CDSkillProgress" }

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
        // If we have a profile, load profile-scoped data
        if let profile = getCurrentProfile() {
            // Only migrate orphans if profile is owned (in private store)
            // Shared profiles can't have relationships with private store entities
            if isCurrentProfileOwned {
                migrateOrphanedRecords(to: profile)
            }

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

        performSave(operation: "Save skill progress: \(progress.skillId)", entityId: progress.id) {
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
            // Get ID before deletion for CloudKit sync
            let entityId = cdProgress.id

            // Mark for deletion in context first
            viewContext.delete(cdProgress)

            // performDelete queues CloudKit deletion BEFORE saving, then commits
            performDelete(operation: "Delete skill progress: \(skillId)", entityId: entityId) {
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

    // MARK: - Practice Matrix Operations

    /// Update a cell in the phase x location matrix
    func updateMatrixCell(
        skillId: String,
        phaseId: String,
        location: LocationTier,
        state: PhaseLocationState
    ) {
        var progress = getOrCreateProgress(for: skillId)
        progress.updateCell(phaseId: phaseId, location: location, state: state)

        // Recalculate unlock states when a cell is mastered
        if state == .mastered {
            // We need phase IDs to recalculate - extract from current matrix
            let phaseIds = Array(Set(progress.phaseLocationMatrix.map(\.phaseId)))
            progress.recalculateUnlockStates(phaseIds: phaseIds)
        }

        saveProgress(progress)

        logger.info("Updated matrix cell \(phaseId)/\(location.rawValue) to \(state.rawValue) for \(skillId)")
    }

    /// Initialize matrix for a skill with given phase IDs
    func initializeMatrix(skillId: String, phaseIds: [String]) {
        var progress = getOrCreateProgress(for: skillId)

        // Only initialize if not already done
        guard progress.phaseLocationMatrix.isEmpty else {
            logger.debug("Matrix already initialized for \(skillId)")
            return
        }

        progress.initializeMatrix(phaseIds: phaseIds)
        saveProgress(progress)

        logger.info("Initialized matrix with \(phaseIds.count) phases for \(skillId)")
    }

    /// Get suggested next cell to practice for a skill
    func suggestedNextCell(for skillId: String, phaseIds: [String]) -> (phaseId: String, location: LocationTier)? {
        let progress = self.progress(for: skillId)
        return progress.suggestedNextCell(phaseIds: phaseIds)
    }

    /// Recalculate unlock states based on current mastery
    func recalculateUnlockStates(for skillId: String, phaseIds: [String]) {
        var progress = getOrCreateProgress(for: skillId)
        progress.recalculateUnlockStates(phaseIds: phaseIds)
        saveProgress(progress)
    }

    /// Migrate existing progress to matrix based on current phase
    /// Called when user opens a skill for first time after update
    func migrateToMatrix(skillId: String, phaseIds: [String]) {
        var progress = getOrCreateProgress(for: skillId)

        // Skip if already has matrix
        guard progress.phaseLocationMatrix.isEmpty else { return }

        // Initialize empty matrix first
        progress.initializeMatrix(phaseIds: phaseIds)

        // Based on current phase, estimate matrix progress
        switch progress.phase {
        case .notStarted:
            // First phase, inside = notStarted (already set by initializeMatrix)
            break

        case .luring:
            // In luring phase - first phase being practiced
            if let firstPhaseId = phaseIds.first {
                progress.updateCell(phaseId: firstPhaseId, location: .inside, state: .inProgress)
            }

        case .addingCue:
            // Past luring - assume first phase mastered inside
            if let firstPhaseId = phaseIds.first {
                progress.updateCell(phaseId: firstPhaseId, location: .inside, state: .mastered)
                if phaseIds.count > 1 {
                    progress.updateCell(phaseId: phaseIds[1], location: .inside, state: .inProgress)
                }
            }

        case .proofing:
            // Proofing - multiple phases likely done
            let masteredCount = min(2, phaseIds.count)
            for i in 0..<masteredCount {
                progress.updateCell(phaseId: phaseIds[i], location: .inside, state: .mastered)
            }
            if masteredCount < phaseIds.count {
                progress.updateCell(phaseId: phaseIds[masteredCount], location: .inside, state: .inProgress)
            }

        case .generalizing:
            // Generalizing - most phases mastered inside, some outside
            for i in 0..<phaseIds.count {
                progress.updateCell(phaseId: phaseIds[i], location: .inside, state: .mastered)
                if i < phaseIds.count / 2 {
                    progress.updateCell(phaseId: phaseIds[i], location: .outside, state: .mastered)
                }
            }

        case .maintaining, .needsWork:
            // Mastered or needs work - assume all done
            for phaseId in phaseIds {
                progress.updateCell(phaseId: phaseId, location: .inside, state: .mastered)
                progress.updateCell(phaseId: phaseId, location: .outside, state: .mastered)
            }
        }

        // Recalculate unlocks
        progress.recalculateUnlockStates(phaseIds: phaseIds)

        saveProgress(progress)
        logger.info("Migrated \(skillId) to matrix based on phase \(progress.phase.rawValue)")
    }
}
