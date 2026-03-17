//
//  Strings+Widgets.swift
//  Otis-app
//
//  Widgets and push notification strings

import Foundation
import OtisShared

private let table = "Widgets"

extension Strings {

    // MARK: - Notifications (push)
    enum PushNotifications {
        static let pottyAlarmTitle = String(localized: "Potty alarm!", table: table)
        static let goOutsideNowTitle = String(localized: "Go outside now!", table: table)
        static let mealTimeTitle = String(localized: "Time to eat!", table: table)
        static let mealOverdueTitle = String(localized: "Meal time!", table: table)
        static let walkTimeTitle = String(localized: "Time for a walk!", table: table)
        static let appointmentReminderTitle = String(localized: "Upcoming appointment", table: table)

        static func needsToPeeSoon(name: String) -> String {
            String(localized: "\(name) needs to pee soon!", table: table)
        }
        static func needsToPeeIn(name: String, minutes: Int) -> String {
            String(localized: "\(name) needs to pee in ~\(minutes) min", table: table)
        }
        static func needsToPeeNow(name: String) -> String {
            String(localized: "\(name) needs to pee now!", table: table)
        }
        static func mealReminder(name: String, meal: String) -> String {
            String(localized: "Time for \(name)'s \(meal)", table: table)
        }
        static func walkReminder(name: String) -> String {
            String(localized: "Time for \(name)'s walk", table: table)
        }
        static let napNeededTitle = String(localized: "Nap needed?", table: table)
        static func napNeededBody(name: String, minutes: Int) -> String {
            let duration = DurationFormatter.format(minutes, style: .naturalLanguage)
            return String(localized: "\(name) has been awake for \(duration)", table: table)
        }
        static func appointmentReminder(name: String, title: String, time: String) -> String {
            String(localized: "\(name) has '\(title)' at \(time)", table: table)
        }

        // Wake up soon notifications
        static let wakingUpSoonTitle = String(localized: "Waking up soon", table: table)
        static func wakingUpSoonBody(name: String) -> String {
            String(localized: "\(name) should wake up soon", table: table)
        }
        static func wakingUpSoonWithWalk(name: String) -> String {
            String(localized: "\(name) should wake up soon – walk is due", table: table)
        }
        static func wakingUpSoonWithMeal(name: String) -> String {
            String(localized: "\(name) should wake up soon – meal is due", table: table)
        }
        static func wakingUpSoonWithWalkAndMeal(name: String) -> String {
            String(localized: "\(name) should wake up soon – walk and meal are due", table: table)
        }
        static func wakingUpSoonWithPotty(name: String) -> String {
            String(localized: "\(name) should wake up soon – potty break needed", table: table)
        }

        // Moments notifications
        static let newMomentTitle = String(localized: "New photo!", table: table)
        static func newMomentBody(personName: String, puppyName: String) -> String {
            String(localized: "\(personName) captured a moment with \(puppyName)", table: table)
        }
        static func newMomentWithNote(personName: String, note: String) -> String {
            String(localized: "\(personName): \"\(note)\"", table: table)
        }
        static let likeActionTitle = String(localized: "Like", table: table)
        static let viewActionTitle = String(localized: "View", table: table)
    }
}
