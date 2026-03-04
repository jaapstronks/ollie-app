//
//  PredictionCalculations.swift
//  Otis-app
//
//  Potty prediction calculations ported from web app's predictions.js

import Foundation
import OtisShared
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
    /// Tracking paused - puppy is with someone else
    case coverageGap(type: CoverageGapType, since: Date)
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

    var isPaused: Bool {
        if case .coverageGap = self {
            return true
        }
        return false
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

    /// Minimum number of gaps required to use historical median
    static let minGapsForMedian = 5

    /// Minimum overdue threshold before showing rounded bucket (< 15 min shows "now" without minutes)
    static let overdueRoundingThresholdMinutes = 15

    // MARK: - Overdue Rounding

    /// Round overdue minutes to friendly buckets: "15+", "30+", "45+", "1h+", "2h+", etc.
    /// Returns nil if overdue is below threshold (should just say "now" without specific time)
    static func roundedOverdueBucket(_ minutes: Int) -> String? {
        if minutes < overdueRoundingThresholdMinutes {
            return nil // Below threshold, don't show specific time
        } else if minutes < 30 {
            return "15+ min"
        } else if minutes < 45 {
            return "30+ min"
        } else if minutes < 60 {
            return "45+ min"
        } else if minutes < 120 {
            return "1h+"
        } else {
            let hours = minutes / 60
            return "\(hours)h+"
        }
    }

    // MARK: - Public Methods

    /// Calculate potty prediction with urgency level
    /// - Parameters:
    ///   - events: Recent puppy events (today + yesterday)
    ///   - config: Prediction configuration from profile
    ///   - gapStats: Optional historical gap statistics for pattern-based predictions
    /// - Returns: Full prediction with urgency, triggers, and timing
    static func calculatePrediction(
        events: [PuppyEvent],
        config: PredictionConfig,
        gapStats: GapStats? = nil
    ) -> PottyPrediction {
        // Determine base gap: use historical median if sufficient data, otherwise default
        let baseGap = calculateBaseGap(gapStats: gapStats, config: config)
        // Check for active coverage gap first - tracking is paused
        if let activeGap = events.activeGaps().first,
           let gapType = activeGap.gapType {
            return PottyPrediction(
                urgency: .coverageGap(type: gapType, since: activeGap.time),
                trigger: .none,
                expectedGapMinutes: baseGap,
                minutesSinceLast: nil,
                lastWasIndoor: false
            )
        }

        // Find last potty event
        let lastPlas = events.pee().chronological().last

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
                expectedGapMinutes: baseGap,
                minutesSinceLast: nil,
                lastWasIndoor: false
            )
        }

        let minutesSince = Date().minutesSince(last.time)
        let lastWasIndoor = last.location == .binnen

        // Check for triggers that shorten the expected gap
        let trigger = detectTrigger(events: events, lastPlasTime: last.time)
        let expectedGap = calculateExpectedGap(
            baseGap: baseGap,
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
        case .coverageGap(let type, _):
            return type.icon
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    /// Get icon color for urgency level
    static func iconColor(for urgency: PottyUrgency) -> Color {
        switch urgency {
        case .justWent:
            return .otisSuccess
        case .normal:
            return .otisInfo
        case .attention:
            return .otisAccent
        case .soon:
            return .otisWarning
        case .overdue:
            return .otisDanger
        case .postAccident:
            return .otisDanger
        case .coverageGap:
            return .orange
        case .unknown:
            return .otisMuted
        }
    }

    /// Get display text for urgency level (Dutch)
    static func displayText(for prediction: PottyPrediction, puppyName: String = "Puppy") -> String {
        switch prediction.urgency {
        case .justWent:
            return Strings.Prediction.justPeed
        case .normal(let remaining):
            return Strings.Prediction.nextIn(remaining)
        case .attention(let remaining):
            return Strings.Prediction.nextIn(remaining)
        case .soon(let remaining):
            if remaining <= 0 {
                return Strings.Prediction.soon
            }
            return Strings.TimeFormat.stillMinutes(remaining)
        case .overdue(let overdue):
            // Use rounded bucket for overdue display (15+, 30+, 45+, 1h+)
            // Below threshold just says "needs to pee now" without specific time
            if let bucket = roundedOverdueBucket(overdue) {
                return Strings.Prediction.needsToPeeNowOverdueRounded(name: puppyName, bucket: bucket)
            }
            return Strings.Prediction.needsToPeeNow(name: puppyName)
        case .postAccident:
            return Strings.Prediction.afterAccidentGoOutside
        case .coverageGap:
            return Strings.CoverageGap.trackingPaused
        case .unknown:
            return Strings.TimeFormat.noData
        }
    }

    /// Get subtitle text with trigger info
    static func subtitleText(for prediction: PottyPrediction) -> String? {
        guard let minutes = prediction.minutesSinceLast else { return nil }

        var parts: [String] = []

        // Time since last
        if minutes < 60 {
            parts.append(Strings.TimeFormat.minutesAgo(minutes))
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                parts.append(Strings.TimeFormat.hoursAgo(hours))
            } else {
                parts.append(Strings.TimeFormat.hoursMinutesAgo(hours: hours, minutes: mins))
            }
        }

        // Add trigger info
        switch prediction.trigger {
        case .postMeal(let ago):
            parts.append(Strings.TimeFormat.afterEatingAgo(ago))
        case .postSleep(let ago):
            parts.append(Strings.TimeFormat.afterNapAgo(ago))
        case .none:
            break
        }

        // Add indoor warning
        if prediction.lastWasIndoor {
            parts.append(Strings.TimeFormat.inside)
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Private Helpers

    /// Determine base gap from historical data or config default
    /// Uses historical median when sufficient data is available (more robust to outliers)
    private static func calculateBaseGap(gapStats: GapStats?, config: PredictionConfig) -> Int {
        guard let stats = gapStats,
              stats.count >= minGapsForMedian,
              stats.medianMinutes > 0 else {
            return config.defaultGapMinutes
        }
        return stats.medianMinutes
    }

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
