//
//  Strings+Memories.swift
//  Ollie-app
//
//  Localized strings for "On This Day" memories feature

import Foundation

extension Strings {
    enum Memories {
        static let oneWeekAgo = String(localized: "1 week ago", comment: "Memory time frame label for events from 1 week ago")
        static let oneMonthAgo = String(localized: "1 month ago", comment: "Memory time frame label for events from 1 month ago")
        static let oneYearAgo = String(localized: "1 year ago", comment: "Memory time frame label for events from 1 year ago")
        static let onThisDay = String(localized: "On this day", comment: "Memory card header title")
        static let noMemories = String(localized: "No events recorded", comment: "Shown when no memories exist for target date")

        static func moreEvents(_ count: Int) -> String {
            String(localized: "+\(count) more", comment: "Shows additional event count in collapsed memories card")
        }
    }
}
