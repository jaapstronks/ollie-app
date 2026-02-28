//
//  MedicationStore.swift
//  Ollie-app
//
//  Manages medication completion tracking with Core Data and automatic CloudKit sync
//

import Foundation
import CoreData
import OllieShared
import Combine
import os

/// Manages medication completion tracking with Core Data storage
@MainActor
final class MedicationStore: BaseStore {

    // MARK: - Published State

    @Published private(set) var completions: [MedicationCompletion] = []

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "MedicationStore")
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        let cdCompletions = CDMedicationCompletion.fetchAllCompletions(in: viewContext)
        completions = cdCompletions.compactMap { $0.toMedicationCompletion() }
        logger.info("Loaded \(self.completions.count) medication completions from Core Data")
    }

    // MARK: - Public Methods

    /// Load completions for a specific date (refreshes from Core Data)
    func loadCompletions(for date: Date) {
        performInitialLoad()
    }

    /// Check if a medication time is complete for a given date
    func isComplete(medicationId: UUID, timeId: UUID, for date: Date) -> Bool {
        CDMedicationCompletion.isCompleted(
            medicationId: medicationId,
            timeId: timeId,
            date: date,
            in: viewContext
        )
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

        _ = CDMedicationCompletion.create(from: completion, in: viewContext)

        performSave(operation: "Marked medication \(medicationId) time \(timeId) as complete") {
            completions.append(completion)
        }

        return completion
    }

    /// Delete a completion
    func deleteCompletion(_ completion: MedicationCompletion) {
        guard let cdCompletion = CDMedicationCompletion.fetch(byId: completion.id, in: viewContext) else {
            logger.warning("Completion not found for deletion: \(completion.id)")
            return
        }

        viewContext.delete(cdCompletion)

        performDelete(operation: "Deleted medication completion \(completion.id)") {
            completions.removeAll { $0.id == completion.id }
        }
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

                let minutesUntilDue = calendar.dateComponents([.minute], from: now, to: scheduledDate).minute ?? 0

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

        return pending.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    /// Clean up old completions (older than 90 days)
    func cleanupOldCompletions() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        let request = NSFetchRequest<CDMedicationCompletion>(entityName: "CDMedicationCompletion")
        request.predicate = NSPredicate(format: "date < %@", cutoffDate as CVarArg)

        do {
            let oldCompletions = try viewContext.fetch(request)
            for completion in oldCompletions {
                viewContext.delete(completion)
            }
            try persistenceController.save()
            performInitialLoad()
            logger.info("Cleaned up \(oldCompletions.count) old medication completions")
        } catch {
            logger.error("Failed to cleanup old completions: \(error.localizedDescription)")
        }
    }
}
