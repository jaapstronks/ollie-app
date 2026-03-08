//
//  YearRecap.swift
//  OtisShared
//
//  Year in Review recap models - annual statistics and highlights

import Foundation

// MARK: - Year Recap

/// Complete year-end recap with statistics, highlights, and growth journey
public struct YearRecap: Identifiable, Sendable {
    public let id = UUID()
    public let year: Int
    public let puppyName: String
    public let stats: YearStats
    public let monthHighlights: [MonthHighlight]
    public let topMoments: [TopMoment]
    public let growthJourney: GrowthJourney?

    public init(
        year: Int,
        puppyName: String,
        stats: YearStats,
        monthHighlights: [MonthHighlight],
        topMoments: [TopMoment],
        growthJourney: GrowthJourney?
    ) {
        self.year = year
        self.puppyName = puppyName
        self.stats = stats
        self.monthHighlights = monthHighlights
        self.topMoments = topMoments
        self.growthJourney = growthJourney
    }

    /// Whether this recap has meaningful data
    public var hasData: Bool {
        stats.totalWalks > 0 ||
        stats.totalMeals > 0 ||
        stats.totalTrainingSessions > 0 ||
        stats.totalSocialEvents > 0 ||
        stats.photoCount > 0
    }

    /// Year as formatted string (e.g., "2025")
    public var yearString: String {
        "\(year)"
    }
}

// MARK: - Year Stats

/// Aggregated statistics for the entire year
public struct YearStats: Sendable {
    public let totalWalks: Int
    public let totalWalkMinutes: Int
    public let totalMeals: Int
    public let totalSleepHours: Int
    public let totalTrainingSessions: Int
    public let totalSocialEvents: Int
    public let totalPottyEvents: Int
    public let outdoorPottyCount: Int
    public let photoCount: Int
    public let milestoneCount: Int
    public let uniqueSocialContacts: Int
    public let daysLogged: Int

    public init(
        totalWalks: Int,
        totalWalkMinutes: Int,
        totalMeals: Int,
        totalSleepHours: Int,
        totalTrainingSessions: Int,
        totalSocialEvents: Int,
        totalPottyEvents: Int,
        outdoorPottyCount: Int,
        photoCount: Int,
        milestoneCount: Int,
        uniqueSocialContacts: Int,
        daysLogged: Int
    ) {
        self.totalWalks = totalWalks
        self.totalWalkMinutes = totalWalkMinutes
        self.totalMeals = totalMeals
        self.totalSleepHours = totalSleepHours
        self.totalTrainingSessions = totalTrainingSessions
        self.totalSocialEvents = totalSocialEvents
        self.totalPottyEvents = totalPottyEvents
        self.outdoorPottyCount = outdoorPottyCount
        self.photoCount = photoCount
        self.milestoneCount = milestoneCount
        self.uniqueSocialContacts = uniqueSocialContacts
        self.daysLogged = daysLogged
    }

    // MARK: - Computed Properties

    /// Outdoor potty percentage (0-100)
    public var outdoorPottyPercentage: Int {
        guard totalPottyEvents > 0 else { return 0 }
        return Int(round(Double(outdoorPottyCount) / Double(totalPottyEvents) * 100))
    }

    /// Total walk hours as formatted string
    public var formattedWalkHours: String {
        let hours = Double(totalWalkMinutes) / 60.0
        if hours >= 1 {
            let formatted = hours.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", hours)
                : String(format: "%.1f", hours)
            return formatted
        } else {
            return String(format: "%.1f", hours)
        }
    }

    /// Average walks per day that had logging
    public var averageWalksPerDay: Double {
        guard daysLogged > 0 else { return 0 }
        return Double(totalWalks) / Double(daysLogged)
    }
}

// MARK: - Month Highlight

/// Highlight data for a single month
public struct MonthHighlight: Identifiable, Sendable {
    public let id = UUID()
    public let month: Int  // 1-12
    public let year: Int
    public let photoIds: [String]  // Photo file paths
    public let caption: String?
    public let milestones: [String]
    public let walkCount: Int
    public let trainingCount: Int
    public let socialCount: Int

    public init(
        month: Int,
        year: Int,
        photoIds: [String],
        caption: String?,
        milestones: [String],
        walkCount: Int,
        trainingCount: Int,
        socialCount: Int
    ) {
        self.month = month
        self.year = year
        self.photoIds = photoIds
        self.caption = caption
        self.milestones = milestones
        self.walkCount = walkCount
        self.trainingCount = trainingCount
        self.socialCount = socialCount
    }

    /// The month as a Date (first day of that month)
    public var monthDate: Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Localized month name (e.g., "January")
    public var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: monthDate)
    }

    /// Short month name (e.g., "Jan")
    public var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: monthDate)
    }

    /// Whether this month has any data
    public var hasData: Bool {
        !photoIds.isEmpty || !milestones.isEmpty || walkCount > 0 || trainingCount > 0 || socialCount > 0
    }
}

// MARK: - Top Moment

/// A highlighted moment from the year
public struct TopMoment: Identifiable, Sendable {
    public let id = UUID()
    public let category: TopMomentCategory
    public let title: String
    public let subtitle: String?
    public let photoPath: String?
    public let count: Int?

    public init(
        category: TopMomentCategory,
        title: String,
        subtitle: String? = nil,
        photoPath: String? = nil,
        count: Int? = nil
    ) {
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.photoPath = photoPath
        self.count = count
    }
}

/// Categories of top moments
public enum TopMomentCategory: String, CaseIterable, Sendable {
    case bestFriend        // Most frequent social contact
    case favoriteSpot      // Most visited location
    case biggestMilestone  // Most significant milestone
    case mostActiveMonth   // Month with most activity
    case longestStreak     // Longest outdoor potty streak
}

// MARK: - Growth Journey

/// Weight and developmental progression over the year
public struct GrowthJourney: Sendable {
    public let monthlyWeights: [MonthWeight]
    public let startWeight: Double?
    public let endWeight: Double?
    public let totalGain: Double?
    public let phaseCompletions: [PhaseCompletion]

    public init(
        monthlyWeights: [MonthWeight],
        startWeight: Double?,
        endWeight: Double?,
        totalGain: Double?,
        phaseCompletions: [PhaseCompletion]
    ) {
        self.monthlyWeights = monthlyWeights
        self.startWeight = startWeight
        self.endWeight = endWeight
        self.totalGain = totalGain
        self.phaseCompletions = phaseCompletions
    }

    /// Whether there's meaningful growth data
    public var hasData: Bool {
        !monthlyWeights.isEmpty || !phaseCompletions.isEmpty
    }

    /// Formatted weight gain string (e.g., "+5.2 kg")
    public var formattedWeightGain: String? {
        guard let gain = totalGain else { return nil }
        let sign = gain >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", gain)) kg"
    }
}

/// Weight snapshot for a specific month
public struct MonthWeight: Identifiable, Sendable {
    public let id = UUID()
    public let month: Int  // 1-12
    public let weightKg: Double
    public let ageWeeks: Int?

    public init(month: Int, weightKg: Double, ageWeeks: Int? = nil) {
        self.month = month
        self.weightKg = weightKg
        self.ageWeeks = ageWeeks
    }
}

/// A lifecycle phase achievement during the year
public struct PhaseCompletion: Identifiable, Sendable {
    public let id = UUID()
    public let phase: String  // "puppy", "adolescent", "adult", "senior"
    public let completedAt: Date?
    public let startedAt: Date?

    public init(phase: String, completedAt: Date? = nil, startedAt: Date? = nil) {
        self.phase = phase
        self.completedAt = completedAt
        self.startedAt = startedAt
    }
}
