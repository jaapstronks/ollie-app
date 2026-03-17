//
//  ContributionStats.swift
//  OtisShared
//
//  Contribution statistics per user for gamification and team insights.
//

import Foundation

// MARK: - Contribution Stats Model

/// Statistics for a single user's contributions over a time period
public struct ContributionStats: Identifiable, Equatable, Sendable {
    public var id: String { userRecordID }

    /// CloudKit user record ID
    public let userRecordID: String

    /// Display name (resolved via ParticipantResolver)
    public let displayName: String

    /// Whether this is the current user
    public let isCurrentUser: Bool

    // MARK: - Event Counts

    /// Total events logged
    public let totalEvents: Int

    /// Number of walks logged
    public let walkCount: Int

    /// Total walk duration in minutes
    public let walkMinutes: Int

    /// Number of training sessions
    public let trainingSessions: Int

    /// Number of potty breaks logged
    public let pottyBreaks: Int

    /// Number of outdoor potty breaks (success)
    public let outdoorPottyBreaks: Int

    /// Number of moments/photos logged
    public let momentsLogged: Int

    /// Number of meals logged
    public let mealsLogged: Int

    /// Number of social events logged
    public let socialEvents: Int

    // MARK: - Period

    /// Start of the statistics period
    public let startDate: Date

    /// End of the statistics period
    public let endDate: Date

    // MARK: - Computed Properties

    /// Outdoor potty success rate (0.0 - 1.0)
    public var outdoorSuccessRate: Double {
        guard pottyBreaks > 0 else { return 0 }
        return Double(outdoorPottyBreaks) / Double(pottyBreaks)
    }

    /// Average walk duration in minutes
    public var averageWalkMinutes: Double {
        guard walkCount > 0 else { return 0 }
        return Double(walkMinutes) / Double(walkCount)
    }

    /// Percentage of total events (set externally when comparing multiple users)
    public var contributionPercentage: Double = 0

    public init(
        userRecordID: String,
        displayName: String,
        isCurrentUser: Bool,
        totalEvents: Int,
        walkCount: Int,
        walkMinutes: Int,
        trainingSessions: Int,
        pottyBreaks: Int,
        outdoorPottyBreaks: Int,
        momentsLogged: Int,
        mealsLogged: Int,
        socialEvents: Int,
        startDate: Date,
        endDate: Date
    ) {
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.isCurrentUser = isCurrentUser
        self.totalEvents = totalEvents
        self.walkCount = walkCount
        self.walkMinutes = walkMinutes
        self.trainingSessions = trainingSessions
        self.pottyBreaks = pottyBreaks
        self.outdoorPottyBreaks = outdoorPottyBreaks
        self.momentsLogged = momentsLogged
        self.mealsLogged = mealsLogged
        self.socialEvents = socialEvents
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Time Period

/// Common time periods for contribution statistics
public enum ContributionPeriod: String, CaseIterable, Sendable {
    case today
    case thisWeek
    case thisMonth
    case allTime

    public var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return DateInterval(start: start, end: now)

        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return DateInterval(start: start, end: now)

        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return DateInterval(start: start, end: now)

        case .allTime:
            // Use a very old date as start
            let start = calendar.date(byAdding: .year, value: -10, to: now) ?? now
            return DateInterval(start: start, end: now)
        }
    }

    public var label: String {
        switch self {
        case .today: return Strings.ContributionStats.today
        case .thisWeek: return Strings.ContributionStats.thisWeek
        case .thisMonth: return Strings.ContributionStats.thisMonth
        case .allTime: return Strings.ContributionStats.allTime
        }
    }
}

// MARK: - Contribution Calculations

/// Calculates contribution statistics from events
public enum ContributionCalculations {

