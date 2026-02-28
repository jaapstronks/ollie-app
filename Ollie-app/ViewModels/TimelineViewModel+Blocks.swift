//
//  TimelineViewModel+Blocks.swift
//  Ollie-app
//
//  Extension for activity block computation for the visual timeline

import Foundation
import OllieShared
import SwiftUI

// MARK: - Activity Block State

extension TimelineViewModel {

    /// Activity blocks for the current day
    var activityBlocks: [ActivityBlock] {
        // Get previous day events for overnight sleep
        let calendar = Calendar.current
        let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        let previousDayStart = calendar.startOfDay(for: previousDay)
        let currentDayStart = calendar.startOfDay(for: currentDate)

        let previousDayEvents = eventStore.getEvents(from: previousDayStart, to: currentDayStart)

        return ActivityBlockGenerator.generateBlocks(
            events: events,
            for: currentDate,
            previousDayEvents: previousDayEvents
        )
    }

    /// Summary of activity blocks for the current day
    var activityBlockSummary: ActivityBlockSummary {
        ActivityBlockGenerator.generateSummary(from: activityBlocks)
    }

    /// Start time for the timeline display
    var timelineStartTime: Date {
        let bounds = ActivityBlockGenerator.timelineBounds(for: activityBlocks, date: currentDate)
        return bounds.start
    }

    /// End time for the timeline display
    var timelineEndTime: Date {
        let bounds = ActivityBlockGenerator.timelineBounds(for: activityBlocks, date: currentDate)
        return bounds.end
    }
}
