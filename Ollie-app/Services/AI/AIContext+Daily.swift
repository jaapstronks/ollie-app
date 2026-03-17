//
//  AIContext+Daily.swift
//  Ollie-app
//
//  Daily AI context components: Potty, Sleep, Feeding, Exercise, Recent Events
//

import Foundation
import OtisShared

// MARK: - Potty Patterns Context

/// Potty training progress and patterns.
struct PottyPatternsContext: AIContextComponent {
    static let componentKey = "potty_patterns"
    static let estimatedTokens = 120

    let minutesSinceLastPee: Int?
    let minutesSinceLastPoop: Int?
    let medianPeeGapMinutes: Int?
    let outdoorStreakCount: Int
    let last24hSuccessRate: Double?
    let isUrgent: Bool
    let predictedMinutesUntilNext: Int?
    let timeOfDayPattern: String?

    init(events: [PuppyEvent], prediction: PottyPrediction?, gapStats: GapStats?) {
        let now = Date()
        let pees = events.pee()
        let poops = events.poop()

        self.minutesSinceLastPee = pees.first.map { Int(now.timeIntervalSince($0.time) / 60) }
        self.minutesSinceLastPoop = poops.first.map { Int(now.timeIntervalSince($0.time) / 60) }
        self.medianPeeGapMinutes = gapStats?.medianMinutes

        // Calculate outdoor streak
        var streak = 0
        for event in pees {
            if event.location == .buiten {
                streak += 1
            } else {
                break
            }
        }
        self.outdoorStreakCount = streak

        // 24h success rate
        let last24h = events.filter { now.timeIntervalSince($0.time) <= 24 * 3600 }
        let pottyEvents = last24h.filter { $0.type == .plassen || $0.type == .poepen }
        let outdoorCount = pottyEvents.filter { $0.location == .buiten }.count
        self.last24hSuccessRate = pottyEvents.isEmpty ? nil : Double(outdoorCount) / Double(pottyEvents.count)

        if let prediction = prediction {
            switch prediction.urgency {
            case .soon, .overdue, .postAccident:
                self.isUrgent = true
            default:
                self.isUrgent = false
            }
            if let minutesSince = prediction.minutesSinceLast {
                self.predictedMinutesUntilNext = max(0, prediction.expectedGapMinutes - minutesSince)
            } else {
                self.predictedMinutesUntilNext = prediction.expectedGapMinutes
            }
        } else {
            self.isUrgent = false
            self.predictedMinutesUntilNext = nil
        }

        self.timeOfDayPattern = nil
    }
}

// MARK: - Sleep Context

/// Current sleep state and patterns.
struct SleepContext: AIContextComponent {
    static let componentKey = "sleep"
    static let estimatedTokens = 60

    let isSleeping: Bool
    let minutesAsleep: Int?
    let minutesAwake: Int?
    let lastNightSleepHours: Double?
    let napsToday: Int
    let napMinutesToday: Int

    init(events: [PuppyEvent], sleepState: SleepState) {
        self.isSleeping = sleepState.isSleeping

        switch sleepState {
        case .sleeping(_, let durationMin):
            self.minutesAsleep = durationMin
            self.minutesAwake = nil
        case .awake(_, let durationMin):
            self.minutesAsleep = nil
            self.minutesAwake = durationMin
        case .unknown:
            self.minutesAsleep = nil
            self.minutesAwake = nil
        }

        self.lastNightSleepHours = nil

        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.time >= today }
        let sleepEvents = todayEvents.filter { $0.type == .slapen }
        let wakeEvents = todayEvents.filter { $0.type == .ontwaken }

        self.napsToday = sleepEvents.count

        var totalNapMinutes = 0
        for sleepEvent in sleepEvents {
            if let wakeEvent = wakeEvents.first(where: { $0.time > sleepEvent.time }) {
                let duration = wakeEvent.time.timeIntervalSince(sleepEvent.time) / 60
                if duration < 180 {
                    totalNapMinutes += Int(duration)
                }
            }
        }
        self.napMinutesToday = totalNapMinutes
    }
}

// MARK: - Feeding Context

/// Meal and feeding patterns.
struct FeedingContext: AIContextComponent {
    static let componentKey = "feeding"
    static let estimatedTokens = 50

    let scheduledMealsPerDay: Int
    let mealsLoggedToday: Int
    let minutesSinceLastMeal: Int?
    let waterEventsLast2h: Int

    init(profile: PuppyProfile, events: [PuppyEvent]) {
        self.scheduledMealsPerDay = profile.mealSchedule.mealsPerDay

        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.time >= today }
        self.mealsLoggedToday = todayEvents.meals().count

        self.minutesSinceLastMeal = events.meals().first.map { Int(Date().timeIntervalSince($0.time) / 60) }

        let twoHoursAgo = Date().addingTimeInterval(-2 * 3600)
        self.waterEventsLast2h = events.filter { $0.type == .drinken && $0.time >= twoHoursAgo }.count
    }
}

// MARK: - Exercise Context

/// Exercise and activity patterns.
struct ExerciseContext: AIContextComponent {
    static let componentKey = "exercise"
    static let estimatedTokens = 60

    let maxExerciseMinutes: Int
    let exerciseMinutesToday: Int
    let walksToday: Int
    let minutesSinceLastWalk: Int?
    let yardVisitsToday: Int

    init(profile: PuppyProfile, events: [PuppyEvent]) {
        self.maxExerciseMinutes = profile.maxExerciseMinutes

        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.time >= today }

        let walks = todayEvents.walks()
        self.walksToday = walks.count
        self.exerciseMinutesToday = walks.compactMap { $0.durationMin }.reduce(0, +)

        self.minutesSinceLastWalk = events.walks().first.map { Int(Date().timeIntervalSince($0.time) / 60) }
        self.yardVisitsToday = todayEvents.filter { $0.type == .tuin }.count
    }
}

// MARK: - Recent Events Summary

/// Summary of recent logged events for pattern context.
struct RecentEventsSummary: AIContextComponent {
    static let componentKey = "recent_events"
    static let estimatedTokens = 80

    let eventsLast24h: Int
    let eventsByType: [String: Int]
    let hoursSinceLastEvent: Double?
    let avgEventsPerDay: Double

    init(events: [PuppyEvent]) {
        let now = Date()
        let last24h = events.filter { now.timeIntervalSince($0.time) <= 24 * 3600 }
        self.eventsLast24h = last24h.count

        var byType: [String: Int] = [:]
        for event in last24h {
            byType[event.type.rawValue, default: 0] += 1
        }
        self.eventsByType = byType

        self.hoursSinceLastEvent = events.first.map { now.timeIntervalSince($0.time) / 3600 }

        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 3600)
        let last7Days = events.filter { $0.time >= sevenDaysAgo }
        self.avgEventsPerDay = Double(last7Days.count) / 7.0
    }
}
