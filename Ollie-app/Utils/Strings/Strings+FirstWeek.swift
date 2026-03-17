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

        // MARK: - Photo Prompt

        static var photoPromptTitle: String {
            String(localized: "Capture this moment", table: table)
        }

        static func photoPromptSubtitle(name: String) -> String {
            String(localized: "Add a photo to remember \(name)'s first days", table: table)
        }

        static var addFirstPhoto: String {
            String(localized: "Add First Photo", table: table)
        }

        // MARK: - Family Invite Prompt

        static var invitePromptTitle: String {
            String(localized: "Share the care", table: table)
        }

        static func invitePromptSubtitle(name: String) -> String {
            String(localized: "Invite a partner or family member to help track \(name)", table: table)
        }

        static var inviteSomeone: String {
            String(localized: "Invite Someone", table: table)
        }

        // MARK: - First Event Celebration

        static var firstEventTitle: String {
            String(localized: "First moment logged!", table: table)
        }

        static var firstEventSubtitle: String {
            String(localized: "You're on your way to understanding your puppy's patterns.", table: table)
        }

        // MARK: - Streak Celebrations

        static func streakCelebration(days: Int) -> String {
            String(localized: "\(days)-day streak! You're building great habits.", table: table)
        }

        static var keepItUp: String {
            String(localized: "Keep it up!", table: table)
        }

        // MARK: - Patterns Emerging

        static var patternsEmergingTitle: String {
            String(localized: "Patterns are forming", table: table)
        }

        static func patternsEmergingSubtitle(name: String) -> String {
            String(localized: "We're learning \(name)'s rhythms. Keep logging!", table: table)
        }

        // MARK: - Week Recap Tease Preview

        static var weekRecapTeaseTitle: String {
            String(localized: "Your first recap is coming!", table: table)
        }

        static func weekRecapTeaseSubtitle(daysLeft: Int) -> String {
            if daysLeft == 1 {
                return String(localized: "Tomorrow you'll see your first weekly summary.", table: table)
            } else {
                return String(localized: "In \(daysLeft) days, you'll see your first weekly summary.", table: table)
            }
        }

        // MARK: - Push Notifications

        static func howIsPuppy(name: String) -> String {
            String(localized: "How's \(name) doing?", table: table)
        }

        static var tapToLog: String {
            String(localized: "Tap to log what they're up to right now.", table: table)
        }

        static var goodMorning: String {
            String(localized: "Good morning!", table: table)
        }

        static func readyToTrack(name: String) -> String {
            String(localized: "Ready to track \(name)'s day?", table: table)
        }

        static func dontForgetToLog(name: String) -> String {
            String(localized: "Don't forget to log \(name)'s day", table: table)
        }

        static var evenQuickLogHelps: String {
            String(localized: "Even a quick potty log helps build routine insights.", table: table)
        }

        static func dayStreak(days: Int) -> String {
            String(localized: "Day \(days)!", table: table)
        }

        static var keepStreakGoing: String {
            String(localized: "Keep the streak going — log your first moment.", table: table)
        }
    }
}
