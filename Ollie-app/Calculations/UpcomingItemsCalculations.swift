//
//  UpcomingItemsCalculations.swift
//  Otis-app
//
//  Business logic for calculating upcoming meals and walks
//

import Foundation
import OtisShared

// MARK: - Upcoming Items Calculation

struct UpcomingCalculations {
    /// Threshold in minutes - items within this time become actionable
    static let actionableThresholdMinutes = 10

    /// Calculate upcoming meals and walks for today
    /// Returns separate actionable items (within 10 min or overdue) and upcoming items (>10 min away)
    /// - Parameter isWalkInProgress: When true, suppresses overdue walk warnings since user is already walking
    static func calculateUpcoming(
        events: [PuppyEvent],
        mealSchedule: MealSchedule?,
        walkSchedule: WalkSchedule?,
        forecasts: [HourForecast] = [],
        date: Date = Date(),
        isWalkInProgress: Bool = false
    ) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        guard isToday else { return ([], []) }

        var allItems: [UpcomingItem] = []

        // Calculate upcoming meals
        if let schedule = mealSchedule {
            let mealsToday = events.meals()
            let mealCount = mealsToday.count

            for (index, portion) in schedule.portions.enumerated() {
                // Skip meals already eaten
                if index < mealCount { continue }

                // Parse target time
                if let targetTime = portion.targetTime,
                   let scheduledTime = Date.fromTimeString(targetTime, on: date) {
                    allItems.append(UpcomingItem(
                        icon: "fork.knife",
                        label: portion.label,
                        detail: portion.amount,
                        targetTime: scheduledTime,
                        itemType: .meal
                    ))
                }
            }
        }

        // Calculate all remaining walk suggestions (show ALL like meals)
        if let schedule = walkSchedule {
            let suggestions = WalkSuggestionCalculations.calculateRemainingSuggestions(
                events: events,
                walkSchedule: schedule,
                date: date
            )

            for (index, suggestion) in suggestions.enumerated() {
                // Look up weather forecast for suggested walk time
                let forecast = forecasts.first {
                    calendar.isDate($0.time, equalTo: suggestion.suggestedTime, toGranularity: .hour)
                }

                // Build detail string showing progress (only for first walk)
                let progressDetail: String
                if index == 0 {
                    progressDetail = Strings.Walks.walksProgress(
                        completed: suggestion.walksCompletedToday,
                        total: suggestion.targetWalksPerDay
                    )
                } else {
                    // For subsequent walks, show just the time
                    progressDetail = suggestion.timeString
                }

                allItems.append(UpcomingItem(
                    icon: "figure.walk",
                    label: suggestion.label,
                    detail: progressDetail,
                    targetTime: suggestion.suggestedTime,
                    itemType: .walk,
                    weatherIcon: forecast?.icon,
                    temperature: forecast.map { Int($0.temperature) },
                    rainWarning: forecast?.rainWarning ?? false
                ))
            }
        }

        // Sort by target time
        allItems.sort { $0.targetTime < $1.targetTime }

        // Filter out stale overdue walks: once a new walk is due, don't show previous overdue walks
        // Keep only the most recent overdue walk (if any), discard older ones
        let overdueWalks = allItems.filter { $0.itemType == .walk && $0.minutesUntil < 0 }
        let mostRecentOverdueWalk = overdueWalks.max(by: { $0.targetTime < $1.targetTime })
        let staleOverdueWalkTimes = Set(overdueWalks
            .filter { $0.targetTime != mostRecentOverdueWalk?.targetTime }
            .map { $0.targetTime })

        // Separate into actionable and upcoming
        var actionable: [ActionableItem] = []
        var upcoming: [UpcomingItem] = []

        for item in allItems {
            let minutesUntil = item.minutesUntil

            // Skip stale overdue walks (older walks when a newer walk is due)
            if item.itemType == .walk && staleOverdueWalkTimes.contains(item.targetTime) {
                continue
            }

            if minutesUntil < 0 {
                // Overdue - but skip walk items if a walk is already in progress
                if isWalkInProgress && item.itemType == .walk {
                    // Don't show "walk overdue" when already on a walk
                    continue
                }
                actionable.append(ActionableItem(
                    item: item,
                    state: .overdue(minutesOverdue: abs(minutesUntil))
                ))
            } else if minutesUntil <= 5 {
                // Due now (within 5 min window) - skip walks if already on a walk
                if isWalkInProgress && item.itemType == .walk {
                    continue
                }
                actionable.append(ActionableItem(
                    item: item,
                    state: .due
                ))
            } else if minutesUntil <= actionableThresholdMinutes {
                // Approaching (6-10 min)
                actionable.append(ActionableItem(
                    item: item,
                    state: .approaching(minutesUntil: minutesUntil)
                ))
            } else {
                // Future - goes to upcoming list
                upcoming.append(item)
            }
        }

        return (actionable, upcoming)
    }

    /// Legacy method for backwards compatibility - returns all items as UpcomingItem
    static func calculateUpcoming(
        events: [PuppyEvent],
        mealSchedule: MealSchedule?,
        walkSchedule: WalkSchedule?,
        forecasts: [HourForecast] = [],
        date: Date = Date(),
        isWalkInProgress: Bool = false
    ) -> [UpcomingItem] {
        let (actionable, upcoming) = calculateUpcoming(
            events: events,
            mealSchedule: mealSchedule,
            walkSchedule: walkSchedule,
            forecasts: forecasts,
            date: date,
            isWalkInProgress: isWalkInProgress
        ) as (actionable: [ActionableItem], upcoming: [UpcomingItem])

        // Combine actionable items back as UpcomingItem for legacy callers
        let actionableAsUpcoming = actionable.map { $0.item }
        return actionableAsUpcoming + upcoming
    }
}
