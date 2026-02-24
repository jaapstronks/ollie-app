//
//  MedicationStore.swift
//  Ollie-app
//
//  Manages medication completion tracking with JSONL persistence
//

import Foundation
import OllieShared
import Combine
import os

/// Manages medication completion tracking
@MainActor
class MedicationStore: ObservableObject {
    @Published private(set) var completions: [MedicationCompletion] = []

    private let logger = Logger.ollie(category: "MedicationStore")

    /// File name for medication completions
    private let completionsFileName = "medication-completions.jsonl"

    init() {
        loadAllCompletions()
    }

    // MARK: - Public Methods

    /// Load completions for a specific date (no-op, all completions already loaded)
    func loadCompletions(for date: Date) {
        // Completions are already loaded in memory from init
        // This method exists for API consistency if we add date-based filtering later
    }

    /// Check if a medication time is complete for a given date
    func isComplete(medicationId: UUID, timeId: UUID, for date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return completions.contains { completion in
            completion.medicationId == medicationId &&
            completion.timeId == timeId &&
            calendar.isDate(completion.date, inSameDayAs: startOfDay)
        }
    }

    /// Mark a medication as complete
    @discardableResult
    func markComplete(medicationId: UUID, timeId: UUID, for date: Date) -> MedicationCompletion {
        let completion = MedicationCompletion(
            medicationId: medicationId,
            timeId: timeId,
            date: date,
            completedAt: Date()
        )

        completions.append(completion)
        saveCompletions()

        logger.info("Marked medication \(medicationId) time \(timeId) as complete")
        return completion
    }

    /// Delete a completion
    func deleteCompletion(_ completion: MedicationCompletion) {
        completions.removeAll { $0.id == completion.id }
        saveCompletions()
        logger.info("Deleted medication completion \(completion.id)")
    }

    /// Get pending medications for a date
    func pendingMedications(schedule: MedicationSchedule, for date: Date) -> [PendingMedication] {
        var pending: [PendingMedication] = []
        let now = Date()
        let calendar = Calendar.current

        for medication in schedule.medications {
            guard medication.isScheduledFor(date: date) else { continue }

            for time in medication.times {
                // Skip if already completed
                if isComplete(medicationId: medication.id, timeId: time.id, for: date) {
                    continue
                }

                guard let scheduledDate = time.scheduledDate(for: date) else { continue }

                // Only show if scheduled time has passed or is within 30 minutes
                let minutesUntilDue = calendar.dateComponents([.minute], from: now, to: scheduledDate).minute ?? 0

                // Show medication if:
                // - It's past the scheduled time (overdue)
                // - It's within 30 minutes of the scheduled time
                // - We're viewing a past date
                let isToday = calendar.isDateInToday(date)
                let shouldShow = !isToday || minutesUntilDue <= 30

                if shouldShow {
                    let isOverdue = isToday && now > scheduledDate
                    pending.append(PendingMedication(
                        medication: medication,
                        time: time,
                        scheduledDate: scheduledDate,
                        isOverdue: isOverdue
                    ))
                }
            }
        }

        // Sort by scheduled time
        return pending.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    // MARK: - Private Methods

    private func loadAllCompletions() {
        completions = JSONFileStorage.loadJSONL(from: completionsFileName, inDataDirectory: true, logger: logger)
        logger.info("Loaded \(self.completions.count) medication completions")
    }

    private func saveCompletions() {
        JSONFileStorage.saveJSONL(completions, to: completionsFileName, inDataDirectory: true, logger: logger)
    }

    /// Clean up old completions (older than 90 days)
    func cleanupOldCompletions() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let oldCount = completions.count
        completions.removeAll { $0.date < cutoffDate }

        if completions.count != oldCount {
            saveCompletions()
            logger.info("Cleaned up \(oldCount - self.completions.count) old medication completions")
        }
    }
}
