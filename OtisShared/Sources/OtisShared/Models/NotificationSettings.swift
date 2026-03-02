//
//  NotificationSettings.swift
//  OtisShared
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

    // MARK: - Smart Notification Settings

    /// Quiet hours start (hour 0-23, e.g., 22 for 10 PM). Non-urgent notifications suppressed.
    public var quietHoursStart: Int
    /// Quiet hours end (hour 0-23, e.g., 7 for 7 AM). Non-urgent notifications suppressed.
    public var quietHoursEnd: Int
    /// Whether quiet hours are enabled
    public var quietHoursEnabled: Bool

    public init(
        isEnabled: Bool,
        pottyReminders: PottyReminderSettings,
        mealReminders: MealReminderSettings,
        napReminders: NapReminderSettings,
        walkReminders: WalkReminderSettings,
        appointmentReminders: AppointmentReminderSettings = AppointmentReminderSettings(),
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 7,
        quietHoursEnabled: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.pottyReminders = pottyReminders
        self.mealReminders = mealReminders
        self.napReminders = napReminders
        self.walkReminders = walkReminders
        self.appointmentReminders = appointmentReminders
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.quietHoursEnabled = quietHoursEnabled
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

    /// Check if a given time falls within quiet hours
    public func isInQuietHours(_ date: Date = Date()) -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = Calendar.current.component(.hour, from: date)

        if quietHoursStart > quietHoursEnd {
            // Spans midnight (e.g., 22:00 - 07:00)
            return hour >= quietHoursStart || hour < quietHoursEnd
        } else {
            // Same day (e.g., 14:00 - 16:00)
            return hour >= quietHoursStart && hour < quietHoursEnd
        }
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
    /// Whether to send "waking up soon" notifications based on average nap duration
    public var wakeUpSoonEnabled: Bool
    /// Minutes before expected wake time to send notification
    public var wakeUpSoonMinutesBefore: Int

    public init(
        isEnabled: Bool = true,
        awakeThresholdMinutes: Int = 45,
        wakeUpSoonEnabled: Bool = true,
        wakeUpSoonMinutesBefore: Int = 10
    ) {
        self.isEnabled = isEnabled
        self.awakeThresholdMinutes = awakeThresholdMinutes
        self.wakeUpSoonEnabled = wakeUpSoonEnabled
        self.wakeUpSoonMinutesBefore = wakeUpSoonMinutesBefore
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
