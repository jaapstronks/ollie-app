//
//  Strings.swift
//  Ollie-app
//
//  Main enum for all user-facing strings.
//  Strings are organized into domain-based extensions in separate files.
//
//  Usage: Text(Strings.Timeline.noEvents)
//  For interpolation: Text(Strings.Timeline.dayWith(puppyName: profile.name))

import Foundation

enum Strings {
    // String extensions are organized in separate files:
    // - Strings+Common.swift: Common, App, Tabs, FAB
    // - Strings+Events.swift: EventType, EventLocation, QuickLog, etc.
    // - Strings+Timeline.swift: Timeline, Upcoming, PottyStatus, etc.
    // - Strings+Training.swift: Training module
    // - Strings+Settings.swift: Settings, Meals, Notifications
    // - Strings+Health.swift: Health, Medications
    // - Strings+Walks.swift: Walks, WalkLocations, Spots
    // - Strings+Onboarding.swift: Onboarding, SizeCategory
    // - Strings+Premium.swift: Premium, Siri
    // - Strings+Widgets.swift: Widgets, PushNotifications
    // - Strings+Social.swift: Socialization
    // - Strings+Misc.swift: Stats, Streak, Tips, Errors, etc.
}
