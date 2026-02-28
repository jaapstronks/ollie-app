//
//  Strings+Health.swift
//  Ollie-app
//
//  Health and medications strings

import Foundation

private let table = "Health"

extension Strings {

    // MARK: - Health View
    enum Health {
        static let title = String(localized: "Health", table: table)
        static let weight = String(localized: "Weight", table: table)
        static let milestones = String(localized: "Milestones", table: table)
        static let noWeightData = String(localized: "No weight data yet", table: table)
        static let logFirstWeight = String(localized: "Log your first weight measurement", table: table)
        static let logWeight = String(localized: "Log weight", table: table)
        static let currentWeight = String(localized: "Current weight", table: table)
        static let growthCurve = String(localized: "Growth curve", table: table)
        static let referenceRange = String(localized: "Reference range", table: table)

        // Weight status
        static let weightOnTrack = String(localized: "On track", table: table)
        static let weightAboveReference = String(localized: "Above reference", table: table)
        static let weightBelowReference = String(localized: "Below reference", table: table)

        // Weight delta
        static func sinceLast(_ delta: String) -> String {
            String(localized: "\(delta) since last", table: table)
        }
        static func sincePrevious(_ delta: String, date: String) -> String {
            String(localized: "\(delta) since \(date)", table: table)
        }

        // Accessibility
        static func currentWeight(_ weight: String) -> String {
            String(localized: "Current weight: \(weight)", table: table)
        }
        static func weightIncreased(_ delta: String) -> String {
            String(localized: "Gained \(delta)", table: table)
        }
        static func weightDecreased(_ delta: String) -> String {
            String(localized: "Lost \(delta)", table: table)
        }

        // Chart
        static let weeks = String(localized: "Weeks", table: table)
        static let kg = String(localized: "kg", table: table)
        static let lbs = String(localized: "lbs", table: table)
        static let yourPuppy = String(localized: "Your puppy", table: table)
        static let reference = String(localized: "Reference", table: table)

        // Milestones
        static let done = String(localized: "Done", table: table)
        static let nextUp = String(localized: "Next up", table: table)
        static let future = String(localized: "Upcoming", table: table)
        static let overdue = String(localized: "Overdue", table: table)
        static let medicalMilestones = String(localized: "Medical Milestones", table: table)
        static let noMedicalMilestones = String(localized: "No medical milestones yet", table: table)

        // Default milestones (Dutch vaccination schedule)
        static let firstDewormingBreeder = String(localized: "First deworming (breeder)", table: table)
        static let firstVaccination = String(localized: "First vaccination (DHP + Lepto)", table: table)
        static let firstVetVisit = String(localized: "First vet visit", table: table)
        static let firstDewormingHome = String(localized: "First deworming (home)", table: table)
        static let secondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)", table: table)
        static let thirdVaccination = String(localized: "Third vaccination (cocktail)", table: table)
        static let neuteredDiscussion = String(localized: "Spay/neuter discussion with vet", table: table)
        static let yearlyVaccination = String(localized: "Yearly vaccination", table: table)

