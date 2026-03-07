//
//  SentimentStore.swift
//  Ollie-app
//
//  Manages user sentiment check-ins and determines when to prompt for ratings.
//

import Foundation
import SwiftUI
import Combine
import OtisShared

// MARK: - Sentiment Store

@MainActor
final class SentimentStore: ObservableObject {
    static let shared = SentimentStore()

    @Published private(set) var checkIns: [SentimentCategory: SentimentCheckIn] = [:]
    @Published var primaryFocus: SentimentCategory?

    private let fileURL: URL
    private let checkInIntervalDays = 2  // Ask about each category every 2 days

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("sentiment_checkins.json")
        load()
    }

    // MARK: - State

    /// Current sentiment state for AI context.
    var state: SentimentState {
        SentimentState(
            checkIns: checkIns,
            primaryFocus: primaryFocus,
            lastCheckInDate: checkIns.values.map(\.date).max()
        )
    }

    /// Categories where user is struggling (score 1-3, fresh).
    var strugglingCategories: [SentimentCategory] {
        state.strugglingCategories
    }

    /// Categories where tips should be muted (score 5, fresh).
    var mutedCategories: [SentimentCategory] {
        state.mutedCategories
    }

    // MARK: - Check-In Logic

    /// Record a new check-in.
    func recordCheckIn(category: SentimentCategory, score: Int, contextSummary: String? = nil) {
        let checkIn = SentimentCheckIn(category: category, score: score, contextSummary: contextSummary)
        checkIns[category] = checkIn
        save()
    }

    /// Set or clear the primary focus.
    func setPrimaryFocus(_ category: SentimentCategory?) {
        primaryFocus = category
        save()
    }

    /// Get score for a category if fresh.
    func score(for category: SentimentCategory) -> Int? {
        state.score(for: category)
    }

    /// Check if a category needs tips (struggling or no data).
    func needsTips(for category: SentimentCategory) -> Bool {
        guard let checkIn = checkIns[category], checkIn.isFresh else {
            return true  // No data = might need tips
        }
        return checkIn.isStruggling
    }

    /// Check if tips should be muted for a category.
    func shouldMuteTips(for category: SentimentCategory) -> Bool {
        guard let checkIn = checkIns[category], checkIn.isFresh else {
            return false
        }
        return checkIn.shouldMuteTips
    }

    // MARK: - Question Scheduling

    /// Determine which question to show today, if any.
    /// Returns nil if no question should be shown.
    func nextQuestionToAsk(profile: PuppyProfile) -> SentimentCategory? {
        let ageWeeks = profile.ageInWeeks

        // Build list of relevant categories
        var categories = SentimentCategory.coreCategories
        categories.append(contentsOf: SentimentCategory.ageRelevantCategories(ageWeeks: ageWeeks))

        // On first launch (no check-ins), return the first core category
        if checkIns.isEmpty {
            return .pottyTraining
        }

        // Find categories that need a check-in (never asked or stale)
        let needsCheckIn = categories.filter { category in
            guard let checkIn = checkIns[category] else {
                return true  // Never asked
            }
            return checkIn.ageInDays >= checkInIntervalDays
        }

        // Prioritize: never asked > most stale
        let sorted = needsCheckIn.sorted { cat1, cat2 in
            let age1 = checkIns[cat1]?.ageInDays ?? Int.max
            let age2 = checkIns[cat2]?.ageInDays ?? Int.max
            return age1 > age2
        }

        return sorted.first
    }

    /// Check if initial onboarding questions are needed.
    /// Returns categories that haven't been asked yet from core set.
    func pendingOnboardingQuestions() -> [SentimentCategory] {
        SentimentCategory.coreCategories.filter { checkIns[$0] == nil }
    }

    /// Whether we should show the onboarding flow (multiple questions at once).
    var needsOnboarding: Bool {
        pendingOnboardingQuestions().count >= 3
    }

    // MARK: - Persistence

    private struct StorageModel: Codable {
        let checkIns: [String: SentimentCheckIn]
        let primaryFocus: String?
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
                    guard let category = SentimentCategory(rawValue: key) else { return nil }
                    return (category, value)
                }
            )

            if let focusRaw = storage.primaryFocus {
                primaryFocus = SentimentCategory(rawValue: focusRaw)
            }
        } catch {
            print("Failed to load sentiment check-ins: \(error)")
        }
    }

    private func save() {
        do {
            let storage = StorageModel(
                checkIns: Dictionary(uniqueKeysWithValues: checkIns.map { ($0.key.rawValue, $0.value) }),
                primaryFocus: primaryFocus?.rawValue
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(storage)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save sentiment check-ins: \(error)")
        }
    }

    /// Clear all check-ins (for testing).
    func clearAll() {
        checkIns.removeAll()
        primaryFocus = nil
        save()
    }
}
