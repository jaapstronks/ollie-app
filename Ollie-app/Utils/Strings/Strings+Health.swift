//
//  Strings+Health.swift
//  Ollie-app
//
//  Health and medications strings

import Foundation

extension Strings {

    // MARK: - Health View
    enum Health {
        static let title = String(localized: "Health")
        static let weight = String(localized: "Weight")
        static let milestones = String(localized: "Milestones")
        static let noWeightData = String(localized: "No weight data yet")
        static let logFirstWeight = String(localized: "Log your first weight measurement")
        static let logWeight = String(localized: "Log weight")
        static let currentWeight = String(localized: "Current weight")
        static let growthCurve = String(localized: "Growth curve")
        static let referenceRange = String(localized: "Reference range")

        // Weight status
        static let weightOnTrack = String(localized: "On track")
        static let weightAboveReference = String(localized: "Above reference")
        static let weightBelowReference = String(localized: "Below reference")

        // Weight delta
        static func sinceLast(_ delta: String) -> String {
            String(localized: "\(delta) since last")
        }
        static func sincePrevious(_ delta: String, date: String) -> String {
            String(localized: "\(delta) since \(date)")
        }

        // Chart
        static let weeks = String(localized: "Weeks")
        static let kg = String(localized: "kg")
        static let yourPuppy = String(localized: "Your puppy")
        static let reference = String(localized: "Reference")

        // Milestones
        static let done = String(localized: "Done")
        static let nextUp = String(localized: "Next up")
        static let future = String(localized: "Upcoming")
        static let overdue = String(localized: "Overdue")

        // Default milestones (Dutch vaccination schedule)
        static let firstDewormingBreeder = String(localized: "First deworming (breeder)")
        static let firstVaccination = String(localized: "First vaccination (DHP + Lepto)")
        static let firstVetVisit = String(localized: "First vet visit")
        static let firstDewormingHome = String(localized: "First deworming (home)")
        static let secondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)")
        static let thirdVaccination = String(localized: "Third vaccination (cocktail)")
        static let neuteredDiscussion = String(localized: "Spay/neuter discussion with vet")
        static let yearlyVaccination = String(localized: "Yearly vaccination")

        // Week/month labels
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)")
        }
        static func monthNumber(_ month: Int) -> String {
            String(localized: "\(month) months")
        }

        // Weight log sheet
        static let weightKg = String(localized: "Weight (kg)")
        static let enterWeight = String(localized: "Enter weight")
        static let weightPlaceholder = String(localized: "e.g. 8.5")
    }

    // MARK: - Medications
    enum Medications {
        static let title = String(localized: "Medications")
        static let addMedication = String(localized: "Add medication")
        static let editMedication = String(localized: "Edit medication")
        static let name = String(localized: "Name")
        static let instructions = String(localized: "Instructions")
        static let instructionsPlaceholder = String(localized: "Dosage, notes...")
        static let schedule = String(localized: "Schedule")
        static let daily = String(localized: "Daily")
        static let weekly = String(localized: "Weekly")
        static let times = String(localized: "Times")
        static let addTime = String(localized: "Add time")
        static let linkToMeal = String(localized: "Link to meal")
        static let startDate = String(localized: "Start date")
        static let endDate = String(localized: "End date")
        static let indefinitely = String(localized: "Indefinitely")
        static let untilDate = String(localized: "Until date")
        static let markAsDone = String(localized: "Slide to complete")
        static let overdue = String(localized: "Overdue")
        static let scheduled = String(localized: "scheduled")
        static let noMedications = String(localized: "No medications")
        static let noMedicationsHint = String(localized: "Tap to add your puppy's medications")
        static let active = String(localized: "Active")
        static let paused = String(localized: "Paused")
        static let icon = String(localized: "Icon")
        static let daysOfWeek = String(localized: "Days of week")
        static let duration = String(localized: "Duration")

        // Day names (short)
        static let sunday = String(localized: "Sun")
        static let monday = String(localized: "Mon")
        static let tuesday = String(localized: "Tue")
        static let wednesday = String(localized: "Wed")
        static let thursday = String(localized: "Thu")
        static let friday = String(localized: "Fri")
        static let saturday = String(localized: "Sat")

        static func dayShort(_ index: Int) -> String {
            switch index {
            case 0: return sunday
            case 1: return monday
            case 2: return tuesday
            case 3: return wednesday
            case 4: return thursday
            case 5: return friday
            case 6: return saturday
            default: return ""
            }
        }

        // Delete confirmation
        static let deleteConfirmTitle = String(localized: "Delete medication?")
        static let deleteConfirmMessage = String(localized: "This will remove the medication from your schedule.")
    }
}
