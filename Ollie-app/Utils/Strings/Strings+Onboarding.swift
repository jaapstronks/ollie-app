//
//  Strings+Onboarding.swift
//  Ollie-app
//
//  Onboarding and size category strings

import Foundation

extension Strings {

    // MARK: - Size Categories
    enum SizeCategory {
        static let small = String(localized: "Small (<10kg)")
        static let medium = String(localized: "Medium (10-25kg)")
        static let large = String(localized: "Large (25-45kg)")
        static let extraLarge = String(localized: "Extra large (>45kg)")

        static let smallExamples = String(localized: "Chihuahua, Maltese, Yorkshire Terrier")
        static let mediumExamples = String(localized: "Beagle, Cocker Spaniel, Border Collie")
        static let largeExamples = String(localized: "Labrador, Golden Retriever, German Shepherd")
        static let extraLargeExamples = String(localized: "Bernese Mountain Dog, Great Dane, Saint Bernard")
    }

    // MARK: - Onboarding
    enum Onboarding {
        // Welcome step
        static let welcomeSubtitle = String(localized: "Track meals, potty, sleep & walks — and actually understand what your puppy needs.")
        static let preparingTitle = String(localized: "Preparing for your puppy?")
        static let preparingSubtitle = String(localized: "Start logging from day one. You'll thank yourself in week two.")
        static let alreadyInTitle = String(localized: "Already in the deep end?")
        static let alreadyInSubtitle = String(localized: "Just start tracking. Patterns emerge fast.")
        static let getStarted = String(localized: "Get Started")

        static let nameQuestion = String(localized: "What's your puppy's name?")
        static let namePlaceholder = String(localized: "Name")
        static let nameAccessibility = String(localized: "Enter your puppy's name")

        static func breedQuestion(name: String) -> String {
            String(localized: "What breed is \(name)?")
        }
        static let otherBreed = String(localized: "Other / Unknown")
        static let enterCustom = String(localized: "Enter custom")

        static func birthDateQuestion(name: String) -> String {
            String(localized: "When was \(name) born?")
        }
        static let birthDate = String(localized: "Birth date")
        static func birthDateAccessibility(name: String) -> String {
            String(localized: "\(name)'s birth date")
        }

        static func homeDateQuestion(name: String) -> String {
            String(localized: "When did \(name) come home?")
        }
        static let homeDate = String(localized: "Home date")
        static func homeDateAccessibility(name: String) -> String {
            String(localized: "Date \(name) came home")
        }

        static func sizeQuestion(name: String) -> String {
            String(localized: "How big will \(name) get?")
        }

        static let readyToStart = String(localized: "Ready to begin!")

        // Confirmation step
        static let born = String(localized: "Born")
        static let cameHome = String(localized: "Came home")
        static let breedOptional = String(localized: "Breed (optional)")
    }

    // MARK: - Plan Tab
    enum PlanTab {
        static let title = String(localized: "Plan")
        static let puppyAge = String(localized: "Puppy age")
        static let upcomingMilestones = String(localized: "Upcoming milestones")
        static let moments = String(localized: "Moments")
        static let seeAllMoments = String(localized: "See all moments")
        static let noUpcomingMilestones = String(localized: "No upcoming milestones")
        static let allMilestonesDone = String(localized: "All milestones completed!")
        static let nextUp = String(localized: "Next up")
        static let overdue = String(localized: "Overdue")

        static func weeksOld(_ weeks: Int) -> String {
            String(localized: "\(weeks) weeks old")
        }

        static func monthsOld(_ months: Int) -> String {
            if months == 1 {
                return String(localized: "1 month old")
            } else {
                return String(localized: "\(months) months old")
            }
        }

        static func daysHome(_ days: Int) -> String {
            String(localized: "\(days) days home")
        }
    }
}
