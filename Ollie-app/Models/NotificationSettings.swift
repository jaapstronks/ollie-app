//
//  NotificationSettings.swift
//  Ollie-app
//

import Foundation

/// Settings for smart notifications
struct NotificationSettings: Codable {
    /// Master toggle for all notifications
    var isEnabled: Bool
    var pottyReminders: PottyReminderSettings
    var mealReminders: MealReminderSettings
    var napReminders: NapReminderSettings
    var walkReminders: WalkReminderSettings

    static func defaultSettings() -> NotificationSettings {
        NotificationSettings(
            isEnabled: false,
            pottyReminders: PottyReminderSettings(),
            mealReminders: MealReminderSettings(),
            napReminders: NapReminderSettings(),
            walkReminders: WalkReminderSettings()
        )
    }
}

/// Settings for potty break reminders
struct PottyReminderSettings: Codable {
    var isEnabled: Bool = true
    var urgencyLevel: PottyNotificationLevel = .soon

    init(isEnabled: Bool = true, urgencyLevel: PottyNotificationLevel = .soon) {
        self.isEnabled = isEnabled
        self.urgencyLevel = urgencyLevel
    }
}

/// When to send potty notifications relative to expected time
enum PottyNotificationLevel: String, Codable, CaseIterable, Identifiable {
    case attention  // ~20 min remaining
    case soon       // ~10 min remaining
    case overdue    // Past expected time

    var id: String { rawValue }

    var label: String {
        switch self {
        case .attention: return Strings.NotificationSettings.pottyLevelEarly
        case .soon: return Strings.NotificationSettings.pottyLevelSoon
        case .overdue: return Strings.NotificationSettings.pottyLevelOnTime
        }
    }

    var description: String {
        switch self {
        case .attention: return Strings.NotificationSettings.pottyLevelEarlyDesc
        case .soon: return Strings.NotificationSettings.pottyLevelSoonDesc
        case .overdue: return Strings.NotificationSettings.pottyLevelOnTimeDesc
        }
    }

    /// Minutes before expected potty time to trigger notification
    var minutesBefore: Int {
        switch self {
        case .attention: return 20
        case .soon: return 10
        case .overdue: return 0
        }
    }
}

/// Settings for meal reminders
struct MealReminderSettings: Codable {
    var isEnabled: Bool = true
    var minutesBefore: Int = 10

    init(isEnabled: Bool = true, minutesBefore: Int = 10) {
        self.isEnabled = isEnabled
        self.minutesBefore = minutesBefore
    }
}

/// Settings for nap reminders (when puppy has been awake too long)
struct NapReminderSettings: Codable {
    var isEnabled: Bool = true
    var awakeThresholdMinutes: Int = 45

    init(isEnabled: Bool = true, awakeThresholdMinutes: Int = 45) {
        self.isEnabled = isEnabled
        self.awakeThresholdMinutes = awakeThresholdMinutes
    }
}

/// Settings for walk reminders
struct WalkReminderSettings: Codable {
    var isEnabled: Bool = true
    var minutesBefore: Int = 15

    init(isEnabled: Bool = true, minutesBefore: Int = 15) {
        self.isEnabled = isEnabled
        self.minutesBefore = minutesBefore
    }
}
