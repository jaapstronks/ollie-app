//
//  AIUsageMonitor.swift
//  Ollie-app
//
//  Tracks AI API usage for monitoring costs and debugging.
//

import Foundation
import os

// MARK: - Usage Entry

struct AIUsageEntry: Codable {
    let timestamp: Date
    let surface: String
    let provider: String?
    let model: String?
    let latencyMs: Int
    let success: Bool
    let cached: Bool
    let mocked: Bool
}

struct AIUsageStats: Codable {
    let date: String
    var totalCalls: Int
    var successfulCalls: Int
    var failedCalls: Int
    var cachedHits: Int
    var mockedCalls: Int
    var totalLatencyMs: Int
    var callsByProvider: [String: Int]
    var callsBySurface: [String: Int]

    var averageLatencyMs: Int {
        guard successfulCalls > 0 else { return 0 }
        return totalLatencyMs / successfulCalls
    }

    var cacheHitRate: Double {
        guard totalCalls > 0 else { return 0 }
        return Double(cachedHits) / Double(totalCalls)
    }

    static func empty(for date: String) -> AIUsageStats {
        AIUsageStats(
            date: date,
            totalCalls: 0,
            successfulCalls: 0,
            failedCalls: 0,
            cachedHits: 0,
            mockedCalls: 0,
            totalLatencyMs: 0,
            callsByProvider: [:],
            callsBySurface: [:]
        )
    }
}

// MARK: - Usage Monitor

@MainActor
final class AIUsageMonitor {
    static let shared = AIUsageMonitor()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.otis", category: "AIUsageMonitor")
    private let fileURL: URL
    private var stats: [String: AIUsageStats] = [:]  // date -> stats
    private let maxDays = 30  // Keep 30 days of stats

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("ai_usage_stats.json")
        loadStats()
    }

    // MARK: - Recording

    /// Record an AI API call (or cache hit/mock).
    func record(
        surface: AINudgeSurface,
        provider: String?,
        model: String?,
        latencyMs: Int,
        success: Bool,
        cached: Bool,
        mocked: Bool
    ) {
        let today = Date().dayStamp()

        var todayStats = stats[today] ?? .empty(for: today)
        todayStats.totalCalls += 1

        if cached {
            todayStats.cachedHits += 1
        } else if mocked {
            todayStats.mockedCalls += 1
        } else if success {
            todayStats.successfulCalls += 1
            todayStats.totalLatencyMs += latencyMs
            if let provider {
                todayStats.callsByProvider[provider, default: 0] += 1
            }
        } else {
            todayStats.failedCalls += 1
        }

        todayStats.callsBySurface[surface.rawValue, default: 0] += 1

        stats[today] = todayStats
        saveStats()

        // Log summary periodically
        if todayStats.totalCalls % 10 == 0 {
            logger.info("AI Usage today: \(todayStats.totalCalls) calls, \(todayStats.cachedHits) cached, \(todayStats.mockedCalls) mocked, \(todayStats.successfulCalls) API calls")
        }
    }

    /// Record a cache hit (no API call made).
    func recordCacheHit(surface: AINudgeSurface) {
        record(surface: surface, provider: nil, model: nil, latencyMs: 0, success: true, cached: true, mocked: false)
    }

    /// Record a mock response (no API call made).
    func recordMockResponse(surface: AINudgeSurface) {
        record(surface: surface, provider: "mock", model: "mock", latencyMs: 0, success: true, cached: false, mocked: true)
    }

    // MARK: - Retrieval

    /// Get today's usage stats.
    var todayStats: AIUsageStats {
        let today = Date().dayStamp()
        return stats[today] ?? .empty(for: today)
    }

    /// Get stats for the last N days.
    func recentStats(days: Int) -> [AIUsageStats] {
        let calendar = Calendar.current
        var result: [AIUsageStats] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStamp = date.dayStamp()
            result.append(stats[dayStamp] ?? .empty(for: dayStamp))
        }

        return result
    }

    /// Get total API calls (not cached/mocked) for the last N days.
    func totalAPICalls(days: Int) -> Int {
        recentStats(days: days).reduce(0) { $0 + $1.successfulCalls + $1.failedCalls }
    }

    /// Get summary text for display.
    var summaryText: String {
        let today = todayStats
        let week = recentStats(days: 7)
        let weekAPICalls = week.reduce(0) { $0 + $1.successfulCalls + $1.failedCalls }
        let weekCacheHits = week.reduce(0) { $0 + $1.cachedHits }
        let weekMocked = week.reduce(0) { $0 + $1.mockedCalls }

        var lines: [String] = []
        lines.append("Today:")
        lines.append("  API calls: \(today.successfulCalls + today.failedCalls)")
        lines.append("  Cache hits: \(today.cachedHits)")
        lines.append("  Mocked: \(today.mockedCalls)")
        if today.successfulCalls > 0 {
            lines.append("  Avg latency: \(today.averageLatencyMs)ms")
        }

        lines.append("")
        lines.append("Last 7 days:")
        lines.append("  API calls: \(weekAPICalls)")
        lines.append("  Cache hits: \(weekCacheHits)")
        lines.append("  Mocked: \(weekMocked)")

        if !today.callsByProvider.isEmpty {
            lines.append("")
            lines.append("Providers today:")
            for (provider, count) in today.callsByProvider.sorted(by: { $0.value > $1.value }) {
                lines.append("  \(provider): \(count)")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Persistence

    private func loadStats() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            stats = try decoder.decode([String: AIUsageStats].self, from: data)

            // Prune old entries
            pruneOldStats()
        } catch {
            logger.error("Failed to load AI usage stats: \(error.localizedDescription)")
        }
    }

    private func saveStats() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(stats)
            try data.write(to: fileURL)
        } catch {
            logger.error("Failed to save AI usage stats: \(error.localizedDescription)")
        }
    }

    private func pruneOldStats() {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) else { return }
        let cutoffStamp = cutoffDate.dayStamp()

        stats = stats.filter { $0.key >= cutoffStamp }
    }

    /// Clear all stats (for testing).
    func clearAll() {
        stats.removeAll()
        saveStats()
    }
}

// Uses Date.dayStamp() from Date+AI.swift
