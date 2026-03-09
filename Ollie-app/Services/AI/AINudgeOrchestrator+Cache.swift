//
//  AINudgeOrchestrator+Cache.swift
//  Otis-app
//
//  Cache management for AI nudge orchestration.
//

import Foundation
import os

// MARK: - Cache Types

extension AINudgeOrchestrator {
    struct CacheEntry<T> {
        let value: T
        let updatedAt: Date
    }
}

// MARK: - Cache Management

extension AINudgeOrchestrator {

    func isFresh(_ date: Date, maxAgeMinutes: Int) -> Bool {
        Date().timeIntervalSince(date) < Double(maxAgeMinutes * 60)
    }

    func insightCacheKey(profileID: UUID) -> String {
        "\(profileID.uuidString)-insight-\(Date().windowStamp(hours: 6))"
    }

    func notificationPolicyCacheKey(profileID: UUID) -> String {
        "\(profileID.uuidString)-policy-\(Date().windowStamp(hours: 4))"
    }

    func getCachedInsight(for cacheKey: String) -> CacheEntry<AIInsightBundleDecision>? {
        insightCache[cacheKey]
    }

    func setCachedInsight(_ decision: AIInsightBundleDecision, for cacheKey: String) {
        insightCache[cacheKey] = CacheEntry(value: decision, updatedAt: Date())
    }

    func getCachedNotificationPolicy(for cacheKey: String) -> CacheEntry<AINotificationPolicyDecision>? {
        notificationPolicyCache[cacheKey]
    }

    func setCachedNotificationPolicy(_ policy: AINotificationPolicyDecision, for cacheKey: String) {
        notificationPolicyCache[cacheKey] = CacheEntry(value: policy, updatedAt: Date())
    }

    func getPendingRecommendations(for profileID: UUID) -> [AILoggingCategoryRecommendation] {
        pendingRecommendations[profileID] ?? []
    }

    func setPendingRecommendations(_ recommendations: [AILoggingCategoryRecommendation]?, for profileID: UUID) {
        pendingRecommendations[profileID] = recommendations
    }

    func removePendingRecommendation(profileID: UUID, category: AILoggingCategory) {
        guard var current = pendingRecommendations[profileID] else { return }
        current.removeAll { $0.category == category }
        pendingRecommendations[profileID] = current
    }

    func hasInFlightTask(for dedupeKey: String) -> Bool {
        inFlightRefreshTasks[dedupeKey] != nil
    }

    func setInFlightTask(_ task: Task<Void, Never>, for dedupeKey: String) {
        inFlightRefreshTasks[dedupeKey] = task
    }

    func clearInFlightTask(for dedupeKey: String) {
        inFlightRefreshTasks[dedupeKey] = nil
    }
}
