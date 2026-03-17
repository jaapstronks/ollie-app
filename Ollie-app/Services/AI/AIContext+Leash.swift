//
//  AIContext+Leash.swift
//  Ollie-app
//
//  Leash behavior context for AI integration

import Foundation
import OtisShared

// MARK: - Leash Behavior Context

/// Context about leash walking behavior for AI processing
struct LeashBehaviorContext: Codable {
    /// Recent sentiment average (last 14 days)
    let recentAverage: Double?

    /// Previous period sentiment average (15-28 days ago)
    let previousPeriodAverage: Double?

    /// Trend compared to previous period
    let trend: String?  // "improving", "stable", "declining"

    /// Total number of sentiment ratings ever
    let totalRatings: Int

    /// Most recent rating score
    let lastRating: Int?

    /// Date of most recent rating
    let lastRatingDate: Date?

    /// Whether leash training is marked as mastered
    let isMastered: Bool

    /// Date when leash training was marked as mastered
    let masteredDate: Date?
}

// MARK: - AI Context Extension

extension AIContextBuilder {

    /// Build leash behavior context for AI
    @MainActor
    func buildLeashBehaviorContext() -> LeashBehaviorContext {
        let sentimentStore = SentimentStore.shared
        let masteryStore = TrainingMasteryStore.shared

        // Get recent check-ins
        let recentCheckIn = sentimentStore.checkIns[.leashBehavior]
        let recentAverage: Double?
        let totalRatings: Int

        if let checkIn = recentCheckIn,
           checkIn.date > Date().addingTimeInterval(-14 * 86400) {
            recentAverage = Double(checkIn.score)
            totalRatings = 1  // Store only keeps latest
        } else {
            recentAverage = nil
            totalRatings = 0
        }

        // Previous period average (we don't have historical data in current store)
        let previousPeriodAverage: Double? = nil

        // Calculate trend
        let trend: String? = nil  // Can't calculate without historical data

        // Last rating info
        let lastRating = recentCheckIn?.score
        let lastRatingDate = recentCheckIn?.date

        return LeashBehaviorContext(
            recentAverage: recentAverage,
            previousPeriodAverage: previousPeriodAverage,
            trend: trend,
            totalRatings: totalRatings,
            lastRating: lastRating,
            lastRatingDate: lastRatingDate,
            isMastered: masteryStore.leashTrainingMastered,
            masteredDate: masteryStore.leashMasteredDate
        )
    }

    /// Build leash behavior summary for AI dog summary
    @MainActor
    func leashBehaviorSummary() -> String {
        let context = buildLeashBehaviorContext()

        if context.isMastered {
            if let date = context.masteredDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Leash walking: Mastered (since \(formatter.string(from: date)))"
            }
            return "Leash walking: Mastered"
        }

        if let avg = context.recentAverage {
            var summary = "Leash walking: \(String(format: "%.1f", avg))/5 average"
            if let trend = context.trend {
                summary += " (\(trend))"
            }
            return summary
        }

        return "Leash walking: No ratings yet"
    }
}

// MARK: - AI Instructions Integration

extension AIInstructions {

    /// Add leash behavior to the dog context
    static func leashBehaviorSection(context: LeashBehaviorContext) -> String {
        var lines: [String] = []
        lines.append("## Leash Walking")

        if context.isMastered {
            lines.append("- Status: Mastered")
            if let date = context.masteredDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                lines.append("- Mastered since: \(formatter.string(from: date))")
            }
        } else {
            if let avg = context.recentAverage {
                lines.append("- Recent average rating: \(String(format: "%.1f", avg))/5")
            } else {
                lines.append("- No ratings yet")
            }

            if let trend = context.trend {
                lines.append("- Trend: \(trend)")
            }
        }

        if let lastRating = context.lastRating, let lastDate = context.lastRatingDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            lines.append("- Last rating: \(lastRating)/5 on \(formatter.string(from: lastDate))")
        }

        return lines.joined(separator: "\n")
    }
}
