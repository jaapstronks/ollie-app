//
//  Strings+VisualTimeline.swift
//  Ollie-app
//
//  Localization strings for the visual timeline feature

import Foundation

private let table = "Timeline"

extension Strings {

    // MARK: - Visual Timeline
    enum VisualTimeline {
        // View mode toggle
        static let visualMode = String(localized: "Visual", table: table)
        static let listMode = String(localized: "List", table: table)
        static let switchToVisual = String(localized: "Switch to visual view", table: table)
        static let switchToList = String(localized: "Switch to list view", table: table)

        // Legend
        static let legendSleep = String(localized: "Sleep", table: table)
        static let legendWalk = String(localized: "Walk", table: table)
        static let legendPotty = String(localized: "Potty", table: table)
        static let legendMeal = String(localized: "Meal", table: table)

        // Block types
        static let sleepBlock = String(localized: "Sleep", table: table)
        static let walkBlock = String(localized: "Walk", table: table)
        static let pottyOutdoor = String(localized: "Potty (outdoor)", table: table)
        static let pottyIndoor = String(localized: "Potty (indoor)", table: table)
        static let mealBlock = String(localized: "Meal", table: table)
        static let awakeBlock = String(localized: "Awake", table: table)

        // Block detail
        static let ongoing = String(localized: "Ongoing", table: table)
        static let containedEvents = String(localized: "Events", table: table)

        // Quick stats
        static let sleepToday = String(localized: "Sleep today", table: table)
        static let walksToday = String(localized: "Walks today", table: table)
        static let pottyScore = String(localized: "Potty success", table: table)
        static let outdoor = String(localized: "out", table: table)
        static let indoor = String(localized: "in", table: table)

        // Empty state
        static let noActivity = String(localized: "No activity yet", table: table)
        static let noActivityHint = String(localized: "Events will appear here as a visual timeline", table: table)

        // Summary stats
        static func sleepDuration(_ duration: String) -> String {
            String(localized: "\(duration) sleep", table: table)
        }
        static func walkCount(_ count: Int) -> String {
            String(localized: "\(count) walks", table: table)
        }
        static func pottyCount(outdoor: Int, indoor: Int) -> String {
            if indoor > 0 {
                return String(localized: "\(outdoor)/\(indoor) potty", table: table)
            }
            return String(localized: "\(outdoor) potty", table: table)
        }
        static func mealCount(_ count: Int) -> String {
            String(localized: "\(count) meals", table: table)
        }
    }
}
