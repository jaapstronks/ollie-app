//
//  HealthSymptomStore.swift
//  Ollie-app
//
//  Manages health symptom logging and analysis
//  Part of Brief 04: Health Logging
//

import Combine
import Foundation
import SwiftUI
import OtisShared

// MARK: - Symptom Trend Summary

/// Summary of symptom trends for a condition
struct SymptomTrendSummary: Equatable {
    let conditionId: UUID?
    let episodesThisWeek: Int
    let episodesLastWeek: Int
    let trend: SymptomTrend
    let commonTriggers: [String: Int]  // Trigger -> count

    var trendDescription: String {
        if episodesThisWeek < episodesLastWeek {
            return trend.label
        } else if episodesThisWeek > episodesLastWeek {
            return trend.label
        } else {
            return trend.label
        }
    }
}

// MARK: - Health Symptom Store

@MainActor
final class HealthSymptomStore: ObservableObject {
    static let shared = HealthSymptomStore()

    @Published private(set) var symptoms: [HealthSymptomLog] = []

    private let fileURL: URL
    private let calendar = Calendar.current

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("health_symptoms.json")
        load()
    }

    // MARK: - CRUD Operations

    /// Log a new symptom
    func log(_ symptom: HealthSymptomLog) {
        symptoms.append(symptom)
        save()
    }

    /// Update an existing symptom
    func update(_ symptom: HealthSymptomLog) {
        if let index = symptoms.firstIndex(where: { $0.id == symptom.id }) {
            symptoms[index] = symptom.withUpdatedTimestamp()
            save()
        }
    }

    /// Delete a symptom by ID
    func delete(id: UUID) {
        symptoms.removeAll { $0.id == id }
        save()
    }

    /// Mark a symptom as resolved
    func resolve(id: UUID) {
        if let index = symptoms.firstIndex(where: { $0.id == id }) {
            var symptom = symptoms[index]
            symptom.status = .resolved
            symptom.duration = .resolved
            symptoms[index] = symptom.withUpdatedTimestamp()
            save()
        }
    }

    // MARK: - Queries

    /// Get symptoms for a specific condition
    func symptoms(for conditionId: UUID?, days: Int = 30) -> [HealthSymptomLog] {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return symptoms.filter { symptom in
            symptom.createdAt >= cutoff &&
            (conditionId == nil || symptom.relatedConditionId == conditionId)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Get symptoms logged today
    func symptomsToday() -> [HealthSymptomLog] {
        let today = calendar.startOfDay(for: Date())
        return symptoms.filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Get recent symptoms (last 7 days)
    func recentSymptoms() -> [HealthSymptomLog] {
        symptoms(for: nil, days: 7)
    }

    /// Count symptoms of a specific type within days
    func symptomCount(type: SymptomType, days: Int) -> Int {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return symptoms.filter { $0.symptomType == type && $0.createdAt >= cutoff }.count
    }

    /// Get active (unresolved) symptoms
    func activeSymptoms() -> [HealthSymptomLog] {
        symptoms.filter { $0.status == .active || $0.status == .recurring }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Analysis

    /// Calculate trend for a specific condition
    func trend(for conditionId: UUID?) -> SymptomTrendSummary {
        let now = Date()
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? now

        let thisWeekSymptoms = symptoms.filter { symptom in
            symptom.createdAt >= startOfThisWeek &&
            (conditionId == nil || symptom.relatedConditionId == conditionId)
        }

        let lastWeekSymptoms = symptoms.filter { symptom in
            symptom.createdAt >= startOfLastWeek &&
            symptom.createdAt < startOfThisWeek &&
            (conditionId == nil || symptom.relatedConditionId == conditionId)
        }

        // Determine trend
        let trend: SymptomTrend
        if thisWeekSymptoms.count < lastWeekSymptoms.count {
            trend = .improving
        } else if thisWeekSymptoms.count > lastWeekSymptoms.count {
            trend = .worsening
        } else {
            trend = .stable
        }

        // Count triggers
        var triggerCounts: [String: Int] = [:]
        for symptom in thisWeekSymptoms + lastWeekSymptoms {
            for trigger in symptom.triggers {
                triggerCounts[trigger.label, default: 0] += 1
            }
            if let customTrigger = symptom.customTrigger, !customTrigger.isEmpty {
                triggerCounts[customTrigger, default: 0] += 1
            }
        }

        return SymptomTrendSummary(
            conditionId: conditionId,
            episodesThisWeek: thisWeekSymptoms.count,
            episodesLastWeek: lastWeekSymptoms.count,
            trend: trend,
            commonTriggers: triggerCounts
        )
    }

    /// Get common triggers for a condition
    func commonTriggers(for conditionId: UUID?, limit: Int = 3) -> [(trigger: String, count: Int)] {
        let trendSummary = trend(for: conditionId)
        return trendSummary.commonTriggers
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (trigger: $0.key, count: $0.value) }
    }

    /// Get symptoms grouped by type for display
    func symptomsByType(days: Int = 30) -> [SymptomType: [HealthSymptomLog]] {
        let relevantSymptoms = symptoms(for: nil, days: days)
        return Dictionary(grouping: relevantSymptoms) { $0.symptomType }
    }

    /// Check if there are any recent emergency symptoms
    func hasRecentEmergencySymptoms() -> Bool {
        let recentSymptoms = symptomsToday()
        return recentSymptoms.contains { $0.symptomType.urgencyLevel == .emergency }
    }

    /// Get context summary for AI
    func contextSummary() -> String {
        let recent = recentSymptoms()
        guard !recent.isEmpty else { return "" }

        let typeCounts = Dictionary(grouping: recent) { $0.symptomType }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)

        let summaryParts = typeCounts.map { "\($0.key.label): \($0.value)x" }
        return "Recent symptoms: " + summaryParts.joined(separator: ", ")
    }

    // MARK: - Persistence

    private struct StorageModel: Codable {
        let symptoms: [HealthSymptomLog]
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let storage = try decoder.decode(StorageModel.self, from: data)
            symptoms = storage.symptoms
        } catch {
            print("Failed to load health symptoms: \(error)")
        }
    }

    private func save() {
        do {
            let storage = StorageModel(symptoms: symptoms)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(storage)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save health symptoms: \(error)")
        }
    }

    /// Clear all symptoms (for testing)
    func clearAll() {
        symptoms.removeAll()
        save()
    }
}
