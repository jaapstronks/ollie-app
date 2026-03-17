//
//  PatternCalculations.swift
//  Otis-app
//
//  Pattern analysis calculations for trigger success rates
//  Optimized: Uses single-pass categorization to avoid repeated filtering

import Foundation
import OtisShared
import SwiftUI

/// A trigger pattern that may lead to potty events
struct PatternTrigger: Identifiable, Equatable {
    let id: String
    let name: String       // "Na slaap", "Na eten"
    let iconName: String   // SF Symbol name
    let iconColor: Color   // Icon tint color
    let outdoorCount: Int
    let indoorCount: Int

    init(id: String, name: String, iconName: String, iconColor: Color, outdoorCount: Int, indoorCount: Int) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.iconColor = iconColor
        self.outdoorCount = outdoorCount
        self.indoorCount = indoorCount
    }

    var totalCount: Int {
        outdoorCount + indoorCount
    }

    var successRate: Int {
        guard totalCount > 0 else { return 0 }
        return (outdoorCount * 100) / totalCount
    }

    var hasData: Bool {
        totalCount > 0
    }
}

/// Result of pattern analysis
struct PatternAnalysis: Equatable {
    let triggers: [PatternTrigger]
    let periodDays: Int

    var hasTriggers: Bool {
        triggers.contains { $0.hasData }
    }

    static var empty: PatternAnalysis {
        PatternAnalysis(triggers: [], periodDays: 0)
    }
}

/// Pattern calculation utilities
struct PatternCalculations {

    /// Time window after a trigger event to count as "triggered" (in minutes)
    static let triggerWindowMinutes = 30

    // MARK: - Public Methods

    /// Analyze patterns in potty events to find trigger success rates
    /// Optimized: categorizes events in single pass, then analyzes each trigger type
    /// - Parameters:
    ///   - events: Array of puppy events (ideally 7+ days)
    ///   - periodDays: Number of days included in analysis
    /// - Returns: Pattern analysis with trigger success rates
    static func analyzePatterns(events: [PuppyEvent], periodDays: Int = 7) -> PatternAnalysis {
        // Single-pass categorization - O(n) instead of O(6n) with repeated filters
        let categories = events.categorized()

        // Analyze each trigger type using pre-categorized refs
        let triggers = [
            analyzeSleepTrigger(categories: categories),
            analyzeMealTrigger(categories: categories),
            analyzeWalkTrigger(categories: categories),
            analyzeWaterTrigger(categories: categories),
            analyzePlayTrigger(categories: categories)
        ]

        return PatternAnalysis(triggers: triggers, periodDays: periodDays)
    }

    // MARK: - Individual Trigger Analysis (Optimized)

    /// Analyze post-sleep potty patterns
    private static func analyzeSleepTrigger(categories: EventCategories) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        for wakeRef in categories.wakes {
            if let pottyRef = categories.firstPottyAfter(time: wakeRef.time) {
                if pottyRef.location == .buiten {
                    outdoorCount += 1
                } else if pottyRef.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "sleep",
            name: Strings.Patterns.afterSleep,
            iconName: "moon.zzz.fill",
            iconColor: .otisSleep,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-meal potty patterns
    private static func analyzeMealTrigger(categories: EventCategories) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        for mealRef in categories.meals {
            if let pottyRef = categories.firstPottyAfter(time: mealRef.time) {
                if pottyRef.location == .buiten {
                    outdoorCount += 1
                } else if pottyRef.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "meal",
            name: Strings.Patterns.afterEating,
            iconName: "fork.knife",
            iconColor: .otisAccent,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-walk potty patterns (during or right after walk)
    private static func analyzeWalkTrigger(categories: EventCategories) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        for walkRef in categories.walks {
            // Use wider window (60 min) since walks can be longer
            if let pottyRef = categories.firstPottyAfter(time: walkRef.time, windowMinutes: 60) {
                if pottyRef.location == .buiten {
                    outdoorCount += 1
                } else if pottyRef.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "walk",
            name: Strings.Patterns.duringWalk,
            iconName: "figure.walk",
            iconColor: .otisAccent,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-water potty patterns
    private static func analyzeWaterTrigger(categories: EventCategories) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        for drinkRef in categories.drinks {
            if let pottyRef = categories.firstPottyAfter(time: drinkRef.time) {
                if pottyRef.location == .buiten {
                    outdoorCount += 1
                } else if pottyRef.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "water",
            name: Strings.Patterns.afterDrinking,
            iconName: "drop.fill",
            iconColor: .otisInfo,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-play potty patterns (training/social as proxies for play)
    private static func analyzePlayTrigger(categories: EventCategories) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        // Combine training and social refs (already categorized)
        let playRefs = categories.trainingSessions + categories.socialEvents

        for playRef in playRefs {
            if let pottyRef = categories.firstPottyAfter(time: playRef.time) {
                if pottyRef.location == .buiten {
                    outdoorCount += 1
                } else if pottyRef.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "play",
            name: Strings.Patterns.afterPlaying,
            iconName: "tennisball.fill",
            iconColor: .otisAccent,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }
}
