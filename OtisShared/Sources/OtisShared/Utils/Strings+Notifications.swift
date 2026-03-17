//
//  Strings+Notifications.swift
//  OtisShared
//
//  Notification settings strings.
//

import Foundation

extension Strings {
    // MARK: - Notification Settings
    public enum NotificationSettings {
        public static var title: String { String(localized: "Reminders", bundle: Strings.bundle) }
        public static var enableInSettings: String { String(localized: "Enable notifications in Settings to receive reminders.", bundle: Strings.bundle) }
        public static var notificationsDisabled: String { String(localized: "Notifications disabled", bundle: Strings.bundle) }
        public static var enableToReceive: String { String(localized: "Enable notifications to receive reminders", bundle: Strings.bundle) }
        public static var remindersDescription: String { String(localized: "Receive smart reminders for potty, meals, naps, and walks.", bundle: Strings.bundle) }
        public static var pottyReminders: String { String(localized: "Potty reminders", bundle: Strings.bundle) }
        public static var pottyAlarm: String { String(localized: "Potty alarm", bundle: Strings.bundle) }
        public static var mealReminder: String { String(localized: "Meal reminder", bundle: Strings.bundle) }
        public static var mealReminderDescription: String { String(localized: "Reminder before it's time for the next meal.", bundle: Strings.bundle) }
        public static var napNeeded: String { String(localized: "Nap needed", bundle: Strings.bundle) }
        public static func napReminderDescription(name: String) -> String {
            String(localized: "Reminder when \(name) has been awake too long.", bundle: Strings.bundle)
        }
        public static var walkReminders: String { String(localized: "Walk reminders", bundle: Strings.bundle) }
        public static var addWalk: String { String(localized: "Add walk", bundle: Strings.bundle) }
        public static var removeLast: String { String(localized: "Remove last", bundle: Strings.bundle) }
        public static var walks: String { String(localized: "Walks", bundle: Strings.bundle) }
        public static var walkReminderDescription: String { String(localized: "Reminder before it's time for a walk.", bundle: Strings.bundle) }
        public static var pottyLevelEarly: String { String(localized: "Early (~20 min)", bundle: Strings.bundle) }
        public static var pottyLevelSoon: String { String(localized: "Soon (~10 min)", bundle: Strings.bundle) }
        public static var pottyLevelOnTime: String { String(localized: "On time (0 min)", bundle: Strings.bundle) }
        public static var pottyLevelEarlyDesc: String { String(localized: "Reminder when ~20 minutes remaining", bundle: Strings.bundle) }
        public static var pottyLevelSoonDesc: String { String(localized: "Reminder when ~10 minutes remaining", bundle: Strings.bundle) }
        public static var pottyLevelOnTimeDesc: String { String(localized: "Reminder when it's time", bundle: Strings.bundle) }
    }
}
