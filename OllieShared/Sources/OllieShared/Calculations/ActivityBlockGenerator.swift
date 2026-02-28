//
//  ActivityBlockGenerator.swift
//  OllieShared
//
//  Generates activity blocks from puppy events for the visual timeline

import Foundation

/// Generator for activity blocks from puppy events
public struct ActivityBlockGenerator {

    // MARK: - Configuration

    /// Default start of day (6 AM)
    public static let defaultDayStartHour = 6

    /// Default end of day (10 PM / 22:00)
    public static let defaultDayEndHour = 22

    // MARK: - Public Methods

    /// Generate activity blocks for a given day's events
    /// - Parameters:
    ///   - events: All events for the day (sorted chronologically)
    ///   - date: The date to generate blocks for
    ///   - previousDayEvents: Events from the previous day (for overnight sleep)
    /// - Returns: Array of activity blocks sorted by start time
    public static func generateBlocks(
        events: [PuppyEvent],
        for date: Date,
        previousDayEvents: [PuppyEvent] = []
    ) -> [ActivityBlock] {
        var blocks: [ActivityBlock] = []
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDateInToday(date)

        // Determine day bounds
        let dayStart = calendar.date(bySettingHour: defaultDayStartHour, minute: 0, second: 0, of: date) ?? date
        let dayEnd: Date
        if isToday {
            dayEnd = now
        } else {
            dayEnd = calendar.date(bySettingHour: defaultDayEndHour, minute: 0, second: 0, of: date) ?? date
        }

        // Build sleep sessions
        let allEvents = previousDayEvents + events
        let sleepSessions = SleepSession.buildSessions(from: allEvents)

        // Add sleep blocks
        for session in sleepSessions {
            // Check if session overlaps with our day
            let sessionEnd = session.endTime ?? now
            guard session.startTime < dayEnd && sessionEnd > dayStart else { continue }

            // Clamp to day bounds
            let blockStart = max(session.startTime, dayStart)
            let blockEnd = min(sessionEnd, dayEnd)

            let block = ActivityBlock(
                id: session.id,
                type: .sleep,
                startTime: blockStart,
                endTime: blockEnd,
                containedEventIds: [session.startEventId] + (session.endEventId.map { [$0] } ?? []),
                isOngoing: session.isOngoing && isToday
            )
            blocks.append(block)
        }

        // Add walk blocks
        let walks = events.walks()
        for walk in walks {
            let duration = walk.durationMin ?? 30  // Default to 30 min if no duration
            let walkEnd = walk.time.addingTimeInterval(Double(duration) * 60)

            let block = ActivityBlock(
                id: walk.id,
                type: .walk,
                startTime: walk.time,
                endTime: walkEnd,
                containedEventIds: [walk.id],
                isOngoing: false
            )
            blocks.append(block)
        }

        // Add potty markers
        let pottyEvents = events.filter { $0.type.isPottyEvent }
        for potty in pottyEvents {
            let isOutdoor = potty.location == .buiten
            let block = ActivityBlock(
                id: potty.id,
                type: .potty(outdoor: isOutdoor),
                startTime: potty.time,
                endTime: potty.time,  // Point in time
                containedEventIds: [potty.id],
                isOngoing: false
            )
            blocks.append(block)
        }

        // Add meal markers
        let mealEvents = events.filter { $0.type == .eten || $0.type == .drinken }
        for meal in mealEvents {
            let block = ActivityBlock(
                id: meal.id,
                type: .meal,
                startTime: meal.time,
                endTime: meal.time,  // Point in time
                containedEventIds: [meal.id],
                isOngoing: false
            )
            blocks.append(block)
        }

        // Sort by start time
        return blocks.sorted { $0.startTime < $1.startTime }
    }

    /// Generate a summary from activity blocks
    /// - Parameter blocks: Array of activity blocks
    /// - Returns: Summary statistics
    public static func generateSummary(from blocks: [ActivityBlock]) -> ActivityBlockSummary {
        var totalSleepMinutes = 0
        var walkCount = 0
        var totalWalkMinutes = 0
        var outdoorPottyCount = 0
        var indoorPottyCount = 0
        var mealCount = 0

        for block in blocks {
            switch block.type {
            case .sleep:
                totalSleepMinutes += block.durationMinutes
            case .walk:
                walkCount += 1
                totalWalkMinutes += block.durationMinutes
            case .potty(let outdoor):
                if outdoor {
                    outdoorPottyCount += 1
                } else {
                    indoorPottyCount += 1
                }
            case .meal:
                mealCount += 1
            case .awake:
                break
            }
        }

        return ActivityBlockSummary(
            totalSleepMinutes: totalSleepMinutes,
            walkCount: walkCount,
            totalWalkMinutes: totalWalkMinutes,
            outdoorPottyCount: outdoorPottyCount,
            indoorPottyCount: indoorPottyCount,
            mealCount: mealCount
        )
    }

    /// Generate blocks and summary together
    /// - Parameters:
    ///   - events: All events for the day
    ///   - date: The date to generate for
    ///   - previousDayEvents: Events from previous day for overnight sleep
    /// - Returns: Tuple of blocks and summary
    public static func generate(
        events: [PuppyEvent],
        for date: Date,
        previousDayEvents: [PuppyEvent] = []
    ) -> (blocks: [ActivityBlock], summary: ActivityBlockSummary) {
        let blocks = generateBlocks(events: events, for: date, previousDayEvents: previousDayEvents)
        let summary = generateSummary(from: blocks)
        return (blocks, summary)
    }

    /// Get the time bounds for displaying the timeline
    /// - Parameters:
    ///   - blocks: Activity blocks to display
    ///   - date: The date being displayed
    /// - Returns: Start and end times for the timeline view
    public static func timelineBounds(
        for blocks: [ActivityBlock],
        date: Date
    ) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        // Default bounds
        var startHour = defaultDayStartHour
        var endHour = defaultDayEndHour

        // Expand to fit earliest block
        if let firstBlock = blocks.first {
            let blockHour = calendar.component(.hour, from: firstBlock.startTime)
            if blockHour < startHour {
                startHour = max(0, blockHour - 1)
            }
        }

        // Expand to fit latest block (or current time if today)
        if let lastBlock = blocks.last {
            let blockEndHour = calendar.component(.hour, from: lastBlock.endTime)
            if blockEndHour >= endHour {
                endHour = min(23, blockEndHour + 1)
            }
        }

        let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) ?? date
        let end: Date

        if isToday {
            end = Date()
        } else {
            end = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: date) ?? date
        }

        return (start, end)
    }
}
