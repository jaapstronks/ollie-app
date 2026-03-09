//
//  TrainingPlanStore.swift
//  Otis-app
//
//  Manages training plan data and skill progress tracking with Core Data and automatic CloudKit sync
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages the training plan and skill progress with Core Data storage
@MainActor
final class TrainingPlanStore: BaseStore {

    // MARK: - Published State

    @Published private(set) var trainingPlan: TrainingPlan?
    @Published private(set) var masteredSkills: [MasteredSkill] = []
    @Published private(set) var isLoading: Bool = true

    private var eventStore: EventStore?
    private weak var skillProgressStore: SkillProgressStore?

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Computed Properties

    /// Set of mastered skill IDs for backwards compatibility
    var masteredSkillIds: Set<String> {
        Set(masteredSkills.map { $0.skillId })
    }

    /// Get the MasteredSkill record for a skill ID
    func masteredSkill(for skillId: String) -> MasteredSkill? {
        masteredSkills.first { $0.skillId == skillId }
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "TrainingPlanStore")
        loadTrainingPlan()
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        let cdSkills = CDMasteredSkill.fetchAllSkills(in: viewContext)
        masteredSkills = cdSkills.compactMap { $0.toMasteredSkill() }
        logger.debug("Loaded \(self.masteredSkills.count) mastered skills from Core Data")
    }

    // MARK: - Setup

    /// Set the event store for fetching training sessions
    func setEventStore(_ eventStore: EventStore) {
        self.eventStore = eventStore
    }

    /// Set the skill progress store for syncing mastery state
    func setSkillProgressStore(_ store: SkillProgressStore) {
        self.skillProgressStore = store
    }

    // MARK: - Linear Progression

    /// All skills in linear order
    var allSkillsOrdered: [Skill] {
        trainingPlan?.allSkillsOrdered ?? []
    }

    /// Next skill to learn (first non-mastered skill whose requirements are met)
    var nextSkill: Skill? {
        allSkillsOrdered.first { skill in
            !masteredSkillIds.contains(skill.id) && isUnlocked(skill)
        }
    }

    /// Skills that are unlocked (requirements met, not yet mastered)
    var unlockedSkills: [Skill] {
        allSkillsOrdered.filter { skill in
            !masteredSkillIds.contains(skill.id) && isUnlocked(skill)
        }
    }

    /// Skills that have been mastered
    var masteredSkillsList: [Skill] {
        allSkillsOrdered.filter { masteredSkillIds.contains($0.id) }
    }

    /// Skills that are locked (requirements not met)
    var lockedSkills: [Skill] {
        allSkillsOrdered.filter { skill in
            !masteredSkillIds.contains(skill.id) && !isUnlocked(skill)
        }
    }

    /// Check if a skill is unlocked (all requirements mastered)
    func isUnlocked(_ skill: Skill) -> Bool {
        skill.requires.allSatisfy { masteredSkillIds.contains($0) }
    }

    // MARK: - Session Counts

    /// Get the count of training sessions for a specific skill
    func sessionCount(for skillId: String) -> Int {
        guard let eventStore = eventStore else { return 0 }

        // Look back one year for training sessions
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let allEvents = eventStore.getEvents(
            from: oneYearAgo,
            to: Date()
        )

        return allEvents.training().filter { event in
            event.exercise == skillId
        }.count
    }

    /// Get session counts for all skills
    var allSessionCounts: [String: Int] {
        guard let trainingPlan = trainingPlan else { return [:] }

        var counts: [String: Int] = [:]
        for skill in trainingPlan.skills {
            counts[skill.id] = sessionCount(for: skill.id)
        }
        return counts
    }

    /// Get all skill IDs that have at least one session
    var startedSkillIds: Set<String> {
        let counts = allSessionCounts
        return Set(counts.filter { $0.value > 0 }.keys)
    }

    // MARK: - Status Calculation

    /// Get the status for a specific skill
    func status(for skillId: String) -> SkillStatus {
        let count = sessionCount(for: skillId)
        let isMastered = masteredSkillIds.contains(skillId)
        return SkillStatusCalculations.calculateStatus(sessionCount: count, isMastered: isMastered)
    }

    /// Check if a skill is locked (requirements not met)
    func isLocked(_ skill: Skill) -> Bool {
        !isUnlocked(skill)
    }

    /// Get missing requirements for a locked skill
    func missingRequirements(for skill: Skill) -> [Skill] {
        guard let trainingPlan = trainingPlan else { return [] }
        return trainingPlan.missingRequirements(for: skill.id, masteredSkillIds: masteredSkillIds)
    }

    // MARK: - Progress Calculation

    /// Get progress for a category
    func categoryProgress(for category: TrainingCategory) -> (started: Int, total: Int) {
        guard let trainingPlan = trainingPlan else { return (0, 0) }
        return SkillStatusCalculations.categoryProgress(
            category: category,
            skills: trainingPlan.skills,
            sessionCounts: allSessionCounts,
            masteredSkillIds: masteredSkillIds
        )
    }

    /// Get overall progress percentage (0.0 - 1.0)
    var overallProgress: Double {
        guard let trainingPlan = trainingPlan else { return 0 }
        return SkillStatusCalculations.overallProgress(
            skills: trainingPlan.skills,
            sessionCounts: allSessionCounts,
            masteredSkillIds: masteredSkillIds
        )
    }

    /// Count of mastered skills vs total
    var masteryProgress: (mastered: Int, total: Int) {
        guard let trainingPlan = trainingPlan else { return (0, 0) }
        return (masteredSkillIds.count, trainingPlan.skills.count)
    }

    // MARK: - All Skills With Status

    /// Get all skills with their full status information for the unified list view
    var allSkillsWithStatus: [SkillProgressInfo] {
        guard trainingPlan != nil else { return [] }

        let nextSkillId = nextSkill?.id

        return allSkillsOrdered.map { skill in
            let skillStatus = status(for: skill.id)
            let sessions = sessionCount(for: skill.id)
            let locked = isLocked(skill)
            let isNext = skill.id == nextSkillId
            let missing = missingRequirements(for: skill)

            return SkillProgressInfo(
                skill: skill,
                status: skillStatus,
                sessionCount: sessions,
                isLocked: locked,
                isNextUp: isNext,
                missingRequirements: missing
            )
        }
    }

    // MARK: - Recent Sessions

    /// Get recent training sessions for a specific skill
    func recentSessions(for skillId: String, limit: Int = 5) -> [PuppyEvent] {
        guard let eventStore = eventStore else { return [] }

        let allEvents = eventStore.getEvents(from: Date.daysAgo(30), to: Date())

        return allEvents.training()
            .filter { $0.exercise == skillId }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Mastered Skills Management

    /// Mark a skill as mastered
    func markAsMastered(_ skillId: String) {
        guard !masteredSkillIds.contains(skillId) else { return }

        let skill = MasteredSkill(skillId: skillId)

        _ = CDMasteredSkill.create(from: skill, in: viewContext)

        performSave(operation: "Marked skill as mastered: \(skillId)") {
            masteredSkills.append(skill)
        }

        // Sync to SkillProgressStore
        skillProgressStore?.transitionToMaintaining(skillId: skillId)
    }

    /// Unmark a skill as mastered
    func unmarkMastered(_ skillId: String) {
        guard masteredSkill(for: skillId) != nil else { return }

        if let cdSkill = CDMasteredSkill.fetch(bySkillId: skillId, in: viewContext) {
            viewContext.delete(cdSkill)

            performDelete(operation: "Unmarked skill as mastered: \(skillId)") {
                masteredSkills.removeAll { $0.skillId == skillId }
            }
        }

        // Sync to SkillProgressStore
        skillProgressStore?.transitionFromMaintaining(skillId: skillId)
    }

    /// Toggle mastered state for a skill
    func toggleMastered(_ skillId: String) {
        if masteredSkillIds.contains(skillId) {
            unmarkMastered(skillId)
        } else {
            markAsMastered(skillId)
        }
    }

    // MARK: - Private: Training Plan Loading

    private func loadTrainingPlan() {
        isLoading = true
        defer { isLoading = false }

        guard let url = Bundle.main.url(forResource: "training-plan", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let plan = try? decoder.decode(TrainingPlan.self, from: data) else {
            logger.error("Failed to load training plan from bundle")
            return
        }

        trainingPlan = plan
    }
}
