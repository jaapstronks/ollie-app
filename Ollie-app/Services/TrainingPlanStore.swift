//
//  TrainingPlanStore.swift
//  Ollie-app
//
//  Manages training plan data and skill progress tracking with CloudKit sync
//

import Foundation
import OllieShared
import Combine
import os

/// Manages the training plan and skill progress
@MainActor
class TrainingPlanStore: ObservableObject {
    @Published private(set) var trainingPlan: TrainingPlan?
    @Published private(set) var masteredSkills: [MasteredSkill] = []
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var isSyncing: Bool = false

    /// The start date for the 6-week training program
    static let startDate = Date.fromDateString("2026-02-14") ?? Date()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger.ollie(category: "TrainingPlanStore")
    private let cloudKit = CloudKitService.shared

    private var eventStore: EventStore?

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let cloudMigrationCompleted = "trainingPlanStore.cloudMigrationCompleted.v2"
        static let legacyFormatMigrated = "trainingPlanStore.legacyFormatMigrated"
    }

    // MARK: - Computed Properties

    /// Set of mastered skill IDs for backwards compatibility
    var masteredSkillIds: Set<String> {
        Set(masteredSkills.map { $0.skillId })
    }

    /// Get the MasteredSkill record for a skill ID
    func masteredSkill(for skillId: String) -> MasteredSkill? {
        masteredSkills.first { $0.skillId == skillId }
    }

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        loadTrainingPlan()
        migrateFromLegacyFormat()
        loadMasteredSkills()
    }

    // MARK: - CloudKit Sync

    /// Perform initial sync on app launch
    func initialSync() async {
        guard cloudKit.isCloudAvailable else {
            logger.info("CloudKit not available, skipping mastered skills sync")
            return
        }

        // Migrate existing local mastered skills to CloudKit if needed
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.cloudMigrationCompleted) {
            await migrateLocalMasteredSkills()
        }

        // Fetch from cloud and merge
        await fetchFromCloud()
    }

    /// Force sync with CloudKit
    func forceSync() async {
        await fetchFromCloud()
    }

    /// Migrate existing local mastered skills to CloudKit (one-time)
    private func migrateLocalMasteredSkills() async {
        guard !masteredSkills.isEmpty else {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.cloudMigrationCompleted)
            return
        }

        logger.info("Migrating \(self.masteredSkills.count) local mastered skills to CloudKit")

        do {
            try await cloudKit.saveMasteredSkills(masteredSkills)
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.cloudMigrationCompleted)
            logger.info("Mastered skills migration completed")
        } catch {
            logger.error("Mastered skills migration failed: \(error.localizedDescription)")
        }
    }

    /// Fetch mastered skills from CloudKit and merge with local
    private func fetchFromCloud() async {
        guard cloudKit.isCloudAvailable else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let cloudSkills = try await cloudKit.fetchAllMasteredSkills()
            let merged = mergeMasteredSkills(local: masteredSkills, cloud: cloudSkills)

            if merged.map({ $0.skillId }).sorted() != masteredSkills.map({ $0.skillId }).sorted() {
                masteredSkills = merged
                saveMasteredSkills()
                logger.info("Mastered skills updated from CloudKit (\(merged.count) skills)")
            }
        } catch {
            logger.warning("Failed to fetch mastered skills from cloud: \(error.localizedDescription)")
        }
    }

    /// Save a mastered skill to CloudKit
    private func saveToCloud(_ skill: MasteredSkill) async {
        guard cloudKit.isCloudAvailable else { return }

        do {
            try await cloudKit.saveMasteredSkill(skill)
            logger.debug("Mastered skill synced to CloudKit: \(skill.skillId)")
        } catch {
            logger.warning("Failed to save mastered skill to cloud: \(error.localizedDescription)")
        }
    }

    /// Delete a mastered skill from CloudKit
    private func deleteFromCloud(_ skill: MasteredSkill) async {
        guard cloudKit.isCloudAvailable else { return }

        do {
            try await cloudKit.deleteMasteredSkill(skill)
            logger.debug("Mastered skill deleted from CloudKit: \(skill.skillId)")
        } catch {
            logger.warning("Failed to delete mastered skill from cloud: \(error.localizedDescription)")
        }
    }

    /// Merge local and cloud mastered skills, preferring newer modifiedAt for conflicts
    private func mergeMasteredSkills(local: [MasteredSkill], cloud: [MasteredSkill]) -> [MasteredSkill] {
        var merged: [String: MasteredSkill] = [:]

        // Add all local skills
        for skill in local {
            merged[skill.skillId] = skill
        }

        // Merge cloud skills (prefer newer modifiedAt, or earlier masteredAt for same modifiedAt)
        for cloudSkill in cloud {
            if let existing = merged[cloudSkill.skillId] {
                // Keep the one with newer modifiedAt
                // If same modifiedAt, keep the one with earlier masteredAt (first to master wins)
                if cloudSkill.modifiedAt > existing.modifiedAt {
                    merged[cloudSkill.skillId] = cloudSkill
                } else if cloudSkill.modifiedAt == existing.modifiedAt &&
                          cloudSkill.masteredAt < existing.masteredAt {
                    merged[cloudSkill.skillId] = cloudSkill
                }
            } else {
                merged[cloudSkill.skillId] = cloudSkill
            }
        }

        return Array(merged.values).sorted { $0.masteredAt > $1.masteredAt }
    }

    // MARK: - Setup

    /// Set the event store for fetching training sessions
    func setEventStore(_ eventStore: EventStore) {
        self.eventStore = eventStore
    }

    // MARK: - Week Calculation

    /// Calculate the current week number (1-6+)
    var currentWeek: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Self.startDate, to: Date()).day ?? 0
        let week = (days / 7) + 1
        return max(1, week)  // At minimum week 1
    }

    /// Get the week plan for the current week
    var currentWeekPlan: WeekPlan? {
        trainingPlan?.weekPlan(for: min(currentWeek, 6))
    }

    /// Get focus skills for the current week
    var currentFocusSkills: [Skill] {
        trainingPlan?.focusSkills(for: min(currentWeek, 6)) ?? []
    }

    // MARK: - Session Counts

    /// Get the count of training sessions for a specific skill
    func sessionCount(for skillId: String) -> Int {
        guard let eventStore = eventStore else { return 0 }

        let allEvents = eventStore.getEvents(
            from: Self.startDate,
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

    /// Check if a skill is locked
    func isLocked(_ skill: Skill) -> Bool {
        guard let trainingPlan = trainingPlan else { return false }
        return SkillStatusCalculations.isLocked(
            skill: skill,
            startedSkillIds: startedSkillIds,
            trainingPlan: trainingPlan
        )
    }

    /// Get missing requirements for a locked skill
    func missingRequirements(for skill: Skill) -> [Skill] {
        guard let trainingPlan = trainingPlan else { return [] }
        return trainingPlan.missingRequirements(for: skill.id, startedSkillIds: startedSkillIds)
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

    /// Count of skills started this week
    var weekProgress: (started: Int, total: Int) {
        let focusSkillIds = Set(currentFocusSkills.map { $0.id })
        let startedCount = focusSkillIds.intersection(startedSkillIds).count
        return (startedCount, focusSkillIds.count)
    }

    // MARK: - Recent Sessions

    /// Get recent training sessions for a specific skill
    func recentSessions(for skillId: String, limit: Int = 5) -> [PuppyEvent] {
        guard let eventStore = eventStore else { return [] }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let allEvents = eventStore.getEvents(from: thirtyDaysAgo, to: Date())

        return allEvents.training()
            .filter { $0.exercise == skillId }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Mastered Skills Management

    /// Mark a skill as mastered
    func markAsMastered(_ skillId: String) {
        // Check if already mastered
        guard !masteredSkillIds.contains(skillId) else { return }

        let skill = MasteredSkill(skillId: skillId)
        masteredSkills.append(skill)
        saveMasteredSkills()

        // Sync to CloudKit in background
        Task {
            await saveToCloud(skill)
        }

        logger.info("Marked skill as mastered: \(skillId)")
    }

    /// Unmark a skill as mastered
    func unmarkMastered(_ skillId: String) {
        guard let skill = masteredSkill(for: skillId) else { return }

        masteredSkills.removeAll { $0.skillId == skillId }
        saveMasteredSkills()

        // Delete from CloudKit in background
        Task {
            await deleteFromCloud(skill)
        }

        logger.info("Unmarked skill as mastered: \(skillId)")
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

        // Load from bundled JSON
        guard let url = Bundle.main.url(forResource: "training-plan", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let plan = try? decoder.decode(TrainingPlan.self, from: data) else {
            logger.error("Failed to load training plan from bundle")
            return
        }

        trainingPlan = plan
    }

    // MARK: - Private: Mastered Skills Persistence

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var masteredSkillsURL: URL {
        documentsURL.appendingPathComponent("mastered-skills-v2.json")
    }

    private var legacyMasteredSkillsURL: URL {
        documentsURL.appendingPathComponent("mastered-skills.json")
    }

    /// Migrate from legacy Set<String> format to new [MasteredSkill] format
    private func migrateFromLegacyFormat() {
        guard !UserDefaults.standard.bool(forKey: UserDefaultsKey.legacyFormatMigrated) else { return }

        // Check if legacy file exists
        guard fileManager.fileExists(atPath: legacyMasteredSkillsURL.path),
              let data = try? Data(contentsOf: legacyMasteredSkillsURL),
              let skillIds = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.legacyFormatMigrated)
            return
        }

        logger.info("Migrating \(skillIds.count) skills from legacy format")

        // Convert to new format with current date as masteredAt
        // (We don't have the actual mastered date, so we use now as a best guess)
        let migrationDate = Date()
        let migratedSkills = skillIds.map { skillId in
            MasteredSkill(skillId: skillId, masteredAt: migrationDate)
        }

        // Save in new format
        masteredSkills = migratedSkills
        saveMasteredSkills()

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.legacyFormatMigrated)
        logger.info("Legacy format migration completed")
    }

    private func loadMasteredSkills() {
        guard fileManager.fileExists(atPath: masteredSkillsURL.path),
              let data = try? Data(contentsOf: masteredSkillsURL),
              let skills = try? decoder.decode([MasteredSkill].self, from: data) else {
            masteredSkills = []
            return
        }

        masteredSkills = skills
        logger.debug("Loaded \(skills.count) mastered skills")
    }

    private func saveMasteredSkills() {
        guard let data = try? encoder.encode(masteredSkills) else { return }
        try? data.write(to: masteredSkillsURL, options: .atomic)
    }
}

// MARK: - Date Extension

extension Date {
    /// Parse a date string in YYYY-MM-DD format
    static func fromDateString(_ string: String) -> Date? {
        DateFormatters.dateOnly.date(from: string)
    }
}
