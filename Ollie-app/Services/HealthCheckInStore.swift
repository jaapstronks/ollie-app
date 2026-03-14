//
//  HealthCheckInStore.swift
//  Ollie-app
//
//  Manages health check-in ratings and determines when to prompt for check-ins
//  Part of Brief 04: Health Logging
//

import Foundation
import SwiftUI
import OtisShared

// MARK: - Health Check-In Store

@Observable
@MainActor
final class HealthCheckInStore {
    static let shared = HealthCheckInStore()

    private(set) var checkIns: [HealthCheckInCategory: HealthCheckIn] = [:]

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private let checkInIntervalDays = 3  // Ask about each category every 3 days
    @ObservationIgnored private let calendar = Calendar.current

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("health_checkins.json")
        load()
    }

    // MARK: - State

    /// Current health state for AI context
    /// - Parameter activeConditionCount: Number of active health conditions (pass from profile)
    func state(activeConditionCount: Int = 0) -> HealthState {
        HealthState(
            checkIns: checkIns,
            lastCheckInDate: checkIns.values.map(\.createdAt).max(),
            recentSymptomCount: HealthSymptomStore.shared.recentSymptoms().count,
            activeConditionCount: activeConditionCount
        )
    }

    /// Categories where dog is struggling (score 1-2, fresh)
    var strugglingCategories: [HealthCheckInCategory] {
        state().strugglingCategories
    }

    /// Average health score across all fresh check-ins
    var averageScore: Double? {
        state().averageScore
    }

    // MARK: - Check-In Logic

    /// Record a new check-in
    func recordCheckIn(
        category: HealthCheckInCategory,
        score: Int,
        relatedConditionId: UUID? = nil,
        note: String? = nil,
        contextSummary: String? = nil
    ) {
        let checkIn = HealthCheckIn(
            category: category,
            score: score,
            relatedConditionId: relatedConditionId,
            note: note,
            contextSummary: contextSummary
        )
        checkIns[category] = checkIn
        save()
    }

    /// Get score for a category if fresh
    func score(for category: HealthCheckInCategory) -> Int? {
        state().score(for: category)
    }

    /// Get latest check-in for a category
    func latestCheckIn(for category: HealthCheckInCategory) -> HealthCheckIn? {
        checkIns[category]
    }

    /// Get all check-ins from this week
    func checkInsThisWeek() -> [HealthCheckIn] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return checkIns.values
            .filter { $0.createdAt >= startOfWeek }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Question Scheduling

    /// Determine which category to ask about today, if any
    /// Returns nil if no check-in is needed
    func nextCheckInCategory(
        conditions: [HealthCondition],
        lifecyclePhase: LifecyclePhase
    ) -> HealthCheckInCategory? {
        let relevant = HealthCheckInCategory.relevantCategories(
            conditions: conditions,
            lifecyclePhase: lifecyclePhase
        )

        // No conditions and not senior? No check-ins needed
        guard !relevant.isEmpty else { return nil }

        // Find the category we haven't checked recently
        for category in relevant {
            if let latest = checkIns[category] {
                let daysSince = calendar.dateComponents(
                    [.day], from: latest.createdAt, to: Date()
                ).day ?? 0
                if daysSince >= checkInIntervalDays {
                    return category
                }
            } else {
                // Never asked about this category
                return category
            }
        }

        return nil
    }

    /// Get context summary for a check-in category
    func contextSummary(for category: HealthCheckInCategory, puppyName: String) -> String {
        let symptomStore = HealthSymptomStore.shared
        let recentSymptoms = symptomStore.recentSymptoms()

        // Get category-relevant symptoms
        let relevantSymptoms = recentSymptoms.filter { symptom in
            switch category {
            case .mobility:
                return symptom.symptomType.category == .mobility
            case .breathing:
                return symptom.symptomType.category == .respiratory
            case .skin:
                return symptom.symptomType.category == .skin
            case .digestion:
                return symptom.symptomType.category == .digestive
            case .cognition:
                return symptom.symptomType.category == .neurological
            default:
                return false
            }
        }

        // Get last check-in for this category
        if let lastCheckIn = checkIns[category], lastCheckIn.isFresh {
            let lastScoreLabel = lastCheckIn.scoreDescription.lowercased()
            if relevantSymptoms.isEmpty {
                return "\(puppyName) was rated \"\(lastScoreLabel)\" \(lastCheckIn.ageInDays) days ago."
            } else {
                let symptomCount = relevantSymptoms.count
                return "\(puppyName) was rated \"\(lastScoreLabel)\" \(lastCheckIn.ageInDays) days ago. \(symptomCount) related symptom(s) logged this week."
            }
        }

        if !relevantSymptoms.isEmpty {
            let symptomCount = relevantSymptoms.count
            return "\(symptomCount) related symptom(s) logged this week."
        }

        return ""
    }

    /// Check if we should show a check-in card
    /// - Parameter profile: The puppy profile to check
    func shouldShowCheckInCard(for profile: PuppyProfile?) -> Bool {
        guard let profile = profile else { return false }
        let conditions = profile.healthConditions.filter { $0.status == .active }
        let phase = profile.lifecyclePhase

        return nextCheckInCategory(conditions: conditions, lifecyclePhase: phase) != nil
    }

    /// Get the next category to show in check-in card
    /// - Parameter profile: The puppy profile to check
    func nextCategoryForCard(for profile: PuppyProfile?) -> HealthCheckInCategory? {
        guard let profile = profile else { return nil }
        let conditions = profile.healthConditions.filter { $0.status == .active }
        let phase = profile.lifecyclePhase

        return nextCheckInCategory(conditions: conditions, lifecyclePhase: phase)
    }

    // MARK: - Persistence

    private struct StorageModel: Codable {
        let checkIns: [String: HealthCheckIn]
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let storage = try decoder.decode(StorageModel.self, from: data)

            checkIns = Dictionary(
                uniqueKeysWithValues: storage.checkIns.compactMap { key, value in
                    guard let category = HealthCheckInCategory(rawValue: key) else { return nil }
                    return (category, value)
                }
            )
        } catch {
            print("Failed to load health check-ins: \(error)")
        }
    }

    private func save() {
        do {
            let storage = StorageModel(
                checkIns: Dictionary(uniqueKeysWithValues: checkIns.map { ($0.key.rawValue, $0.value) })
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(storage)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save health check-ins: \(error)")
        }
    }

    /// Clear all check-ins (for testing)
    func clearAll() {
        checkIns.removeAll()
        save()
    }
}
