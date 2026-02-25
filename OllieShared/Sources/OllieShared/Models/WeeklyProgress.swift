//
//  WeeklyProgress.swift
//  OllieShared
//
//  Week-by-week progress tracking for socialization

import Foundation

/// Progress data for a specific week during the socialization period
public struct WeeklyProgress: Identifiable, Sendable {
    public var id: Int { weekNumber }

    /// The week number (8-16+ for socialization window)
    public let weekNumber: Int

    /// Start date of this week
    public let startDate: Date

    /// End date of this week
    public let endDate: Date

    /// Total number of exposures logged this week
    public var exposureCount: Int

    /// Number of different categories with at least one exposure
    public var categoriesWithExposures: Int

    /// Rate of positive reactions (0.0 to 1.0)
    public var positiveReactionRate: Double

    /// Total number of categories available
    public var totalCategories: Int

    // MARK: - Init

    public init(
        weekNumber: Int,
        startDate: Date,
        endDate: Date,
        exposureCount: Int = 0,
        categoriesWithExposures: Int = 0,
        positiveReactionRate: Double = 0.0,
        totalCategories: Int = 7
    ) {
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.exposureCount = exposureCount
        self.categoriesWithExposures = categoriesWithExposures
        self.positiveReactionRate = positiveReactionRate
        self.totalCategories = totalCategories
    }

    // MARK: - Computed Properties

    /// Whether this week meets all criteria for "complete"
    /// - 40+ exposures
    /// - 7+ categories with exposures
    /// - 70%+ positive reaction rate
    public var isComplete: Bool {
        exposureCount >= 40 &&
        categoriesWithExposures >= 7 &&
        positiveReactionRate >= 0.7
    }

    /// Whether this week is currently active (includes today)
    public var isCurrent: Bool {
        let now = Date()
        return startDate <= now && now <= endDate
    }

    /// Whether this week is in the past
    public var isPast: Bool {
        endDate < Date()
    }

    /// Whether this week is in the future
    public var isFuture: Bool {
        startDate > Date()
    }

    /// Progress fraction (0.0 to 1.0) based on exposure count
    /// 40 exposures = 100%
    public var exposureProgressFraction: Double {
        min(1.0, Double(exposureCount) / 40.0)
    }

    /// Progress fraction for category coverage
    public var categoryProgressFraction: Double {
        guard totalCategories > 0 else { return 0 }
        return min(1.0, Double(categoriesWithExposures) / Double(totalCategories))
    }

    /// Overall progress combining all metrics
    public var overallProgress: Double {
        let exposureWeight = 0.5
        let categoryWeight = 0.3
        let reactionWeight = 0.2

        return (exposureProgressFraction * exposureWeight) +
               (categoryProgressFraction * categoryWeight) +
               (positiveReactionRate * reactionWeight)
    }

    /// Status label for display
    public var statusLabel: String {
        if isComplete {
            return String(localized: "Complete")
        } else if isCurrent {
            return String(localized: "This week")
        } else if isPast {
            return String(localized: "Missed")
        } else {
            return String(localized: "Upcoming")
        }
    }

    /// Week label for display (e.g., "Week 8")
    public var weekLabel: String {
        String(localized: "Week \(weekNumber)")
    }
}

// MARK: - Week Progress Status

/// Status of a week's progress
public enum WeekProgressStatus: Sendable {
    case complete
    case current
    case incomplete
    case missed
    case upcoming

    public var icon: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .current: return "circle.circle.fill"
        case .incomplete: return "circle.dashed"
        case .missed: return "exclamationmark.circle.fill"
        case .upcoming: return "circle"
        }
    }
}

// MARK: - Socialization Window

/// Defines the critical socialization window period
public enum SocializationWindow {

    /// First week of socialization window (typically 8 weeks old)
    public static let startWeek = 8

    /// Last week of socialization window (typically 16 weeks old)
    public static let endWeek = 16

    /// Peak week of socialization (most receptive)
    public static let peakWeek = 12

    /// All weeks in the socialization window
    public static var allWeeks: [Int] {
        Array(startWeek...endWeek)
    }

    /// Check if a given age in weeks is within the socialization window
    public static func isInWindow(ageWeeks: Int) -> Bool {
        ageWeeks >= startWeek && ageWeeks <= endWeek
    }

    /// Check if the socialization window has closed
    public static func windowClosed(ageWeeks: Int) -> Bool {
        ageWeeks > endWeek
    }

    /// Weeks remaining in socialization window
    public static func weeksRemaining(ageWeeks: Int) -> Int {
        max(0, endWeek - ageWeeks)
    }

    /// Progress through the socialization window (0.0 to 1.0)
    public static func windowProgress(ageWeeks: Int) -> Double {
        if ageWeeks < startWeek { return 0 }
        if ageWeeks > endWeek { return 1 }
        return Double(ageWeeks - startWeek) / Double(endWeek - startWeek)
    }
}
