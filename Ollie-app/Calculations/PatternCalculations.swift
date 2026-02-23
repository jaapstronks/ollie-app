//
//  PatternCalculations.swift
//  Ollie-app
//
//  Pattern analysis calculations for trigger success rates

import Foundation
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
    /// - Parameters:
    ///   - events: Array of puppy events (ideally 7+ days)
    ///   - periodDays: Number of days included in analysis
    /// - Returns: Pattern analysis with trigger success rates
    static func analyzePatterns(events: [PuppyEvent], periodDays: Int = 7) -> PatternAnalysis {
        let sortedEvents = events.sorted { $0.time < $1.time }

        // Analyze each trigger type
        let triggers = [
            analyzeSleepTrigger(events: sortedEvents),
            analyzeMealTrigger(events: sortedEvents),
            analyzeWalkTrigger(events: sortedEvents),
            analyzeWaterTrigger(events: sortedEvents),
            analyzePlayTrigger(events: sortedEvents)
        ]

        return PatternAnalysis(triggers: triggers, periodDays: periodDays)
    }

    // MARK: - Individual Trigger Analysis

    /// Analyze post-sleep potty patterns
    private static func analyzeSleepTrigger(events: [PuppyEvent]) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        // Find all wake events
        let wakeEvents = events.wakes()

        for wakeEvent in wakeEvents {
            // Look for the first potty event within the trigger window
            if let pottyResult = findFirstPottyAfter(time: wakeEvent.time, events: events) {
                if pottyResult.location == .buiten {
                    outdoorCount += 1
                } else if pottyResult.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "sleep",
            name: Strings.Patterns.afterSleep,
            iconName: "moon.zzz.fill",
            iconColor: .ollieSleep,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-meal potty patterns
    private static func analyzeMealTrigger(events: [PuppyEvent]) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        let mealEvents = events.meals()

        for mealEvent in mealEvents {
            if let pottyResult = findFirstPottyAfter(time: mealEvent.time, events: events) {
                if pottyResult.location == .buiten {
                    outdoorCount += 1
                } else if pottyResult.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "meal",
            name: Strings.Patterns.afterEating,
            iconName: "fork.knife",
            iconColor: .ollieAccent,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-walk potty patterns (during or right after walk)
    private static func analyzeWalkTrigger(events: [PuppyEvent]) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        let walkEvents = events.walks()

        for walkEvent in walkEvents {
            // For walks, we look for potty events during or shortly after the walk
            // Use a wider window since walks can be longer
            if let pottyResult = findFirstPottyAfter(time: walkEvent.time, events: events, windowMinutes: 60) {
                if pottyResult.location == .buiten {
                    outdoorCount += 1
                } else if pottyResult.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "walk",
            name: Strings.Patterns.duringWalk,
            iconName: "figure.walk",
            iconColor: .ollieAccent,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-water potty patterns
    private static func analyzeWaterTrigger(events: [PuppyEvent]) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        let waterEvents = events.drinks()

        for waterEvent in waterEvents {
            // Water typically leads to potty within 15-30 minutes
            if let pottyResult = findFirstPottyAfter(time: waterEvent.time, events: events) {
                if pottyResult.location == .buiten {
                    outdoorCount += 1
                } else if pottyResult.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "water",
            name: Strings.Patterns.afterDrinking,
            iconName: "drop.fill",
            iconColor: .ollieInfo,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    /// Analyze post-play potty patterns (training/social as proxies for play)
    private static func analyzePlayTrigger(events: [PuppyEvent]) -> PatternTrigger {
        var outdoorCount = 0
        var indoorCount = 0

        // Training and social events are often high-energy activities
        let playEvents = events.ofTypes([.training, .sociaal])

        for playEvent in playEvents {
            if let pottyResult = findFirstPottyAfter(time: playEvent.time, events: events) {
                if pottyResult.location == .buiten {
                    outdoorCount += 1
                } else if pottyResult.location == .binnen {
                    indoorCount += 1
                }
            }
        }

        return PatternTrigger(
            id: "play",
            name: Strings.Patterns.afterPlaying,
            iconName: "tennisball.fill",
            iconColor: .ollieAccent,
            outdoorCount: outdoorCount,
            indoorCount: indoorCount
        )
    }

    // MARK: - Helpers

    /// Find the first potty event within the trigger window after a given time
    /// - Parameters:
    ///   - time: The trigger event time
    ///   - events: Sorted array of events
    ///   - windowMinutes: Time window to search within
    /// - Returns: The first potty event within the window, or nil
    private static func findFirstPottyAfter(
        time: Date,
        events: [PuppyEvent],
        windowMinutes: Int = triggerWindowMinutes
    ) -> PuppyEvent? {
        let windowEnd = time.addingTimeInterval(Double(windowMinutes * 60))

        // Find first potty event after the trigger time and within the window
        return events.first { event in
            guard event.type == .plassen else { return false }
            guard event.time > time && event.time <= windowEnd else { return false }
            return event.location != nil // Must have location data
        }
    }
}
