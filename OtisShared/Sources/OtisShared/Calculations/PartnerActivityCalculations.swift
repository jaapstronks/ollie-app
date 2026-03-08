//
//  PartnerActivityCalculations.swift
//  OtisShared
//
//  Calculations for partner activity summaries (handoff cards)
//

import Foundation

/// Summary of activities logged by a partner while the current user was away
public struct PartnerActivitySummary: Equatable, Sendable {
    /// CloudKit record IDs of partners who logged events
    public let partnerRecordIDs: [String]

    /// Names of partners who logged events (resolved via ParticipantResolver)
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

    /// Featured moment event (moment with photo, or first photo event)
    public let featuredMoment: PuppyEvent?

    /// Natural language summary of activities
    public let handoverSummary: String?

    /// Legacy: IDs of partners who logged events (deprecated)
    @available(*, deprecated, message: "Use partnerRecordIDs instead")
    public var partnerIds: [UUID] { [] }

    /// Total event count
    public var totalEventCount: Int { events.count }

    /// Whether this summary has any highlight events (training, socialization, walks)
    public var hasHighlights: Bool {
        !trainingEvents.isEmpty || !socializationEvents.isEmpty || !walkEvents.isEmpty
    }

    /// Whether there's a featured moment to show
    public var hasFeaturedMoment: Bool {
        featuredMoment?.thumbnailPath != nil || featuredMoment?.photo != nil
    }

    /// Whether the summary should be shown (has highlights or 3+ events)
    public var shouldShow: Bool {
        hasHighlights || totalEventCount >= 3
    }

    /// Combined partner names for display (e.g., "Sarah" or "Sarah and Mike")
    public var partnerDisplayName: String {
        // Filter out empty/whitespace-only names
        let validNames = partnerNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        switch validNames.count {
        case 0: return ""
        case 1: return validNames[0]
        case 2: return "\(validNames[0]) and \(validNames[1])"
        default:
            let allButLast = validNames.dropLast().joined(separator: ", ")
            return "\(allButLast), and \(validNames.last!)"
        }
    }

    /// Number of partners with valid names (for grammar decisions)
    public var partnerCount: Int {
        partnerNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }

    /// New initializer with all fields
    public init(
        partnerRecordIDs: [String],
        partnerNames: [String],
        events: [PuppyEvent],
        startTime: Date,
        endTime: Date,
        trainingEvents: [PuppyEvent],
        socializationEvents: [PuppyEvent],
        walkEvents: [PuppyEvent],
        otherNotableEvents: [PuppyEvent],
        featuredMoment: PuppyEvent? = nil,
        handoverSummary: String? = nil
    ) {
        self.partnerRecordIDs = partnerRecordIDs
        self.partnerNames = partnerNames
        self.events = events
        self.startTime = startTime
        self.endTime = endTime
        self.trainingEvents = trainingEvents
        self.socializationEvents = socializationEvents
        self.walkEvents = walkEvents
        self.otherNotableEvents = otherNotableEvents
        self.featuredMoment = featuredMoment
        self.handoverSummary = handoverSummary
    }

    /// Legacy initializer for backwards compatibility
    @available(*, deprecated, message: "Use init with partnerRecordIDs instead")
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
        self.partnerRecordIDs = partnerIds.map { $0.uuidString }
        self.partnerNames = partnerNames
        self.events = events
        self.startTime = startTime
        self.endTime = endTime
        self.trainingEvents = trainingEvents
        self.socializationEvents = socializationEvents
        self.walkEvents = walkEvents
        self.otherNotableEvents = otherNotableEvents
        self.featuredMoment = nil
        self.handoverSummary = nil
    }
}

/// Partner activity calculation utilities
public struct PartnerActivityCalculations {

    // MARK: - Public Methods

