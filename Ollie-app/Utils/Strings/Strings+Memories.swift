//
//  Strings+Memories.swift
//  Otis-app
//
//  Localized strings for "On This Day" memories feature

import Foundation

extension Strings {
    enum Memories {
        private static let table = "Memories"

        static let oneWeekAgo = String(localized: "1 week ago", table: table, comment: "Memory time frame label for events from 1 week ago")
        static let oneMonthAgo = String(localized: "1 month ago", table: table, comment: "Memory time frame label for events from 1 month ago")
        static let oneYearAgo = String(localized: "1 year ago", table: table, comment: "Memory time frame label for events from 1 year ago")
        static let onThisDay = String(localized: "On this day", table: table, comment: "Memory card header title")
        static let noMemories = String(localized: "No events recorded", table: table, comment: "Shown when no memories exist for target date")
        static let photoInCloud = String(localized: "Syncing...", table: table, comment: "Shown when a photo is in iCloud but not yet downloaded locally")

        static func moreEvents(_ count: Int) -> String {
            String(localized: "+\(count) more", table: table, comment: "Shows additional event count in collapsed memories card")
        }
    }
}
