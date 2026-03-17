//
//  AINudgeOrchestrator+Cache.swift
//  Otis-app
//
//  Cache management for AI nudge orchestration.
//  Includes disk persistence to survive app restarts.
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

// MARK: - Persistent Cache Entry (for disk storage)

struct PersistentInsightCacheEntry: Codable {
    let value: AIInsightBundleDecision
    let updatedAt: Date
    let cacheKey: String
}

struct PersistentPolicyCacheEntry: Codable {
    let value: AINotificationPolicyDecision
    let updatedAt: Date
    let cacheKey: String
}

struct PersistentCacheStore: Codable {
    var insights: [PersistentInsightCacheEntry]
    var policies: [PersistentPolicyCacheEntry]
    var lastCleanup: Date

    static var empty: PersistentCacheStore {
        PersistentCacheStore(insights: [], policies: [], lastCleanup: Date())
    }
}

// MARK: - Cache Management

extension AINudgeOrchestrator {

    private static var cacheFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("ai_nudge_cache.json")
    }

    func isFresh(_ date: Date, maxAgeMinutes: Int) -> Bool {
        Date().timeIntervalSince(date) < Double(maxAgeMinutes * 60)
    }

    func insightCacheKey(profileID: UUID) -> String {
        let locale = Locale.current.identifier
        return "\(profileID.uuidString)-insight-\(Date().windowStamp(hours: 6))-\(locale)"
    }

    func notificationPolicyCacheKey(profileID: UUID) -> String {
        "\(profileID.uuidString)-policy-\(Date().windowStamp(hours: 4))"
    }

    func getCachedInsight(for cacheKey: String) -> CacheEntry<AIInsightBundleDecision>? {
        // Check in-memory cache first
        if let cached = insightCache[cacheKey] {
            return cached
        }

        // Try loading from disk if not in memory
        loadCacheFromDiskIfNeeded()
        return insightCache[cacheKey]
    }

    func setCachedInsight(_ decision: AIInsightBundleDecision, for cacheKey: String) {
        insightCache[cacheKey] = CacheEntry(value: decision, updatedAt: Date())
        saveCacheToDisk()
    }

    func getCachedNotificationPolicy(for cacheKey: String) -> CacheEntry<AINotificationPolicyDecision>? {
        // Check in-memory cache first
        if let cached = notificationPolicyCache[cacheKey] {
            return cached
        }

        // Try loading from disk if not in memory
        loadCacheFromDiskIfNeeded()
        return notificationPolicyCache[cacheKey]
    }

    func setCachedNotificationPolicy(_ policy: AINotificationPolicyDecision, for cacheKey: String) {
        notificationPolicyCache[cacheKey] = CacheEntry(value: policy, updatedAt: Date())
        saveCacheToDisk()
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

    // MARK: - Disk Persistence

    private var hasLoadedFromDisk: Bool {
        get { _hasLoadedFromDisk }
        set { _hasLoadedFromDisk = newValue }
    }

    private static var _hasLoadedFromDisk = false
    private var _hasLoadedFromDisk: Bool {
        get { Self._hasLoadedFromDisk }
        set { Self._hasLoadedFromDisk = newValue }
    }

    func loadCacheFromDiskIfNeeded() {
        guard !hasLoadedFromDisk else { return }
        hasLoadedFromDisk = true

        let fileURL = Self.cacheFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.debug("No cache file found on disk")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let store = try decoder.decode(PersistentCacheStore.self, from: data)

            // Load insights (only fresh ones)
            for entry in store.insights {
                if isFresh(entry.updatedAt, maxAgeMinutes: 360) {
                    insightCache[entry.cacheKey] = CacheEntry(value: entry.value, updatedAt: entry.updatedAt)
                }
            }

            // Load policies (only fresh ones)
            for entry in store.policies {
                if isFresh(entry.updatedAt, maxAgeMinutes: 240) {
                    notificationPolicyCache[entry.cacheKey] = CacheEntry(value: entry.value, updatedAt: entry.updatedAt)
                }
            }

            logger.info("Loaded \(self.insightCache.count) insights and \(self.notificationPolicyCache.count) policies from disk cache")
        } catch {
            logger.error("Failed to load cache from disk: \(error.localizedDescription)")
        }
    }

    func saveCacheToDisk() {
        // Convert in-memory caches to persistent format
        let insights = insightCache.map { key, entry in
            PersistentInsightCacheEntry(value: entry.value, updatedAt: entry.updatedAt, cacheKey: key)
        }

        let policies = notificationPolicyCache.map { key, entry in
            PersistentPolicyCacheEntry(value: entry.value, updatedAt: entry.updatedAt, cacheKey: key)
        }

        let store = PersistentCacheStore(insights: insights, policies: policies, lastCleanup: Date())

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(store)
            try data.write(to: Self.cacheFileURL)
            logger.debug("Saved cache to disk: \(insights.count) insights, \(policies.count) policies")
        } catch {
            logger.error("Failed to save cache to disk: \(error.localizedDescription)")
        }
    }

    /// Clear all cached data (for testing/debugging).
    func clearAllCaches() {
        insightCache.removeAll()
        notificationPolicyCache.removeAll()
        pendingRecommendations.removeAll()
        lastBudgetExhaustedTime.removeAll()

        // Delete disk cache
        try? FileManager.default.removeItem(at: Self.cacheFileURL)
        logger.info("Cleared all AI caches")
    }
}
