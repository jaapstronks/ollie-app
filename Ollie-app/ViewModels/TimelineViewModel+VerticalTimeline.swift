//
//  TimelineViewModel+VerticalTimeline.swift
//  Otis-app
//
//  Extension for the vertical day-planner timeline view
//  Delegates to TimelineItemBuilder for pure functions
//  VerticalTimelineItem model is in Models/VerticalTimelineItem.swift
//

import Foundation
import OtisShared

// MARK: - ViewModel Extension

extension TimelineViewModel {

    /// Set of event IDs that occurred during walks (for dual-track layout)
    /// Delegates to TimelineItemBuilder
    var walkConcurrentEventIds: Set<UUID> {
        TimelineItemBuilder.walkConcurrentEventIds(from: events)
    }

    /// Items prepared for vertical timeline display
    /// Groups sleep sessions, walks with duration, point events, and appointments
    /// Sorted newest-first (future at top, past at bottom)
    /// PERFORMANCE: Returns cached value to avoid rebuilding on every access
    var verticalTimelineItems: [VerticalTimelineItem] {
        cachedVerticalTimelineItems
    }

    /// Timeline start time (6am or first event - 1 hour, whichever is earlier)
    /// Delegates to TimelineItemBuilder
    var verticalTimelineStartTime: Date {
        TimelineItemBuilder.verticalTimelineStartTime(events: events, currentDate: currentDate)
    }

    /// Timeline end time (10pm or last event + 1 hour, whichever is later)
    /// Delegates to TimelineItemBuilder
    var verticalTimelineEndTime: Date {
        TimelineItemBuilder.verticalTimelineEndTime(
            events: events,
            currentDate: currentDate,
            isShowingToday: isShowingToday
        )
    }
}
