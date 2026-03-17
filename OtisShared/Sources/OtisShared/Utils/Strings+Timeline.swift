//
//  Strings+Timeline.swift
//  OtisShared
//
//  Timeline view strings.
//

import Foundation

extension Strings {
    // MARK: - Timeline
    public enum Timeline {
        public static var previousDay: String { String(localized: "Previous day", bundle: Strings.bundle) }
        public static var nextDay: String { String(localized: "Next day", bundle: Strings.bundle) }
        public static func dateLabel(date: String) -> String {
            String(localized: "Date: \(date)", bundle: Strings.bundle)
        }
        public static var noEvents: String { String(localized: "No events yet", bundle: Strings.bundle) }
        public static var tapToLog: String { String(localized: "Tap below to log the first one", bundle: Strings.bundle) }
        public static var deleteConfirmTitle: String { String(localized: "Delete?", bundle: Strings.bundle) }
        public static func deleteConfirmMessage(event: String, time: String) -> String {
            String(localized: "Are you sure you want to delete '\(event)' from \(time)?", bundle: Strings.bundle)
        }
        public static var eventDeleted: String { String(localized: "Event deleted", bundle: Strings.bundle) }
        public static var undoAccessibility: String { String(localized: "Double-tap Undo to restore", bundle: Strings.bundle) }
        public static var goToTodayHint: String { String(localized: "Double-tap to go to today", bundle: Strings.bundle) }
    }
}