        // Week/month labels
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)", table: table)
        }
        static func monthNumber(_ month: Int) -> String {
            String(localized: "\(month) months", table: table)
        }

        // Weight log sheet
        static let weightKg = String(localized: "Weight (kg)", table: table)
        static let weightLbs = String(localized: "Weight (lbs)", table: table)
        static let enterWeight = String(localized: "Enter weight", table: table)
        static let weightPlaceholder = String(localized: "e.g. 8.5", table: table)
        static let weightPlaceholderLbs = String(localized: "e.g. 18.7", table: table)

        // Milestone sections
        static let upcomingMilestones = String(localized: "Coming Up", table: table)
        static let completedMilestones = String(localized: "Completed", table: table)
        static let addMilestone = String(localized: "Add Milestone", table: table)
        static let completeMilestone = String(localized: "Mark Complete", table: table)
        static let uncompleteMilestone = String(localized: "Mark Incomplete", table: table)

        // Milestone completion sheet
        static let completeTitle = String(localized: "Complete Milestone", table: table)
        static let completionDate = String(localized: "Completion date", table: table)
        static let addNotes = String(localized: "Add notes", table: table)
        static let notesPlaceholder = String(localized: "Optional notes about this milestone...", table: table)
        static let vetClinic = String(localized: "Vet clinic", table: table)
        static let vetClinicPlaceholder = String(localized: "Clinic name (optional)", table: table)
        static let addToCalendar = String(localized: "Add to Calendar", table: table)
        static let removeFromCalendar = String(localized: "Remove from Calendar", table: table)
        static let addPhoto = String(localized: "Add Photo", table: table)

        // Milestone labels (localized versions of labelKeys)
        static let milestoneFirstDewormingBreeder = String(localized: "First deworming (breeder)", table: table)
        static let milestoneFirstVaccination = String(localized: "First vaccination (DHP + Lepto)", table: table)
        static let milestoneFirstVaccinationDetail = String(localized: "Core vaccination at 8 weeks", table: table)
        static let milestoneFirstVetVisit = String(localized: "First vet visit", table: table)
        static let milestoneFirstDewormingHome = String(localized: "First deworming (home)", table: table)
        static let milestoneSecondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)", table: table)
        static let milestoneSecondVaccinationDetail = String(localized: "Booster vaccination at 12 weeks", table: table)
        static let milestoneThirdVaccination = String(localized: "Third vaccination (cocktail)", table: table)
        static let milestoneThirdVaccinationDetail = String(localized: "Final puppy vaccination at 16 weeks", table: table)
        static let milestoneNeuteredDiscussion = String(localized: "Spay/neuter discussion with vet", table: table)
        static let milestoneYearlyVaccination = String(localized: "Yearly vaccination", table: table)

        // Developmental milestones
        static let milestoneSocializationStart = String(localized: "Socialization window begins", table: table)
        static let milestoneSocializationStartDetail = String(localized: "Critical period for positive experiences starts now", table: table)
        static let milestoneSocializationPeak = String(localized: "Peak socialization period", table: table)
        static let milestoneSocializationPeakDetail = String(localized: "Most receptive time for new experiences", table: table)
        static let milestoneSocializationEnd = String(localized: "Socialization window closing", table: table)
        static let milestoneSocializationEndDetail = String(localized: "Window is narrowing - focus on remaining exposures", table: table)
        static let milestoneFearPeriod1 = String(localized: "First fear period", table: table)
        static let milestoneFearPeriod1Detail = String(localized: "Be extra gentle with new experiences", table: table)
        static let milestoneFearPeriod2 = String(localized: "Second fear period", table: table)
        static let milestoneFearPeriod2Detail = String(localized: "Temporary increase in fearfulness - stay patient", table: table)

        // Administrative milestones
        static let milestoneMicrochipRegistration = String(localized: "Microchip registration", table: table)
        static let milestoneInsuranceSetup = String(localized: "Pet insurance setup", table: table)
        static let milestoneInsuranceSetupDetail = String(localized: "Consider health insurance coverage", table: table)
        static let milestoneDogLicense = String(localized: "Dog license", table: table)
        static let milestoneDogLicenseDetail = String(localized: "Register with your municipality if required", table: table)

        // Custom milestone (Ollie+)
        static let customMilestoneTitle = String(localized: "Title", table: table)
        static let customMilestoneDate = String(localized: "Date", table: table)
        static let customMilestoneCategory = String(localized: "Category", table: table)
        static let customMilestoneReminder = String(localized: "Reminder", table: table)
        static let customMilestoneReminderDays = String(localized: "days before", table: table)

        // Milestone timing
        static let today = String(localized: "Today", table: table)
        static let photoAdded = String(localized: "Photo added", table: table)
        static let addPhotoButton = String(localized: "Add photo", table: table)
        static let reminderNextOccurrence = String(localized: "Add reminder for next occurrence", table: table)
        static let optionalNotes = String(localized: "Optional notes about this milestone", table: table)
        static let calendarHelpText = String(localized: "Add this milestone to your default calendar with a reminder", table: table)

        static func inDays(_ days: Int) -> String {
            String(localized: "in \(days)d", table: table)
        }

        static func daysOverdue(_ days: Int) -> String {
            String(localized: "\(days)d overdue", table: table)
        }

        static func daysAgo(_ days: Int) -> String {
            String(localized: "\(days)d ago", table: table)
        }
    }

    // MARK: - This Week Card
    enum ThisWeek {
        static let title = String(localized: "This Week", table: table)
        static let socializationActive = String(localized: "Socialization active", table: table)
        static let windowEnded = String(localized: "Window ended", table: table)
        static let exposures = String(localized: "exposures", table: table)
        static let categories = String(localized: "categories", table: table)
        static let focusOn = String(localized: "Focus on:", table: table)
        static let upcoming = String(localized: "Coming up", table: table)
    }

    // MARK: - Medications
    enum Medications {
        static let title = String(localized: "Medications", table: table)
        static let addMedication = String(localized: "Add medication", table: table)
        static let editMedication = String(localized: "Edit medication", table: table)
        static let name = String(localized: "Name", table: table)
        static let instructions = String(localized: "Instructions", table: table)
        static let instructionsPlaceholder = String(localized: "Dosage, notes...", table: table)
        static let schedule = String(localized: "Schedule", table: table)
        static let daily = String(localized: "Daily", table: table)
        static let weekly = String(localized: "Weekly", table: table)
        static let times = String(localized: "Times", table: table)
        static let addTime = String(localized: "Add time", table: table)
        static let linkToMeal = String(localized: "Link to meal", table: table)
        static let startDate = String(localized: "Start date", table: table)
        static let endDate = String(localized: "End date", table: table)
        static let indefinitely = String(localized: "Indefinitely", table: table)
        static let untilDate = String(localized: "Until date", table: table)
        static let markAsDone = String(localized: "Slide to complete", table: table)
        static let overdue = String(localized: "Overdue", table: table)
        static let scheduled = String(localized: "scheduled", table: table)
        static let noMedications = String(localized: "No medications", table: table)
        static let noMedicationsHint = String(localized: "Tap to add your puppy's medications", table: table)
        static let active = String(localized: "Active", table: table)
        static let paused = String(localized: "Paused", table: table)
        static let icon = String(localized: "Icon", table: table)
        static let daysOfWeek = String(localized: "Days of week", table: table)
        static let duration = String(localized: "Duration", table: table)

        // Day names (short)
        static let sunday = String(localized: "Sun", table: table)
        static let monday = String(localized: "Mon", table: table)
        static let tuesday = String(localized: "Tue", table: table)
        static let wednesday = String(localized: "Wed", table: table)
        static let thursday = String(localized: "Thu", table: table)
        static let friday = String(localized: "Fri", table: table)
        static let saturday = String(localized: "Sat", table: table)

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
        static let deleteConfirmTitle = String(localized: "Delete medication?", table: table)
        static let deleteConfirmMessage = String(localized: "This will remove the medication from your schedule.", table: table)
    }
}
