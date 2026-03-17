//
//  AIBudgetManager.swift
//  Ollie-app
//
//  Manages AI request budget limits per surface and profile.
//  Enforces daily call limits to prevent excessive API usage.
//

@preconcurrency import CoreData
import Foundation

/// Manages AI request budgets and rate limiting
@MainActor
final class AIBudgetManager {

    // MARK: - Dependencies

    private let persistenceController: PersistenceController

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Public API

    /// Check if budget is available for a request.
    /// Does not consume budget - use `consumeBudget` after successful check.
    func hasBudget(profileId: UUID, surface: AISurface) -> Bool {
        let context = persistenceController.viewContext
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else {
            return false
        }

        // Check per-surface limit
        let surfaceCount = CDAICache.todayCallCount(surface: surface, profile: cdProfile, in: context)
        guard surfaceCount < surface.maxCallsPerDay else { return false }

        // Check total daily limit
        let totalCount = CDAICache.todayTotalCallCount(profile: cdProfile, in: context)
        guard totalCount < AINudgeRollout.maxTotalCallsPerDay else { return false }

        return true
    }

    /// Check and consume budget atomically.
    /// Returns true if budget was available and consumed, false otherwise.
    func consumeBudgetIfAvailable(profileId: UUID, surface: AISurface) -> Bool {
        // For now, budget is "consumed" implicitly when a cache entry is created
        // This method just checks availability
        return hasBudget(profileId: profileId, surface: surface)
    }

    /// Get remaining budget for a surface today.
    func remainingBudget(profileId: UUID, surface: AISurface) -> Int {
        let context = persistenceController.viewContext
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else {
            return 0
        }

        let surfaceCount = CDAICache.todayCallCount(surface: surface, profile: cdProfile, in: context)
        return max(0, surface.maxCallsPerDay - surfaceCount)
    }

    /// Get remaining total budget today.
    func remainingTotalBudget(profileId: UUID) -> Int {
        let context = persistenceController.viewContext
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else {
            return 0
        }

        let totalCount = CDAICache.todayTotalCallCount(profile: cdProfile, in: context)
        return max(0, AINudgeRollout.maxTotalCallsPerDay - totalCount)
    }

    /// Get usage statistics for a profile.
    func usageStats(profileId: UUID) -> AIBudgetUsageStats {
        let context = persistenceController.viewContext
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else {
            return AIBudgetUsageStats(
                totalUsedToday: 0,
                totalLimit: AINudgeRollout.maxTotalCallsPerDay,
                surfaceUsage: [:]
            )
        }

        let totalCount = CDAICache.todayTotalCallCount(profile: cdProfile, in: context)

        var surfaceUsage: [AISurface: AIBudgetSurfaceUsage] = [:]
        for surface in AISurface.allCases {
            let count = CDAICache.todayCallCount(surface: surface, profile: cdProfile, in: context)
            surfaceUsage[surface] = AIBudgetSurfaceUsage(
                used: count,
                limit: surface.maxCallsPerDay
            )
        }

        return AIBudgetUsageStats(
            totalUsedToday: totalCount,
            totalLimit: AINudgeRollout.maxTotalCallsPerDay,
            surfaceUsage: surfaceUsage
        )
    }
}

// MARK: - Supporting Types

/// Budget usage statistics for a profile
struct AIBudgetUsageStats {
    let totalUsedToday: Int
    let totalLimit: Int
    let surfaceUsage: [AISurface: AIBudgetSurfaceUsage]

    var totalRemaining: Int {
        max(0, totalLimit - totalUsedToday)
    }

    var usagePercentage: Double {
        guard totalLimit > 0 else { return 0 }
        return Double(totalUsedToday) / Double(totalLimit)
    }
}

/// Budget usage for a specific surface
struct AIBudgetSurfaceUsage {
    let used: Int
    let limit: Int

    var remaining: Int {
        max(0, limit - used)
    }

    var isExhausted: Bool {
        used >= limit
    }
}
