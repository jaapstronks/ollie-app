//
//  AINudgeOrchestrator+RequestBuilder.swift
//  Otis-app
//
//  Request building and context construction for AI nudge orchestration.
//

import Foundation
import OtisShared

// MARK: - Context Building

extension AINudgeOrchestrator {

    struct PeriodStats {
        var walkAvg: Double?
        var mealAvg: Double?
        var pottyAvg: Double?
        var trainingAvg: Double?
    }

    func buildContext(profile: PuppyProfile, recentEvents: [PuppyEvent]) -> AINudgeContextSummary {
        let (recentStats, priorStats) = calculateHistoricalStats(events: recentEvents)

        return .init(
            ageWeeks: profile.ageInWeeks,
            daysHome: profile.daysHome,
            recentEventCount: recentEvents.count,
            recentWalkCount: recentEvents.walks().count,
            recentMealCount: recentEvents.meals().count,
            recentPottyCount: recentEvents.pee().count,
            recentDaysWalkAvg: recentStats.walkAvg,
            priorDaysWalkAvg: priorStats.walkAvg,
            recentDaysMealAvg: recentStats.mealAvg,
            priorDaysMealAvg: priorStats.mealAvg,
            recentDaysPottyAvg: recentStats.pottyAvg,
            priorDaysPottyAvg: priorStats.pottyAvg,
            recentDaysTrainingAvg: recentStats.trainingAvg,
            priorDaysTrainingAvg: priorStats.trainingAvg
        )
    }

    /// Calculate average daily counts for recent (last 3 days) vs prior (4 days before that)
    func calculateHistoricalStats(events: [PuppyEvent]) -> (recent: PeriodStats, prior: PeriodStats) {
        let calendar = Calendar.current
        let now = Date()

        // Recent period: last 3 days (including today)
        let recentStart = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!
        // Prior period: 4 days before that
        let priorStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!

        let recentEvents = events.filter { $0.time >= recentStart }
        let priorEvents = events.filter { $0.time >= priorStart && $0.time < recentStart }

        // Calculate averages (recent = 3 days, prior = 4 days)
        let recentDays = 3.0
        let priorDays = 4.0

        let recentStats = PeriodStats(
            walkAvg: Double(recentEvents.walks().count) / recentDays,
            mealAvg: Double(recentEvents.meals().count) / recentDays,
            pottyAvg: Double(recentEvents.potty().count) / recentDays,
            trainingAvg: Double(recentEvents.training().count) / recentDays
        )

        // Only include prior stats if we have enough history
        let priorStats: PeriodStats
        if !priorEvents.isEmpty {
            priorStats = PeriodStats(
                walkAvg: Double(priorEvents.walks().count) / priorDays,
                mealAvg: Double(priorEvents.meals().count) / priorDays,
                pottyAvg: Double(priorEvents.potty().count) / priorDays,
                trainingAvg: Double(priorEvents.training().count) / priorDays
            )
        } else {
            priorStats = PeriodStats(walkAvg: nil, mealAvg: nil, pottyAvg: nil, trainingAvg: nil)
        }

        return (recentStats, priorStats)
    }

    func inferStaleCategories(from events: [PuppyEvent]) -> [AILoggingCategory] {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 3600)
        let recent = events.filter { $0.time >= oneDayAgo }
        var stale: [AILoggingCategory] = []

        if recent.pee().isEmpty { stale.append(.potty) }
        if recent.walks().isEmpty { stale.append(.walk) }
        if recent.meals().isEmpty { stale.append(.meal) }
        if !recent.contains(where: { $0.type == .training }) { stale.append(.training) }
        if !recent.contains(where: { $0.type == .sociaal }) { stale.append(.socialization) }
        return stale
    }

    func pottyPredictionFromEvents(_ recentEvents: [PuppyEvent]) -> PottyPrediction {
        let config = PredictionConfig.defaultConfig()
        let gaps = GapCalculations.recentGaps(events: recentEvents, days: 7)
        let gapStats = GapCalculations.calculateGapStats(gaps: gaps)
        return PredictionCalculations.calculatePrediction(
            events: recentEvents,
            config: config,
            gapStats: gapStats
        )
    }

    func stableUpcomingID(_ item: UpcomingItem) -> String {
        "\(item.itemType.eventType.rawValue)|\(item.targetTime.timeIntervalSince1970)|\(item.label)"
    }

    func stateKey(_ state: ActionableItemState) -> String {
        switch state {
        case .overdue: return "overdue"
        case .due: return "due"
        case .approaching: return "approaching"
        }
    }
}