    /// Find partner activity since the user's last seen timestamp (legacy UUID version)
    /// @deprecated Use findPartnerActivityByRecordID instead
    /// - Parameters:
    ///   - events: All events to analyze
    ///   - currentUserId: ID of the current user (events from this user are excluded)
    ///   - lastSeenTimestamp: When the user last dismissed/acknowledged partner activity
    ///   - householdMembers: All household members (for name lookup)
    ///   - userLastActivityTime: Time of the user's last logged event (for gap detection)
    /// - Returns: Partner activity summary if there's activity to show, nil otherwise
    @available(*, deprecated, message: "Use findPartnerActivityByRecordID with CloudKit record IDs")
    public static func findPartnerActivity(
        events: [PuppyEvent],
        currentUserId: UUID?,
        lastSeenTimestamp: Date?,
        householdMembers: HouseholdMembers,
        userLastActivityTime: Date?
    ) -> PartnerActivitySummary? {
        guard let currentUserId = currentUserId else { return nil }

        let currentUserIdString = currentUserId.uuidString

        // Filter to partner events only (not logged by current user)
        let partnerEvents = events.filter { event in
            guard let loggedBy = event.loggedBy else { return false }
            return loggedBy != currentUserIdString
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

        // Collect unique partner CloudKit record IDs and names
        var partnerRecordIDs: [String] = []
        var partnerRecordIDSet = Set<String>()
        var partnerNames: [String] = []

        for event in sortedEvents {
            if let loggedBy = event.loggedBy, !partnerRecordIDSet.contains(loggedBy) {
                partnerRecordIDSet.insert(loggedBy)
                partnerRecordIDs.append(loggedBy)
                // Try to look up by UUID (legacy) - convert string back to UUID
                if let uuid = UUID(uuidString: loggedBy),
                   let member = householdMembers.member(byId: uuid) {
                    partnerNames.append(member.name)
                } else {
                    partnerNames.append("Partner")
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

        // Find featured moment and generate summary (added in Phase 2)
        let featuredMoment = findFeaturedMoment(in: sortedEvents)
        let handoverSummary = generateHandoverSummary(events: sortedEvents, puppyName: nil)

        let summary = PartnerActivitySummary(
            partnerRecordIDs: partnerRecordIDs,
            partnerNames: partnerNames,
            events: sortedEvents,
            startTime: startTime,
            endTime: endTime,
            trainingEvents: trainingEvents,
            socializationEvents: socializationEvents,
            walkEvents: walkEvents,
            otherNotableEvents: otherNotableEvents,
            featuredMoment: featuredMoment,
            handoverSummary: handoverSummary
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
            .filter { $0.loggedBy == currentUserId.uuidString }
            .max(by: { $0.time < $1.time })?
            .time
    }

    // MARK: - CloudKit Record ID Based Methods

    /// Find partner activity using CloudKit record IDs
    /// - Parameters:
    ///   - events: All events to analyze
    ///   - currentUserRecordID: CloudKit record ID of the current user
    ///   - lastSeenTimestamp: When the user last dismissed/acknowledged partner activity
    ///   - userLastActivityTime: Time of the user's last logged event (for gap detection)
    ///   - puppyName: Name of the puppy (for natural language summary)
    ///   - partnerNameResolver: Optional closure to resolve partner names from record IDs
    /// - Returns: Partner activity summary if there's activity to show, nil otherwise
    public static func findPartnerActivityByRecordID(
        events: [PuppyEvent],
        currentUserRecordID: String,
        lastSeenTimestamp: Date?,
        userLastActivityTime: Date?,
        puppyName: String? = nil,
        partnerNameResolver: ((String) -> String)? = nil
    ) -> PartnerActivitySummary? {
        // Filter to partner events only (not logged by current user)
        let partnerEvents = events.filter { event in
            guard let loggedBy = event.loggedBy else { return false }
            return loggedBy != currentUserRecordID
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

        // Collect unique partner CloudKit record IDs
        var partnerRecordIDs: [String] = []
        var partnerRecordIDSet = Set<String>()
        for event in sortedEvents {
            if let loggedBy = event.loggedBy, !partnerRecordIDSet.contains(loggedBy) {
                partnerRecordIDSet.insert(loggedBy)
                partnerRecordIDs.append(loggedBy)
            }
        }

        // Resolve partner names via closure or use placeholder
        let partnerNames = partnerRecordIDs.map { recordID in
            partnerNameResolver?(recordID) ?? "Partner"
        }

        // Categorize events
        let trainingEvents = sortedEvents.filter { $0.type == .training }
        let socializationEvents = sortedEvents.filter { $0.type == .sociaal }
        let walkEvents = sortedEvents.filter { $0.type == .uitlaten }

        // Other notable events (exclude routine potty/meals, already categorized events)
        let notableTypes: Set<EventType> = [.milestone, .medicatie, .gedrag, .moment, .gewicht]
        let otherNotableEvents = sortedEvents.filter { notableTypes.contains($0.type) }

        // Find featured moment (moment with photo, or first event with photo)
        let featuredMoment = findFeaturedMoment(in: sortedEvents)

        // Generate natural language summary
        let handoverSummary = generateHandoverSummary(
            events: sortedEvents,
            puppyName: puppyName
        )

        let summary = PartnerActivitySummary(
            partnerRecordIDs: partnerRecordIDs,
            partnerNames: partnerNames,
            events: sortedEvents,
            startTime: startTime,
            endTime: endTime,
            trainingEvents: trainingEvents,
            socializationEvents: socializationEvents,
            walkEvents: walkEvents,
            otherNotableEvents: otherNotableEvents,
            featuredMoment: featuredMoment,
            handoverSummary: handoverSummary
        )

        // Only return if it meets the threshold to show
        guard summary.shouldShow else { return nil }

        return summary
    }

    /// Get events logged by the current user using CloudKit record ID
    /// - Parameters:
    ///   - events: All events to analyze
    ///   - currentUserRecordID: CloudKit record ID of the current user
    /// - Returns: Most recent event time logged by the current user
    public static func findUserLastActivityTimeByRecordID(
        events: [PuppyEvent],
        currentUserRecordID: String
    ) -> Date? {
        return events
            .filter { $0.loggedBy == currentUserRecordID }
            .max(by: { $0.time < $1.time })?
            .time
    }

    // MARK: - Featured Moment & Summary Generation

    /// Find the best moment to feature in handover card
    /// Prioritizes: moments with photos > walks with photos > any event with photo
    /// - Parameter events: Events to search
    /// - Returns: Best event to feature, or nil
    public static func findFeaturedMoment(in events: [PuppyEvent]) -> PuppyEvent? {
        // First priority: moment events with photos
        if let moment = events.first(where: {
            $0.type == .moment && ($0.thumbnailPath != nil || $0.photo != nil)
        }) {
            return moment
        }

        // Second priority: walks with photos
        if let walk = events.first(where: {
            $0.type == .uitlaten && ($0.thumbnailPath != nil || $0.photo != nil)
        }) {
            return walk
        }

        // Third priority: any event with a photo
        if let withPhoto = events.first(where: {
            $0.thumbnailPath != nil || $0.photo != nil
        }) {
            return withPhoto
        }

        return nil
    }

    /// Generate natural language summary of partner activities
    /// - Parameters:
    ///   - events: Partner events to summarize
    ///   - puppyName: Optional puppy name for personalization
    /// - Returns: Natural language summary string
    public static func generateHandoverSummary(
        events: [PuppyEvent],
        puppyName: String?
    ) -> String? {
        guard !events.isEmpty else { return nil }

        // Count key activities
        let pottyOutside = events.filter { isPottyEvent($0) && $0.location == .buiten }.count
        let pottyInside = events.filter { isPottyEvent($0) && $0.location == .binnen }.count
        let naps = events.filter { $0.type == .slapen }.count
        let walks = events.filter { $0.type == .uitlaten }.count
        let trainingSessions = events.filter { $0.type == .training }.count
        let meals = events.filter { $0.type == .eten }.count

        // Calculate total walk duration
        let walkMinutes = events
            .filter { $0.type == .uitlaten }
            .compactMap { $0.durationMin }
            .reduce(0, +)

        var parts: [String] = []

        // Sleep/nap summary
        if naps > 0 {
            parts.append(naps == 1
                ? String(localized: "1 nap", table: "Handoff")
                : String(localized: "\(naps) naps", table: "Handoff"))
        }

        // Walk summary with duration
        if walks > 0 {
            if walkMinutes > 0 {
                parts.append(walks == 1
                    ? String(localized: "\(walkMinutes) min walk", table: "Handoff")
                    : String(localized: "\(walkMinutes) min walks", table: "Handoff"))
            } else {
                parts.append(walks == 1
                    ? String(localized: "1 walk", table: "Handoff")
                    : String(localized: "\(walks) walks", table: "Handoff"))
            }
        }

        // Training summary
        if trainingSessions > 0 {
            parts.append(trainingSessions == 1
                ? String(localized: "training", table: "Handoff")
                : String(localized: "\(trainingSessions) training sessions", table: "Handoff"))
        }

        // Meals summary
        if meals > 0 {
            parts.append(meals == 1
                ? String(localized: "1 meal", table: "Handoff")
                : String(localized: "\(meals) meals", table: "Handoff"))
        }

        // Build main summary
        var summary = parts.joined(separator: ", ")

        // Add potty status at the end
        if pottyOutside > 0 || pottyInside > 0 {
            if summary.isEmpty {
                // Only potty events
                if pottyInside == 0 && pottyOutside > 0 {
                    summary = String(localized: "All potty breaks outside!", table: "Handoff")
                } else if pottyInside > 0 {
                    summary = pottyInside == 1
                        ? String(localized: "1 accident inside", table: "Handoff")
                        : String(localized: "\(pottyInside) accidents inside", table: "Handoff")
                }
            } else {
                // Append potty summary
                if pottyInside == 0 && pottyOutside > 0 {
                    summary += String(localized: " — all potty outside!", table: "Handoff")
                } else if pottyInside > 0 {
                    let accidentText = pottyInside == 1
                        ? String(localized: "1 accident", table: "Handoff")
                        : String(localized: "\(pottyInside) accidents", table: "Handoff")
                    summary += String(localized: " — \(accidentText) inside", table: "Handoff")
                }
            }
        }

        // Return nil if nothing meaningful to say
        return summary.isEmpty ? nil : summary
    }

    /// Check if an event is a potty event
    private static func isPottyEvent(_ event: PuppyEvent) -> Bool {
        event.type == .plassen || event.type == .poepen
    }
}
