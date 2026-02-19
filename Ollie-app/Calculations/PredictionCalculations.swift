//
//  PredictionCalculations.swift
//  Ollie-app
//
//  Potty prediction calculations ported from web app's predictions.js

import Foundation
import SwiftUI

/// Urgency level for potty predictions
enum PottyUrgency: Equatable {
    /// Just went outside < 15 min ago
    case justWent
    /// Normal countdown, plenty of time
    case normal(minutesRemaining: Int)
    /// Getting closer, 10-20 min remaining
    case attention(minutesRemaining: Int)
    /// Very soon, < 10 min remaining
    case soon(minutesRemaining: Int)
    /// Past expected time
    case overdue(minutesOverdue: Int)
    /// After an indoor accident - go outside now
    case postAccident
    /// No data available
    case unknown

    var isUrgent: Bool {
        switch self {
        case .soon, .overdue, .postAccident:
            return true
        default:
            return false
        }
    }
}

/// Active trigger that shortens the expected potty interval
enum PottyTrigger: Equatable {
    case postMeal(minutesAgo: Int)
    case postSleep(minutesAgo: Int)
    case none
}

/// Prediction result with all context
struct PottyPrediction: Equatable {
    let urgency: PottyUrgency
    let trigger: PottyTrigger
    let expectedGapMinutes: Int
    let minutesSinceLast: Int?
    let lastWasIndoor: Bool
}

/// Potty prediction calculation utilities
struct PredictionCalculations {

    /// Time window after meal to apply post-meal trigger (minutes)
    static let postMealWindowMinutes = 30

    /// Time window after wake to apply post-sleep trigger (minutes)
    static let postSleepWindowMinutes = 20

    /// Threshold for "just went" state (minutes)
    static let justWentThresholdMinutes = 15

    /// Threshold for "attention" state (minutes remaining)
    static let attentionThresholdMinutes = 20

    /// Threshold for "soon" state (minutes remaining)
    static let soonThresholdMinutes = 10

    // MARK: - Public Methods

    /// Calculate potty prediction with urgency level
    /// - Parameters:
    ///   - events: Recent puppy events (today + yesterday)
    ///   - config: Prediction configuration from profile
    /// - Returns: Full prediction with urgency, triggers, and timing
    static func calculatePrediction(
        events: [PuppyEvent],
        config: PredictionConfig
    ) -> PottyPrediction {
        // Find last potty event
        let lastPlas = events
            .filter { $0.type == .plassen }
            .sorted { $0.time < $1.time }
            .last

        // Check for recent indoor accident
        if let last = lastPlas, last.location == .binnen {
            let minutesSince = Date().minutesSince(last.time)
            if minutesSince < justWentThresholdMinutes {
                return PottyPrediction(
                    urgency: .postAccident,
                    trigger: .none,
                    expectedGapMinutes: 0,
                    minutesSinceLast: minutesSince,
                    lastWasIndoor: true
                )
            }
        }

        guard let last = lastPlas else {
            return PottyPrediction(
                urgency: .unknown,
                trigger: .none,
                expectedGapMinutes: config.defaultGapMinutes,
                minutesSinceLast: nil,
                lastWasIndoor: false
            )
        }

        let minutesSince = Date().minutesSince(last.time)
        let lastWasIndoor = last.location == .binnen

        // Check for triggers that shorten the expected gap
        let trigger = detectTrigger(events: events, lastPlasTime: last.time)
        let expectedGap = calculateExpectedGap(
            baseGap: config.defaultGapMinutes,
            trigger: trigger,
            config: config
        )

        // Calculate urgency based on time remaining
        let urgency = calculateUrgency(
            minutesSince: minutesSince,
            expectedGap: expectedGap,
            lastWasOutdoor: last.location == .buiten
        )

        return PottyPrediction(
            urgency: urgency,
            trigger: trigger,
            expectedGapMinutes: expectedGap,
            minutesSinceLast: minutesSince,
            lastWasIndoor: lastWasIndoor
        )
    }

    /// Get emoji for urgency level (legacy)
    static func emoji(for urgency: PottyUrgency) -> String {
        switch urgency {
        case .justWent:
            return "✅"
        case .normal:
            return "🚽"
        case .attention:
            return "🚽"
        case .soon:
            return "⚠️"
        case .overdue:
            return "🚨"
        case .postAccident:
            return "⚠️"
        case .unknown:
            return "❓"
        }
    }

