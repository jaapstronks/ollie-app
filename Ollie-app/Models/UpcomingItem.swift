//
//  UpcomingItem.swift
//  Ollie-app
//
//  Models for upcoming scheduled items (meals, walks)
//

import Foundation
import OllieShared

// MARK: - Upcoming Item Type

/// Type of upcoming item for action handling
enum UpcomingItemType {
    case meal
    case walk

    var eventType: EventType {
        switch self {
        case .meal: return .eten
        case .walk: return .uitlaten
        }
    }
}

// MARK: - Upcoming Item

/// Represents an upcoming scheduled item (meal or walk)
struct UpcomingItem: Identifiable {
    let id = UUID()
    let icon: String             // SF Symbol name
    let label: String
    let detail: String?
    let targetTime: Date
    let itemType: UpcomingItemType
    let weatherIcon: String?     // SF Symbol name (sun.max.fill, cloud.rain.fill, etc.)
    let temperature: Int?        // Temperature in °C
    let rainWarning: Bool        // Highlight if >60% rain probability

    init(
        icon: String,
        label: String,
        detail: String?,
        targetTime: Date,
        itemType: UpcomingItemType,
        weatherIcon: String? = nil,
        temperature: Int? = nil,
        rainWarning: Bool = false
    ) {
        self.icon = icon
        self.label = label
        self.detail = detail
        self.targetTime = targetTime
        self.itemType = itemType
        self.weatherIcon = weatherIcon
        self.temperature = temperature
        self.rainWarning = rainWarning
    }

    var timeString: String {
        targetTime.timeString
    }

    /// Minutes until target time (negative if past)
    var minutesUntil: Int {
        Int(targetTime.timeIntervalSince(Date()) / 60)
    }
}

// MARK: - Actionable Item State

/// State of an actionable item
enum ActionableItemState {
    case approaching(minutesUntil: Int)  // 1-10 min before
    case due                              // at scheduled time (0 min or just past)
    case overdue(minutesOverdue: Int)     // past scheduled time
}

// MARK: - Actionable Item

/// An item that requires action (within 10 min or overdue)
struct ActionableItem: Identifiable {
    let id = UUID()
    let item: UpcomingItem
    let state: ActionableItemState
}
