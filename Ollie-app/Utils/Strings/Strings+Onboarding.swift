//
//  Strings+Onboarding.swift
//  Ollie-app
//
//  Onboarding and size category strings

import Foundation

private let table = "Onboarding"

extension Strings {

    // MARK: - Size Categories
    enum SizeCategory {
        static let small = String(localized: "Small (<10kg)", table: table)
        static let medium = String(localized: "Medium (10-25kg)", table: table)
        static let large = String(localized: "Large (25-45kg)", table: table)
        static let extraLarge = String(localized: "Extra large (>45kg)", table: table)

        static let smallExamples = String(localized: "Chihuahua, Maltese, Yorkshire Terrier", table: table)
        static let mediumExamples = String(localized: "Beagle, Cocker Spaniel, Border Collie", table: table)
        static let largeExamples = String(localized: "Labrador, Golden Retriever, German Shepherd", table: table)
        static let extraLargeExamples = String(localized: "Bernese Mountain Dog, Great Dane, Saint Bernard", table: table)
    }

    // MARK: - Onboarding
    enum Onboarding {
        // Welcome step
        static let welcomeSubtitle = String(localized: "Track meals, potty, sleep & walks — and actually understand what your puppy needs.", table: table)
        static let preparingTitle = String(localized: "Preparing for your puppy?", table: table)
        static let preparingSubtitle = String(localized: "Start logging from day one. You'll thank yourself in week two.", table: table)
        static let alreadyInTitle = String(localized: "Already in the deep end?", table: table)
        static let alreadyInSubtitle = String(localized: "Just start tracking. Patterns emerge fast.", table: table)
        static let getStarted = String(localized: "Get Started", table: table)

        static let nameQuestion = String(localized: "What's your puppy's name?", table: table)
        static let nameSubtitle = String(localized: "We'll use this throughout the app", table: table)
        static let namePlaceholder = String(localized: "Name", table: table)
        static let nameAccessibility = String(localized: "Enter your puppy's name", table: table)

        static func breedQuestion(name: String) -> String {
            String(localized: "What breed is \(name)?", table: table)
        }
        static let otherBreed = String(localized: "Other / Unknown", table: table)
        static let enterCustom = String(localized: "Enter custom", table: table)

        static func birthDateQuestion(name: String) -> String {
            String(localized: "When was \(name) born?", table: table)
        }
        static let birthDate = String(localized: "Birth date", table: table)
        static func birthDateAccessibility(name: String) -> String {
            String(localized: "\(name)'s birth date", table: table)
        }

        static func homeDateQuestion(name: String) -> String {
            String(localized: "When did \(name) come home?", table: table)
        }
        static let homeDate = String(localized: "Home date", table: table)
        static func homeDateAccessibility(name: String) -> String {
            String(localized: "Date \(name) came home", table: table)
        }

        static func sizeQuestion(name: String) -> String {
            String(localized: "How big will \(name) get?", table: table)
        }

        static let readyToStart = String(localized: "Ready to begin!", table: table)

        // Photo step
        static func photoQuestion(name: String) -> String {
            String(localized: "Add a photo of \(name)?", table: table)
        }
        static let photoSubtitle = String(localized: "This is optional — you can always add one later.", table: table)
        static let skip = String(localized: "Skip", table: table)

        // Confirmation step
        static let born = String(localized: "Born", table: table)
        static let cameHome = String(localized: "Came home", table: table)
        static let breedOptional = String(localized: "Breed (optional)", table: table)

        // Progress accessibility
        static let progressAccessibility = String(localized: "Setup progress", table: table)
        static func progressValue(current: Int, total: Int) -> String {
            String(localized: "Step \(current) of \(total)", table: table)
        }
    }

    // MARK: - Permissions (Onboarding)
    enum Permissions {
        // Notifications
        static let notificationsTitle = String(localized: "Never miss a potty break", table: table)
        static let notificationsSubtitle = String(localized: "Smart reminders help you stay ahead of your puppy's needs.", table: table)
        static let notificationsBenefit1 = String(localized: "Potty reminders based on patterns", table: table)
        static let notificationsBenefit2 = String(localized: "Meal time alerts", table: table)
        static let notificationsBenefit3 = String(localized: "Nap reminders when awake too long", table: table)
        static let enableNotifications = String(localized: "Enable Notifications", table: table)

        // Location
        static let locationTitle = String(localized: "Track walks & check weather", table: table)
        static let locationSubtitle = String(localized: "Save favorite spots and get weather forecasts for your walks.", table: table)
        static let locationBenefit1 = String(localized: "Save and revisit walk spots", table: table)
        static let locationBenefit2 = String(localized: "Weather forecasts for planning", table: table)
        static let locationBenefit3 = String(localized: "Track routes and distances", table: table)
        static let enableLocation = String(localized: "Enable Location", table: table)

        // Shared
        static let notNow = String(localized: "Not Now", table: table)
        static let letsGo = String(localized: "Let's Go!", table: table)
    }

    // MARK: - Plan Tab
    enum PlanTab {
        static let title = String(localized: "Plan", table: table)
        static let puppyAge = String(localized: "Puppy age", table: table)
        static let upcomingMilestones = String(localized: "Upcoming milestones", table: table)
        static let moments = String(localized: "Moments", table: table)
        static let seeAllMoments = String(localized: "See all moments", table: table)
        static let noUpcomingMilestones = String(localized: "No upcoming milestones", table: table)
        static let allMilestonesDone = String(localized: "All milestones completed!", table: table)
        static let nextUp = String(localized: "Next up", table: table)
        static let overdue = String(localized: "Overdue", table: table)

        static func weeksOld(_ weeks: Int) -> String {
            String(localized: "\(weeks) weeks old", table: table)
        }

        static func monthsOld(_ months: Int) -> String {
            if months == 1 {
                return String(localized: "1 month old", table: table)
            } else {
                return String(localized: "\(months) months old", table: table)
            }
        }

        static func daysHome(_ days: Int) -> String {
            String(localized: "\(days) days home", table: table)
        }

        // Age stages
        static let ageStageNewborn = String(localized: "Newborn", table: table)
        static let ageStageSocialization = String(localized: "Socialization", table: table)
        static let ageStageJuvenile = String(localized: "Juvenile", table: table)
        static let ageStageAdolescent = String(localized: "Adolescent", table: table)
        static let ageStageAdult = String(localized: "Adult", table: table)
    }
}
