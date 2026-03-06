//
//  RegressionLogStore.swift
//  Ollie-app
//
//  Manages regression log persistence with Core Data.
//  Tracks skill regressions for AI analysis and training insights.
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages regression log tracking with Core Data persistence
@MainActor
final class RegressionLogStore: BaseStore {

    // MARK: - Published State

    @Published private(set) var regressionLogs: [RegressionLogEntry] = []
    @Published private(set) var isLoading: Bool = true

    // MARK: - Computed Properties

    /// Get all unrecovered regressions
    var unrecoveredRegressions: [RegressionLogEntry] {
        regressionLogs.filter { $0.recoveredAt == nil }
    }

    /// Get regressions from the last N days
    func recentRegressions(days: Int) -> [RegressionLogEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return regressionLogs.filter { $0.occurredAt >= cutoff }
    }

    /// Get regression count by skill
    var regressionCountBySkill: [String: Int] {
        var counts: [String: Int] = [:]
        for log in regressionLogs {
            counts[log.skillId, default: 0] += 1
        }
        return counts
    }

    /// Get skills with multiple regressions (indicates pace issues)
    var skillsWithMultipleRegressions: [String] {
        regressionCountBySkill
            .filter { $0.value >= 2 }
            .map { $0.key }
    }

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "RegressionLogStore")
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        let cdLogs = CDRegressionLog.fetchAll(in: viewContext)
        regressionLogs = cdLogs.compactMap { $0.toRegressionLogEntry() }
        logger.debug("Loaded \(self.regressionLogs.count) regression log entries from Core Data")
    }

    // MARK: - CRUD Operations

    /// Log a new regression event
    func logRegression(
        skillId: String,
        previousTier: Int,
        successRateAtFailure: Double
    ) -> RegressionLogEntry {
        let entry = RegressionLogEntry(
            skillId: skillId,
            occurredAt: Date(),
            previousTier: previousTier,
            successRateAtFailure: successRateAtFailure
        )

        _ = CDRegressionLog.create(from: entry, in: viewContext)

        performSave(operation: "Log regression for skill: \(skillId)") {
            self.regressionLogs.insert(entry, at: 0)
        }

        logger.info("Logged regression for skill \(skillId) from tier \(previousTier)")
        return entry
    }

    /// Mark a regression as recovered
    func markRecovered(
        regressionId: UUID,
        sessionsToRecover: Int
    ) {
        guard let cdLog = CDRegressionLog.fetch(byId: regressionId, in: viewContext) else {
            logger.warning("Regression log not found for ID: \(regressionId)")
            return
        }

        cdLog.recoveredAt = Date()
        cdLog.sessionsToRecover = NSNumber(value: sessionsToRecover)
        cdLog.modifiedAt = Date()

        performSave(operation: "Mark regression recovered: \(regressionId)") {
            if let index = self.regressionLogs.firstIndex(where: { $0.id == regressionId }) {
                var updated = self.regressionLogs[index]
                updated.recoveredAt = Date()
                updated.sessionsToRecover = sessionsToRecover
                self.regressionLogs[index] = updated
            }
        }

        logger.info("Marked regression \(regressionId) as recovered after \(sessionsToRecover) sessions")
    }

    /// Delete a regression log entry
    func deleteRegression(id: UUID) {
        guard let cdLog = CDRegressionLog.fetch(byId: id, in: viewContext) else {
            return
        }

        viewContext.delete(cdLog)

        performDelete(operation: "Delete regression log: \(id)") {
            self.regressionLogs.removeAll { $0.id == id }
        }
    }

    // MARK: - Query Methods

    /// Get regressions for a specific skill
    func regressions(for skillId: String) -> [RegressionLogEntry] {
        regressionLogs.filter { $0.skillId == skillId }
    }

    /// Check if a skill has had recent regressions (within days)
    func hasRecentRegression(skillId: String, withinDays days: Int) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return regressionLogs.contains { $0.skillId == skillId && $0.occurredAt >= cutoff }
    }

    /// Get the most recent regression for a skill
    func mostRecentRegression(for skillId: String) -> RegressionLogEntry? {
        regressions(for: skillId).first  // Already sorted by date descending
    }

    /// Check if skill is currently in regression (unrecovered)
    func isInRegression(skillId: String) -> Bool {
        regressionLogs.contains { $0.skillId == skillId && $0.recoveredAt == nil }
    }

    // MARK: - Statistics

    /// Average sessions to recover from regression
    var averageSessionsToRecover: Double? {
        let recovered = regressionLogs.compactMap { $0.sessionsToRecover }
        guard !recovered.isEmpty else { return nil }
        return Double(recovered.reduce(0, +)) / Double(recovered.count)
    }

    /// Average regression duration in days
    var averageRegressionDurationDays: Double? {
        let durations = regressionLogs.compactMap { $0.regressionDurationDays }
        guard !durations.isEmpty else { return nil }
        return Double(durations.reduce(0, +)) / Double(durations.count)
    }
}
