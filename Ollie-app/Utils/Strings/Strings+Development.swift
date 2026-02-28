//
//  Strings+Development.swift
//  Ollie-app
//
//  Localized strings for developmental periods, roadmap, and age-based content

import Foundation

private let table = "Development"

extension Strings {

    /// Strings for developmental periods and roadmap
    enum Development {
        // MARK: - Title
        static let title = String(localized: "Development", table: table)

        // MARK: - Section Headers
        static let thisWeek = String(localized: "This Week", table: table)
        static let comingUp = String(localized: "Coming Up", table: table)
        static let later = String(localized: "Later", table: table)

        // MARK: - Roadmap
        static let roadmapTitle = String(localized: "Development Roadmap", table: table)
        static let seeRoadmap = String(localized: "See development roadmap", table: table)
        static let currentStage = String(localized: "Current stage", table: table)
        static let youAreHere = String(localized: "You are here", table: table)

        // MARK: - Developmental Stages
        static let stageNeonatal = String(localized: "Neonatal", table: table)
        static let stageNeonatalDesc = String(localized: "Birth to 2 weeks", table: table)
        static let stageTransitional = String(localized: "Transitional", table: table)
        static let stageTransitionalDesc = String(localized: "2-3 weeks", table: table)
        static let stageSocialization = String(localized: "Socialization", table: table)
        static let stageSocializationDesc = String(localized: "3-16 weeks", table: table)
        static let stageJuvenile = String(localized: "Juvenile", table: table)
        static let stageJuvenileDesc = String(localized: "4-6 months", table: table)
        static let stageAdolescent = String(localized: "Adolescent", table: table)
        static let stageAdolescentDesc = String(localized: "6-18 months", table: table)
        static let stageAdult = String(localized: "Adult", table: table)
        static let stageAdultDesc = String(localized: "18+ months", table: table)

        // MARK: - Period Banners
        static let activePeriods = String(localized: "Active Periods", table: table)
        static let socializationWindow = String(localized: "Socialization Window", table: table)
        static let socializationWindowOpen = String(localized: "Socialization window is open", table: table)
        static let socializationWindowClosing = String(localized: "Socialization window is closing", table: table)
        static let socializationWindowClosed = String(localized: "Socialization window has closed", table: table)
        static let fearPeriod = String(localized: "Fear Period", table: table)
        static let fearPeriodActive = String(localized: "Be extra gentle with new experiences", table: table)

        // MARK: - Period Advice
        static let socializationAdvice = String(localized: "Focus on positive experiences with new people, places, sounds, and other animals.", table: table)
        static let fearPeriodAdvice = String(localized: "Avoid overwhelming situations. Keep new experiences positive and low-pressure.", table: table)

        // MARK: - Age Labels
        static func ageWeekWithDate(week: Int, date: String) -> String {
            String(localized: "Age week \(week) · ~\(date)", table: table)
        }
        static func monthsWithDate(months: Int, date: String) -> String {
            String(localized: "\(months) months · ~\(date)", table: table)
        }

        // MARK: - Weeks Remaining
        static func weeksRemaining(_ weeks: Int) -> String {
            if weeks == 1 {
                return String(localized: "1 week remaining", table: table)
            }
            return String(localized: "\(weeks) weeks remaining", table: table)
        }

        // MARK: - Empty States
        static let noActivePeriods = String(localized: "No active developmental periods", table: table)
        static let nothingThisWeek = String(localized: "Nothing scheduled this week", table: table)
        static let nothingComingUp = String(localized: "Nothing coming up", table: table)
    }
}
