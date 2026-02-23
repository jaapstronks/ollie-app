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

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "nl.jaapstronks.Ollie", category: "MedicationStore")

    /// File name for medication completions
    private let completionsFileName = "medication-completions.jsonl"

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

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

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var dataDirectoryURL: URL {
        documentsURL.appendingPathComponent(Constants.dataDirectoryName, isDirectory: true)
    }

    private var completionsFileURL: URL {
        dataDirectoryURL.appendingPathComponent(completionsFileName)
    }

    private func ensureDataDirectoryExists() {
        if !fileManager.fileExists(atPath: dataDirectoryURL.path) {
            try? fileManager.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private func loadAllCompletions() {
        let url = completionsFileURL

        guard fileManager.fileExists(atPath: url.path),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            completions = []
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        completions = lines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(MedicationCompletion.self, from: data)
        }

        logger.info("Loaded \(self.completions.count) medication completions")
    }

    private func saveCompletions() {
        ensureDataDirectoryExists()

        let lines = completions.compactMap { completion -> String? in
            guard let data = try? encoder.encode(completion) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        let content = lines.joined(separator: "\n")
        let url = completionsFileURL

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Failed to save medication completions: \(error.localizedDescription)")
        }
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
