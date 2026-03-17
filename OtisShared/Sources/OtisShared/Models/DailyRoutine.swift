//
//  DailyRoutine.swift
//  OtisShared
//
//  Daily routine tracking for adult dogs - scheduled activities that repeat each day
//

import Foundation

// MARK: - Routine Category

/// Categories for organizing routine items
public enum RoutineCategory: String, Codable, Sendable, CaseIterable {
    case morning
    case afternoon
    case evening
    case anytime

    public var label: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .anytime: return "Anytime"
        }
    }

    public var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .anytime: return "clock.fill"
        }
    }
}

// MARK: - Routine Item

/// A single item in the daily routine
public struct RoutineItem: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var label: String
    public var time: Date?                         // Optional scheduled time
    public var category: RoutineCategory
    public var isEnabled: Bool
    public var linkedEventType: String?            // Links to PuppyEvent.EventType for auto-completion
    public var sortOrder: Int
    public var createdAt: Date
    public var modifiedAt: Date

    /// Human-readable name for logging (conforms to StorableModel)
    public var displayName: String {
        label
    }

    public init(
        id: UUID = UUID(),
        label: String,
        time: Date? = nil,
        category: RoutineCategory = .morning,
        isEnabled: Bool = true,
        linkedEventType: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.time = time
        self.category = category
        self.isEnabled = isEnabled
        self.linkedEventType = linkedEventType
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Formatted time string for display
    public var formattedTime: String? {
        guard let time = time else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

// MARK: - Daily Routine

/// A complete daily routine consisting of multiple items
public struct DailyRoutine: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var items: [RoutineItem]
    public var isActive: Bool
    public var createdAt: Date
    public var modifiedAt: Date

    /// Human-readable name for logging
    public var displayName: String {
        name
    }

    public init(
        id: UUID = UUID(),
        name: String = "Daily Routine",
        items: [RoutineItem] = [],
        isActive: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.isActive = isActive
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Items grouped by category
    public var itemsByCategory: [RoutineCategory: [RoutineItem]] {
        Dictionary(grouping: items.filter(\.isEnabled)) { $0.category }
    }

    /// Items sorted by time for a given category
    public func items(for category: RoutineCategory) -> [RoutineItem] {
        items
            .filter { $0.category == category && $0.isEnabled }
            .sorted { item1, item2 in
                // Sort by time if both have times, otherwise by sortOrder
                if let time1 = item1.time, let time2 = item2.time {
                    return time1 < time2
                }
                return item1.sortOrder < item2.sortOrder
            }
    }
}

// MARK: - Default Templates

public extension DailyRoutine {

    /// Default routine template for adult dogs
    static func adultDogDefault() -> DailyRoutine {
        let now = Date()
        let calendar = Calendar.current

        func time(hour: Int, minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }

        return DailyRoutine(
            name: "Daily Routine",
            items: [
                // Morning
                RoutineItem(label: "Morning walk", time: time(hour: 7, minute: 30), category: .morning, linkedEventType: "uitlaten", sortOrder: 0),
                RoutineItem(label: "Breakfast", time: time(hour: 8), category: .morning, linkedEventType: "eten", sortOrder: 1),

                // Afternoon
                RoutineItem(label: "Midday walk", time: time(hour: 12, minute: 30), category: .afternoon, linkedEventType: "uitlaten", sortOrder: 2),
                RoutineItem(label: "Play time", time: nil, category: .afternoon, sortOrder: 3),

                // Evening
                RoutineItem(label: "Evening walk", time: time(hour: 18), category: .evening, linkedEventType: "uitlaten", sortOrder: 4),
                RoutineItem(label: "Dinner", time: time(hour: 18, minute: 30), category: .evening, linkedEventType: "eten", sortOrder: 5),
                RoutineItem(label: "Final potty break", time: time(hour: 22), category: .evening, linkedEventType: "uitlaten", sortOrder: 6)
            ]
        )
    }

    /// Minimal routine for low-maintenance dogs
    static func minimal() -> DailyRoutine {
        let now = Date()
        let calendar = Calendar.current

        func time(hour: Int, minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }

        return DailyRoutine(
            name: "Simple Routine",
            items: [
                RoutineItem(label: "Morning walk", time: time(hour: 8), category: .morning, linkedEventType: "uitlaten", sortOrder: 0),
                RoutineItem(label: "Meals", time: time(hour: 8, minute: 30), category: .morning, linkedEventType: "eten", sortOrder: 1),
                RoutineItem(label: "Evening walk", time: time(hour: 18), category: .evening, linkedEventType: "uitlaten", sortOrder: 2)
            ]
        )
    }
}

// MARK: - Array Extensions

public extension Array where Element == RoutineItem {
    /// Sort items by time (earliest first)
    func sortedByTime() -> [RoutineItem] {
        sorted { item1, item2 in
            guard let time1 = item1.time else { return false }
            guard let time2 = item2.time else { return true }
            return time1 < time2
        }
    }

    /// Filter to only enabled items
    var enabled: [RoutineItem] {
        filter(\.isEnabled)
    }

    /// Get the next scheduled item after a given time
    func nextItem(after date: Date = Date()) -> RoutineItem? {
        let calendar = Calendar.current

        return filter { item in
            guard let itemTime = item.time else { return false }
            // Compare time components only (ignore date)
            let itemComponents = calendar.dateComponents([.hour, .minute], from: itemTime)
            let nowComponents = calendar.dateComponents([.hour, .minute], from: date)

            guard let itemHour = itemComponents.hour,
                  let itemMinute = itemComponents.minute,
                  let nowHour = nowComponents.hour,
                  let nowMinute = nowComponents.minute else { return false }

            let itemMinutes = itemHour * 60 + itemMinute
            let nowMinutes = nowHour * 60 + nowMinute

            return itemMinutes > nowMinutes
        }
        .sortedByTime()
        .first
    }
}
