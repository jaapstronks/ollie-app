//
//  Strings+Recap.swift
//  Otis-app
//
//  Strings for Monthly and Year Recap features

import Foundation

private let table = "Recap"

extension Strings {

    // MARK: - Recap Strings
    enum Recap {
        // Card titles
        static let cardTitle = String(localized: "Your month with", table: table)
        static let cardTitleReady = String(localized: "Your recap is ready!", table: table)
        static let viewRecap = String(localized: "View recap", table: table)
        static let almostComplete = String(localized: "Month almost complete", table: table)

        // Sheet titles
        static let sheetTitle = String(localized: "Monthly Recap", table: table)
        static let shareRecap = String(localized: "Share", table: table)

        // Stats labels
        static func walksCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 walk", table: table)
            } else {
                return String(localized: "\(count) walks", table: table)
            }
        }

        static func trainingSessions(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 training session", table: table)
            } else {
                return String(localized: "\(count) training sessions", table: table)
            }
        }

        static func socialMeetups(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 social meetup", table: table)
            } else {
                return String(localized: "\(count) social meetups", table: table)
            }
        }

        static func pottyOutdoors(_ percentage: Int) -> String {
            String(localized: "\(percentage)% outdoors", table: table)
        }

        static func totalTime(_ hours: String) -> String {
            String(localized: "\(hours) total", table: table)
        }

        static func daysWithWalks(_ days: Int, total: Int) -> String {
            String(localized: "\(days) of \(total) days", table: table)
        }

        // Photo grid
        static let moments = String(localized: "Moments", table: table)
        static let noPhotos = String(localized: "No photos this month", table: table)

        static func photoCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 photo", table: table)
            } else {
                return String(localized: "\(count) photos", table: table)
            }
        }

        // Month navigation
        static let previousMonth = String(localized: "Previous month", table: table)
        static let nextMonth = String(localized: "Next month", table: table)
        static let selectMonth = String(localized: "Select month", table: table)

        // Empty states
        static let noDataThisMonth = String(localized: "No activity logged this month", table: table)
        static let noRecapsAvailable = String(localized: "No monthly recaps available yet", table: table)

        // Share card
        static let monthWith = String(localized: "month with", table: table)

        // Accessibility
        static func recapAccessibilityLabel(month: String, walks: Int, training: Int) -> String {
            String(localized: "Monthly recap for \(month): \(walks) walks, \(training) training sessions", table: table)
        }

        // MARK: - Year in Review

        // Year card titles
        static let yearInReview = String(localized: "Year in Review", table: table)
        static let yearRecapReady = String(localized: "Your year recap is ready!", table: table)
        static let viewYearRecap = String(localized: "View year recap", table: table)
        static let yearRecapTitle = String(localized: "Year in Review", table: table)

        // Year strings with interpolation
        static func yearWith(year: Int, name: String) -> String {
            String(localized: "\(year) with \(name)", table: table)
        }

        static func yearWithName(name: String) -> String {
            String(localized: "A year with \(name)", table: table)
        }

        static func yearJourney(year: Int) -> String {
            String(localized: "Your \(year) journey", table: table)
        }

        // Year stats
        static func yearWalksCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 walk", table: table)
            } else {
                return String(localized: "\(count) walks", table: table)
            }
        }

        static func yearPhotosCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 photo", table: table)
            } else {
                return String(localized: "\(count) photos", table: table)
            }
        }

        static func yearTrainingCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 session", table: table)
            } else {
                return String(localized: "\(count) sessions", table: table)
            }
        }

        // Year stat labels
        static let walks = String(localized: "walks", table: table)
        static let hours = String(localized: "hours", table: table)
        static let photos = String(localized: "photos", table: table)
        static let training = String(localized: "training", table: table)
        static let social = String(localized: "social", table: table)
        static let friends = String(localized: "friends", table: table)

        static func daysLogged(_ days: Int) -> String {
            String(localized: "\(days) days logged", table: table)
        }

        // Year sections
        static let monthlyHighlights = String(localized: "Monthly Highlights", table: table)
        static let topMoments = String(localized: "Top Moments", table: table)
        static let growthJourney = String(localized: "Growth Journey", table: table)

        // Growth journey
        static let startedAt = String(localized: "Started at", table: table)
        static let endedAt = String(localized: "Ended at", table: table)

        // Year empty state
        static let noDataThisYear = String(localized: "No activity logged this year", table: table)

        // Year accessibility
        static func yearRecapAccessibilityLabel(year: Int, walks: Int, photos: Int) -> String {
            String(localized: "Year recap for \(year): \(walks) walks, \(photos) photos", table: table)
        }
    }
}
