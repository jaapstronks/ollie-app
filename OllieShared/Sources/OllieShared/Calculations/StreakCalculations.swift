//
//  StreakCalculations.swift
//  OllieShared
//
//  Streak calculations ported from web app's streaks.js
//  Note: iconColor method is in iOS-only extension

import Foundation

/// Streak information
public struct StreakInfo: Equatable, Sendable {
    public let currentStreak: Int
    public let bestStreak: Int
    public let lastOutdoorTime: Date?
    public let lastIndoorTime: Date?

    public init(currentStreak: Int, bestStreak: Int, lastOutdoorTime: Date?, lastIndoorTime: Date?) {
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastOutdoorTime = lastOutdoorTime
        self.lastIndoorTime = lastIndoorTime
    }

    public var hasActiveStreak: Bool {
        currentStreak > 0
    }

    public var isOnFire: Bool {
        currentStreak >= 5
    }

    public static var empty: StreakInfo {
        StreakInfo(
            currentStreak: 0,
            bestStreak: 0,
            lastOutdoorTime: nil,
            lastIndoorTime: nil
        )
    }
}

/// Streak calculation utilities
public struct StreakCalculations {

    // MARK: - Public Methods

    /// Calculate current consecutive outdoor potty streak
    public static func calculateCurrentStreak(events: [PuppyEvent]) -> Int {
        let pottyEvents = events.pee().reverseChronological()

        var streak = 0
        for event in pottyEvents {
            if event.location == .buiten {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    /// Calculate best ever streak
    public static func calculateBestStreak(events: [PuppyEvent]) -> Int {
        let pottyEvents = events.pee().chronological()

        var bestStreak = 0
        var currentStreak = 0

        for event in pottyEvents {
            if event.location == .buiten {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return bestStreak
    }

    /// Get full streak information
    /// Coverage gaps do NOT break streaks - the streak continues across gaps
    public static func getStreakInfo(events: [PuppyEvent], coverageGaps: [PuppyEvent] = []) -> StreakInfo {
        // Filter out potty events that occurred during coverage gaps
        let allPotty = events.pee().chronological()
        let pottyEvents: [PuppyEvent]

        if coverageGaps.isEmpty {
            pottyEvents = allPotty
        } else {
            pottyEvents = allPotty.filter { event in
                !CoverageGapFilter.isTimeCoveredByGap(event.time, gaps: coverageGaps)
            }
        }

        guard !pottyEvents.isEmpty else { return .empty }

        var bestStreak = 0
        var runningStreak = 0

        for event in pottyEvents {
            if event.location == .buiten {
                runningStreak += 1
                bestStreak = max(bestStreak, runningStreak)
            } else {
                runningStreak = 0
            }
        }

        let reversed = pottyEvents.reversed()
        var currentStreak = 0

        for event in reversed {
            if event.location == .buiten {
                currentStreak += 1
            } else {
                break
            }
        }

        let lastOutdoor = pottyEvents.last { $0.location == .buiten }
        let lastIndoor = pottyEvents.last { $0.location == .binnen }

        return StreakInfo(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            lastOutdoorTime: lastOutdoor?.time,
            lastIndoorTime: lastIndoor?.time
        )
    }

    /// Get SF Symbol icon name for streak count
    public static func iconName(for streak: Int) -> String {
        if streak == 0 {
            return "heart.slash.fill"
        } else if streak < 3 {
            return "hand.thumbsup.fill"
        } else if streak < 5 {
            return "flame.fill"
        } else {
            return "flame.fill"
        }
    }

    /// Get motivational message for streak
    public static func message(for streak: Int) -> String {
        if streak == 0 {
            return Strings.Stats.streakStartAgain
        } else if streak == 1 {
            return Strings.Stats.streakGoodStart
        } else if streak < 3 {
            return Strings.Stats.streakNiceWork
        } else if streak < 5 {
            return Strings.Stats.streakSuperKeepGoing
        } else if streak < 10 {
            return Strings.Stats.streakFantastic
        } else {
            return Strings.Stats.streakIncredible
        }
    }
}
