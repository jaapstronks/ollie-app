//
//  Strings+RecentActivity.swift
//  Otis-app
//
//  Localization strings for the recent activity preview and full timeline sheet

import Foundation

private let table = "Timeline"

extension Strings {

    // MARK: - Recent Activity

    enum RecentActivity {

        // MARK: - Section Titles
        static let sectionTitle = String(localized: "Recent Activity", table: table)
        static let fullTimelineTitle = String(localized: "Timeline", table: table)

        // MARK: - Empty State
        static let noRecentActivity = String(localized: "No recent activity", table: table)
        static let startLogging = String(localized: "Start logging to see events here", table: table)

        // MARK: - Actions
        static let viewFullTimeline = String(localized: "View full timeline", table: table)

        // MARK: - Time Context
        static func inLastHours(_ hours: Int) -> String {
            String(localized: "in the last \(hours) hours", table: table)
        }

        // MARK: - Sheet Navigation
        static let done = String(localized: "Done", table: table)
    }
}
