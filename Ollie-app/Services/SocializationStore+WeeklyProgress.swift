//
//  SocializationStore+WeeklyProgress.swift
//  Otis-app
//
//  Weekly progress tracking and suggestions for SocializationStore
//

import Foundation
import OtisShared

extension SocializationStore {

    // MARK: - Weekly Progress

    /// Get progress for a specific week
    func weeklyProgress(for weekNumber: Int, profile: PuppyProfile) -> WeeklyProgress {
        let calendar = Calendar.current

        // Calculate week start/end dates based on birth date
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekNumber, to: profile.birthDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return WeeklyProgress(
                weekNumber: weekNumber,
                startDate: Date(),
                endDate: Date()
            )
        }

        // Filter exposures for this week
        let weekExposures = allExposures.filter { exposure in
            exposure.date >= weekStart && exposure.date <= calendar.date(byAdding: .day, value: 1, to: weekEnd)!
        }

        // Count unique categories with exposures
        let categoriesWithExposures = Set(
            weekExposures.compactMap { exposure in
                category(forItemId: exposure.itemId)?.id
            }
        ).count

        // Calculate positive reaction rate
        let positiveCount = weekExposures.filter { $0.reaction.isPositive }.count
        let positiveRate = weekExposures.isEmpty ? 0.0 : Double(positiveCount) / Double(weekExposures.count)

        return WeeklyProgress(
            weekNumber: weekNumber,
            startDate: weekStart,
            endDate: weekEnd,
            exposureCount: weekExposures.count,
            categoriesWithExposures: categoriesWithExposures,
            positiveReactionRate: positiveRate,
            totalCategories: categories.count
        )
    }

    /// Get all weekly progress for the socialization window
    func allWeeklyProgress(profile: PuppyProfile) -> [WeeklyProgress] {
        SocializationWindow.allWeeks.map { weekNumber in
            weeklyProgress(for: weekNumber, profile: profile)
        }
    }

    /// Get the current week's progress
    func currentWeekProgress(profile: PuppyProfile) -> WeeklyProgress? {
        let ageWeeks = profile.ageInWeeks
        guard SocializationWindow.isInWindow(ageWeeks: ageWeeks) else { return nil }
        return weeklyProgress(for: ageWeeks, profile: profile)
    }

    /// Check if in socialization window
    func isInSocializationWindow(profile: PuppyProfile) -> Bool {
        SocializationWindow.isInWindow(ageWeeks: profile.ageInWeeks)
    }

    /// Check if socialization window has closed
    func socializationWindowClosed(profile: PuppyProfile) -> Bool {
        SocializationWindow.windowClosed(ageWeeks: profile.ageInWeeks)
    }

    // MARK: - Week Detail Helpers

    /// Get category-level progress for a specific week
    func categoryProgressForWeek(_ week: WeeklyProgress, profile: PuppyProfile) -> [(category: SocializationCategory, count: Int, total: Int)] {
        var result: [(category: SocializationCategory, count: Int, total: Int)] = []

        for category in categories {
            let exposuresInWeek = category.items.reduce(0) { count, item in
                count + allExposures.filter { exposure in
                    exposure.itemId == item.id &&
                    exposure.date >= week.startDate &&
                    exposure.date <= week.endDate
                }.count
            }

            // Target is roughly items count (one per item as minimum goal)
            let target = max(1, category.items.count)
            result.append((category: category, count: exposuresInWeek, total: target))
        }

        return result
    }

    /// Get focus suggestions for a specific week
    func focusSuggestions(for week: WeeklyProgress, profile: PuppyProfile) -> [String] {
        var suggestions: [String] = []
        let progress = categoryProgressForWeek(week, profile: profile)

        // Find categories with zero exposures this week (critical gaps)
        let zeroExposureCategories = progress.filter { $0.count == 0 }
            .map { $0.category }
            .prefix(2)

        for category in zeroExposureCategories {
            // Get a few item suggestions from the category (items not yet comfortable)
            let itemNames = category.items.filter { !isComfortable(itemId: $0.id) }
                .prefix(3)
                .map { $0.localizedDisplayName }
                .joined(separator: ", ")

            if !itemNames.isEmpty {
                suggestions.append("\(category.localizedDisplayName): \(itemNames)")
            }
        }

        // If we have fewer than 2 suggestions, add categories below 50%
        if suggestions.count < 2 {
            let lowProgressCategories = progress
                .filter { Double($0.count) / Double(max(1, $0.total)) < 0.5 && $0.count > 0 }
                .sorted { $0.count < $1.count }
                .map { $0.category }
                .prefix(2 - suggestions.count)

            for category in lowProgressCategories {
                let itemNames = category.items.filter { !isComfortable(itemId: $0.id) }
                    .prefix(3)
                    .map { $0.localizedDisplayName }
                    .joined(separator: ", ")

                if !itemNames.isEmpty && !suggestions.contains(where: { $0.hasPrefix(category.localizedDisplayName) }) {
                    suggestions.append("\(category.localizedDisplayName): \(itemNames)")
                }
            }
        }

        return suggestions
    }
}
