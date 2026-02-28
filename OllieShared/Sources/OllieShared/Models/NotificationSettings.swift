//
//  NotificationSettings.swift
//  OllieShared
//

import Foundation

/// Settings for smart notifications
public struct NotificationSettings: Codable, Sendable {
    public var isEnabled: Bool
    public var pottyReminders: PottyReminderSettings
    public var mealReminders: MealReminderSettings
    public var napReminders: NapReminderSettings
    public var walkReminders: WalkReminderSettings
    public var appointmentReminders: AppointmentReminderSettings

    public init(
        isEnabled: Bool,
        pottyReminders: PottyReminderSettings,
        mealReminders: MealReminderSettings,
        napReminders: NapReminderSettings,
        walkReminders: WalkReminderSettings,
        appointmentReminders: AppointmentReminderSettings = AppointmentReminderSettings()
    ) {
        self.isEnabled = isEnabled
        self.pottyReminders = pottyReminders
        self.mealReminders = mealReminders
        self.napReminders = napReminders
        self.walkReminders = walkReminders
        self.appointmentReminders = appointmentReminders
    }

    public static func defaultSettings() -> NotificationSettings {
        NotificationSettings(
            isEnabled: false,
            pottyReminders: PottyReminderSettings(),
            mealReminders: MealReminderSettings(),
            napReminders: NapReminderSettings(),
            walkReminders: WalkReminderSettings(),
            appointmentReminders: AppointmentReminderSettings()
        )
    }
}

/// Settings for potty break reminders
public struct PottyReminderSettings: Codable, Sendable {
    public var isEnabled: Bool
    public var urgencyLevel: PottyNotificationLevel

    public init(isEnabled: Bool = true, urgencyLevel: PottyNotificationLevel = .soon) {
        self.isEnabled = isEnabled
        self.urgencyLevel = urgencyLevel
    }
}

/// When to send potty notifications relative to expected time
public enum PottyNotificationLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case attention  // ~20 min remaining
    case soon       // ~10 min remaining
    case overdue    // Past expected time

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .attention: return Strings.NotificationSettings.pottyLevelEarly
        case .soon: return Strings.NotificationSettings.pottyLevelSoon
        case .overdue: return Strings.NotificationSettings.pottyLevelOnTime
        }
    }

    public var description: String {
        switch self {
        case .attention: return Strings.NotificationSettings.pottyLevelEarlyDesc
        case .soon: return Strings.NotificationSettings.pottyLevelSoonDesc
        case .overdue: return Strings.NotificationSettings.pottyLevelOnTimeDesc
        }
    }

    /// Minutes before expected potty time to trigger notification
    public var minutesBefore: Int {
        switch self {
        case .attention: return 20
        case .soon: return 10
        case .overdue: return 0
        }
    }
}

/// Settings for meal reminders
public struct MealReminderSettings: Codable, Sendable {
    public var isEnabled: Bool
    /// Minutes relative to scheduled time: 0 = at time, negative = after (overdue)
    public var minutesOffset: Int

    public init(isEnabled: Bool = true, minutesOffset: Int = 0) {
        self.isEnabled = isEnabled
        self.minutesOffset = minutesOffset
    }

    /// For backwards compatibility with old settings
    public var minutesBefore: Int {
        get { minutesOffset }
        set { minutesOffset = newValue }
    }
}

/// Settings for nap reminders
public struct NapReminderSettings: Codable, Sendable {
    public var isEnabled: Bool
    public var awakeThresholdMinutes: Int

    public init(isEnabled: Bool = true, awakeThresholdMinutes: Int = 45) {
        self.isEnabled = isEnabled
        self.awakeThresholdMinutes = awakeThresholdMinutes
    }
}

/// Settings for walk reminders
public struct WalkReminderSettings: Codable, Sendable {
    public var isEnabled: Bool
    /// Minutes relative to scheduled time: 0 = at time, negative = after (overdue)
    public var minutesOffset: Int

    public init(isEnabled: Bool = true, minutesOffset: Int = 0) {
        self.isEnabled = isEnabled
        self.minutesOffset = minutesOffset
    }

    /// For backwards compatibility with old settings
    public var minutesBefore: Int {
        get { minutesOffset }
        set { minutesOffset = newValue }
    }
}

/// Settings for appointment reminders
public struct AppointmentReminderSettings: Codable, Sendable {
    public var isEnabled: Bool

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
}
