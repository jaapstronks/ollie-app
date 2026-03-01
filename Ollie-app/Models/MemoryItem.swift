//
//  MemoryItem.swift
//  Otis-app
//
//  Model for "On This Day" memories feature

import Foundation
import OtisShared

/// Represents a memory from a past date
struct MemoryItem: Identifiable {
    let id: UUID
    let event: PuppyEvent
    let timeFrame: TimeFrame

    /// Time frames for memories based on how long user has been using the app
    enum TimeFrame {
        case week   // < 4 months of data
        case month  // 4-12 months of data
        case year   // > 12 months of data

        /// Localized label for display
        var label: String {
            switch self {
            case .week: return Strings.Memories.oneWeekAgo
            case .month: return Strings.Memories.oneMonthAgo
            case .year: return Strings.Memories.oneYearAgo
            }
        }

        /// SF Symbol icon
        var icon: String {
            "calendar"
        }

        /// Calendar component to subtract for target date
        func targetDate(from date: Date) -> Date? {
            let calendar = Calendar.current
            switch self {
            case .week:
                return calendar.date(byAdding: .weekOfYear, value: -1, to: date)
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: date)
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: date)
            }
        }
    }

    init(event: PuppyEvent, timeFrame: TimeFrame) {
        self.id = event.id
        self.event = event
        self.timeFrame = timeFrame
    }
}

// MARK: - Event Type Filtering

extension EventType {
    /// Whether this event type is memorable (should be shown in memories)
    var isMemorableEvent: Bool {
        switch self {
        case .sociaal, .milestone, .training, .uitlaten, .moment, .gewicht:
            return true
        case .plassen, .poepen, .eten, .drinken, .slapen, .ontwaken,
             .medicatie, .bench, .tuin, .gedrag, .coverageGap:
            return false
        }
    }
}
