//
//  Strings+FirstWeek.swift
//  Otis-app
//
//  Localized strings for the first week summary card
//

import Foundation

extension Strings {
    enum FirstWeek {
        private static let table = "FirstWeek"

        // MARK: - Card Header

        static func cardTitle(day: Int, name: String) -> String {
            String(localized: "Day \(day) with \(name)", table: table)
        }

        // MARK: - Main Messages (by day range)

        static let day1Message = String(
            localized: "Focus on bonding and feeling safe. The routines can wait.",
            table: table
        )

        static let days2to3Message = String(
            localized: "Building your first rhythms together.",
            table: table
        )

        static let days4to5Message = String(
            localized: "The routine is taking shape.",
            table: table
        )

        static let days6to7Message = String(
            localized: "Almost through week one!",
            table: table
        )

        // MARK: - Potty Training Lines

        static func outdoorPottyCount(count: Int) -> String {
            if count == 0 {
                return String(localized: "No outdoor potties yesterday — keep trying!", table: table)
            } else if count == 1 {
                return String(localized: "1 outdoor potty yesterday", table: table)
            } else {
                return String(localized: "\(count) outdoor potties yesterday", table: table)
            }
        }

        // MARK: - Crate Training Lines

        static let logNapLocationTip = String(
            localized: "Tip: Log where naps happen to track crate comfort.",
            table: table
        )

        static let noCrateNapsYet = String(
            localized: "No crate naps yet — that's okay.",
            table: table
        )

        static func crateNapCount(count: Int) -> String {
            if count == 1 {
                return String(localized: "1 crate nap yesterday", table: table)
            } else {
                return String(localized: "\(count) crate naps yesterday", table: table)
            }
        }

        static func allNapsInCrate(count: Int) -> String {
            if count == 1 {
                return String(localized: "All naps in crate yesterday!", table: table)
            } else {
                return String(localized: "All \(count) naps in crate yesterday!", table: table)
            }
        }

        // MARK: - Encouragement

        static let encouragement = String(
            localized: "You're doing great.",
            table: table
        )

        // MARK: - Accessibility

        static func accessibilityLabel(day: Int, name: String) -> String {
            String(localized: "First week summary. Day \(day) with \(name).", table: table)
        }

        static let expandHint = String(
            localized: "Tap to expand",
            table: table
        )

        static let collapseHint = String(
            localized: "Tap to collapse",
            table: table
        )
    }
}