    /// Calculate contribution stats for all users in the given events
    /// - Parameters:
    ///   - events: Events to analyze
    ///   - period: Time period to filter events
    ///   - currentUserRecordID: CloudKit record ID of current user (for isCurrentUser flag)
    ///   - nameResolver: Closure to resolve user record IDs to display names
    /// - Returns: Array of ContributionStats sorted by total events (descending)
    public static func calculate(
        events: [PuppyEvent],
        period: DateInterval,
        currentUserRecordID: String?,
        nameResolver: ((String) -> String)? = nil
    ) -> [ContributionStats] {
        // Filter events to the period
        let periodEvents = events.filter { event in
            period.contains(event.time)
        }

        // Group events by user record ID
        var eventsByUser: [String: [PuppyEvent]] = [:]
        for event in periodEvents {
            let key = event.loggedBy ?? "unknown"
            eventsByUser[key, default: []].append(event)
        }

        // Calculate stats for each user
        var stats: [ContributionStats] = []
        let totalEventsCount = periodEvents.count

        for (userRecordID, userEvents) in eventsByUser {
            let displayName = nameResolver?(userRecordID) ?? "Partner"
            let isCurrentUser = userRecordID == currentUserRecordID

            let walkEvents = userEvents.filter { $0.type == .uitlaten }
            let walkMinutes = walkEvents.compactMap { $0.durationMin }.reduce(0, +)

            let pottyEvents = userEvents.filter { $0.type == .plassen || $0.type == .poepen }
            let outdoorPotty = pottyEvents.filter { $0.location == .buiten }

            var contributionStats = ContributionStats(
                userRecordID: userRecordID,
                displayName: displayName,
                isCurrentUser: isCurrentUser,
                totalEvents: userEvents.count,
                walkCount: walkEvents.count,
                walkMinutes: walkMinutes,
                trainingSessions: userEvents.filter { $0.type == .training }.count,
                pottyBreaks: pottyEvents.count,
                outdoorPottyBreaks: outdoorPotty.count,
                momentsLogged: userEvents.filter { $0.type == .moment }.count,
                mealsLogged: userEvents.filter { $0.type == .eten }.count,
                socialEvents: userEvents.filter { $0.type == .sociaal }.count,
                startDate: period.start,
                endDate: period.end
            )

            // Calculate contribution percentage
            if totalEventsCount > 0 {
                contributionStats.contributionPercentage = Double(userEvents.count) / Double(totalEventsCount)
            }

            stats.append(contributionStats)
        }

        // Sort by total events (descending)
        return stats.sorted { $0.totalEvents > $1.totalEvents }
    }

    /// Calculate stats for a single user
    public static func calculateForUser(
        events: [PuppyEvent],
        userRecordID: String,
        period: DateInterval,
        displayName: String,
        isCurrentUser: Bool
    ) -> ContributionStats {
        // Filter events to the period and user
        let userEvents = events.filter { event in
            period.contains(event.time) && event.loggedBy == userRecordID
        }

        let walkEvents = userEvents.filter { $0.type == .uitlaten }
        let walkMinutes = walkEvents.compactMap { $0.durationMin }.reduce(0, +)

        let pottyEvents = userEvents.filter { $0.type == .plassen || $0.type == .poepen }
        let outdoorPotty = pottyEvents.filter { $0.location == .buiten }

        return ContributionStats(
            userRecordID: userRecordID,
            displayName: displayName,
            isCurrentUser: isCurrentUser,
            totalEvents: userEvents.count,
            walkCount: walkEvents.count,
            walkMinutes: walkMinutes,
            trainingSessions: userEvents.filter { $0.type == .training }.count,
            pottyBreaks: pottyEvents.count,
            outdoorPottyBreaks: outdoorPotty.count,
            momentsLogged: userEvents.filter { $0.type == .moment }.count,
            mealsLogged: userEvents.filter { $0.type == .eten }.count,
            socialEvents: userEvents.filter { $0.type == .sociaal }.count,
            startDate: period.start,
            endDate: period.end
        )
    }

    /// Get a summary comparing contributions between users
    public static func getSummary(
        stats: [ContributionStats]
    ) -> ContributionSummary {
        let totalEvents = stats.reduce(0) { $0 + $1.totalEvents }
        let totalWalks = stats.reduce(0) { $0 + $1.walkCount }
        let totalWalkMinutes = stats.reduce(0) { $0 + $1.walkMinutes }
        let totalTraining = stats.reduce(0) { $0 + $1.trainingSessions }

        return ContributionSummary(
            totalEvents: totalEvents,
            totalWalks: totalWalks,
            totalWalkMinutes: totalWalkMinutes,
            totalTrainingSessions: totalTraining,
            contributorCount: stats.count,
            topContributor: stats.first
        )
    }
}

// MARK: - Contribution Summary

/// Summary of all contributions
public struct ContributionSummary: Equatable, Sendable {
    public let totalEvents: Int
    public let totalWalks: Int
    public let totalWalkMinutes: Int
    public let totalTrainingSessions: Int
    public let contributorCount: Int
    public let topContributor: ContributionStats?

    /// Whether this is a team effort (multiple contributors)
    public var isTeamEffort: Bool {
        contributorCount > 1
    }
}
