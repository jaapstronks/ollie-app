//
//  StreakCalculations.swift
//  Ollie-app
//
//  Streak calculations ported from web app's streaks.js

import Foundation

/// Streak information
struct StreakInfo: Equatable {
    let currentStreak: Int
    let bestStreak: Int
    let lastOutdoorTime: Date?
    let lastIndoorTime: Date?

    var hasActiveStreak: Bool {
        currentStreak > 0
    }

    var isOnFire: Bool {
        currentStreak >= 5
    }

    static var empty: StreakInfo {
        StreakInfo(
            currentStreak: 0,
            bestStreak: 0,
            lastOutdoorTime: nil,
            lastIndoorTime: nil
        )
    }
}

/// Streak calculation utilities
struct StreakCalculations {

    // MARK: - Public Methods

    /// Calculate current consecutive outdoor potty streak (from most recent)
    /// - Parameter events: Array of puppy events
    /// - Returns: Number of consecutive outdoor potty events
    static func calculateCurrentStreak(events: [PuppyEvent]) -> Int {
        let pottyEvents = events
            .filter { $0.type == .plassen }
            .sorted { $0.time > $1.time }  // Most recent first

        var streak = 0
        for event in pottyEvents {
            if event.location == .buiten {
                streak += 1
            } else {
                break  // Indoor event breaks the streak
            }
        }
        return streak
    }

    /// Calculate best ever streak
    /// - Parameter events: Array of puppy events
    /// - Returns: Longest consecutive outdoor streak
    static func calculateBestStreak(events: [PuppyEvent]) -> Int {
        let pottyEvents = events
            .filter { $0.type == .plassen }
            .sorted { $0.time < $1.time }  // Chronological

        var bestStreak = 0
        var currentStreak = 0

        for event in pottyEvents {
            if event.location == .buiten {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0  // Reset on indoor
            }
        }

        return bestStreak
    }

    /// Get full streak information
    /// - Parameter events: Array of puppy events
    /// - Returns: StreakInfo with current and best streaks
    static func getStreakInfo(events: [PuppyEvent]) -> StreakInfo {
        let pottyEvents = events
            .filter { $0.type == .plassen }
            .sorted { $0.time < $1.time }

        guard !pottyEvents.isEmpty else { return .empty }

        // Calculate best streak
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

        // Calculate current streak (from most recent)
        let reversed = pottyEvents.reversed()
        var currentStreak = 0

        for event in reversed {
            if event.location == .buiten {
                currentStreak += 1
            } else {
                break
            }
        }

        // Find last outdoor and indoor times
        let lastOutdoor = pottyEvents.last { $0.location == .buiten }
        let lastIndoor = pottyEvents.last { $0.location == .binnen }

        return StreakInfo(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            lastOutdoorTime: lastOutdoor?.time,
            lastIndoorTime: lastIndoor?.time
        )
    }

    /// Get emoji for streak count
    static func emoji(for streak: Int) -> String {
        if streak == 0 {
            return "💔"
        } else if streak < 3 {
            return "👍"
        } else if streak < 5 {
            return "🔥"
        } else if streak < 10 {
            return "🔥🔥"
        } else {
            return "🔥🔥🔥"
        }
    }

    /// Get motivational message for streak (Dutch)
    static func message(for streak: Int) -> String {
        if streak == 0 {
            return "Begin opnieuw!"
        } else if streak == 1 {
            return "Goed begin!"
        } else if streak < 3 {
            return "Lekker bezig!"
        } else if streak < 5 {
            return "Super! Houd vol!"
        } else if streak < 10 {
            return "Fantastisch! 🎉"
        } else {
            return "Ongelofelijk! 🏆"
        }
    }
}
