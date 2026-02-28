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

    /// Re-localizes the label to the current locale
    /// This handles stored labels that may have been created in a different language
    var localizedLabel: String {
        ScheduleLabelLocalizer.localize(label, itemType: itemType)
    }
}

// MARK: - Schedule Label Localizer

/// Utility to re-localize meal and walk schedule labels
/// Handles the case where labels were stored in one language but need to display in another
enum ScheduleLabelLocalizer {

    /// Localizes a stored label to the current locale
    static func localize(_ storedLabel: String, itemType: UpcomingItemType) -> String {
        switch itemType {
        case .meal:
            return localizeMealLabel(storedLabel)
        case .walk:
            return localizeWalkLabel(storedLabel)
        }
    }

    // MARK: - Meal Labels

    /// Maps known meal labels (in any supported language) to current locale
    private static func localizeMealLabel(_ label: String) -> String {
        // Map all known variations to the canonical localized string
        let normalizedLabel = label.lowercased().trimmingCharacters(in: .whitespaces)

        // Breakfast variations
        if normalizedLabel == "breakfast" || normalizedLabel == "ontbijt" {
            return Strings.Meals.breakfast
        }

        // Lunch variations
        if normalizedLabel == "lunch" {
            return Strings.Meals.lunch
        }

        // Afternoon variations
        if normalizedLabel == "afternoon" || normalizedLabel == "middag" {
            return Strings.Meals.afternoon
        }

        // Dinner variations
        if normalizedLabel == "dinner" || normalizedLabel == "diner" || normalizedLabel == "avondeten" {
            return Strings.Meals.dinner
        }

        // Morning variations
        if normalizedLabel == "morning" || normalizedLabel == "ochtend" {
            return Strings.Meals.morning
        }

        // Evening variations
        if normalizedLabel == "evening" || normalizedLabel == "avond" {
            return Strings.Meals.evening
        }

        // Fall back to original label if no match
        return label
    }

    // MARK: - Walk Labels

    /// Maps known walk labels (in any supported language) to current locale
    private static func localizeWalkLabel(_ label: String) -> String {
        let normalizedLabel = label.lowercased().trimmingCharacters(in: .whitespaces)

        // Morning walk
        if normalizedLabel == "morning walk" || normalizedLabel == "ochtendwandeling" {
            return Strings.Walks.morningWalk
        }

        // Evening walk
        if normalizedLabel == "evening walk" || normalizedLabel == "avondwandeling" {
            return Strings.Walks.eveningWalk
        }

        // Afternoon walk
        if normalizedLabel == "afternoon walk" || normalizedLabel == "middagwandeling" {
            return Strings.Walks.afternoonWalk
        }

        // Late afternoon
        if normalizedLabel == "late afternoon" || normalizedLabel == "late middag" {
            return Strings.Walks.lateAfternoon
        }

        // Early morning
        if normalizedLabel == "early morning" || normalizedLabel == "vroege ochtend" {
            return Strings.Walks.earlyMorning
        }

        // Mid-morning
        if normalizedLabel == "mid-morning" || normalizedLabel == "mid-ochtend" {
            return Strings.Walks.midMorning
        }

        // Lunch walk
        if normalizedLabel == "lunch walk" || normalizedLabel == "lunchwandeling" {
            return Strings.Walks.lunchWalk
        }

        // Early afternoon
        if normalizedLabel == "early afternoon" || normalizedLabel == "vroege middag" {
            return Strings.Walks.earlyAfternoon
        }

        // Late evening
        if normalizedLabel == "late evening" || normalizedLabel == "late avond" {
            return Strings.Walks.lateEvening
        }

        // Night walk
        if normalizedLabel == "night walk" || normalizedLabel == "nachtwandeling" {
            return Strings.Walks.nightWalk
        }

        // Next walk (generic)
        if normalizedLabel == "next walk" || normalizedLabel == "volgende wandeling" {
            return Strings.Walks.nextWalk
        }

        // Fall back to original label if no match
        return label
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
