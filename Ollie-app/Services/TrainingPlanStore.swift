//
//  TrainingPlanStore.swift
//  Ollie-app
//
//  Manages training plan data and skill progress tracking
//

import Foundation
import OllieShared
import Combine

/// Manages the training plan and skill progress
@MainActor
class TrainingPlanStore: ObservableObject {
    @Published private(set) var trainingPlan: TrainingPlan?
    @Published private(set) var masteredSkillIds: Set<String> = []
    @Published private(set) var isLoading: Bool = true

    /// The start date for the 6-week training program
    static let startDate = Date.fromDateString("2026-02-14") ?? Date()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var eventStore: EventStore?

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        decoder = JSONDecoder()

        loadTrainingPlan()
        loadMasteredSkills()
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
        masteredSkillIds.insert(skillId)
        saveMasteredSkills()
    }

    /// Unmark a skill as mastered
    func unmarkMastered(_ skillId: String) {
        masteredSkillIds.remove(skillId)
        saveMasteredSkills()
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
            print("Failed to load training plan from bundle")
            return
        }

        trainingPlan = plan
    }

    // MARK: - Private: Mastered Skills Persistence

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var masteredSkillsURL: URL {
        documentsURL.appendingPathComponent("mastered-skills.json")
    }

    private func loadMasteredSkills() {
        guard fileManager.fileExists(atPath: masteredSkillsURL.path),
              let data = try? Data(contentsOf: masteredSkillsURL),
              let skillIds = try? decoder.decode(Set<String>.self, from: data) else {
            masteredSkillIds = []
            return
        }

        masteredSkillIds = skillIds
    }

    private func saveMasteredSkills() {
        guard let data = try? encoder.encode(masteredSkillIds) else { return }
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
