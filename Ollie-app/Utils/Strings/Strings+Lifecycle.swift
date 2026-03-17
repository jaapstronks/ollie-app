//
//  Strings+Lifecycle.swift
//  Otis-app
//
//  Strings for lifecycle phase transitions

import Foundation

private let table = "Lifecycle"

extension Strings {

    // MARK: - Lifecycle Transitions
    enum LifecycleTransition {
        static let letsGo = String(localized: "Let's go!", table: table)

        // MARK: - Teenage Phase
        enum Teenage {
            static func title(name: String) -> String {
                String(localized: "\(name) is growing up!", table: table)
            }
            static func subtitle(name: String) -> String {
                String(localized: "\(name) has entered the adolescent phase! Here's what changes:", table: table)
            }
            static let behaviorTracking = String(localized: "Track behavior challenges", table: table)
            static let maintenanceMode = String(localized: "Training shifts to maintenance", table: table)
            static let adventureFocus = String(localized: "More focus on adventures", table: table)
        }

        // MARK: - Adult Phase
        enum Adult {
            static func title(name: String) -> String {
                String(localized: "\(name) is all grown up!", table: table)
            }
            static func subtitle(name: String) -> String {
                String(localized: "\(name) is now an adult dog! Here's what changes:", table: table)
            }
            static let routineFocus = String(localized: "Establish daily routines", table: table)
            static let healthMonitoring = String(localized: "Health monitoring begins", table: table)
            static let memoriesCapture = String(localized: "Capture special moments", table: table)
        }

        // MARK: - Senior Phase
        enum Senior {
            static func title(name: String) -> String {
                String(localized: "\(name)'s golden years", table: table)
            }
            static func subtitle(name: String) -> String {
                String(localized: "\(name) is now a senior dog! Here's what changes:", table: table)
            }
            static let wellnessCheckins = String(localized: "Regular wellness check-ins", table: table)
            static let medicationReminders = String(localized: "Medication tracking enabled", table: table)
            static let comfortTips = String(localized: "Comfort and care tips", table: table)
        }

        // MARK: - Notification Preferences
        enum Notifications {
            static let title = String(localized: "Notification Preferences", table: table)
            static let keepCurrent = String(localized: "Keep current settings", table: table)
            static let useDefaults = String(localized: "Use recommended settings", table: table)
            static func defaultsDescription(phase: String) -> String {
                String(localized: "Optimized for the \(phase) phase", table: table)
            }
        }
    }
}