    /// Get SF Symbol icon name for urgency level
    static func iconName(for urgency: PottyUrgency) -> String {
        switch urgency {
        case .justWent:
            return "checkmark.circle.fill"
        case .normal:
            return "clock.fill"
        case .attention:
            return "clock.badge.exclamationmark.fill"
        case .soon:
            return "exclamationmark.triangle.fill"
        case .overdue:
            return "bell.badge.fill"
        case .postAccident:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    /// Get icon color for urgency level
    static func iconColor(for urgency: PottyUrgency) -> Color {
        switch urgency {
        case .justWent:
            return .ollieSuccess
        case .normal:
            return .ollieInfo
        case .attention:
            return .ollieAccent
        case .soon:
            return .ollieWarning
        case .overdue:
            return .ollieDanger
        case .postAccident:
            return .ollieDanger
        case .unknown:
            return .ollieMuted
        }
    }

    /// Get display text for urgency level (Dutch)
    static func displayText(for prediction: PottyPrediction, puppyName: String = "Puppy") -> String {
        switch prediction.urgency {
        case .justWent:
            return "Net geplast"
        case .normal(let remaining):
            return "Volgende over ~\(remaining) min"
        case .attention(let remaining):
            return "Volgende over ~\(remaining) min"
        case .soon(let remaining):
            if remaining <= 0 {
                return "Binnenkort!"
            }
            return "Nog ~\(remaining) min"
        case .overdue(let overdue):
            if overdue < 5 {
                return "\(puppyName) moet nu plassen!"
            }
            return "\(puppyName) moet nu plassen! (\(overdue) min over tijd)"
        case .postAccident:
            return "Na ongelukje — nu naar buiten!"
        case .unknown:
            return "Nog geen data"
        }
    }

    /// Get subtitle text with trigger info (Dutch)
    static func subtitleText(for prediction: PottyPrediction) -> String? {
        guard let minutes = prediction.minutesSinceLast else { return nil }

        var parts: [String] = []

        // Time since last
        if minutes < 60 {
            parts.append("\(minutes) min geleden")
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                parts.append("\(hours) uur geleden")
            } else {
                parts.append("\(hours)u \(mins)m geleden")
            }
        }

        // Add trigger info
        switch prediction.trigger {
        case .postMeal(let ago):
            parts.append("(na eten \(ago)m geleden)")
        case .postSleep(let ago):
            parts.append("(na dutje \(ago)m geleden)")
        case .none:
            break
        }

        // Add indoor warning
        if prediction.lastWasIndoor {
            parts.append("- binnen")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Private Helpers

    /// Detect if a trigger is active (post-meal or post-sleep)
    private static func detectTrigger(events: [PuppyEvent], lastPlasTime: Date) -> PottyTrigger {
        let now = Date()

        // Check for recent meal AFTER last plas
        let recentMeal = events
            .filter { $0.type == .eten && $0.time > lastPlasTime }
            .sorted { $0.time < $1.time }
            .last

        if let meal = recentMeal {
            let minutesSinceMeal = now.minutesSince(meal.time)
            if minutesSinceMeal <= postMealWindowMinutes {
                return .postMeal(minutesAgo: minutesSinceMeal)
            }
        }

        // Check for recent wake from significant nap AFTER last plas
        if SleepCalculations.justWokeFromSignificantNap(events: events, windowMinutes: postSleepWindowMinutes) {
            // Find the wake event
            let wakeEvents = events
                .filter { $0.type == .ontwaken && $0.time > lastPlasTime }
                .sorted { $0.time < $1.time }

            if let lastWake = wakeEvents.last {
                let minutesSinceWake = now.minutesSince(lastWake.time)
                if minutesSinceWake <= postSleepWindowMinutes {
                    return .postSleep(minutesAgo: minutesSinceWake)
                }
            }
        }

        return .none
    }

    /// Calculate expected gap with trigger adjustments
    private static func calculateExpectedGap(
        baseGap: Int,
        trigger: PottyTrigger,
        config: PredictionConfig
    ) -> Int {
        switch trigger {
        case .postMeal:
            return Int(Double(baseGap) * config.postMealGapMultiplier)
        case .postSleep:
            return Int(Double(baseGap) * config.postSleepGapMultiplier)
        case .none:
            return baseGap
        }
    }

    /// Calculate urgency level based on timing
    private static func calculateUrgency(
        minutesSince: Int,
        expectedGap: Int,
        lastWasOutdoor: Bool
    ) -> PottyUrgency {
        // Just went (outdoor only, < 15 min ago)
        if lastWasOutdoor && minutesSince < justWentThresholdMinutes {
            return .justWent
        }

        let remaining = expectedGap - minutesSince

        if remaining <= 0 {
            return .overdue(minutesOverdue: abs(remaining))
        } else if remaining < soonThresholdMinutes {
            return .soon(minutesRemaining: remaining)
        } else if remaining < attentionThresholdMinutes {
            return .attention(minutesRemaining: remaining)
        } else {
            return .normal(minutesRemaining: remaining)
        }
    }
}
