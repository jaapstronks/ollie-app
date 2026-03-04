//
//  Strings+VerticalTimeline.swift
//  Otis-app
//
//  Localization strings for the vertical day-planner timeline

import Foundation

private let table = "Timeline"

extension Strings {

    // MARK: - Vertical Timeline
    enum VerticalTimeline {

        // MARK: - Section & Navigation
        static let sectionTitle = String(localized: "Day timeline", table: table)
        static let now = String(localized: "Now", table: table)
        static let ongoing = String(localized: "Ongoing", table: table)

        // MARK: - Sleep Descriptions
        static func sleepingNow(name: String) -> String {
            String(localized: "\(name) is sleeping", table: table)
        }
        static func sleptThroughNight(name: String) -> String {
            String(localized: "\(name) slept through the night", table: table)
        }
        static func tookShortNap(name: String) -> String {
            String(localized: "\(name) took a short nap", table: table)
        }
        static func tookNap(name: String) -> String {
            String(localized: "\(name) took a nap", table: table)
        }

        // MARK: - Walk Descriptions
        static func wentForWalk(name: String) -> String {
            String(localized: "\(name) went for a walk", table: table)
        }
        static func wentForWalkPeed(name: String) -> String {
            String(localized: "\(name) went for a walk and peed", table: table)
        }
        static func wentForWalkPooped(name: String) -> String {
            String(localized: "\(name) went for a walk and pooped", table: table)
        }
        static func wentForWalkPeedPooped(name: String) -> String {
            String(localized: "\(name) went for a walk and did both", table: table)
        }

        // MARK: - Potty Descriptions
        static func peedOutside(name: String) -> String {
            String(localized: "\(name) peed outside", table: table)
        }
        static func poopedOutside(name: String) -> String {
            String(localized: "\(name) pooped outside", table: table)
        }
        static func hadAccidentPee(name: String) -> String {
            String(localized: "\(name) had an accident (pee)", table: table)
        }
        static func hadAccidentPoop(name: String) -> String {
            String(localized: "\(name) had an accident (poop)", table: table)
        }

        // MARK: - Meal Descriptions
        static func hadMeal(name: String, meal: String) -> String {
            String(localized: "\(name) had \(meal)", table: table)
        }
        static func hadWater(name: String) -> String {
            String(localized: "\(name) had water", table: table)
        }
        static let mealBreakfast = String(localized: "breakfast", table: table)
        static let mealLunch = String(localized: "lunch", table: table)
        static let mealSnack = String(localized: "a snack", table: table)
        static let mealDinner = String(localized: "dinner", table: table)

        // MARK: - Training Descriptions
        static func didTraining(name: String) -> String {
            String(localized: "\(name) did training", table: table)
        }
        static func trainedExercise(name: String, exercise: String) -> String {
            String(localized: "\(name) practiced \(exercise)", table: table)
        }

        // MARK: - Training Session (Grouped)
        static func trainingSessionGeneric(name: String, count: Int) -> String {
            String(localized: "\(name) did \(count) training exercises", table: table)
        }
        static func trainingSessionWithSkills(name: String, count: Int, skills: String) -> String {
            String(localized: "\(name) practiced \(count) skills: \(skills)", table: table)
        }
        static func trainingSessionCount(count: Int) -> String {
            String(localized: "Training (\(count))", table: table)
        }

        // MARK: - Social Descriptions
        static func socializing(name: String) -> String {
            String(localized: "\(name) socialized", table: table)
        }
        static func metSomeone(name: String, who: String) -> String {
            String(localized: "\(name) met \(who)", table: table)
        }

        // MARK: - Other Activity Descriptions
        static func wentToGarden(name: String) -> String {
            String(localized: "\(name) went to the garden", table: table)
        }
        static func wentToCrate(name: String) -> String {
            String(localized: "\(name) went to crate", table: table)
        }
        static func achievedMilestone(name: String) -> String {
            String(localized: "\(name) achieved a milestone", table: table)
        }
        static func behaviorNote(name: String) -> String {
            String(localized: "Behavior note", table: table)
        }
        static func weighed(name: String, weight: String) -> String {
            String(localized: "\(name) weighed \(weight) kg", table: table)
        }
        static func wasWeighed(name: String) -> String {
            String(localized: "\(name) was weighed", table: table)
        }
        static func capturedMoment(name: String) -> String {
            String(localized: "Captured a moment", table: table)
        }
        static func tookMedication(name: String) -> String {
            String(localized: "\(name) took medication", table: table)
        }
        static func wasWith(name: String, caregiver: String) -> String {
            String(localized: "\(name) was with \(caregiver)", table: table)
        }
        static func wasWithCaregiver(name: String) -> String {
            String(localized: "\(name) was with caregiver", table: table)
        }

        // MARK: - Timeline Labels
        static let sleep = String(localized: "Nap", table: table)
        static let walk = String(localized: "Walk", table: table)
        static let pee = String(localized: "Pee", table: table)
        static let poop = String(localized: "Poop", table: table)
        static let accident = String(localized: "Accident", table: table)
        static let meal = String(localized: "Meal", table: table)
        static let water = String(localized: "Water", table: table)
        static let training = String(localized: "Training", table: table)
        static let social = String(localized: "Social", table: table)
        static let weighed = String(localized: "Weighed", table: table)
        static let medication = String(localized: "Medication", table: table)
        static let outdoor = String(localized: "outdoor", table: table)
        static let indoor = String(localized: "indoor", table: table)

        // MARK: - Empty State
        static let noEventsYet = String(localized: "No events yet today", table: table)
        static let addFirstEvent = String(localized: "Tap below to log the first one", table: table)

        // MARK: - Daylight
        static let sunrise = String(localized: "Sunrise", table: table)
        static let sunset = String(localized: "Sunset", table: table)

        // MARK: - Appointments
        static let upcoming = String(localized: "Upcoming", table: table)
        static func scheduledFor(time: String) -> String {
            String(localized: "Scheduled for \(time)", table: table)
        }
    }
}
