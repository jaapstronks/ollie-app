//
//  AchievementState.swift
//  OllieShared
//
//  Persistent state tracking for achievements and celebrations

import Foundation

// MARK: - Achievement State

/// Tracks unlocked achievements and personal bests
public struct AchievementState: Codable, Sendable {
    /// Map of achievement ID to unlock date
    public var unlockedAchievements: [String: Date]

    /// Personal best values by category (e.g., "pottyStreak" -> 7)
    public var personalBests: [String: Int]

    /// Last time a Tier 2 celebration was shown
    public var lastTier2Date: Date?

    /// Last time a Tier 3 celebration was shown
    public var lastTier3Date: Date?

    /// Queued achievements waiting to be shown (IDs)
    public var queuedAchievements: [String]

    public init(
        unlockedAchievements: [String: Date] = [:],
        personalBests: [String: Int] = [:],
        lastTier2Date: Date? = nil,
        lastTier3Date: Date? = nil,
        queuedAchievements: [String] = []
    ) {
        self.unlockedAchievements = unlockedAchievements
        self.personalBests = personalBests
        self.lastTier2Date = lastTier2Date
        self.lastTier3Date = lastTier3Date
        self.queuedAchievements = queuedAchievements
    }

    /// Empty initial state
    public static let empty = AchievementState()

    // MARK: - Queries

    /// Check if an achievement has been unlocked
    public func isUnlocked(_ achievementId: String) -> Bool {
        unlockedAchievements[achievementId] != nil
    }

    /// Get unlock date for an achievement
    public func unlockDate(for achievementId: String) -> Date? {
        unlockedAchievements[achievementId]
    }

    /// Get personal best for a category
    public func personalBest(for category: String) -> Int? {
        personalBests[category]
    }

    /// Check if a value is a new personal best
    public func isPersonalBest(for category: String, value: Int) -> Bool {
        guard let current = personalBests[category] else { return true }
        return value > current
    }

    // MARK: - Fatigue Prevention

    /// Check if a Tier 2 celebration can be shown (max 1 per session)
    /// Session is approximated as 15-minute window
    public func canShowTier2(now: Date = Date()) -> Bool {
        guard let lastDate = lastTier2Date else { return true }
        let sessionWindow: TimeInterval = 15 * 60  // 15 minutes
        return now.timeIntervalSince(lastDate) > sessionWindow
    }

    /// Check if a Tier 3 celebration can be shown (max 1 per day)
    public func canShowTier3(now: Date = Date()) -> Bool {
        guard let lastDate = lastTier3Date else { return true }
        let calendar = Calendar.current
        return !calendar.isDate(now, inSameDayAs: lastDate)
    }

    /// Determine the effective tier for an achievement based on fatigue rules
    public func effectiveTier(for achievement: Achievement, now: Date = Date()) -> CelebrationTier {
        switch achievement.tier {
        case .major:
            if canShowTier3(now: now) {
                return .major
            } else if canShowTier2(now: now) {
                return .notable
            } else {
                return .subtle
            }
        case .notable:
            if canShowTier2(now: now) {
                return .notable
            } else {
                return .subtle
            }
        case .subtle:
            return .subtle
        }
    }

    // MARK: - Mutations

    /// Record an achievement as unlocked
    public mutating func unlock(_ achievement: Achievement, at date: Date = Date()) {
        unlockedAchievements[achievement.id] = date

        // Update personal best if applicable
        if let value = achievement.value {
            let categoryKey = achievement.category.rawValue
            if isPersonalBest(for: categoryKey, value: value) {
                personalBests[categoryKey] = value
            }
        }
    }

    /// Record that a Tier 2 celebration was shown
    public mutating func recordTier2Shown(at date: Date = Date()) {
        lastTier2Date = date
    }

    /// Record that a Tier 3 celebration was shown
    public mutating func recordTier3Shown(at date: Date = Date()) {
        lastTier3Date = date
    }

    /// Add an achievement to the queue
    public mutating func queueAchievement(_ achievementId: String) {
        if !queuedAchievements.contains(achievementId) {
            queuedAchievements.append(achievementId)
        }
    }

    /// Pop the next achievement from the queue
    public mutating func popQueuedAchievement() -> String? {
        guard !queuedAchievements.isEmpty else { return nil }
        return queuedAchievements.removeFirst()
    }

    /// Clear the queue
    public mutating func clearQueue() {
        queuedAchievements.removeAll()
    }
}

// MARK: - Celebration Settings

/// User preferences for celebration behavior
public enum CelebrationStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    /// All celebration tiers as designed
    case full
    /// Tier 2 becomes Tier 1, Tier 3 becomes Tier 2
    case subtle
    /// All celebrations are Tier 1 style
    case minimal
    /// No celebration UI (achievements still tracked)
    case off

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .full: return String(localized: "Full celebrations")
        case .subtle: return String(localized: "Subtle only")
        case .minimal: return String(localized: "Minimal")
        case .off: return String(localized: "Off")
        }
    }

    public var description: String {
        switch self {
        case .full: return String(localized: "All celebration tiers as designed")
        case .subtle: return String(localized: "Tier 3 becomes card, Tier 2 becomes shimmer")
        case .minimal: return String(localized: "All celebrations become inline shimmer")
        case .off: return String(localized: "No celebration UI (achievements still tracked)")
        }
    }

    /// Transform an achievement tier based on this style preference
    public func transform(_ tier: CelebrationTier) -> CelebrationTier? {
        switch self {
        case .full:
            return tier
        case .subtle:
            switch tier {
            case .major: return .notable
            case .notable, .subtle: return .subtle
            }
        case .minimal:
            return .subtle
        case .off:
            return nil
        }
    }
}
