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

        // Milestone sections
        static let upcomingMilestones = String(localized: "Coming Up")
        static let completedMilestones = String(localized: "Completed")
        static let addMilestone = String(localized: "Add Milestone")
        static let completeMilestone = String(localized: "Mark Complete")
        static let uncompleteMilestone = String(localized: "Mark Incomplete")

        // Milestone completion sheet
        static let completeTitle = String(localized: "Complete Milestone")
        static let completionDate = String(localized: "Completion date")
        static let addNotes = String(localized: "Add notes")
        static let notesPlaceholder = String(localized: "Optional notes about this milestone...")
        static let vetClinic = String(localized: "Vet clinic")
        static let vetClinicPlaceholder = String(localized: "Clinic name (optional)")
        static let addToCalendar = String(localized: "Add to Calendar")
        static let removeFromCalendar = String(localized: "Remove from Calendar")
        static let addPhoto = String(localized: "Add Photo")

        // Milestone labels (localized versions of labelKeys)
        static let milestoneFirstDewormingBreeder = String(localized: "First deworming (breeder)")
        static let milestoneFirstVaccination = String(localized: "First vaccination (DHP + Lepto)")
        static let milestoneFirstVaccinationDetail = String(localized: "Core vaccination at 8 weeks")
        static let milestoneFirstVetVisit = String(localized: "First vet visit")
        static let milestoneFirstDewormingHome = String(localized: "First deworming (home)")
        static let milestoneSecondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)")
        static let milestoneSecondVaccinationDetail = String(localized: "Booster vaccination at 12 weeks")
        static let milestoneThirdVaccination = String(localized: "Third vaccination (cocktail)")
        static let milestoneThirdVaccinationDetail = String(localized: "Final puppy vaccination at 16 weeks")
        static let milestoneNeuteredDiscussion = String(localized: "Spay/neuter discussion with vet")
        static let milestoneYearlyVaccination = String(localized: "Yearly vaccination")

        // Developmental milestones
        static let milestoneSocializationStart = String(localized: "Socialization window begins")
        static let milestoneSocializationStartDetail = String(localized: "Critical period for positive experiences starts now")
        static let milestoneSocializationPeak = String(localized: "Peak socialization period")
        static let milestoneSocializationPeakDetail = String(localized: "Most receptive time for new experiences")
        static let milestoneSocializationEnd = String(localized: "Socialization window closing")
        static let milestoneSocializationEndDetail = String(localized: "Window is narrowing - focus on remaining exposures")
        static let milestoneFearPeriod1 = String(localized: "First fear period")
        static let milestoneFearPeriod1Detail = String(localized: "Be extra gentle with new experiences")
        static let milestoneFearPeriod2 = String(localized: "Second fear period")
        static let milestoneFearPeriod2Detail = String(localized: "Temporary increase in fearfulness - stay patient")

        // Administrative milestones
        static let milestoneMicrochipRegistration = String(localized: "Microchip registration")
        static let milestoneInsuranceSetup = String(localized: "Pet insurance setup")
        static let milestoneInsuranceSetupDetail = String(localized: "Consider health insurance coverage")
        static let milestoneDogLicense = String(localized: "Dog license")
        static let milestoneDogLicenseDetail = String(localized: "Register with your municipality if required")

        // Custom milestone (Ollie+)
        static let customMilestoneTitle = String(localized: "Title")
        static let customMilestoneDate = String(localized: "Date")
        static let customMilestoneCategory = String(localized: "Category")
        static let customMilestoneReminder = String(localized: "Reminder")
        static let customMilestoneReminderDays = String(localized: "days before")

        // Milestone timing
        static let today = String(localized: "Today")
        static let photoAdded = String(localized: "Photo added")
        static let addPhotoButton = String(localized: "Add photo")
        static let reminderNextOccurrence = String(localized: "Add reminder for next occurrence")
        static let optionalNotes = String(localized: "Optional notes about this milestone")
        static let calendarHelpText = String(localized: "Add this milestone to your default calendar with a reminder")

        static func inDays(_ days: Int) -> String {
            String(localized: "in \(days)d")
        }

        static func daysOverdue(_ days: Int) -> String {
            String(localized: "\(days)d overdue")
        }

        static func daysAgo(_ days: Int) -> String {
            String(localized: "\(days)d ago")
        }
    }

    // MARK: - This Week Card
    enum ThisWeek {
        static let title = String(localized: "This Week")
        static let socializationActive = String(localized: "Socialization active")
        static let windowEnded = String(localized: "Window ended")
        static let exposures = String(localized: "exposures")
        static let categories = String(localized: "categories")
        static let focusOn = String(localized: "Focus on:")
        static let upcoming = String(localized: "Coming up")
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
