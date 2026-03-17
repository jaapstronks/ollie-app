//
//  Strings+Moments.swift
//  Ollie-app
//
//  Localized strings for moments-related features.
//

import Foundation

extension Strings {
    enum Moments {
        private static let table = "Localizable"

        // MARK: - Recent Moment Card

        /// "Latest Moment"
        static let latestMoment = String(localized: "Latest Moment", table: table)

        /// "View in Diary"
        static let viewInDiary = String(localized: "View in Diary", table: table)
    }
}
