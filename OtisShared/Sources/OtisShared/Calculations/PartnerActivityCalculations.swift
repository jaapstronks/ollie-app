//
//  PartnerActivityCalculations.swift
//  OtisShared
//
//  Calculations for partner activity summaries (handoff cards)
//

import Foundation

/// Summary of activities logged by a partner while the current user was away
public struct PartnerActivitySummary: Equatable, Sendable {
    /// IDs of partners who logged events
    public let partnerIds: [UUID]

    /// Names of partners who logged events
    public let partnerNames: [String]

    /// All partner-logged events (sorted by time)
    public let events: [PuppyEvent]

    /// Time range of partner activity
    public let startTime: Date
    public let endTime: Date

    /// Training events (prioritized)
    public let trainingEvents: [PuppyEvent]

    /// Socialization events (prioritized)
    public let socializationEvents: [PuppyEvent]

    /// Walk events (prioritized)
    public let walkEvents: [PuppyEvent]

    /// Other notable events (medications, milestones, etc.)
    public let otherNotableEvents: [PuppyEvent]

    /// Total event count
    public var totalEventCount: Int { events.count }

    /// Whether this summary has any highlight events (training, socialization, walks)
    public var hasHighlights: Bool {
        !trainingEvents.isEmpty || !socializationEvents.isEmpty || !walkEvents.isEmpty
    }

    /// Whether the summary should be shown (has highlights or 3+ events)
    public var shouldShow: Bool {
        hasHighlights || totalEventCount >= 3
    }

    /// Combined partner names for display (e.g., "Sarah" or "Sarah and Mike")
    public var partnerDisplayName: String {
        switch partnerNames.count {
        case 0: return ""
        case 1: return partnerNames[0]
        case 2: return "\(partnerNames[0]) and \(partnerNames[1])"
        default:
            let allButLast = partnerNames.dropLast().joined(separator: ", ")
            return "\(allButLast), and \(partnerNames.last!)"
        }
    }

    public init(
        partnerIds: [UUID],
        partnerNames: [String],
        events: [PuppyEvent],
        startTime: Date,
        endTime: Date,
        trainingEvents: [PuppyEvent],
        socializationEvents: [PuppyEvent],
        walkEvents: [PuppyEvent],
        otherNotableEvents: [PuppyEvent]
    ) {
        self.partnerIds = partnerIds
        self.partnerNames = partnerNames
        self.events = events
        self.startTime = startTime
        self.endTime = endTime
        self.trainingEvents = trainingEvents
        self.socializationEvents = socializationEvents
        self.walkEvents = walkEvents
        self.otherNotableEvents = otherNotableEvents
    }
}

/// Partner activity calculation utilities
public struct PartnerActivityCalculations {

    // MARK: - Public Methods

    /// Find partner activity since the user's last seen timestamp
    /// - Parameters:
    ///   - events: All events to analyze
    ///   - currentUserId: ID of the current user (events from this user are excluded)
    ///   - lastSeenTimestamp: When the user last dismissed/acknowledged partner activity
    ///   - householdMembers: All household members (for name lookup)
    ///   - userLastActivityTime: Time of the user's last logged event (for gap detection)
    /// - Returns: Partner activity summary if there's activity to show, nil otherwise
    public static func findPartnerActivity(
        events: [PuppyEvent],
        currentUserId: UUID?,
        lastSeenTimestamp: Date?,
        householdMembers: HouseholdMembers,
        userLastActivityTime: Date?
    ) -> PartnerActivitySummary? {
        guard let currentUserId = currentUserId else { return nil }

        // Filter to partner events only (not logged by current user)
        let partnerEvents = events.filter { event in
            guard let loggedBy = event.loggedBy else { return false }
            return loggedBy != currentUserId
        }

        guard !partnerEvents.isEmpty else { return nil }

        // Find events after last seen timestamp (if any)
        let relevantEvents: [PuppyEvent]
        if let lastSeen = lastSeenTimestamp {
            relevantEvents = partnerEvents.filter { $0.createdAt > lastSeen }
        } else {
            relevantEvents = partnerEvents
        }

        guard !relevantEvents.isEmpty else { return nil }

        // Check for minimum 30-minute gap since user's last activity
        if let userLastActivity = userLastActivityTime {
            let oldestPartnerEvent = relevantEvents.min(by: { $0.time < $1.time })
            if let oldest = oldestPartnerEvent {
                let gap = oldest.time.timeIntervalSince(userLastActivity)
                // Require at least 30 minutes gap
                if gap < 30 * 60 {
                    return nil
                }
            }
        }

        // Sort events by time
        let sortedEvents = relevantEvents.sorted { $0.time < $1.time }

        // Extract time range
        guard let startTime = sortedEvents.first?.time,
              let endTime = sortedEvents.last?.time else {
            return nil
        }

        // Collect unique partner IDs and names
        var partnerIdSet = Set<UUID>()
        var partnerNames: [String] = []

        for event in sortedEvents {
            if let loggedBy = event.loggedBy, !partnerIdSet.contains(loggedBy) {
                partnerIdSet.insert(loggedBy)
                if let member = householdMembers.member(byId: loggedBy) {
                    partnerNames.append(member.name)
                }
            }
        }

        // Categorize events
        let trainingEvents = sortedEvents.filter { $0.type == .training }
        let socializationEvents = sortedEvents.filter { $0.type == .sociaal }
        let walkEvents = sortedEvents.filter { $0.type == .uitlaten }

        // Other notable events (exclude routine potty/meals, already categorized events)
        let notableTypes: Set<EventType> = [.milestone, .medicatie, .gedrag, .moment, .gewicht]
        let otherNotableEvents = sortedEvents.filter { notableTypes.contains($0.type) }

        let summary = PartnerActivitySummary(
            partnerIds: Array(partnerIdSet),
            partnerNames: partnerNames,
            events: sortedEvents,
            startTime: startTime,
            endTime: endTime,
            trainingEvents: trainingEvents,
            socializationEvents: socializationEvents,
            walkEvents: walkEvents,
            otherNotableEvents: otherNotableEvents
        )

        // Only return if it meets the threshold to show
        guard summary.shouldShow else { return nil }

        return summary
    }

    /// Get events logged by the current user (for finding their last activity)
    /// - Parameters:
    ///   - events: All events to analyze
    ///   - currentUserId: ID of the current user
    /// - Returns: Most recent event time logged by the current user
    public static func findUserLastActivityTime(
        events: [PuppyEvent],
        currentUserId: UUID?
    ) -> Date? {
        guard let currentUserId = currentUserId else { return nil }

        return events
            .filter { $0.loggedBy == currentUserId }
            .max(by: { $0.time < $1.time })?
            .time
    }
}
